var assert = require('assert');
var colors = require('colors/safe');

let dName = "def_name";
let dSymbol = "def_symbol";
let dTotalSupply = 1000;
let dGranularity = 1;
let dSpecialAddress = "0xa04be405fe794146df4a6a0cac0009933323d65e29dedfaf80a1f880fa8cd329";

var conInst;
var defaultPassword = "PLAT4life";
var testCounter = 1;

// need to be unlocked manually
var account_two = "0xa0dd7205acbaad446e7bd4e1755a9d1e8dd74b793656cc7af5876cba0f616bab";
var account_three = "0xa076b66cb825ca43aab11aa807ced2586023e6a62d8d600b0f3e16445a8d3ced";

// unlockink account
unlockAccount(web3, account_two, defaultPassword);
unlockAccount(web3, account_three, defaultPassword);

function unlockAccount(web3, targetAccount, password) {
  web3.personal.unlockAccount(targetAccount, password, 49999, (err, unlock) => {
    if (err) {
      console.log("unlockerr", JSON.stringify(err));
    } else {
      console.log("unlocked successfully! Account: " + targetAccount);
    }
  });
}

function logTestMessage(message){
  console.log(colors.grey(message) + colors.blue('(test' + testCounter + ')'));
  testCounter++;
}

function test(contractInstance){
  console.log(colors.green("function test"));

  var one = contractInstance.balanceOf.call(account_two);
  var two = contractInstance.balanceOf(account_three);
  var three = contractInstance.balanceOf(dSpecialAddress);

  console.log('account1 balance: ' + one.valueOf());
  console.log('account1 balance: ' + two.valueOf());
  console.log('account1 balance: ' + three.valueOf());

}

// Testing setting operators 
module.exports = function(callback) {
  const artifacts = require('../build/contracts/ATSImpl.json')
  const contract = require('aion-contract');
  const ATSImpl = contract(artifacts);
  let counter = 0;

  ATSImpl.setProvider(web3.currentProvider);

  console.log(colors.green('Test: operators'));

  // get the contract instance
  return ATSImpl.deployed().then(function(instance) {
    conInst = instance;
    logTestMessage('    check if account_two is an operator for itself')

    //test(conInst);

    return conInst.isOperatorFor.call(account_two, account_two);

  }).then(function(result) {
    assert.equal(result.valueOf(), true, colors.red("Each account should be an operator for itself"));
    logTestMessage('    check if another random address is not an operator')
    return conInst.isOperatorFor.call(account_three, account_two);

  }).then(function(result){
    assert.equal(result.valueOf(), false, colors.red("account_three should not be an operator for account_two unless authorized"));
    logTestMessage('    authorize account_three as an operator for account_two')
    return conInst.authorizeOperator(account_three, {from: account_two, gas: 1999999}); // this will take slightly longer since it makes changes to the contract

  }).then(function(){
    logTestMessage('    check if account_three is now an operator for account_two')
    return conInst.isOperatorFor.call(account_three, account_two); 

  }).then(function(result){
    assert.equal(result.valueOf(), true, colors.red("account_three should now be an operator for account_two"));
    logTestMessage('    revoke account_three from being an operator of account_two')
    return conInst.revokeOperator(account_three, {from: account_two, gas:1999999}); // this will take slightly longer since it makes changes to the contract

  }).then(function(){
    logTestMessage('    check if account_three is no longer an operator for account_two');
    return conInst.isOperatorFor.call(account_three, account_two);

  }).then(function(result){
    assert.equal(result.valueOf(), false, colors.red('account_three should no longer be an operator for account_two'))
    logTestMessage('    try to revoke account_two from being operator for itself');
    conInst.revokeOperator.call(account_two, {from: account_two, gas: 1999999});
    return conInst.isOperatorFor(account_two, account_two);

  }).then(function(result){
    assert.equal(result.valueOf(), true, 'an account should always be operator for itself');

  }).catch(err => {
    console.log('promise error >>>', err);
    //console.log(conInst.AuthorizedOperator());
  })
}


// function sendTransactions() {
//     contractInstance = web3.eth.contract(abi).at(contractAddr);
//     let i = 0;
//     setInterval(() => {
//         unlock(web3, a0, pw0).then(
//             () => {
//                 // let hash = contractInstance.winningProposal({
//                 //     from: a0,
//                 //     gas: 4699999
//                 // });
//                 // console.log('tx', i, hash);
//                 console.log('contractInstance', contractInstance);
//                 let hash = contractInstance.setCompleted(i, {from: a0, gas: 1999999});

//                 // .then((msg) => {
//                 //     console.log('setComplerted tx receipt >>>>', msg);
//                 //     // resolve();
//                 //   }).catch((err) => {
//                 //     console.log('setComplerted ERR >>>>', err);
//                 // });

//                 console.log('tx', i, hash);

//                 i++;
//             })
//     }, args.intervalTime);
// }