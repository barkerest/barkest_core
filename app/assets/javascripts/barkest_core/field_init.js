$(function() {
  $('div.date').datepicker({ format: "mm/dd/yyyy", todayBtn: "linked", todayHighlight: true, clearBtn: true });
  $('input.float').regexMask('float');
  $('input.integer').regexMask('integer');
  $('.double-scroll').doubleScroll({ onlyIfScroll: true, resetOnWindowResize: true });
});

