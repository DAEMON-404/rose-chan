# Applies 4chan X's own themes (the two Rosé Pine variants), the look that sits
# on top of them (Dossier Declassified or the plain classic cards), and the
# optional motion layer. The CSS lives in src/css/rose-pine.css and
# src/css/animations.css; this module only decides which classes belong on
# <html>, keeps them in sync as settings change in this tab or another one, and
# owns the small pieces of DOM the theme adds: the case-file header, the
# redaction screen, the scanline sweep and the staggered reveal.
Theme =
  variants: ['rose-pine-dawn', 'rose-pine']
  styles:   ['dossier', 'classic']
  fonts:    ['dm-mono', 'system', 'board']
  accents:  ['iris', 'foam', 'rose', 'pine', 'gold', 'love']
  # Classes Main.setClass applies to match the site's own stylesheet. While one
  # of our themes is on they would fight with it, so they come off.
  nativeStyles: ['yotsuba', 'yotsuba-b', 'futaba', 'burichan', 'photon', 'tomorrow', 'spooky']
  densities: ['compact', 'normal', 'roomy']
  speeds:   ['fast', 'normal', 'slow']

  # Settings that only make sense inside one look or the other.
  dossierOnly: ['Stamps', 'Paper Grain']

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
    Theme.reveal.init()

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

  style: ->
    style = Conf['Theme Style']
    if style in Theme.styles then style else 'dossier'

  font: ->
    font = Conf['Theme Font']
    if font in Theme.fonts then font else 'dm-mono'

  setClass: (className, enabled) ->
    (if enabled then $.addClass else $.rmClass) doc, className

  apply: ->
    theme = Theme.current()
    $.rmClass doc, 'rp-theme', Theme.variants...
    if theme isnt 'none'
      $.addClass doc, 'rp-theme', theme
      $.rmClass doc, Theme.nativeStyles...
    Theme.applyModifiers theme isnt 'none'
    Theme.applyMotion()
    Theme.updateShortcut()
    Theme.scrollToTop.refresh()
    Theme.progress.refresh()
    Theme.dossier.refresh()
    Theme.redact.refresh()
    # A change of variant after the first paint gets the scanline. The first
    # apply happens before the body exists, so nothing runs then.
    if Theme.applied? and Theme.applied isnt theme
      Theme.sweep()
    Theme.applied = theme
    # Turning the theme off hands styling of our dialogs back to the site's
    # own stylesheet, which Main only re-reads when asked.
    Main.updateNativeStyle?()

  # Everything here is scoped to rp-theme in the CSS, but the classes come off
  # anyway when the theme is off so nothing leaks if a rule ever loses its guard.
  applyModifiers: (enabled) ->
    $.rmClass doc, ("rp-#{style}"  for style  in Theme.styles)...
    $.rmClass doc, ("rp-font-#{font}" for font in Theme.fonts)...
    $.rmClass doc, ("rp-accent-#{accent}" for accent in Theme.accents)...
    $.rmClass doc, 'rp-compact', 'rp-roomy', 'rp-square', 'rp-card-op', 'rp-blur',
      'rp-grain', 'rp-stamps', 'rp-spotlight'
    return unless enabled

    $.addClass doc, "rp-#{Theme.style()}"
    $.addClass doc, "rp-font-#{Theme.font()}"

    accent = Conf['Theme Accent']
    $.addClass doc, "rp-accent-#{accent}" if accent in Theme.accents

    density = Conf['Theme Density']
    $.addClass doc, "rp-#{density}" if density in ['compact', 'roomy']

    Theme.setClass 'rp-square',    Conf['Square Corners']
    Theme.setClass 'rp-card-op',   Conf['Card OP']
    Theme.setClass 'rp-blur',      Conf['Blur Effects']
    Theme.setClass 'rp-grain',     Conf['Paper Grain']
    Theme.setClass 'rp-stamps',    Conf['Stamps']
    Theme.setClass 'rp-spotlight', Conf['Spotlight']

  applyMotion: ->
    animations = !!Conf['Animations']
    Theme.setClass 'fourchanx-animations', animations

    $.rmClass doc, 'fx-speed-fast', 'fx-speed-slow'
    speed = Conf['Animation Speed']
    $.addClass doc, "fx-speed-#{speed}" if speed in ['fast', 'slow']

    Theme.setClass 'fx-hover-lift',    animations and Conf['Hover Effects']
    Theme.setClass 'fx-force-motion',  Conf['Force Motion']
    Theme.setClass 'fx-smooth-scroll', Conf['Smooth Scrolling']

  motionEnabled: ->
    $.hasClass doc, 'fourchanx-animations'

  # Posts pulled in by the thread updater fade (or, in the dossier look, stamp)
  # in instead of appearing abruptly.
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

  # A scanline runs down the page when the variant flips. Only while the
  # motion layer is on: without it the element would never animate, and so
  # never get its animationend to clean itself up.
  sweep: ->
    return unless d.body and Theme.motionEnabled()
    $.rm Theme.scanEl if Theme.scanEl
    Theme.scanEl = el = $.el 'div', id: 'rp-scan'
    done = ->
      $.rm el
      delete Theme.scanEl if Theme.scanEl is el
    $.one el, 'animationend', done
    # Belt and braces, in case the animation is interrupted.
    setTimeout done, 2000
    $.add d.body, el

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

  # One-click bundles for the Theme tab. Each sets several options at once and
  # leaves everything it does not name alone.
  presets:
    'dossier-dark':
      'Theme':       'rose-pine'
      'Auto Theme':  false
      'Theme Style': 'dossier'
      'Theme Font':  'dm-mono'
      'Card OP':     true
      'Paper Grain': true
      'Stamps':      true
    'dossier-dawn':
      'Theme':       'rose-pine-dawn'
      'Auto Theme':  false
      'Theme Style': 'dossier'
      'Theme Font':  'dm-mono'
      'Card OP':     true
      'Paper Grain': true
      'Stamps':      true
    'classic-dark':
      'Theme':       'rose-pine'
      'Auto Theme':  false
      'Theme Style': 'classic'
      'Theme Font':  'system'
    'classic-dawn':
      'Theme':       'rose-pine-dawn'
      'Auto Theme':  false
      'Theme Style': 'classic'
      'Theme Font':  'system'
    'off':
      'Theme':       'none'

  applyPreset: (name) ->
    return unless (preset = $.getOwn Theme.presets, name)
    for key, val of preset
      Conf[key] = val
      $.set key, val
    Theme.apply()
    $.event 'ThemeChanged', {theme: Theme.current()}
    preset

  # Which preset the current settings match, if any, so the tab can mark it.
  activePreset: ->
    for name, preset of Theme.presets
      match = true
      for key, val of preset when Conf[key] isnt val
        match = false
        break
      return name if match
    null

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

