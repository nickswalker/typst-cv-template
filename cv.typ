// CV generated from a JSON Resume-style file.
//
//   ./build.sh
//
// Settings that are likely to change are near the top: fonts, metrics, which
// sections appear and in what order.

#let data = json(sys.inputs.at("cv", default: "cv.json"))
#let basics = data.basics

// The body font needs light, regular, medium, semibold and bold weights and
// an italic. Either can also be set when building:
//   ./build.sh compile --input body-font="EB Garamond"
#let body-font = sys.inputs.at("body-font", default: "Source Serif 4")
#let name-font = sys.inputs.at("name-font", default: body-font)

// ---------------------------------------------------------------------------
// Metrics
// ---------------------------------------------------------------------------
#let size = 11pt
#let lead = 15pt // baseline grid
#let text-width = 504pt
// Horizontal positions sit on a 12-column grid without gutters
#let unit = text-width / 12 // 42pt
#let tab = 4 * unit // subtitle tab stop, a third of the way across
#let tab-wide = 5 * unit // for long titles
#let min-gap = unit / 3 // smallest allowed gap between tabbed columns
#let second-line-indent = 12pt // the one small indent: second lines, bullet text
#let pub-indent = unit
#let review-columns = 3 // 4 units each, so they line up with the subtitle tab
#let review-tab = 2 * unit
#let icon-width = unit / 2
#let keep = 2 // rows or entries kept together at the end of a section
#let gray = rgb("#a7a9ac")
#let rule = 0.3pt + gray

#let section-order = (
  "Education",
  "Appointments",
  "Interests",
  "Publications",
  "Research Experience",
  "Grants",
  "Teaching Experience",
  "Mentoring",
  "Leadership and Professional Service",
  "Recognition",
  "Skills",
  "Personal",
)
// (heading, label prefix, types)
#let publication-order = (
  ("Thesis", "t", ("thesis",)),
  ("Conference", "c", ("conference",)),
  ("Preprint", "a", ("preprint", "working")),
  ("Journal", "j", ("journal",)),
  ("Patent", "p", ("patent",)),
  ("Refereed Symposium, Workshop", "w", ("symposium", "workshop")),
  ("Periodical Feature", "f", ("feature", "periodical")),
)
#let pub-link-suffix = "?ref=cv"
#let show-education-highlights = true

// ---------------------------------------------------------------------------
// Page and text setup
// ---------------------------------------------------------------------------
#set document(
  title: basics.name + "’s CV",
  author: basics.name,
  description: basics.summary,
)

#let folio(body) = text(weight: 300, fill: gray, body)

#set page(
  paper: "us-letter",
  // Lines of 15pt; last baseline at 744pt. The first baseline is at 69pt on
  // the first page, and a line lower on later pages to clear the header.
  margin: (x: 54pt, top: 58pt + lead, bottom: 44pt),
  header-ascent: lead,
  footer-descent: 0pt,
  header: context if counter(page).get().first() > 1 {
    folio(basics.name + h(1fr) + counter(page).display())
  },
  footer: context if counter(page).get().first() == 1 {
    folio(h(1fr) + "Updated " + datetime.today().display("[month repr:long] [year]"))
  },
)

// Fixed top/bottom edges make every line exactly one grid unit tall, whatever
// its font or size, so everything stays on the baseline grid.
#set text(
  font: body-font,
  size: size,
  number-type: "old-style", // dates and years are switched to lining figures
  lang: "en",
  hyphenate: false, // the text is ragged right anyway
  top-edge: 11pt,
  bottom-edge: -4pt,
)
#set par(leading: 0pt, spacing: 0pt, justify: false, linebreaks: "optimized")
#set block(spacing: 0pt)

// The data uses straight apostrophes. None of it uses single quotation marks,
// so every one can become a typographic apostrophe.
#show "'": "’"

#show heading: set text(size: size, weight: 600)
#show heading: set block(above: 0pt, below: 0pt, sticky: true)
#show heading.where(level: 1): it => block({
  // No rule when the section starts a page; it would run into the header
  context if here().position().y > page.margin.top + 1pt {
    place(top + left, dy: 11pt - 18.06pt, line(length: 100%, stroke: rule))
  }
  // Smaller, wider capitals than the body, so entry titles are the strongest thing in a section
  text(size: 9pt, tracking: 0.08em, upper(it.body))
})

