/*jshint browser: true, bitwise: false, maxstatements: 20*/
/*globals $, moment*/

/*var linkFormatter = function (value) {
  return $(
};*/

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
        date: moment(new Date(cells[1])).from(moment()),
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

window.bigCellFormatter = function(value) {
  return '<div class="odc-table-big-cell">' + value + '</div>';
};

window.nameFormatter = function(value, row) {
  return '<a href="' + row.href + '">' + row.name +
    '</a> <span class="superscript">(' + row.id +')</span>';
};

window.ratioFormatter = function(value) {
  return Number(value).toFixed(2) + 'x';
};

window.utcTimeSinceFormatter = function(value) {
  return moment(value).fromNow();
};

window.statusFormatter = function(value, row) {
  var output,
      statusCode = Number(row.status),
      status,
      tester = $('<span />').append($('<a>Test</a>').addClass('test-if-cached')
  .attr({
    href: row.href + '?test=true'
  })).html();

  if (statusCode === 200) {
    status = "Probably cached";
  } else if (statusCode === 201) {
    status = "Newly cached";
  } else if (statusCode >= 400 && statusCode < 500) {
    status = "Can't cache";
  } else {
    status = "Error caching";
  }

  output = status + ' <span class="superscript">(' + tester + ')</a>';
  return output;
};

window.sizeFormatter = function(value) {
  value = Number(value);
  if (value > Math.pow(1000, 3)) {
    return (value / Math.pow(1000, 3)).toFixed(2) + 'GB';
  } else if (value > Math.pow(1000, 2)) {
    return (value / Math.pow(1000, 2)).toFixed(2) + 'MB';
  } else if (value > Math.pow(1000, 1)) {
    return (value / Math.pow(1000, 1)).toFixed(2) + 'KB';
  } else {
    return value + 'B';
  }
};

window.speedFormatter = function(value) {
  return window.sizeFormatter(value) + '/s';
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
  return moment.duration(value, "seconds").format('h[h]m[m]s[s]', precision);
};

window.tagsFormatter = function(value) {
  try {
    var tags = JSON.parse(value),
        output = '<div class="odc-table-tags">';
    for (var i = 0; i < tags.length; i += 1) {
      output += '<div class="odc-table-tag">' + tags[i] + '</div>';
    }
    output += '</div>';
    return output;
  } catch (e) {
    return '';
  }
};

window.timestampFormatter = function(value) {
  var m = moment(new Date(value * 1000));
  return m.fromNow() + ' <span class="superscript">(' +
    m.calendar() + ')</span>';
};

var testIfCached = function (evt) {
var $el = $(evt.target),
    href = $el.attr('href');

evt.preventDefault();
$el.text('Testing...');
$.ajax(href).done(function () {
  $el.text('Fully');
}).fail(function () {
  $el.text('Gzip only');
}).always(function () {

});
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
    var href = $('<a />').attr('href', cells[5])[0].pathname,
        id = cells[1],
        speed = wgetSpeed2Number(cells[4]),
        $link = $('<a />').attr('href', href).text(id);

      data.push({
        id: $('<span />').append($link).html(),
        href: href,
        //date: moment(new Date(cells[1])).from(moment()),
        lastCached: cells[2],
        status: cells[0],
        size: cells[3],
        downloadSpeed: speed,
        // timing not as useful because the cache masks socrata's performance
        //connectTime: cells[5],
        //pretransferTime: cell[6],
        //starttransferTime: cells[7],
        //totalTime: cells[8],
        totalTime: cells[3] / speed,
        // size: (cells[3] / 1000000).toFixed(2) + 'MB',
        //test: $('<span />').append($test).html(),
        //cacheTest: href,
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
        ratio: Number(cells[28]) / Number(cells[3])
      });
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
        $('.test-if-cached').off('click', testIfCached);
      }).on('post-body.bs.table', function () {
        $('.test-if-cached').on('click', testIfCached);
      });

      // Weird, this should be covered by post-body hook above.
      $('.test-if-cached').on('click', testIfCached);
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
