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

var account_one_initial_balance;
var account_two_initial_balance;
var account_three_initial_balance;

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
  console.log(colors.grey(message + ' (test ' + testCounter + ')'));
  testCounter++;
}

function logAccountBalances(contractInstance, account){
  return contractInstance.balanceOf(account).then(function(balance){
    console.log(colors.blue('   balance for '  + account + ' is: ' + balance.valueOf()))
  })
}

// Testing token transfers  
module.exports = function(callback) {
  const artifacts = require('../build/contracts/ATSImpl.json')
  const contract = require('aion-contract');
  const ATSImpl = contract(artifacts);
  let counter = 0;
  let initialBalance1 = 1000;
  let initialBalance2 = 0;
  let initialBalance3 = 0;

  let addValueToTest = 10;
  let addValueToTest2 = 20;
  let burnValue = 70;
  let burnValue2 = 30;

  ATSImpl.setProvider(web3.currentProvider);

  console.log(colors.green('Test: operators'));


  // get the contract instance
  return ATSImpl.deployed().then(function(instance) {
    conInst = instance;

    console.log(colors.blue('Test Accounts'));
    return conInst.balanceOf(dSpecialAddress);

  // get the initial token balance of each account and print in console
  }).then(function(balance){
    account_one_initial_balance = balance;
    console.log(colors.blue('   balance for '  + dSpecialAddress + ' is: ' + balance.valueOf()));
    return conInst.balanceOf(account_two);

  }).then(function(balance){
    account_two_initial_balance = balance;
    console.log(colors.blue('   balance for '  + account_two + ' is: ' + balance.valueOf()));
    return conInst.balanceOf(account_three);

  }).then(function(balance){
    account_three_initial_balance = balance;
    console.log(colors.blue('   balance for '  + account_three + ' is: ' + balance.valueOf()));
    return conInst.totalSupply();

  }).then(function(totalTokenSupply){ 
    dTotalSupply = totalTokenSupply;
    console.log(colors.blue('   current totalSupply is: ' + totalTokenSupply.valueOf()));
    return;

  }).then(function(){
    var sendEvent = conInst.Sent();

    sendEvent.watch(function(error, result){
      if (!error){
        console.log(colors.green('Event: SEND SUCCESS'));
        console.log(result.args);
        return;
      }else{
        console.log(colors.red('Event: SEND FAIL'));
        return;
      }
    })


    var burnEvent = conInst.Burned();
    burnEvent.watch(function(error, result){
      if (!error){
        console.log(colors.green('Event: BURN SUCCESS'));
        console.log(result.args);
        return;
      }else{
        console.log(colors.red('Event: BURN FAIL'));
        return;
      }
    });

    var authorizeOperator = conInst.AuthorizedOperator();
    authorizeOperator.watch(function(error, result){
      if(!error){
        console.log(colors.green('Event: AUTHROIZE OPERATOR SUCCESS'));
        console.log(result.args);
        return;
      }else{
        console.log(colors.red('Event: AUTHROIZE OPERATOR FAIL'));
        return;
      }
    });

    return;

  // Testing send - 1
  }).then(function(){
    return result = conInst.send1(account_three, addValueToTest, "send data 10" , {from: dSpecialAddress, gas: 1999999}); // SEND TRANSACTION

  }).then(function(){

    return conInst.balanceOf(account_three);

  }).then(function(balance){
    logTestMessage('    Test send: from specialAddress')
    assert.equal(balance.valueOf(), (+account_three_initial_balance + +addValueToTest), 'account_three should now have a 10 more tokens');
    return conInst.balanceOf.call(dSpecialAddress);

  }).then(function(balance2){
    assert.equal(balance2.valueOf(), (+account_one_initial_balance - +addValueToTest), 'account_three should now have a 10 less tokens');
    return conInst.operatorSend(dSpecialAddress, account_two, addValueToTest2, 'holder data 20', 'operator data 20', {from: dSpecialAddress, gas: 1999999}); // SEND TRANSACTION
   
  // Testing operatorSend - 2
  }).then(function(){
    logTestMessage('    Test operatorSend: from specialAddress')
    return conInst.balanceOf(account_two);

  }).then(function(balance){
    assert.equal(balance.valueOf(), +account_two_initial_balance + +addValueToTest2, 'account_two should now have 20 more tokens');
    return conInst.balanceOf(dSpecialAddress);

  }).then(function(balance){
    assert.equal(balance.valueOf(), +account_one_initial_balance - +addValueToTest - +addValueToTest2, 'dSpecialAddress should now have 20 less tokens')
    return conInst.burn(burnValue, 'burn 70', {from: dSpecialAddress, gas: 1999999}); // SEND TRANSACTION

  // Testing burn - 3
  }).then(function(){
    logTestMessage('    Test burn: from specialAddress')
    return conInst.balanceOf(dSpecialAddress);

  }).then(function(balance){
    assert.equal(balance.valueOf(), +account_one_initial_balance - +addValueToTest - +addValueToTest2 - +burnValue, 'dSpecialAddress should now have 70 less tokens')
    return conInst.totalSupply();

  }).then(function(balance){
    assert.equal(balance.valueOf(), dTotalSupply - burnValue, 'total supply should have decreased by 70')
    return conInst.operatorBurn(dSpecialAddress, burnValue2, 'holder data 30', 'operator data 30', {from: dSpecialAddress, gas: 1999999}) // SEND TRANSACTION

  // Testing operatorBurn - 4
  }).then(function(){
    logTestMessage('    Test operatorBurn: from specialAddress')
    return conInst.balanceOf(dSpecialAddress);

  }).then(function(balance){
    assert.equal(balance.valueOf(), +account_one_initial_balance - +addValueToTest - +addValueToTest2 - +burnValue - +burnValue2, 'dSpecialAddress should now have 30 less tokens')
    return conInst.totalSupply();

  }).then(function(balance){
    assert.equal(balance.valueOf(), dTotalSupply - burnValue - burnValue2, 'total supply should have decreased by 30')

  // log account balances after sending transactions
  }).then(function(){
    logAccountBalances(conInst, dSpecialAddress);
    logAccountBalances(conInst, account_two);
    logAccountBalances(conInst, account_three);
    return conInst.totalSupply();

  }).then(function(balance){
    console.log(colors.blue('   current totalSupply is: ' + balance.valueOf()));

  }).catch(err => {
    console.log('err', err);

  })
}