#let blank-line = v(lead, weak: true)

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
#let get(item, key) = item.at(key, default: none)

#let linked(url, body) = if body != none and url != none and url != "" { link(url, body) } else { body }

#let strip-protocol(url) = url.replace(regex("^https?://"), "")

#let date-string(item) = {
  let start = get(item, "startDate")
  let end = get(item, "endDate")
  if start != none {
    if end == none { start + "–" } else if end != start { start + "–" + end.slice(-2) } else { start }
  } else if get(item, "date") != none {
    item.date
  }
}

#let semibold = text.with(weight: 600)
#let medium = text.with(weight: 500)
#let plain(body) = body
// Without overhang, a trailing period or dash stays inside the right margin
#let date-text = text.with(number-type: "lining", overhang: false)

// Entry titles are headings, so readers can navigate by entry, but they are
// set inline and kept out of the bookmarks. They sit at level 2 because
// PDF/UA does not allow skipping from level 1 to 3.
#show <entry>: it => it.body
#let entry-title(body) = [#heading(level: 2, outlined: false, body) <entry>]

// Rows have up to three tabbed columns: left, middle, and a flush-right date.
// These helpers work on the styled (left, middle, date) content of a row and
// need to be called in a context, since they measure.
#let fits(stop, left, mid, date) = {
  let date-width = if date == none { 0pt } else { measure(date).width + min-gap }
  measure(left).width + min-gap <= stop and stop + measure(mid).width + date-width <= text-width
}

// Whichever of the two tab stops puts the most rows of a section on a single
// line, preferring the narrower
#let section-stop(rows) = {
  let best = (stop: tab, count: -1)
  for stop in (tab, tab-wide) {
    let count = rows.filter(row => fits(stop, ..row)).len()
    if count > best.count { best = (stop: stop, count: count) }
  }
  best.stop
}

// Where the middle column of a row starts, or none if it needs its own line
#let row-stop(row, section) = if fits(section, ..row) { section }

// A section's entries: a title, an optional subtitle and date, and whatever
// follows in `body`. Each item is (left, mid, date, url, body).
#let entries(items, left-style: semibold, mid-style: emph) = context {
  let rows = items.map(item => (
    left-style(item.left),
    if get(item, "mid") != none { mid-style(item.mid) },
    if get(item, "date") != none { date-text(item.date) },
  ))
  let section = section-stop(rows.filter(row => row.at(1) != none))
  let pieces = items.zip(rows).enumerate().map(((i, (item, (left, mid, date)))) => {
    let url = get(item, "url")
    let title = entry-title(linked(url, left))
    // A title stays with what follows it: its own body, or for the first
    // entry of a section, the second one
    let sticky = get(item, "body") != none or i == 0
    block(breakable: false, sticky: sticky, {
      if mid == none {
        title + h(1fr) + linked(url, date)
      } else {
        let stop = row-stop((left, mid, date), section)
        if stop != none {
          box(width: stop, title) + linked(url, mid) + h(1fr) + linked(url, date)
        } else {
          title + h(1fr) + linked(url, date) + linebreak() + h(second-line-indent) + linked(url, mid)
        }
      }
    })
    get(item, "body")
  })
  // The last entries share a page, so one is never stranded
  let split = calc.max(pieces.len() - keep, 0)
  pieces.slice(0, split).join()
  block(breakable: false, pieces.slice(split).join())
}

// Plain rows on the same tab stops, tagged as a table. Each row is
// (left, middle, date, url).
#let tabbed-table(items) = context {
  let rows = items.map(((left, mid, date, url)) => (left, mid, if date != none { date-text(date) }))
  let section = section-stop(rows)
  let cells = items
      .zip(rows)
      .map((((.., url), (left, mid, date))) => {
        if row-stop((left, mid, date), section) == none {
          (table.cell(colspan: 2, linked(url, left + linebreak() + h(second-line-indent) + mid)), linked(url, date))
        } else {
          // A middle cell gets its natural width, so it runs into the date
          // column instead of wrapping when this row's date is narrower
          let wide(body) = box(width: measure(body).width + 0.1pt, body)
          (linked(url, left), linked(url, wide(mid)), linked(url, date))
        }
      })
  let body = table.with(columns: (section, 1fr, auto), stroke: none, inset: 0pt, align: (left, left, right))
  if cells.len() <= keep + 1 {
    block(breakable: false, body(..cells.flatten()))
  } else {
    // Rows cannot be glued to each other, but a footer is never broken, so
    // the last rows go there to keep them on one page
    body(..cells.slice(0, -keep).flatten(), table.footer(repeat: false, ..cells.slice(-keep).flatten()))
  }
}

