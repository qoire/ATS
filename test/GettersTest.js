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

// test getters
module.exports = function(callback) {
  const artifacts = require('../build/contracts/ATSImpl.json')
  const contract = require('aion-contract');
  const ATSImpl = contract(artifacts);
  var testCounter = 1;

  // master account - always unlocked by tool
  var account_one = "0xa04be405fe794146df4a6a0cac0009933323d65e29dedfaf80a1f880fa8cd329";

  // need to be unlocked manually
  var account_two = "0xa0dd7205acbaad446e7bd4e1755a9d1e8dd74b793656cc7af5876cba0f616bab";
  var account_three = "0xa076b66cb825ca43aab11aa807ced2586023e6a62d8d600b0f3e16445a8d3ced";
  
  // unlockink account
  unlockAccount(web3, account_two, defaultPassword); 
  unlockAccount(web3, account_three, defaultPassword);

  ATSImpl.setProvider(web3.currentProvider);

  console.log(colors.green('Test: basic getters'));

  // get the contract instance
  return ATSImpl.deployed().then(function(instance){ 
    conInst = instance;
    logTestMessage('    check if defult contract name is set correctly');
    return conInst.name.call();

  }).then(function(contractName){
	  assert.equal(contractName.valueOf(), dName, colors.red("initialized name should be 'def_name' "));
    logTestMessage('    check if defult contract symbol is set correctly');
    return conInst.symbol.call();

  }).then(function(contractSymbol){
    assert.equal(contractSymbol.valueOf(), dSymbol, colors.red("initialized symbol should be 'def_symbol' "));
    logTestMessage('    check if totalSupply is set correctly');
    return conInst.totalSupply.call();
  
  }).then(function(contractTotalSupply){
    assert.equal(contractTotalSupply.valueOf(), dTotalSupply, colors.red("totalSupply should be 1000"));
    logTestMessage('    check if granularity is set correctly');
    return conInst.granularity.call();

  }).then(function(contractGrangularity){
    assert.equal(contractGrangularity.valueOf(), dGranularity, colors.red("granularity should be 1"));
    logTestMessage('    check if the special address of the contract is set correctly');
    return conInst.specialAddress.call();

  }).then(function(contractSpecialAddress){
    assert.equal(contractSpecialAddress.valueOf(), dSpecialAddress, colors.red("special address should be 0xa000000000000000000000000000000000000000000000000000000000000111"));
    logTestMessage('    check the balance of specialAddress to be initialized equal to the totalSupply');
    return conInst.balanceOf.call(dSpecialAddress);
  
  }).then(function(balance){
    assert.equal(balance.valueOf(), dTotalSupply, "special address should have a balance of 1000");
    logTestMessage('    check the balance of account_two to be initialized be empty');
    return conInst.balanceOf.call(account_two);   

  }).then(function(balance){
    assert.equal(balance.valueOf(), 0, "account_two should have zero balance to start with")
    logTestMessage('    check the liquid supply');
    return conInst.liquidSupply.call();

  }).then(function(liquidBalance){
    assert.equal(liquidBalance.valueOf(), 0, 'should be zero when initialized');

  }).catch(err => {
    console.log('promise error >>>', err);
  })
}
