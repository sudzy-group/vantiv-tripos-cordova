var exec = require('cordova/exec');

exports.init = function (mode, acceptorId, accountId, accountToken, applicationId, deviceType, deviceAddress, success, error) {
    exec(success, error, 'TriposCordova', 'init', [mode, acceptorId, accountId, accountToken, applicationId, deviceType, deviceAddress]);
};

exports.sale = function (refNum, ticketNumber, transactionAmount, success, error) {
    exec(success, error, 'TriposCordova', 'sale', [refNum, ticketNumber, transactionAmount]);
};

exports.refund = function (referenceNumber, ticketNumber, transactionAmount, success, error) {
    exec(success, error, 'TriposCordova', 'refund', [referenceNumber, ticketNumber, transactionAmount]);
};

exports.creditCardReturn = function (transactionId, referenceNumber, transactionAmount, success, error) {
    exec(success, error, 'TriposCordova', 'creditCardReturn', [transactionId, referenceNumber, transactionAmount]);
};

exports.paymentAccountCreate = function (transactionId, success, error) {
    exec(success, error, 'TriposCordova', 'paymentAccountCreate', [transactionId]);
};

exports.creditcardSale = function (refNum, paymentAccountId, amount, success, error) {
    exec(success, error, 'TriposCordova', 'creditcardSale', [refNum, paymentAccountId, amount]);
};
