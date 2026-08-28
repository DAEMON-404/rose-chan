# Applies 4chan X's own themes (the two Rosé Pine variants) and the optional
# motion layer. The CSS lives in src/css/rose-pine.css and src/css/animations.css;
# this module only decides which classes belong on <html>, and keeps them in
# sync as settings change in this tab or another one.
Theme =
  variants: ['rose-pine-dawn', 'rose-pine']
  accents:  ['iris', 'foam', 'rose', 'pine', 'gold', 'love']
  # Classes Main.setClass applies to match the site's own stylesheet. While one
  # of our themes is on they would fight with it, so they come off.
  nativeStyles: ['yotsuba', 'yotsuba-b', 'futaba', 'burichan', 'photon', 'tomorrow', 'spooky']
  densities: ['compact', 'normal', 'roomy']
  speeds:   ['fast', 'normal', 'slow']

  init: ->
    return if !doc

    Theme.apply()

    # Follow the OS colour scheme while "Auto Theme" is on.
    if (mql = Theme.media())
      onSchemeChange = -> Theme.apply() if Conf['Auto Theme']
      if mql.addEventListener
        mql.addEventListener 'change', onSchemeChange
      else if mql.addListener
        # Deprecated, but the only option on older engines.
        mql.addListener onSchemeChange

    # Keep every tab in agreement.
    for key of Config.themes
      do (key) ->
        $.sync key, (val) ->
          Conf[key] = val ? Config.themes[key]
          Theme.apply()

    $.on d, 'ThreadUpdate', Theme.onThreadUpdate

    Theme.addShortcut()

  media: ->
    unless 'mql' of Theme
      Theme.mql = window.matchMedia?('(prefers-color-scheme: dark)') or null
    Theme.mql

  prefersDark: ->
    !!Theme.media()?.matches

  # The variant actually in force, resolving "Auto Theme" against the OS.
  current: ->
    theme = Conf['Theme']
    return 'none' unless theme in Theme.variants
    return (if Theme.prefersDark() then 'rose-pine' else 'rose-pine-dawn') if Conf['Auto Theme']
    theme

  enabled: ->
    Theme.current() isnt 'none'

  setClass: (className, enabled) ->
    (if enabled then $.addClass else $.rmClass) doc, className

  apply: ->
    theme = Theme.current()
    $.rmClass doc, 'rp-theme', Theme.variants...
    if theme isnt 'none'
      $.addClass doc, 'rp-theme', theme
      $.rmClass doc, Theme.nativeStyles...
    Theme.applyModifiers()
    Theme.applyMotion()
    Theme.updateShortcut()
    Theme.scrollToTop.refresh()
    Theme.progress.refresh()
    # Turning the theme off hands styling of our dialogs back to the site's
    # own stylesheet, which Main only re-reads when asked.
    Main.updateNativeStyle?()

  applyModifiers: ->
    $.rmClass doc, ("rp-accent-#{accent}" for accent in Theme.accents)...
    accent = Conf['Theme Accent']
    $.addClass doc, "rp-accent-#{accent}" if accent in Theme.accents

    $.rmClass doc, 'rp-compact', 'rp-roomy'
    density = Conf['Theme Density']
    $.addClass doc, "rp-#{density}" if density in ['compact', 'roomy']

    Theme.setClass 'rp-square',      Conf['Square Corners']
    Theme.setClass 'rp-modern-font', Conf['Modern Font']
    Theme.setClass 'rp-card-op',     Conf['Card OP']
    Theme.setClass 'rp-blur',        Conf['Blur Effects']

  applyMotion: ->
    animations = !!Conf['Animations']
    Theme.setClass 'fourchanx-animations', animations

    $.rmClass doc, 'fx-speed-fast', 'fx-speed-slow'
    speed = Conf['Animation Speed']
    $.addClass doc, "fx-speed-#{speed}" if speed in ['fast', 'slow']

    Theme.setClass 'fx-hover-lift',    animations and Conf['Hover Effects']
    Theme.setClass 'fx-force-motion',  Conf['Force Motion']
    Theme.setClass 'fx-smooth-scroll', Conf['Smooth Scrolling']

  # Posts pulled in by the thread updater fade in instead of appearing abruptly.
  onThreadUpdate: (e) ->
    return unless Conf['Animations']
    {newPosts} = e.detail
    return unless newPosts
    for fullID in newPosts
      root = g.posts.get(fullID)?.nodes.root
      Theme.markNew root if root
    return

  markNew: (root) ->
    $.addClass root, 'fx-new-post'
    $.one root, 'animationend', -> $.rmClass root, 'fx-new-post'

  # Header shortcut for flipping between the two variants in one click.
  addShortcut: ->
    return unless Header?.addShortcut
    Theme.shortcut = $.el 'a',
      className: 'theme-toggle-link fa'
      href:      'javascript:;'
    $.on Theme.shortcut, 'click', Theme.toggleVariant
    Theme.updateShortcut()
    Header.addShortcut 'theme-toggle', Theme.shortcut, 810

  updateShortcut: ->
    return unless Theme.shortcut
    theme = Theme.current()
    Theme.shortcut.hidden = theme is 'none'
    dark = theme is 'rose-pine'
    Theme.shortcut.textContent = if dark then 'Light' else 'Dark'
    Theme.shortcut.title = "Switch to Rosé Pine #{if dark then 'Dawn' else 'Dark'}"
    $.rmClass Theme.shortcut, 'fa-sun-o', 'fa-moon-o'
    $.addClass Theme.shortcut, (if dark then 'fa-sun-o' else 'fa-moon-o')

  toggleVariant: ->
    return unless Theme.enabled()
    # An explicit click is a deliberate choice, so it wins over "Auto Theme".
    if Conf['Auto Theme']
      Conf['Auto Theme'] = false
      $.set 'Auto Theme', false
    theme = if Theme.current() is 'rose-pine' then 'rose-pine-dawn' else 'rose-pine'
    Conf['Theme'] = theme
    $.set 'Theme', theme
    Theme.apply()
    $.event 'ThemeChanged', {theme}

