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

/** Sorting function for the size column of data tables. */
window.sortBySize = function (alpha, beta) {
  alpha = Number(alpha.substr(0, alpha.length - 2));
  beta = Number(beta.substr(0, beta.length - 2));
  return alpha - beta;
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
      var href = $('<a />').attr('href', cells[cells.length - 1])[0].pathname,
          id = cells[0],
          $link = $('<a />').attr('href', href).text(id),
          $test = $('<a>Test</a>').addClass('test-if-cached')
                                  .attr({
                                    name: id,
                                    href: href + '?test=true'
                                  });
      data.push({
        id: $('<span />').append($link).html(),
        date: moment(new Date(cells[1])).from(moment()),
        status: cells[2],
        size: (cells[3] / 1000000).toFixed(2) + 'MB',
        test: $('<span />').append($test).html()
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
