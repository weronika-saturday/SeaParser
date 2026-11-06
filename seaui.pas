unit SeaUI;

{ Neumorphism ("soft UI") theme for SeaParser, built with csscontrols.
  CSS and HTML are kept here so the look can be changed without touching the form code. }

{$mode objfpc}{$H+}

interface

const
  // Palette (taken from the reference picture)
  //   background  #e9edf0
  //   light shade #ffffff   (top-left)
  //   dark shade  #c5ccd6   (bottom-right)
  //   accent      #5493fc
  //   text        #6b7380
  SEA_BG_COLOR = $F0EDE9;   // #e9edf0 in TColor (BGR) for native TEdit backgrounds

  SEA_CSS =
    // font-family is set on .app (the top node of the markup): it is inherited by all text
    '.app { background-color: #e9edf0; font-family: "Inter", "Segoe UI", "Tahoma", "DejaVu Sans", sans-serif; color: #6b7380;' +
    '  display: flex; flex-direction: column; gap: 10px; padding: 22px 26px 24px 26px; }' +

    // header
    '.header { display: flex; align-items: center; gap: 14px; margin-bottom: 8px; }' +
    '.logo { width: 46px; height: 46px; border-radius: 23px; background-color: #5493fc; color: #ffffff;' +
    '  display: flex; align-items: center; justify-content: center;' +
    '  box-shadow: 5px 5px 10px #c5ccd6, -5px -5px 10px #ffffff; }' +
    '.logo svg { width: 24px; height: 24px; }' +
    '.title { font-size: 20px; font-weight: 600; color: #4a5260; }' +
    '.subtitle { font-size: 12px; color: #9aa2ae; }' +

    // labels and rows
    '.label { font-size: 12px; font-weight: 600; color: #8a93a0; margin: 4px 0 0 14px; }' +
    '.row { display: flex; align-items: center; gap: 14px; }' +

    // inset (pressed) text field like the "search for" bar
    '.field { flex-grow: 1; height: 44px; border-radius: 22px; background-color: #e9edf0;' +
    '  display: flex; align-items: center; padding: 0 18px; cursor: text;' +
    '  box-shadow: inset 4px 4px 8px #c5ccd6, inset -4px -4px 8px #ffffff; }' +
    '.input { flex-grow: 1; height: 22px; font-size: 13px; color: #a3abb7; }' +

    // raised round icon button
    '.iconbtn { width: 44px; height: 44px; border-radius: 22px; background-color: #e9edf0; color: #6b7380;' +
    '  display: flex; align-items: center; justify-content: center; flex-shrink: 0; cursor: pointer;' +
    '  box-shadow: 5px 5px 10px #c5ccd6, -5px -5px 10px #ffffff; transition: color 150ms; }' +
    '.iconbtn svg { width: 20px; height: 20px; }' +
    '.iconbtn:hover { color: #5493fc; }' +
    '.iconbtn:active { box-shadow: inset 4px 4px 8px #c5ccd6, inset -4px -4px 8px #ffffff; }' +

    // radio options
    '.choice { display: flex; align-items: center; gap: 10px; height: 44px; padding: 0 18px 0 8px;' +
    '  border-radius: 22px; background-color: #e9edf0; color: #6b7380; cursor: pointer; font-size: 13px;' +
    '  box-shadow: 5px 5px 10px #c5ccd6, -5px -5px 10px #ffffff; transition: color 150ms; }' +
    '.choice:hover { color: #5493fc; }' +
    '.choice svg { width: 16px; height: 16px; }' +
    '.radio { width: 30px; height: 30px; border-radius: 15px; background-color: #e9edf0;' +
    '  display: flex; align-items: center; justify-content: center;' +
    '  box-shadow: inset 3px 3px 6px #c5ccd6, inset -3px -3px 6px #ffffff; }' +
    '.dot { width: 12px; height: 12px; border-radius: 6px; background-color: #e9edf0; transition: background-color 150ms; }' +
    '.checked { color: #5493fc; }' +
    '.checked .dot { background-color: #5493fc; }' +

    // primary blue button
    '.spacer { flex-grow: 1; }' +
    '.primary { display: flex; align-items: center; justify-content: center; gap: 8px; height: 44px; padding: 0 28px;' +
    '  border-radius: 22px; background-color: #5493fc; color: #ffffff; font-size: 14px; font-weight: 600; cursor: pointer;' +
    '  box-shadow: 5px 5px 10px #c5ccd6, -5px -5px 10px #ffffff; transition: background-color 150ms; }' +
    '.primary svg { width: 16px; height: 16px; }' +
    '.primary:hover { background-color: #4a88f2; }' +
    '.primary:active { background-color: #3f7be3; box-shadow: inset 3px 3px 6px #3769c4, inset -3px -3px 6px #6aa3ff; }' +

    // progress / status
    '.track { height: 8px; border-radius: 4px; background-color: #e9edf0; margin-top: 10px;' +
    '  box-shadow: inset 2px 2px 4px #c5ccd6, inset -2px -2px 4px #ffffff; }' +
    '.bar { height: 8px; border-radius: 4px; background-color: #5493fc; width: 0%; transition: background-color 300ms; }' +
    '.status { font-size: 12px; color: #9aa2ae; margin-left: 14px; }' +
    '.ok { color: #5493fc; }' +
    '.err { color: #e5677a; }';

  // Lucide icons (ISC License, https://lucide.dev)
  ICON_WAVES  = '<svg viewBox="0 0 24 24" stroke-width="2"><path d="M2 6c.6.5 1.2 1 2.5 1C7 7 7 5 9.5 5c2.6 0 2.4 2 5 2 2.5 0 2.5-2 5-2 1.3 0 1.9.5 2.5 1"/>' +
                '<path d="M2 12c.6.5 1.2 1 2.5 1 2.5 0 2.5-2 5-2 2.6 0 2.4 2 5 2 2.5 0 2.5-2 5-2 1.3 0 1.9.5 2.5 1"/>' +
                '<path d="M2 18c.6.5 1.2 1 2.5 1 2.5 0 2.5-2 5-2 2.6 0 2.4 2 5 2 2.5 0 2.5-2 5-2 1.3 0 1.9.5 2.5 1"/></svg>';
  ICON_FOLDER = '<svg viewBox="0 0 24 24" stroke-width="2"><path d="m6 14 1.5-2.9A2 2 0 0 1 9.24 10H20a2 2 0 0 1 1.94 2.5l-1.54 6a2 2 0 0 1-1.95 1.5H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h3.9a2 2 0 0 1 1.69.9l.81 1.2a2 2 0 0 0 1.67.9H18a2 2 0 0 1 2 2v2"/></svg>';
  ICON_SAVE   = '<svg viewBox="0 0 24 24" stroke-width="2"><path d="M15.2 3a2 2 0 0 1 1.4.6l3.8 3.8a2 2 0 0 1 .6 1.4V19a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2z"/>' +
                '<path d="M17 21v-7a1 1 0 0 0-1-1H8a1 1 0 0 0-1 1v7"/><path d="M7 3v4a1 1 0 0 0 1 1h7"/></svg>';
  ICON_BOX    = '<svg viewBox="0 0 24 24" stroke-width="2"><path d="M21 8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16Z"/>' +
                '<path d="m3.3 7 8.7 5 8.7-5"/><path d="M12 22V12"/></svg>';
  ICON_IMAGE  = '<svg viewBox="0 0 24 24" stroke-width="2"><rect width="18" height="18" x="3" y="3" rx="2" ry="2"/><circle cx="9" cy="9" r="2"/>' +
                '<path d="m21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21"/></svg>';
  ICON_PLAY   = '<svg viewBox="0 0 24 24" stroke-width="2"><polygon points="6 3 20 12 6 21 6 3"/></svg>';

  SEA_HTML =
    '<div class="app">' +
    '  <div class="header">' +
    '    <div class="logo">' + ICON_WAVES + '</div>' +
    '    <div><div class="title">SeaParser</div><div class="subtitle">Source Engine Assets Parser</div></div>' +
    '  </div>' +

    '  <div class="label">MAP FILE</div>' +
    '  <div class="row">' +
    '    <div class="field"><div class="input" id="mapEdit">Select a .vmf file...</div></div>' +
    '    <div class="iconbtn" id="openBtn">' + ICON_FOLDER + '</div>' +
    '  </div>' +

    '  <div class="label">ASSETS LIST</div>' +
    '  <div class="row">' +
    '    <div class="field"><div class="input" id="listEdit">Where to save the .txt list...</div></div>' +
    '    <div class="iconbtn" id="saveBtn">' + ICON_SAVE + '</div>' +
    '  </div>' +

    '  <div class="label">ASSETS TYPE</div>' +
    '  <div class="row">' +
    '    <div class="choice checked" id="optModels"><div class="radio"><div class="dot"></div></div>' + ICON_BOX + 'Models</div>' +
    '    <div class="choice" id="optTextures"><div class="radio"><div class="dot"></div></div>' + ICON_IMAGE + 'Textures</div>' +
    '    <div class="spacer"></div>' +
    '    <div class="primary" id="parseBtn">' + ICON_PLAY + 'Parse</div>' +
    '  </div>' +

    '  <div class="track"><div class="bar" id="bar"></div></div>' +
    '  <div class="status" id="status">Ready</div>' +
    '</div>';

implementation

end.