# The first screen of posts (or catalog cards) slides in one after another on
# load. Purely cosmetic: the class is removed as soon as each animation ends,
# and nothing waits on it.
Theme.reveal =
  limit: 16

  init: ->
    $.one d, '4chanXInitFinished', Theme.reveal.run
    $.on  d, 'IndexRefresh',       Theme.reveal.run

  run: ->
    return unless Conf['Animations'] and Conf['Reveal on Load'] and Theme.motionEnabled()
    nodes = $$ ".thread > #{g.SITE.selectors.postContainer}, .catalog-thread"
    for node, i in nodes when i < Theme.reveal.limit
      node.style.setProperty '--fx-i', i
      $.addClass node, 'fx-reveal'
      $.one node, 'animationend', Theme.reveal.done
    return

  done: ->
    $.rmClass @, 'fx-reveal'
    @style.removeProperty '--fx-i'

# Case file header at the top of a thread: number, board, when it was opened,
# how many entries, files and posters it has, its status, and a stamp.
Theme.dossier =
  init: ->
    return unless g.VIEW is 'thread'
    $.one d, '4chanXInitFinished', Theme.dossier.refresh
    $.on  d, 'ThreadUpdate',       Theme.dossier.update
    $.on  d, 'PostsInserted',      Theme.dossier.update

  thread: ->
    return null unless g.VIEW is 'thread' and g.threads
    g.threads.get "#{g.BOARD.ID}.#{g.THREADID}"

  refresh: ->
    thread = Theme.dossier.thread()
    unless thread?.OP?.nodes.root and thread.nodes.root and Theme.enabled() and Conf['Dossier Header']
      Theme.dossier.remove()
      return
    unless Theme.dossier.el
      Theme.dossier.build()
      $.before thread.nodes.root, Theme.dossier.el
    Theme.dossier.update()

  remove: ->
    return unless Theme.dossier.el
    $.rm Theme.dossier.el
    delete Theme.dossier.el
    delete Theme.dossier.nodes

  build: ->
    Theme.dossier.el = el = $.el 'div',
      id: 'rp-dossier'
    ,
      `<%= html(
        '<div class="rp-dossier-head">' +
          '<span class="rp-tag">Case file</span>' +
          '<span class="rp-dossier-no"></span>' +
          '<span class="rp-dossier-board"></span>' +
          '<span class="rp-status"></span>' +
        '</div>' +
        '<dl>' +
          '<div><dt>Opened</dt><dd class="rp-opened"></dd></div>' +
          '<div><dt>Entries</dt><dd class="rp-entries"></dd></div>' +
          '<div><dt>Files</dt><dd class="rp-files"></dd></div>' +
          '<div><dt>Posters</dt><dd class="rp-posters"></dd></div>' +
          '<div><dt>Last entry</dt><dd class="rp-last"></dd></div>' +
        '</dl>' +
        '<span class="rp-stamp" aria-hidden="true">Declassified</span>'
      ) %>`
    Theme.dossier.nodes =
      no:      $ '.rp-dossier-no', el
      board:   $ '.rp-dossier-board', el
      status:  $ '.rp-status', el
      opened:  $ '.rp-opened', el
      entries: $ '.rp-entries', el
      files:   $ '.rp-files', el
      posters: $ '.rp-posters', el
      last:    $ '.rp-last', el

  update: ->
    return unless (nodes = Theme.dossier.nodes) and (thread = Theme.dossier.thread())
    files = 0
    last  = null
    for ID in thread.posts.keys
      post = thread.posts.get ID
      continue unless post
      files += post.files.length
      last = post
    boardTitle = $('.boardTitle')?.textContent.replace(/^\/\w+\/\s*-\s*/, '') or ''
    nodes.no.textContent      = "No. #{thread.ID}"
    nodes.board.textContent   = "/#{g.BOARD.ID}/#{if boardTitle then ' · ' + boardTitle else ''}"
    nodes.opened.textContent  = Theme.dossier.formatDate thread.OP.info.date
    nodes.entries.textContent = thread.posts.keys.length
    nodes.files.textContent   = files
    nodes.posters.textContent = thread.ipCount ? '—'
    nodes.last.textContent    = if last?.info.date then Theme.dossier.relative(last.info.date) else '—'
    status = switch
      when thread.isArchived then 'archived'
      when thread.isDead     then 'expired'
      when thread.isClosed   then 'closed'
      when thread.isSticky   then 'pinned'
      else 'open'
    nodes.status.dataset.status = status
    nodes.status.textContent = status

  formatDate: (date) ->
    return '—' unless date instanceof Date and !isNaN(date)
    pad = (n) -> ('0' + n).slice(-2)
    "#{date.getFullYear()}-#{pad date.getMonth() + 1}-#{pad date.getDate()} #{pad date.getHours()}:#{pad date.getMinutes()}"

  relative: (date) ->
    return '—' unless date instanceof Date and !isNaN(date)
    diff = Math.max 0, Date.now() - date.getTime()
    return 'just now' if diff < 60 * 1000
    minutes = Math.floor diff / (60 * 1000)
    return "#{minutes} min ago" if minutes < 60
    hours = Math.floor minutes / 60
    return "#{hours} h ago" if hours < 48
    days = Math.floor hours / 24
    "#{days} d ago"

