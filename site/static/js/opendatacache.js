/*jshint browser: true, bitwise: false, maxstatements: 20*/
/*globals $, moment, JSON*/

var hash = function(str) {
  var hash = 0, i, chr, len;
  if (str.length === 0) {
    return hash;
  }
  for (i = 0, len = str.length; i < len; i += 1) {
    chr   = str.charCodeAt(i);
    hash  = ((hash << 5) - hash) + chr;
    hash |= 0; // Convert to 32bit integer
  }
  return hash;
};

var indexTable = function (lastHash) {
  var data = [];
  $.ajax('/logs/status.log').done(function (resp) {
    if (hash(resp) === lastHash) {
      return;
    }
    var lines = resp.split('\n');
    for (var i = 0; i < lines.length - 1; i += 1) {
      var cells = lines[i].split('\t');
      var $link = $('<a />').attr('href', cells[0] + '/').text(cells[0]);
      data.push({
        name: $('<span />').append($link).html(),
        //date: moment(new Date(cells[1])).from(moment()),
        date: cells[1],
        caching: Number(cells[2]),
        checked: Number(cells[3]),
        total: Number(cells[4])
      });
    }
    if ($.isArray($('#table').bootstrapTable('getData'))) {
      $('#table').bootstrapTable('load', data);
    } else {
      $('#content').empty().append($('#indexTemplate')
                                   .clone()
                                   .removeClass('template')
                                   .attr('id', 'table'));
      $('#table').bootstrapTable({
        data: data
      });
    }
    // Add a title
    var $title =$('<h2 />')
      .append($('<a />').text('Available portals').attr({
        //'href': 'https://' + portal,
        //'target': '_blank'
      }))
      .addClass('odc-title');
    $('.fixed-table-toolbar').prepend($title);
  }).always(function (resp) {
    var hashed;
    if (typeof resp === 'string') {
      hashed = hash(resp);
    }
    setTimeout(function () { indexTable(hashed); }, 3000);
  });
};

window.rowStyle = function (row) {
  var obj = { classes: '' };
  if (Math.floor(row.status / 100) === 4) {
    obj.classes += ' odc-table-nontabular';
  } else if (Math.floor(row.status / 100) === 5) {
    obj.classes += ' odc-table-cache-error';
  }
  return obj;
};

window.baseFormatter = function (value) {
  return '<div class="odc-table-cell-content">' + value + "</div>";
};

window.nameFormatter = function(value, row) {
  return window.baseFormatter('<a href="' + row.href + '">' + row.name +
    '</a> <span class="superscript">(' + row.id +')</span>');
};

window.ratioFormatter = function(value) {
  return window.baseFormatter(Number(value).toFixed(2) + 'x');
};

window.bigNumberFormatter = function(value) {
  return window.baseFormatter(
    value.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ","));
};

window.utcTimeSinceFormatter = function(value) {
  return window.baseFormatter(moment(value).fromNow());
};

window.statusFormatter = function(value, row) {
  var output,
      statusCode = Number(row.status),
      canTest = false;
      //tester = $('<span />').append($('<a>Test</a>')
      //  .addClass('test-if-cached')
      //  .attr({
      //    href: row.href + '?test=true'
      //  })).html();

  if (statusCode === 200) {
    output = "Checked";
    canTest = true;
  } else if (statusCode === 201) {
    output = "Checked";
    canTest = true;
  } else if (statusCode >= 400 && statusCode < 500) {
    output = "Geographic (no cache)";
  } else {
    output = "Error";
  }

  //if (canTest) {
  //  output = output + ' <span class="superscript">(' + tester + ')</a>';
  //}

  return window.baseFormatter(output);
};

window.sizeFormatter = function(value) {
  value = Number(value);
  if (value > Math.pow(1000, 3)) {
    value = (value / Math.pow(1000, 3)).toFixed(2) + 'GB';
  } else if (value > Math.pow(1000, 2)) {
    value = (value / Math.pow(1000, 2)).toFixed(2) + 'MB';
  } else if (value > Math.pow(1000, 1)) {
    value = (value / Math.pow(1000, 1)).toFixed(2) + 'KB';
  } else {
    value = value + 'B';
  }
  return window.baseFormatter(value);
};

window.speedFormatter = function(value) {
  return window.baseFormatter(window.sizeFormatter(value) + '/s');
};

window.durationFormatter = function(value) {
  value = Number(value);
  var precision = 0;
  if (value < 0.01) {
    precision = 3;
  } else if (value < 0.1) {
    precision = 2;
  } else if (value < 1) {
    precision = 1;
  }
  return window.baseFormatter(
    moment.duration(value, "seconds").format('h[h]m[m]s[s]', precision));
};

window.tagsFormatter = function(value) {
  var output = '';
  try {
    var tags = JSON.parse(value);
    output = '<div class="odc-table-tags">';
    for (var i = 0; i < tags.length; i += 1) {
      output += '<div class="odc-table-tag">' + tags[i] + '</div>';
    }
    output += '</div>';
  } catch (e) {
  }
  return window.baseFormatter(output);
};

window.timestampFormatter = function(value) {
  var m = moment(new Date(value * 1000));
  return window.baseFormatter(m.fromNow() + ' <span class="superscript">(' +
    m.calendar() + ')</span>');
};

window.logsFormatter = function (href) {
  href = href.replace('rows.csv', '');
  return window.baseFormatter('<a target="_blank" href="/logs' + href +
                              '">Logs</a>');
};

window.timeToDownloadFormatter = function (href, row) {
  var lastMiss = '/logs' + href.replace('rows.csv', 'lastmiss.log'),
      cacheTest = href + '?test=true';
  return window.baseFormatter('<a class="estimate-download-time" ' +
                              ' data-size="' + row.size + '" ' +
                              ' data-cache-test="' + cacheTest + '" ' +
                              ' data-last-miss="' + lastMiss + '" ' +
                              'href="#">Estimate</a>');
};

