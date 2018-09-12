contract BridgeRegistry {

    mapping(bytes32 => address) public bridgeIdToBridgeContract;

    mapping(address => mapping(bytes32 => bool)) localAddressToBridgePermission;

    event LogChangedBridgePermission(address localAddress, bytes32 bridgeId, bool status);

    ** Setters **

    function setPermission(bytes32 bridgeId, bool status) public {
        addressToPermission[msg.sender][bridgeId] = _status;
        emit LogChangedBridgePermission(msg.sender, bridgeId, status);
    }

    ** Getters **

    function getPermission(address localAddress, bytes32 bridgeId) public constant returns(bool status) {
        return addressToPermission[msg.sender][bridgeId];
    }

    function getBridgeContract(bytes32 bridgeId) public constant returns(address localAddress) {
        return bridgeIdToBridgeContract[bridgeId];
    }

}
