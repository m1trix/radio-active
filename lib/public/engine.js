vote = function(oDiv) {
    $.ajax({
        url: '/vote/' + oDiv.id,
        type: 'post',
        success: function(sMessage) {
            alert(sMessage);
        },
        error: function(oResponse) {
            alert(oResponse.responseText);
        }
    });
}