# Floating button that returns to the top of a long thread or index.
Theme.scrollToTop =
  init: ->
    Main.ready -> Theme.scrollToTop.refresh()

  refresh: ->
    return unless d.body
    if Conf['Scroll to Top']
      return if Theme.scrollToTop.el
      Theme.scrollToTop.el = el = $.el 'button',
        id:        'scroll-to-top'
        className: 'fa fa-chevron-up'
        title:     'Back to top'
        type:      'button'
      $.on el, 'click', Theme.scrollToTop.jump
      $.add d.body, el
      $.on window, 'scroll resize', Theme.scrollToTop.onScroll
      Theme.scrollToTop.onScroll()
    else if Theme.scrollToTop.el
      $.off window, 'scroll resize', Theme.scrollToTop.onScroll
      $.rm Theme.scrollToTop.el
      delete Theme.scrollToTop.el

  onScroll: ->
    return if Theme.scrollToTop.ticking
    Theme.scrollToTop.ticking = true
    $.queueTask ->
      Theme.scrollToTop.ticking = false
      return unless (el = Theme.scrollToTop.el)
      show = (window.pageYOffset or doc.scrollTop) > 400
      (if show then $.addClass else $.rmClass) el, 'visible'

  jump: ->
    # scroll-behavior on <html> covers the smooth case; this stays a plain jump
    # so it still works when smooth scrolling is turned off.
    window.scrollTo 0, 0

# Thin bar showing how far through the page you have read.
Theme.progress =
  init: ->
    Main.ready -> Theme.progress.refresh()

  refresh: ->
    return unless d.body
    if Conf['Reading Progress']
      return if Theme.progress.el
      Theme.progress.fill = $.el 'div', className: 'progress-fill'
      Theme.progress.el   = $.el 'div', id: 'reading-progress'
      $.add Theme.progress.el, Theme.progress.fill
      $.add d.body, Theme.progress.el
      $.on window, 'scroll resize', Theme.progress.onScroll
      Theme.progress.onScroll()
    else if Theme.progress.el
      $.off window, 'scroll resize', Theme.progress.onScroll
      $.rm Theme.progress.el
      delete Theme.progress.el
      delete Theme.progress.fill

  onScroll: ->
    return if Theme.progress.ticking
    Theme.progress.ticking = true
    $.queueTask ->
      Theme.progress.ticking = false
      return unless (fill = Theme.progress.fill)
      max = d.body.scrollHeight - window.innerHeight
      top = window.pageYOffset or doc.scrollTop
      fraction = if max > 0 then Math.min(1, Math.max(0, top / max)) else 0
      fill.style.width = "#{(fraction * 100).toFixed(2)}%"
