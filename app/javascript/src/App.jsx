import React, { useEffect, useRef, useState } from 'react';

const ACCEPTED_TYPES = '.docx,.pdf,.txt';
const GENERATION_DEBOUNCE_MS = 1200;

const App = () => {
  const [resumeText, setResumeText] = useState('');
  const [coverLetter, setCoverLetter] = useState('');
  const [uploading, setUploading] = useState(false);
  const [generating, setGenerating] = useState(false);
  const [error, setError] = useState('');
  const [notice, setNotice] = useState('');
  const [downloadMenuOpen, setDownloadMenuOpen] = useState(false);

  const fileInputRef = useRef(null);
  const downloadMenuRef = useRef(null);
  const abortControllerRef = useRef(null);
  const debounceTimerRef = useRef(null);

  useEffect(() => {
    if (!downloadMenuOpen) return undefined;

    const handleClickAway = (event) => {
      if (downloadMenuRef.current && !downloadMenuRef.current.contains(event.target)) {
        setDownloadMenuOpen(false);
      }
    };

    document.addEventListener('mousedown', handleClickAway);
    return () => document.removeEventListener('mousedown', handleClickAway);
  }, [downloadMenuOpen]);

  useEffect(() => {
    if (!error && !notice) return undefined;

    const timer = setTimeout(() => {
      setError('');
      setNotice('');
    }, 6000);

    return () => clearTimeout(timer);
  }, [error, notice]);

  useEffect(() => {
    if (debounceTimerRef.current) {
      clearTimeout(debounceTimerRef.current);
      debounceTimerRef.current = null;
    }

    if (uploading) return undefined;

    const trimmed = resumeText.trim();
    if (!trimmed) {
      abortControllerRef.current?.abort();
      abortControllerRef.current = null;
      setGenerating(false);
      setCoverLetter('');
      return undefined;
    }

    debounceTimerRef.current = setTimeout(() => {
      generateCoverLetter(trimmed);
    }, GENERATION_DEBOUNCE_MS);

    return () => {
      if (debounceTimerRef.current) {
        clearTimeout(debounceTimerRef.current);
        debounceTimerRef.current = null;
      }
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [resumeText, uploading]);

  const handleFileUpload = async (event) => {
    const file = event.target.files?.[0];
    if (!file) return;

    setError('');
    setNotice('');
    setUploading(true);

    try {
      const formData = new FormData();
      formData.append('file', file);

      const response = await fetch('/api/resumes', {
        method: 'POST',
        body: formData,
      });

      if (!response.ok) {
        const payload = await safeJson(response);
        setResumeText('');
        setCoverLetter('');
        throw new Error(payload?.error || 'Nie udało się odczytać pliku.');
      }

      const data = await response.json();
      const extractedText = data.resume_text || '';
      setResumeText(extractedText);
      setCoverLetter('');
      setNotice(`${file.name} wczytano. Swinka.CV przygotowuje list motywacyjny…`);
    } catch (err) {
      console.error(err);
      setError(err.message || 'Przesyłanie nie powiodło się.');
    } finally {
      setUploading(false);
      event.target.value = '';
    }
  };

  const generateCoverLetter = async (text) => {
    if (!text) return;

    abortControllerRef.current?.abort();
    const controller = new AbortController();
    abortControllerRef.current = controller;

    setDownloadMenuOpen(false);
    setError('');
    setGenerating(true);
    setNotice('Swinka.CV analizuje CV i pisze list motywacyjny…');

    try {
      const response = await fetch('/api/cover_letters', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ resume_text: text }),
        signal: controller.signal,
      });

      if (!response.ok) {
        const payload = await safeJson(response);
        throw new Error(payload?.error || 'Nie udało się wygenerować listu.');
      }

      const data = await response.json();
      setCoverLetter(data.cover_letter || '');
      setNotice('List gotowy! Możesz go pobrać albo jeszcze poprawić CV.');
    } catch (err) {
      if (err.name === 'AbortError') return;
      console.error(err);
      setError(err.message || 'Generowanie nie powiodło się.');
    } finally {
      if (!controller.signal.aborted) {
        setGenerating(false);
        abortControllerRef.current = null;
      }
    }
  };

  const handleDownload = async (format) => {
    if (!coverLetter.trim() || generating) return;

    setError('');
    setNotice('');

    try {
      const response = await fetch('/api/cover_letters/export', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ cover_letter: coverLetter, format }),
      });

      if (!response.ok) {
        const payload = await safeJson(response);
        throw new Error(payload?.error || 'Nie udało się pobrać pliku.');
      }

      const blob = await response.blob();
      const url = window.URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = `list_motywacyjny.${format}`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      window.URL.revokeObjectURL(url);
    } catch (err) {
      console.error(err);
      setError(err.message || 'Pobieranie nie powiodło się.');
    } finally {
      setDownloadMenuOpen(false);
    }
  };

  const triggerFileDialog = () => {
    fileInputRef.current?.click();
  };

  const showUploadOverlay = !resumeText.trim();

  return (
    <div className="app-shell">
      <div className="background-glow">
        <svg
          className="pig-illustration"
          viewBox="0 0 420 280"
          role="img"
          aria-hidden="true"
        >
          <defs>
            <linearGradient id="pigGradient" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stopColor="#ffe6f0" />
              <stop offset="35%" stopColor="#f9c5d5" />
              <stop offset="100%" stopColor="#f38fb3" />
            </linearGradient>
            <radialGradient id="pigLight" cx="30%" cy="30%" r="70%">
              <stop offset="0%" stopColor="#fff5fb" />
              <stop offset="100%" stopColor="#f8bcd0" stopOpacity="0.2" />
            </radialGradient>
          </defs>
          <g transform="translate(40 20)" fill="none" strokeLinecap="round">
            <path
              d="M88 74c-18-32 6-68 54-68 48 0 78 36 94 92 24-12 42-8 58 12 16 20 10 62-22 72 0 28-32 52-80 52-66 0-110-36-126-92-18-62 24-68 24-68"
              fill="url(#pigGradient)"
              stroke="#f38fb3"
              strokeWidth="6"
            />
            <path
              d="M258 112c24-4 44 10 44 34s-18 38-36 44"
              stroke="#f38fb3"
              strokeWidth="8"
            />
            <path
              d="M84 110c-22-4-42 10-42 34s16 36 32 42"
              stroke="#f38fb3"
              strokeWidth="8"
            />
            <path
              d="M118 192c18 16 60 16 78-2"
              stroke="#ec5f98"
              strokeWidth="10"
            />
            <ellipse cx="168" cy="142" rx="46" ry="34" fill="#f89abd" stroke="#ec5f98" strokeWidth="4" />
            <ellipse cx="150" cy="142" rx="6" ry="10" fill="#1f1f1f" />
            <ellipse cx="186" cy="142" rx="6" ry="10" fill="#1f1f1f" />
            <ellipse cx="128" cy="112" rx="22" ry="24" fill="#fde7f3" stroke="#f9b1cd" strokeWidth="4" />
            <ellipse cx="208" cy="112" rx="22" ry="24" fill="#fde7f3" stroke="#f9b1cd" strokeWidth="4" />
            <circle cx="120" cy="112" r="7" fill="#1f1f1f" />
            <circle cx="200" cy="112" r="7" fill="#1f1f1f" />
            <path d="M108 72c12-22 40-32 72-28" stroke="#f9a7c9" strokeWidth="10" />
            <path d="M232 72c-12-22-40-32-72-28" stroke="#f9a7c9" strokeWidth="10" />
            <path d="M292 126c24 36 6 74-24 88" stroke="#f8a8cc" strokeWidth="14" />
            <path d="M56 126c-24 34-6 74 22 88" stroke="#f8a8cc" strokeWidth="14" />
            <path d="M298 150c26 14 40 60 2 90" stroke="#f278a8" strokeWidth="12" strokeLinejoin="round" />
            <path d="M52 150c-26 14-40 60-2 90" stroke="#f278a8" strokeWidth="12" strokeLinejoin="round" />
            <path d="M276 206c16 2 26 12 26 22 0 16-20 26-38 18" stroke="#f38fb3" strokeWidth="8" />
            <path d="M76 206c-16 2-26 12-26 22 0 16 20 26 38 18" stroke="#f38fb3" strokeWidth="8" />
            <path d="M286 90c18-18 28-42 16-64 24 4 32 38 12 62" stroke="#f793c0" strokeWidth="8" />
            <path d="M60 90c-18-18-28-42-16-64-24 4-32 38-12 62" stroke="#f793c0" strokeWidth="8" />
            <path d="M216 210c6 8 2 18-8 22" stroke="#ec5f98" strokeWidth="6" />
            <path d="M248 210c6 10 2 20-10 24" stroke="#ec5f98" strokeWidth="6" />
            <path d="M120 210c-6 8-2 18 8 22" stroke="#ec5f98" strokeWidth="6" />
            <path d="M92 210c-6 10-2 20 10 24" stroke="#ec5f98" strokeWidth="6" />
            <ellipse cx="168" cy="132" rx="90" ry="72" fill="url(#pigLight)" opacity="0.6" />
          </g>
        </svg>
      </div>

      <header className="app-header">
        <div className="brand-wrap">
          <span className="brand-title">Swinka.CV</span>
        </div>
        <p className="brand-tagline">Napiszę profesjonalny list motywacyjny na podstawie CV.</p>
      </header>

      <div className="workspace">
        <section className="pane">
          <input
            ref={fileInputRef}
            type="file"
            accept={ACCEPTED_TYPES}
            className="file-input"
            onChange={handleFileUpload}
          />

          <div className="pane-body">
            <textarea
              className="pane-textarea"
              placeholder="Wklej treść CV albo wczytaj plik DOCX/PDF. Wszelkie zmiany w CV automatycznie odświeżą list."
              value={resumeText}
              onChange={(event) => setResumeText(event.target.value)}
            />
            <div className={`upload-overlay ${showUploadOverlay ? 'visible' : ''}`}>
              <button
                type="button"
                className="primary-button large"
                onClick={triggerFileDialog}
                disabled={uploading}
              >
                {uploading ? 'Wczytywanie…' : 'Prześlij CV'}
              </button>
              <p>Swinka.CV obsługuje PDF oraz DOCX. Po wczytaniu natychmiast zaczyna się pisanie listu.</p>
            </div>
          </div>

          {resumeText.trim() && (
            <div className="pane-controls pane-controls--bottom">
              <button className="primary-button hollow" type="button" onClick={triggerFileDialog} disabled={uploading}>
                {uploading ? 'Wczytywanie…' : 'Prześlij CV ponownie'}
              </button>
            </div>
          )}
        </section>

        <section className="pane">
          <div className="pane-body">
            <div className="cover-letter-surface">
              {generating && !coverLetter && (
                <div className="cover-letter-placeholder">
                  <p>Swinka.CV analizuje Twoje CV i przygotowuje spersonalizowany list motywacyjny…</p>
                </div>
              )}

              {!generating && !coverLetter && (
                <div className="cover-letter-placeholder">
                  <p>Tutaj pojawi się Twój list motywacyjny. Zacznij od wczytania CV.</p>
                  <p>Zmiana w polu CV od razu odświeży treść listu motywacyjnego.</p>
                </div>
              )}

              {coverLetter && (
                <div className={`cover-letter-text ${generating ? 'muted' : ''}`}>
                  {coverLetter.split(/\n{2,}/).map((paragraph, index) => (
                    <p key={index}>{paragraph.trim()}</p>
                  ))}

                  {generating && (
                    <div className="regenerating-pill">Swinka.CV aktualizuje treść na podstawie ostatnich zmian…</div>
                  )}
                </div>
              )}
            </div>
          </div>

          {coverLetter.trim() && (
            <div className="pane-controls pane-controls--bottom" ref={downloadMenuRef}>
              <div className="download-wrapper">
                <button
                  className="primary-button download"
                  onClick={() => setDownloadMenuOpen((open) => !open)}
                >
                  Pobierz list motywacyjny
                </button>
                {downloadMenuOpen && (
                  <div className="download-menu">
                    <button type="button" onClick={() => handleDownload('docx')}>
                      Word (.docx)
                    </button>
                    <button type="button" onClick={() => handleDownload('pdf')}>
                      PDF (.pdf)
                    </button>
                  </div>
                )}
              </div>
            </div>
          )}
        </section>
      </div>

      {(error || notice) && (
        <div className={`toast ${error ? 'toast-error' : 'toast-notice'}`}>
          {error || notice}
        </div>
      )}
    </div>
  );
};

async function safeJson(response) {
  try {
    return await response.json();
  } catch (_err) {
    return null;
  }
}

export default App;
