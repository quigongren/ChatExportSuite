#!/usr/bin/env node
// macOS Helper v2.0 – Markdown → DOCX (+ optional DOCX → PDF)
// Modes:
//   md-to-docx       <input.md> <output.docx>
//   md-to-docx-pdf   <input.md> <output.docx> <output.pdf>

"use strict";

const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");

const HOME = process.env.HOME || process.env.USERPROFILE || "";
const LOG_DIR = path.join(HOME, "Documents", "CashDevInstallLogs");

if (!fs.existsSync(LOG_DIR)) {
  try {
    fs.mkdirSync(LOG_DIR, { recursive: true });
  } catch (e) {
    // If logging directory cannot be created, continue without file logging.
  }
}

const ts = new Date().toISOString().replace(/[:]/g, "-").replace(/\..+/, "");
const LOG_FILE = path.join(LOG_DIR, `helper_v2.0_${ts}.log`);

function writeLogLine(line) {
  const msg = `[Helper v2.0] ${line}\n`;
  try {
    fs.appendFileSync(LOG_FILE, msg);
  } catch (e) {
    // ignore file logging errors
  }
  process.stdout.write(msg);
}

function runCommand(cmd, args) {
  writeLogLine(`RUN: ${cmd} ${args.join(" ")}`);
  try {
    const out = execFileSync(cmd, args, { encoding: "utf8" });
    if (out && out.trim()) {
      writeLogLine(`OUT: ${out.trim()}`);
    }
    return true;
  } catch (err) {
    const stderr = err.stderr ? err.stderr.toString() : "";
    if (stderr.trim()) {
      writeLogLine(`ERR: ${stderr.trim()}`);
    }
    writeLogLine(`Command failed: ${cmd} (${err.message})`);
    return false;
  }
}

function findPandoc() {
  const candidates = [
    "/opt/homebrew/bin/pandoc",
    "/usr/local/bin/pandoc",
    "/usr/bin/pandoc",
    "pandoc"
  ];
  for (const p of candidates) {
    try {
      execFileSync(p, ["--version"], { stdio: "ignore" });
      return p;
    } catch (e) {
      // try next
    }
  }
  return null;
}

function mdToDocx(inputMd, outputDocx) {
  if (!fs.existsSync(inputMd)) {
    writeLogLine(`ERROR: Input markdown not found: ${inputMd}`);
    process.exit(10); // MD_READ_FAIL
  }

  const pandoc = findPandoc();
  if (!pandoc) {
    writeLogLine("ERROR: pandoc not found. Install with: brew install pandoc");
    process.exit(20); // DOCX_FAIL
  }

  writeLogLine(`Converting Markdown → DOCX`);
  writeLogLine(`  IN:  ${inputMd}`);
  writeLogLine(`  OUT: ${outputDocx}`);

  const ok = runCommand(pandoc, [inputMd, "-f", "markdown", "-t", "docx", "-o", outputDocx]);
  if (!ok) {
    writeLogLine("ERROR: pandoc DOCX conversion failed.");
    process.exit(20); // DOCX_FAIL
  }

  if (!fs.existsSync(outputDocx)) {
    writeLogLine("ERROR: DOCX file not created.");
    process.exit(20); // DOCX_FAIL
  }

  writeLogLine("DOCX conversion complete.");
}

