/* jshint esnext: true */

// == Reprocess Font Awesome CSS == //
var fa = (css, font) => (

// Font Awesome CSS attribution and license
css.match(/\/\*\![^]*?\*\//)[0] + '\n' +

// Font Awesome web font
`@font-face {
  font-family: FontAwesome;
  src: url('data:application/font-woff;base64,${font}') format('woff');
  font-weight: 400;
  font-style: normal;
}
` +

// fa-[icon name] classes
css
  .match(/(\.fa-[^{]*{\s*content:[^}]*}\s*)+/)[0]
  .replace(/([,{;])\s+/g, '$1')
  .replace(/,/g, ', ')

);

// == DM Mono web font (SIL OFL 1.1, see src/css/fonts/OFL.txt) == //
// Bundled as data URIs, like Font Awesome above, so the board's own content
// security policy never gets a say and nothing is fetched from a font CDN.
var dmMono = ([regular, medium, italic]) => (

'/* DM Mono, Copyright 2020 The DM Mono Project Authors (https://www.github.com/googlefonts/dm-mono), SIL Open Font License 1.1 */\n' +
[[regular, 400, 'normal'], [medium, 500, 'normal'], [italic, 400, 'italic']].map(([font, weight, style]) =>
`@font-face {
  font-family: "DM Mono";
  src: url('data:font/woff2;base64,${font}') format('woff2');
  font-weight: ${weight};
  font-style: ${style};
  font-display: swap;
}
`
).join('')

);

// == Create CSS for Link Title Favicons == //
var icons = (names, data) => (

'/* Link Title Favicons */\n' +
names.map((file, i) =>
`.linkify.${file.split('.')[1]}::before {
  content: "";
  background: transparent url('data:image/png;base64,${data[i]}') center left no-repeat!important;
  padding-left: 18px;
}
`
).join('')

);

return {fa, dmMono, icons};
