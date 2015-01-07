/*jshint browser: true*/
/*globals $, moment*/

/*var linkFormatter = function (value) {
  return $(
};*/

var indexTable = function () {
  var data = [];
  $.ajax('/logs/status.log').done(function (resp) {
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
    $('#content').empty().append($('#indexTemplate')
                                 .clone()
                                 .removeClass('template')
                                 .attr('id', 'table'));
    $('#table').bootstrapTable({
      data: data
    });
  });

  setTimeout(indexTable, 2000);
};

var portalTable = function (portal) {
  var data = [];
  $.ajax('/logs/' + portal + '/summary.log').done(function (resp) {
    var lines = resp.split('\n');
    for (var i = 0; i < lines.length; i += 1) {
      var cells = lines[i].split('\t');
      var $link = $('<a />').attr('href', cells[7]).text(cells[0]);
      data.push({
        id: $('<span />').append($link).html(),
        date: moment(new Date(cells[1])).from(moment()),
        status: cells[2],
        size: (cells[3] / 1000000).toFixed(2) + 'MB'
      });
    }
    $('#content').empty().append($('#portalTemplate')
                                 .clone()
                                 .removeClass('template')
                                 .attr('id', 'table'));
    $('#table').bootstrapTable({
      data: data
    });
  });

  setTimeout(function () { portalTable(portal); }, 2000);
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