// Bullets hang to the left, so the text lines up with second-line subtitles
#let highlights(item) = {
  let items = item.at("highlights", default: ()).map(highlight => if type(highlight) == str {
    highlight
  } else {
    linked(get(highlight, "link"), highlight.description)
  })
  if items.len() > 0 {
    let marker-width = 6.3pt
    list(
      marker: box(width: marker-width, align(left, "•")),
      indent: second-line-indent - marker-width,
      body-indent: 0pt,
      spacing: 0pt,
      ..items
    )
  }
}

// The CV owner's name is underlined in author lists:
// "Jordan Avery" -> matches "J. Avery", "J. P. Avery", "J. Avery*"
#let own-name = {
  let parts = basics.name.split(" ")
  regex(parts.first().first() + "\.\s(?:\p{Lu}\.\s)*" + parts.last() + "\*?")
}

#let pub-venue(item, kind) = {
  if kind == "a" {
    emph(item.publisher) + ":" + item.eprint + ", " + item.releaseDate + "."
  } else if get(item, "shortName") != none and get(item, "year") != none {
    emph(item.shortName) + "\u{a0}" + item.year + "."
  } else if kind in ("p", "f") {
    emph(item.publisher) + ", " + item.releaseDate + "."
  } else {
    emph(item.publisher) + ". " + item.releaseDate + "."
  }
}

#let pub-link(item) = if get(item, "link") != none { item.link + pub-link-suffix }

#let publication(item, kind) = block(
  breakable: false,
  linked(pub-link(item), {
    medium("“" + item.name + ".”")
    " "
    {
      show own-name: underline.with(offset: 1pt, stroke: 0.55pt, evade: false)
      item.authors
    }
    ". "
    pub-venue(item, kind)
  }),
)

// Numbered in reverse, so the newest item carries the highest number: [c15]
#let publications(items, kind) = enum(
  numbering: n => linked(pub-link(items.at(items.len() - n)), box(width: pub-indent, "[" + kind + str(n) + "]")),
  reversed: true,
  start: items.len(),
  number-align: start + top,
  indent: 0pt,
  body-indent: 0pt,
  spacing: 0pt,
  ..items.map(item => publication(item, kind))
)

// (2027, 2026, 2025, 2023) -> ’27–’25, ’23
#let year-ranges(years) = {
  let ranges = ()
  for year in years.sorted().rev() {
    if ranges.len() > 0 and ranges.last().last() - 1 == year {
      let range = ranges.pop()
      ranges.push((range.first(), year))
    } else {
      ranges.push((year, year))
    }
  }
  let short(year) = "’" + str(year).slice(-2)
  ranges
    .map(((from, to)) => if from == to { short(from) } else { short(from) + "–" + short(to) })
    .join(", ")
}

#let reviewing(items, count: review-columns) = {
  let venues = (:)
  for item in items {
    let year = int(item.date)
    let venue = venues.at(item.shortName, default: (years: (), site: none, site-year: 0))
    if year not in venue.years { venue.years.push(year) }
    let site = get(item, "website")
    if site != none and site != "https://" and year > venue.site-year {
      venue.site = site
      venue.site-year = year
    }
    venues.insert(item.shortName, venue)
  }
  // Most recently reviewed first, then alphabetical
  let names = venues.keys().sorted(key: name => (-calc.max(..venues.at(name).years), name))
  let entries = names.map(name => {
    let venue = venues.at(name)
    let fits = measure(name).width < review-tab
    // One box per entry: a link over several fragments gets QuadPoints, which Preview and Safari mishandle
    linked(venue.site, box((if fits { box(width: review-tab, name) } else { name + h(0.5em) }) + text(number-type: "lining", year-ranges(venue.years))))
  })
  // A fixed height makes the list fill down the columns evenly, and the
  // block moves to the next page whole rather than splitting its columns
  block(
    breakable: false,
    height: calc.ceil(entries.len() / count) * lead,
    columns(count, gutter: 0pt, list(marker: none, indent: 0pt, body-indent: 0pt, spacing: 0pt, ..entries)),
  )
}