# A privacy screen: one press inks over every post, name, file and thumbnail
# on the page until pressed again. Nothing is saved; the next page load starts
# clear. Bound to a keybind and, optionally, a header shortcut.
Theme.redact =
  init: ->
    return unless Header?.addShortcut
    Theme.redact.shortcut = $.el 'a',
      className: 'redact-link fa fa-eye-slash'
      href:      'javascript:;'
    $.on Theme.redact.shortcut, 'click', Theme.redact.toggle
    Theme.redact.refresh()

  active: ->
    $.hasClass doc, 'rp-redacted'

  toggle: ->
    Theme.redact.set !Theme.redact.active()

  set: (active) ->
    Theme.setClass 'rp-redacted', active
    Theme.redact.refresh()

  refresh: ->
    return unless (link = Theme.redact.shortcut)
    active = Theme.redact.active()
    link.textContent = if active then 'Reveal' else 'Redact'
    link.title = "#{if active then 'Reveal the page' else 'Redact every post on the page'} (#{Conf['Toggle redaction'] or 'no keybind'})"
    $.rmClass link, 'fa-eye', 'fa-eye-slash'
    $.addClass link, (if active then 'fa-eye' else 'fa-eye-slash')
    if Conf['Redaction Shortcut']
      Header.addShortcut 'redact', link, 805 unless link.parentNode
    else if link.parentNode
      Header.rmShortcut link
