pragma solidity 0.4.15;

/// @title TokenBridgeRegistryUserInterface
/// Represents an entity that implements functionality designed to
/// interface with token bridges.
interface TokenBridgeRegistryUserInterface {
    /// @notice Interface for a bridge/relay to execute a `send`
    /// @dev this name was suggested by Michael Kitchen, who suggested
    /// it makes sense to thaw an token from solid to liquid
    ///
    /// @dev function is called by foreign entity to `thaw` tokens
    /// to a particular user.
    function thaw(bytes32 _foreignNetworkId, address _recipient, uint128 _amount, bytes _foreignData) public;

    /// @notice Returns the relay address for the given implementer
    function registry() public constant returns (address);

    /// @notice Interface for a user to execute a `freeze`, which essentially
    /// is a functionality that locks the token (into the special address)
    /// 
    /// @dev function is called by local user to `freeze` tokens thereby
    /// transferring them to another network.
    function freeze(bytes32 _foreignNetworkId, bytes32 _foreignRecipient, uint128 _amount, bytes _localData) public;

    /// @notice function for a token contract to set the registry
    function setRegistry(address _registry) public;

    /// @notice thaw event, to be called by the implementer after
    /// receiving the thaw
    event Thaw(
        bytes32 indexed _foreignNetworkId,
        address indexed _recipient,
        uint128 indexed _amount,
        bytes           _foreignData
    );

    /// @notice emit to indicate a `freeze` has been called by
    /// the local user.
    event Freeze(
        bytes32 indexed _foreignNetworkId,
        bytes32 indexed _foreignRecipient,
        uint128 indexed _amount,
        bytes           _localData
    );

    /// @notice emit to indicate that a registry has been set
    event RegistrySet(
        address indexed _registry
    );
}

/// @title TokenBridge
/// Used by both the registry and `TokenBridgeRegisterUserInterface`,
/// informs the registry contract that a transfer is occuring.
interface TokenBridgeRegistryInterface {
    /// @notice function used by the registry to emit a transfer event
    function transfer(bytes32 _foreignNetworkId, bytes32 _foreignRecipient, uint128 _amount, bytes _localData) public;
}