#let icon(network) = if network == "home" {
  text(font: "Font Awesome 5 Free Solid", weight: 900, network)
} else {
  text(font: "Font Awesome 5 Brands", network)
}

// Icons differ in width, so each gets the same box to keep the URLs aligned
#let profile(network, url) = block(link(url, box(box(width: icon-width, icon(network)) + strip-protocol(url))))

// ---------------------------------------------------------------------------
// Sections
// ---------------------------------------------------------------------------
#let sections = (
  "Education": () => entries(
    data
      .education
      .filter(item => get(item, "hide") != true)
      .map(item => (
        left: item.studyType + " " + item.area,
        mid: item.institution + ", " + item.location,
        date: date-string(item),
        url: get(item, "link"),
        body: if show-education-highlights { highlights(item) },
      )),
  ),
  "Appointments": () => entries(data.appointments.map(item => (
    left: item.position,
    mid: item.company,
    date: date-string(item),
    url: get(item, "website"),
  ))),
  "Interests": () => block(data.interests),
  "Publications": () => {
    let first = true
    for (title, kind, types) in publication-order {
      let items = data.publications.filter(item => item.type in types)
      if items.len() == 0 { continue }
      if not first { blank-line }
      first = false
      heading(level: 2, title)
      publications(items, kind)
    }
  },
  "Research Experience": () => entries(data.research_experience.map(item => (
    left: item.position,
    mid: item.company,
    date: date-string(item),
    url: get(item, "website"),
    body: highlights(item),
  ))),
  "Teaching Experience": () => entries(data.teaching_experience.map(item => (
    left: item.position,
    mid: item.company,
    date: date-string(item),
    url: get(item, "website"),
    body: highlights(item),
  ))),
  "Grants": () => entries(
    left-style: medium,
    data.grants.map(item => (
      left: item.name,
      date: date-string(item),
      url: get(item, "link"),
      body: block(item.awarder + ", " + item.type + ". " + item.amount + ". " + item.role + "."),
    )),
  ),
  "Mentoring": () => {
    let year(value, default) = if value == none { default } else { int(value) }
    let mentees = data.mentoring.sorted(key: item => (
      -year(get(item, "endDate"), 9999),
      -year(get(item, "startDate"), 0),
    ))
    tabbed-table(mentees.map(item => {
      let next = get(item, "next")
      (item.name, item.role + if next != none { " » " + next }, date-string(item), get(item, "url"))
    }))
  },
  "Leadership and Professional Service": () => {
    tabbed-table(
      data
        .volunteer
        .filter(item => item.position != "Reviewer")
        .map(item => (item.position, item.organization, date-string(item), get(item, "website"))),
    )
    blank-line
    heading(level: 2, "Reviewing")
    context reviewing(data.volunteer.filter(item => item.position == "Reviewer"))
  },
  "Recognition": () => entries(data.awards.map(item => (
    left: item.title,
    mid: item.awarder,
    date: date-string(item),
    url: get(item, "link"),
  ))),
  "Skills": () => tabbed-table(data.skills.map(item => (item.name, item.keywords.join(", "), none, none))),
  "Personal": () => {
    profile("home", basics.website)
    for item in basics.profiles {
      if get(item, "hidden") == true { continue }
      profile(lower(item.network), item.url)
    }
  },
)

// ---------------------------------------------------------------------------
// Document
// ---------------------------------------------------------------------------
// The first page has no running header, so its body starts a line higher
#v(-lead)
#block({
  text(font: name-font, weight: 700, size: 18pt, upper(basics.name))
  h(1fr)
  link("mailto:" + basics.email, basics.email)
  linebreak()
  basics.label
  h(1fr)
  link(basics.website + pub-link-suffix, strip-protocol(basics.website))
})

#for name in section-order {
  blank-line
  heading(level: 1, name)
  (sections.at(name))()
}