/* Convert wget speed (like 104 KB/s, 10 MB/s, etc.) to pure number bytes per
 * sec */
var wgetSpeed2Number = function (wgetSpeed) {
  var split = wgetSpeed.split(' '),
      num = Number(split[0]),
      mag = split[1].toLowerCase(),
      pow = 0;

  if (mag === 'kb/s') {
    pow = 1;
  } else if (mag === 'mb/s') {
    pow = 2;
  } else if (mag === 'gb/s') {
    pow = 3;
  }
  return num *= Math.pow(1000, pow);
};

var estimateDownloadTime = function (evt) {
  evt.preventDefault();
  var $el = $(evt.target),
      cached = false,
      uncachedDownloadTime,
      maxSpeed = 300000,
      estimate = '',
      size = $el.data('size'),
      $lastMiss = $.get($el.data('last-miss')),
      $cacheTest = $.get($el.data('cache-test'));

  // If this fails, leave cached false.
  $cacheTest.done(function () {
    cached = true;
  });

  // If this fails, leave uncachedDownloadTime undefined.
  $lastMiss.done(function (resp) {
    var cells = resp.split('\t'),
        estSpeed = wgetSpeed2Number(cells[4]);
    if (estSpeed > maxSpeed) {
      estSpeed = maxSpeed;
    }
    uncachedDownloadTime = Number(cells[3]) / estSpeed;
  });

  $.when($lastMiss, $cacheTest).always(function () {
    if (cached === true) {
      estimate = size / maxSpeed;
    } else {
      estimate = uncachedDownloadTime;
    }

    var precision = 0;
    if (estimate < 0.01) {
      precision = 3;
    } else if (estimate < 0.1) {
      precision = 2;
    } else if (estimate < 1) {
      precision = 1;
    }
    estimate = moment.duration(estimate, "seconds").format('h[h]m[m]s[s]',
                                                           precision);
    if (cached) {
      estimate += ' (Cached)';
    } else {
      estimate += ' (Uncached)';
    }

    $el.parent().text(estimate);

  });


  //$el.text('Testing...');
  //$.ajax(href).done(function () {
  //  $el.text('Fully');
  //}).fail(function () {
  //  $el.text('Gzip only');
  //}).always(function () {

  //});
};

var portalTable = function (portal, lastHash) {
  var data = [];
  $.ajax('/logs/' + portal + '/summary.log').done(function (resp) {
    if (hash(resp) === lastHash) {
      return;
    }
    var lines = resp.split('\n');
    for (var i = 0; i < lines.length - 1; i += 1) {
      var cells = lines[i].split('\t');
      if (!cells[0]) {
        continue;
      }
      try {
        var href = $('<a />').attr('href', cells[5])[0].pathname.replace(
          'nocache/', ''),
            speed = wgetSpeed2Number(cells[4]);

        data.push({
          id: cells[1],
          href: href,
          lastCached: cells[2],
          lastUpdated: cells[18] > cells[23] ? cells[18] : cells[23],
          status: cells[0],
          size: cells[3],
          downloadSpeed: speed,
          totalTime: cells[3] / speed,
          name: cells[6],
          attribution: cells[7],
          averageRating: cells[8],
          category: cells[9],
          createdAt: cells[10],
          description: cells[11],
          displayTime: cells[12],
          downloadType: cells[13],
          downloadCount: cells[14],
          newBackend: cells[15],
          numberOfComments: cells[16],
          oid: cells[17],
          rowsUpdatedAt: cells[18],
          rowsUpdatedBy: cells[19],
          tableId: cells[20],
          totalTimesRated: cells[21],
          viewCount: cells[22],
          viewLastModified: cells[23],
          viewType: cells[24],
          tags: cells[25],
          lineCount: cells[26],
          wordCount: cells[27],
          charCount: cells[28],
          ratio: Number(cells[28]) / Number(cells[3]),
          logs: href
        });
      } catch (err) {
        window.console.log("Problem with table: " + err + " on " +
                          JSON.stringify(cells));
      }
    }
    if ($.isArray($('#table').bootstrapTable('getData'))) {
      $('#table').bootstrapTable('load', data);
    } else {
      $('#content').empty().append($('#portalTemplate')
                                   .clone()
                                   .removeClass('template')
                                   .attr('id', 'table'));
      $('#table').bootstrapTable({
        data: data
      }).on('pre-body.bs.table', function () {
        $('.estimate-download-time').off('click', estimateDownloadTime);
      }).on('post-body.bs.table', function () {
        $('.estimate-download-time').on('click', estimateDownloadTime);
      });

      // Weird, this should be covered by post-body hook above.
      $('.estimate-download-time').on('click', estimateDownloadTime);

      // Add a title
      var $title =$('<h2 />')
        .append($('<a />').text(portal).attr({
          'href': 'https://' + portal,
          'target': '_blank'
        }))
        .addClass('odc-title');
      $('.fixed-table-toolbar').prepend($title);
    }
  }).always(function (resp) {
    var hashed;
    if (typeof resp === 'string') {
      hashed = hash(resp);
    }
    setTimeout(function () { portalTable(portal, hashed); }, 3000);
  });
};

$(document).ready(function () {
  $.extend($.fn.bootstrapTable.defaults, $.fn.bootstrapTable.locales['en-US']);

  if (window.location.pathname === '/') {
    indexTable();
  } else {
    var portal = window.location.pathname;
    portal = portal.substr(1, portal.length - 2);
    portalTable(portal);
  }
});
