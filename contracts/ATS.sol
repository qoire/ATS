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

interface ATS {
    
    /// Returns the name of the token
    function name() public constant returns (string);

    /// Returns the symbol of the token
    function symbol() public constant returns (string);
    
    /// Returns the totalSupply of the token, assuming a fixed number of
    /// token circulation, this number should not change.
    function totalSupply() public constant returns (uint128);

    /// Returns the currently liquid supply of the token, assuming a fixed
    /// number of (total) tokens are available, this number should never
    /// exceed the totalSupply() of the token.
    function liquidSupply() public constant returns (uint128);

    function balanceOf(address owner) public constant returns (uint128);

    function granularity() public constant returns (uint128);

    /// Default Operators removed, rationale behind this is that default operators
    /// Rationale behind this is that all operators should be (opt-in), this includes
    // function defaultOperators() public constant returns (address[]);
    
    function isOperatorFor(address operator, address tokenHolder) public constant returns (bool);
    function authorizeOperator(address operator) public;
    function revokeOperator(address operator) public;

    function send(address to, uint128 amount, bytes holderData) public;
    function operatorSend(address from, address to, uint128 amount, bytes holderData, bytes operatorData) public;

    /// Some functionality should still include a burn (for example slashing ERC20 tokens from a validator)
    function burn(uint128 amount, bytes holderData) public;
    function operatorBurn(address from, uint128 amount, bytes holderData, bytes operatorData) public;

    /// @notice Interface for a bridge/relay to execute a `send`
    /// @dev this name was suggested by Michael Kitchen, who suggested
    /// it makes sense to thaw an token from solid to liquid
    ///
    /// @dev function is called by foreign entity to `thaw` tokens
    /// to a particular user.
    function thaw(address localRecipient, uint128 amount, bytes32 bridgeId, bytes bridgeData, bytes32 remoteSender, bytes32 remoteBridgeId, bytes remoteData) public;    
    
    /// @notice Interface for a user to execute a `freeze`, which essentially
    /// is a functionality that locks the token (into the special address)
    /// 
    /// @dev function is called by local user to `freeze` tokens thereby
    /// transferring them to another network.
    function freeze(bytes32 remoteRecipient, uint128 amount, bytes32 bridgeId, bytes localData) public;
    function operatorFreeze(address localSender, bytes32 remoteRecipient, uint128 amount, bytes32 bridgeId, bytes localData) public;

    /// Event to be emit at the time of contract creation. Rationale behind the event is a few things:
    ///
    /// * It allows one to filter for new ATS tokens being created, in the interest of clarity
    ///   this is a big help. We can simply filter for this event.
    ///
    /// * It indicates the `totalSupply` of the network. `totalSupply` is very important in
    ///   our standard, therefore it makes sense to include it as an emission.
    event Created(
        uint128 indexed     _totalSupply,
        /// This is a horrible name I know, up for debate
        address indexed     _specialAddress);

    event Sent(
        address indexed     _operator,
        address indexed     _from,
        address indexed     _to,
        uint128             _amount,
        bytes               _holderData,
        bytes               _operatorData);

    event Thawed(
        address indexed localRecipient,
        uint128 amount,
        bytes32 indexed bridgeId,
        bytes bridgeData,
        bytes32 indexed remoteSender,
        bytes32 remoteBridgeId,
        bytes remoteData);

    event Froze(
        address indexed localSender,
        bytes32 indexed remoteRecipient,
        uint128 amount,
        bytes32 indexed bridgeId,
        bytes localData);

    event Minted(
        address indexed     _operator,
        address indexed     _to,
        uint128             _amount,
        bytes               _operatorData);

    event Burned(
        address indexed     _operator,
        address indexed     _from,
        uint128             _amount,
        bytes               _holderData,
        bytes               _operatorData);

    event AuthorizedOperator(
        address indexed     _operator,
        address indexed     _tokenHolder);


    event RevokedOperator(
        address indexed     _operator,
        address indexed     _tokenHolder);
}