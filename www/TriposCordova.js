var exec = require('cordova/exec');

exports.init = function (mode, acceptorId, accountId, accountToken, applicationId, deviceType, success, error) {
    exec(success, error, 'TriposCordova', 'init', [mode, acceptorId, accountId, accountToken, applicationId, deviceType]);
};

exports.sale = function (refNum, ticketNumber, transactionAmount, success, error) {
    exec(success, error, 'TriposCordova', 'sale', [refNum, ticketNumber, transactionAmount]);
};

