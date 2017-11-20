var exec = require('cordova/exec');

exports.init = function (mode, acceptorId, accountId, accountToken, applicationId, storeCardID, storeCardPassword, success, error) {
    exec(success, error, 'TriposCordova', 'init', [mode, acceptorId, accountId, accountToken, applicationId, storeCardID, storeCardPassword]);
};

exports.sale = function (transactionAmount, success, error) {
    exec(success, error, 'TriposCordova', 'sale', [transactionAmount]);
};

exports.refund = function (transactionAmount, success, error) {
    exec(success, error, 'TriposCordova', 'refund', [transactionAmount]);
};

