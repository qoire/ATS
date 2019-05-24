/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 *
 * Contributors:
 * https://github.com/jacquesd
 * https://github.com/qoire
 */

pragma solidity 0.4.15;

import { SafeMath } from "./SafeMath.sol";
import { ATS } from "./ATS.sol";
import { ERC20 } from "./ERC20.sol";
import { AionInterfaceImplementer } from "./AionInterfaceImplementer.sol";
import { ATSTokenRecipient } from "./ATSTokenRecipient.sol";
import { ATSTokenSender } from "./ATSTokenSender.sol";

contract ATSBase is ATS, ERC20, AionInterfaceImplementer {
    using SafeMath for uint128;

    /* -- Constants -- */

    address constant internal addressTypeMask = 0xFF00000000000000000000000000000000000000000000000000000000000000;
    address constant internal zeroAddress = 0x0000000000000000000000000000000000000000000000000000000000000000;

    /* -- ATS Contract State -- */

    string internal mName;
    string internal mSymbol;
    uint128 internal mGranularity;
    uint128 internal mTotalSupply;

    mapping(address => uint128) internal mBalances;
    mapping(address => mapping(address => bool)) internal mAuthorized;

    // for ERC20
    mapping(address => mapping(address => uint128)) internal mAllowed;

    /* -- Constructor -- */
    //
    /// @notice Constructor to create a ReferenceToken
    /// @param _name Name of the new token.
    /// @param _symbol Symbol of the new token.
    /// @param _granularity Minimum transferable chunk.
    /// @param _totalSupply of the new token. This can only be set once
    function ATSBase(
        string _name,
        string _symbol,
        uint128 _granularity,
        uint128 _totalSupply
    ) {
        require(_granularity >= 1);
        mName = _name;
        mSymbol = _symbol;
        mTotalSupply = _totalSupply;
        mGranularity = _granularity;

        initialize(_totalSupply);

        // register onto CIR
        setInterfaceDelegate("AIP004Token", this);
    }

    function initialize(uint128 _totalSupply) internal {
        mBalances[msg.sender] = _totalSupply;
        ATSTokenCreated(_totalSupply, msg.sender);
    }

    /* -- ERC777 Interface Implementation -- */
    //
    /// @return the name of the token
    function name() public constant returns (string) { return mName; }

    /// @return the symbol of the token
    function symbol() public constant returns (string) { return mSymbol; }

    /// @return the granularity of the token
    function granularity() public constant returns (uint128) { return mGranularity; }

    /// @return the total supply of the token
    function totalSupply() public constant returns (uint128) { return mTotalSupply; }

    /// @notice Return the account balance of some account
    /// @param _tokenHolder Address for which the balance is returned
    /// @return the balance of `_tokenAddress`.
    function balanceOf(address _tokenHolder) public constant returns (uint128) { return mBalances[_tokenHolder]; }

    /// @notice Send `_amount` of tokens to address `_to` passing `_userData` to the recipient
    /// @param _to The address of the recipient
    /// @param _amount The number of tokens to be sent
    function send(address _to, uint128 _amount, bytes _userData) public {
        doSend(msg.sender, msg.sender, _to, _amount, _userData, "", true);
    }

    /// @notice Authorize a third party `_operator` to manage (send) `msg.sender`'s tokens.
    /// @param _operator The operator that wants to be Authorized
    function authorizeOperator(address _operator) public {
        require(_operator != msg.sender);
        mAuthorized[_operator][msg.sender] = true;
        AuthorizedOperator(_operator, msg.sender);
    }

    /// @notice Revoke a third party `_operator`'s rights to manage (send) `msg.sender`'s tokens.
    /// @param _operator The operator that wants to be Revoked
    function revokeOperator(address _operator) public {
        require(_operator != msg.sender);
        mAuthorized[_operator][msg.sender] = false;
        RevokedOperator(_operator, msg.sender);
    }

    /// @notice Check whether the `_operator` address is allowed to manage the tokens held by `_tokenHolder` address.
    /// @param _operator address to check if it has the right to manage the tokens
    /// @param _tokenHolder address which holds the tokens to be managed
    /// @return `true` if `_operator` is authorized for `_tokenHolder`
    function isOperatorFor(address _operator, address _tokenHolder) public constant returns (bool) {
        return (_operator == _tokenHolder || mAuthorized[_operator][_tokenHolder]);
    }

    /// @notice Send `_amount` of tokens on behalf of the address `from` to the address `to`.
    /// @param _from The address holding the tokens being sent
    /// @param _to The address of the recipient
    /// @param _amount The number of tokens to be sent
    /// @param _userData Data generated by the user to be sent to the recipient
    /// @param _operatorData Data generated by the operator to be sent to the recipient
    function operatorSend(address _from, address _to, uint128 _amount, bytes _userData, bytes _operatorData) public {
        require(isOperatorFor(msg.sender, _from));
        doSend(msg.sender, _from, _to, _amount, _userData, _operatorData, true);
    }

    function burn(uint128 _amount, bytes _holderData) public {
        doBurn(msg.sender, msg.sender, _amount, _holderData, "");
    }

    function operatorBurn(address _tokenHolder, uint128 _amount, bytes _holderData, bytes _operatorData) public {
        require(isOperatorFor(msg.sender, _tokenHolder));
        doBurn(msg.sender, _tokenHolder, _amount, _holderData, _operatorData);
    }

    /* -- Helper Functions -- */

    /// @notice Internal function that ensures `_amount` is multiple of the granularity
    /// @param _amount The quantity that want's to be checked
    function requireMultiple(uint128 _amount) internal constant {
        require(_amount.div(mGranularity).mul(mGranularity) == _amount);
    }

    /// @notice Check whether an address is a regular address or not.
    /// @param _addr Address of the contract that has to be checked
    /// @return `true` if `_addr` is a regular address (not a contract)
    ///
    /// Ideally, we should propose a better system that extcodesize
    ///
    /// *** TODO: CHANGE ME, going to require a resolution on best approach ***
    ///
    /// Given that we won't be able to detect code size.
    ///
    /// @param _addr The address to be checked
    /// @return `true` if the contract is a regular address, `false` otherwise
    function isRegularAddress(address _addr) internal constant returns (bool) {
        // if (_addr == 0) { return false; }
        // uint size;
        // assembly { size := extcodesize(_addr) }
        // return size == 0;
        return true;
    }

    /// @notice Helper function actually performing the sending of tokens.
    /// @param _operator The address performing the send
    /// @param _from The address holding the tokens being sent
    /// @param _to The address of the recipient
    /// @param _amount The number of tokens to be sent
    /// @param _userData Data generated by the user to be passed to the recipient
    /// @param _operatorData Data generated by the operator to be passed to the recipient
    /// @param _preventLocking `true` if you want this function to throw when tokens are sent to a contract not
    ///  implementing `erc777_tokenHolder`.
    ///  ERC777 native Send functions MUST set this parameter to `true`, and backwards compatible ERC20 transfer
    ///  functions SHOULD set this parameter to `false`.
    function doSend(
        address _operator,
        address _from,
        address _to,
        uint128 _amount,
        bytes _userData,
        bytes _operatorData,
        bool _preventLocking
    )
        internal
    {
        requireMultiple(_amount);

        callSender(_operator, _from, _to, _amount, _userData, _operatorData);

        require(_to != address(0));             // forbid sending to 0x0 (=burning)
        require(_to != address(this));          // forbid sending to the contract itself
        require(mBalances[_from] >= _amount);   // ensure enough funds

        mBalances[_from] = mBalances[_from].sub(_amount);
        mBalances[_to] = mBalances[_to].add(_amount);

        callRecipient(_operator, _from, _to, _amount, _userData, _operatorData, _preventLocking);

        Sent(_operator, _from, _to, _amount, _userData, _operatorData);
    }

    /// @notice Helper function actually performing the burning of tokens.
    /// @param _operator The address performing the burn
    /// @param _tokenHolder The address holding the tokens being burn
    /// @param _amount The number of tokens to be burnt
    /// @param _holderData Data generated by the token holder
    /// @param _operatorData Data generated by the operator
    function doBurn(address _operator, address _tokenHolder, uint128 _amount, bytes _holderData, bytes _operatorData)
        internal
    {
        requireMultiple(_amount);
        require(balanceOf(_tokenHolder) >= _amount);

        mBalances[_tokenHolder] = mBalances[_tokenHolder].sub(_amount);
        mTotalSupply = mTotalSupply.sub(_amount);

        callSender(_operator, _tokenHolder, 0x0, _amount, _holderData, _operatorData);
        Burned(_operator, _tokenHolder, _amount, _holderData, _operatorData);
    }

    /// @notice Helper function that checks for ERC777TokensRecipient on the recipient and calls it.
    ///  May throw according to `_preventLocking`
    /// @param _operator The address performing the send or mint
    /// @param _from The address holding the tokens being sent
    /// @param _to The address of the recipient
    /// @param _amount The number of tokens to be sent
    /// @param _userData Data generated by the user to be passed to the recipient
    /// @param _operatorData Data generated by the operator to be passed to the recipient
    /// @param _preventLocking `true` if you want this function to throw when tokens are sent to a contract not
    ///  implementing `ERC777TokensRecipient`.
    ///  ERC777 native Send functions MUST set this parameter to `true`, and backwards compatible ERC20 transfer
    ///  functions SHOULD set this parameter to `false`.
    function callRecipient(
        address _operator,
        address _from,
        address _to,
        uint128 _amount,
        bytes _userData,
        bytes _operatorData,
        bool _preventLocking
    )
        internal
    {
        address recipientImplementation = getInterfaceDelegate(_to, "AIP004TokenRecipient");
        if (recipientImplementation != 0) {
            ATSTokenRecipient(recipientImplementation).tokensReceived(
                _operator, _from, _to, _amount, _userData, _operatorData);
        } else if (_preventLocking) {
            require(isRegularAddress(_to));
        }
    }

    /// @notice Helper function that checks for ERC777TokensSender on the sender and calls it.
    ///  May throw according to `_preventLocking`
    /// @param _from The address holding the tokens being sent
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be sent
    /// @param _userData Data generated by the user to be passed to the recipient
    /// @param _operatorData Data generated by the operator to be passed to the recipient
    ///  implementing `ERC777TokensSender`.
    ///  ERC777 native Send functions MUST set this parameter to `true`, and backwards compatible ERC20 transfer
    ///  functions SHOULD set this parameter to `false`.
    function callSender(
        address _operator,
        address _from,
        address _to,
        uint128 _amount,
        bytes _userData,
        bytes _operatorData
    )
        internal
    {
        address senderImplementation = getInterfaceDelegate(_from, "AIP004TokenSender");
        if (senderImplementation == 0) { return; }
        ATSTokenSender(senderImplementation).tokensToSend(_operator, _from, _to, _amount, _userData, _operatorData);
    }

    function liquidSupply() public constant returns (uint128) {
        return mTotalSupply.sub(balanceOf(this));
    }


    /* -- Cross Chain Functionality -- */

    function thaw(
        address localRecipient,
        uint128 amount,
        bytes32 bridgeId,
        bytes bridgeData,
        bytes32 remoteSender,
        bytes32 remoteBridgeId,
        bytes remoteData)
    public {

    }

    function freeze(
        bytes32 remoteRecipient,
        uint128 amount,
        bytes32 bridgeId,
        bytes localData)
    public {

    }

    function operatorFreeze(address localSender,
        bytes32 remoteRecipient,
        uint128 amount,
        bytes32 bridgeId,
        bytes localData)
    public {

    }

    /* -- ERC20 Functionality -- */
    
    function decimals() public constant returns (uint8) {
        return uint8(18);
    }

    /// @param _to The address of the recipient
    /// @param _amount The number of tokens to be transferred
    /// @return `true`, if the transfer can't be done, it should fail.
    function transfer(address _to, uint128 _amount) public returns (bool success) {
        doSend(msg.sender, msg.sender, _to, _amount, "", "", false);
        return true;
    }

    /// @param _from The address holding the tokens being transferred
    /// @param _to The address of the recipient
    /// @param _amount The number of tokens to be transferred
    /// @return `true`, if the transfer can't be done, it should fail.
    function transferFrom(address _from, address _to, uint128 _amount) public returns (bool success) {
        require(_amount <= mAllowed[_from][msg.sender]);

        mAllowed[_from][msg.sender] = mAllowed[_from][msg.sender].sub(_amount);
        doSend(msg.sender, _from, _to, _amount, "", "", false);
        return true;
    }

    ///  `msg.sender` approves `_spender` to spend `_amount` tokens on its behalf.
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _amount The number of tokens to be approved for transfer
    /// @return `true`, if the approve can't be done, it should fail.
    function approve(address _spender, uint128 _amount) public returns (bool success) {
        mAllowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    ///  This function makes it easy to read the `allowed[]` map
    /// @param _owner The address of the account that owns the token
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens of _owner that _spender is allowed
    ///  to spend
    function allowance(address _owner, address _spender) public constant returns (uint128 remaining) {
        return mAllowed[_owner][_spender];
    }
}
