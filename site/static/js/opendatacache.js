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

window.utcTimeSinceFormatter = function(value) {
  return moment(new Date(value)).fromNow();
};

window.cacheTestFormatter = function(value) {
  return $('<a>Test</a>').addClass('test-if-cached')
  .attr({
    href: value + '?test=true'
  }).html();
};

window.sizeFormatter = function(value) {
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

window.timestampFormatter = function(value) {
  var m = moment(new Date(value * 1000))
  return m.calendar() + ' (' + m.fromNow() + ')';
};

var testIfCached = function (evt) {
  var $el = $(evt.target),
      href = $el.attr('href'),
      id = $el.attr('name');

  evt.preventDefault();

  $el.text('Testing...' + id);
  $.ajax(href).done(function () {
    $el.text('Cached');
  }).fail(function () {
    $el.text('Not cached');
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
          id = cells[0],
          $link = $('<a />').attr('href', href).text(id);
          //$test = $('<a>Test</a>').addClass('test-if-cached')
          //                        .attr({
          //                          name: id,
          //                          href: href + '?test=true'
          //                        });
      data.push({
        id: $('<span />').append($link).html(),
        //date: moment(new Date(cells[1])).from(moment()),
        date: cells[1],
        status: cells[2],
        size: cells[3],
        // size: (cells[3] / 1000000).toFixed(2) + 'MB',
        //test: $('<span />').append($test).html(),
        cacheTest: href,
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
        tags: cells[29]
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