function docxToPdf(docxPath, pdfPath) {
  let fallbackUsed = false;

  if (!fs.existsSync(docxPath)) {
    writeLogLine(`ERROR: DOCX input not found for PDF: ${docxPath}`);
    process.exit(20); // DOCX_FAIL
  }

  writeLogLine(`Starting DOCX → PDF fallback chain.`);

  // 1) textutil
  if (fs.existsSync("/usr/bin/textutil")) {
    writeLogLine("Trying macOS textutil for DOCX → PDF...");
    const ok = runCommand("/usr/bin/textutil", ["-convert", "pdf", docxPath, "-output", pdfPath]);
    fallbackUsed = true;
    if (ok && fs.existsSync(pdfPath)) {
      writeLogLine("DOCX → PDF via textutil succeeded.");
      process.exit(fallbackUsed ? 40 : 0); // FALLBACK_TRIGGERED or OK
    } else {
      writeLogLine("WARNING: textutil conversion failed or output missing.");
    }
  } else {
    writeLogLine("WARNING: textutil not found at /usr/bin/textutil.");
  }

  // 2) LibreOffice headless
  const sofficeCandidates = [
    "/Applications/LibreOffice.app/Contents/MacOS/soffice",
    "/Applications/LibreOffice.app/Contents/MacOS/soffice.bin"
  ];
  let soffice = null;
  for (const s of sofficeCandidates) {
    if (fs.existsSync(s)) {
      soffice = s;
      break;
    }
  }

  if (soffice) {
    writeLogLine(`Trying LibreOffice headless via: ${soffice}`);
    const outDir = path.dirname(pdfPath);
    const ok = runCommand(soffice, [
      "--headless",
      "--nologo",
      "--convert-to",
      "pdf",
      "--outdir",
      outDir,
      docxPath
    ]);
    fallbackUsed = true;
    const guessedPdf = path.join(outDir, path.basename(docxPath, path.extname(docxPath)) + ".pdf");
    const finalPdf = fs.existsSync(pdfPath) ? pdfPath : guessedPdf;
    if (ok && fs.existsSync(finalPdf)) {
      if (finalPdf !== pdfPath) {
        try {
          fs.renameSync(finalPdf, pdfPath);
        } catch (e) {
          writeLogLine(`WARNING: Could not rename LibreOffice PDF to target: ${e.message}`);
        }
      }
      if (fs.existsSync(pdfPath)) {
        writeLogLine("DOCX → PDF via LibreOffice succeeded.");
        process.exit(40); // FALLBACK_TRIGGERED
      }
    }
    writeLogLine("WARNING: LibreOffice conversion failed or output missing.");
  } else {
    writeLogLine("INFO: LibreOffice not installed; skipping that fallback.");
  }

  writeLogLine("ERROR: All DOCX → PDF fallbacks failed. DOCX is valid; PDF not created.");
  process.exit(30); // PDF_FAIL
}

function main() {
  const argv = process.argv.slice(2);
  const mode = argv[0];

  if (!mode || mode === "-h" || mode === "--help") {
    console.log(
      "macOS Helper v2.0\n" +
      "Usage:\n" +
      "  node helper.mjs md-to-docx <input.md> <output.docx>\n" +
      "  node helper.mjs md-to-docx-pdf <input.md> <output.docx> <output.pdf>\n"
    );
    process.exit(0);
  }

  if (mode === "md-to-docx") {
    const inputMd = argv[1];
    const outputDocx = argv[2];
    if (!inputMd || !outputDocx) {
      writeLogLine("ERROR: md-to-docx requires <input.md> <output.docx>");
      process.exit(10); // MD_READ_FAIL
    }
    mdToDocx(path.resolve(inputMd), path.resolve(outputDocx));
    process.exit(0);
  } else if (mode === "md-to-docx-pdf") {
    const inputMd = argv[1];
    const outputDocx = argv[2];
    const outputPdf = argv[3];
    if (!inputMd || !outputDocx || !outputPdf) {
      writeLogLine("ERROR: md-to-docx-pdf requires <input.md> <output.docx> <output.pdf>");
      process.exit(10); // MD_READ_FAIL
    }
    const inPath = path.resolve(inputMd);
    const docxPath = path.resolve(outputDocx);
    const pdfPath = path.resolve(outputPdf);
    mdToDocx(inPath, docxPath);
    docxToPdf(docxPath, pdfPath);
  } else {
    writeLogLine(`ERROR: Unknown mode: ${mode}`);
    process.exit(99); // FATAL
  }
}

try {
  main();
} catch (e) {
  writeLogLine(`FATAL: ${e.message}`);
  process.exit(99);
}
