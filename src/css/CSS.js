<%
  var inc       = require['style'];
  var faCSS     = read('/node_modules/font-awesome/css/font-awesome.css');
  var faWebFont = readBase64('/node_modules/font-awesome/fonts/fontawesome-webfont.woff');
  var dmMono    = inc.dmMono(['Regular', 'Medium', 'Italic'].map(x => readBase64(`fonts/DMMono-${x}.woff2`)));
  var mainCSS   = ['font-awesome', 'style', 'yotsuba', 'yotsuba-b', 'futaba', 'burichan', 'tomorrow', 'photon', 'spooky', 'rose-pine', 'animations'].map(x => read(`${x}.css`)).join('');
  var iconNames = files.filter(f => /^linkify\.[^.]+\.png$/.test(f));
  var icons     = iconNames.map(readBase64);
%>CSS = {

boards:
<%= multiline(
  inc.fa(faCSS, faWebFont) + dmMono + mainCSS + inc.icons(iconNames, icons) + read('supports.css')
) %>,

report:
<%= multiline(read('report.css')) %>,

www:
<%= multiline(read('www.css')) %>,

sub: function(css) {
  var variables = {
    site: g.SITE.selectors
  };
  return css.replace(/\$[\w\$]+/g, function(name) {
    var words = name.slice(1).split('$');
    var sel = variables;
    for (var i = 0; i < words.length; i++) {
      if (typeof sel !== 'object') return ':not(*)';
      sel = $.getOwn(sel, words[i]);
    }
    if (typeof sel !== 'string') return ':not(*)';
    return sel;
  });
}

};
