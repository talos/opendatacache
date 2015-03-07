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
    for (var i = 0; i < lines.length; i += 1) {
      var cells = lines[i].split('\t');
      var $link = $('<a />').attr('href', cells[0] + '/').text(cells[0]);
      data.push({
        name: $('<span />').append($link).html(),
        date: moment(new Date(cells[1])).from(moment()),
        status: cells[2],
        detail: cells[3]
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

window.rowStyle = function (row, idx) {
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

window.nameFormatter = function(value, row, idx) {
  return '<a href="' + row.href + '">' + row.name +
    '</a> <span class="superscript">(' + row.id +')</span>';
};

window.ratioFormatter = function(value) {
  return Number(value).toFixed(2) + 'x';
};

window.utcTimeSinceFormatter = function(value) {
  return moment(value).fromNow();
};

window.statusFormatter = function(value, row, idx) {
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
    return (value / Math.pow(1000, 3)).toFixed(2) + 'GB'
  } else if (value > Math.pow(1000, 2)) {
    return (value / Math.pow(1000, 2)).toFixed(2) + 'MB'
  } else if (value > Math.pow(1000, 1)) {
    return (value / Math.pow(1000, 1)).toFixed(2) + 'KB'
  } else {
    return value + 'B'
  }
};

window.speedFormatter = function(value) {
  return sizeFormatter(value) + '/s';
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
  return moment.duration(value, "seconds").format('h[h]m[m]s[s]', precision)
};

window.tagsFormatter = function(value) {
  try {
    var tags = JSON.parse(value);
  } catch (e) {
    return '';
  }
  var output = '<div class="odc-table-tags">';
  for (var i = 0; i < tags.length; i += 1) {
    output += '<div class="odc-table-tag">' + tags[i] + '</div>';
  }
  output += '</div>';
  return output;
};

window.timestampFormatter = function(value) {
  var m = moment(new Date(value * 1000))
  return m.fromNow() + ' <span class="superscript">(' + m.calendar() + ')</span>';
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

var portalTable = function (portal, lastHash) {
var data = [];
$.ajax('/logs/' + portal + '/summary.log').done(function (resp) {
  if (hash(resp) === lastHash) {
    return;
  }
  var lines = resp.split('\n');
  for (var i = 0; i < lines.length; i += 1) {
    var cells = lines[i].split('\t');
    if (!cells[0]) {
      continue;
    }
    var href = $('<a />').attr('href', cells[9])[0].pathname,
        id = cells[1],
        $link = $('<a />').attr('href', href).text(id);
        //$test = $('<a>Test</a>').addClass('test-if-cached')
          //                        .attr({
          //                          name: id,
          //                          href: href + '?test=true'
          //                        });
      data.push({
        id: $('<span />').append($link).html(),
        href: href,
        //date: moment(new Date(cells[1])).from(moment()),
        lastCached: cells[2],
        status: cells[0],
        size: cells[3],
        downloadSpeed: cells[4],
        // timing not as useful because the cache masks socrata's performance
        //connectTime: cells[5],
        //pretransferTime: cell[6],
        //starttransferTime: cells[7],
        totalTime: cells[8],
        // size: (cells[3] / 1000000).toFixed(2) + 'MB',
        //test: $('<span />').append($test).html(),
        //cacheTest: href,
        name: cells[10],
        attribution: cells[11],
        averageRating: cells[12],
        category: cells[13],
        createdAt: cells[14],
        description: cells[15],
        displayTime: cells[16],
        downloadType: cells[17],
        downloadCount: cells[18],
        newBackend: cells[19],
        numberOfComments: cells[20],
        oid: cells[21],
        rowsUpdatedAt: cells[22],
        rowsUpdatedBy: cells[23],
        tableId: cells[24],
        totalTimesRated: cells[25],
        viewCount: cells[26],
        viewLastModified: cells[27],
        viewType: cells[28],
        tags: cells[29],
        lineCount: cells[30],
        wordCount: cells[31],
        charCount: cells[32],
        ratio: Number(cells[32]) / Number(cells[3])
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
  if (window.location.pathname === '/') {
    indexTable();
  } else {
    var portal = window.location.pathname;
    portal = portal.substr(1, portal.length - 2);
    portalTable(portal);
  }
});
