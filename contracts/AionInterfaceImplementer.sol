pragma solidity 0.4.15;

contract AionInterfaceRegistry {
    function getManager(address target) public constant returns(address);
    function setManager(address target, address manager) public;
    function getInterfaceDelegate(address target, bytes32 interfaceHash) public constant returns (address);
    function setInterfaceDelegate(address target, bytes32 interfaceHash, address delegate) public;
}

contract AionInterfaceImplementer {
    // TODO: this needs to be deployed, this is just a placeholder address
    AionInterfaceRegistry air = AionInterfaceRegistry(0xa0d270e7759e8fc020df5f1352bf4d329342c1bcdfe9297ef594fa352c7cab26);

    function setInterfaceDelegate(string _interfaceLabel, address impl) internal {
        bytes32 interfaceHash = sha3(_interfaceLabel);
        air.setInterfaceDelegate(this, interfaceHash, impl);
    }

    function getInterfaceDelegate(address addr, string _interfaceLabel) internal constant returns(address) {
        bytes32 interfaceHash = sha3(_interfaceLabel);
        return air.getInterfaceDelegate(addr, interfaceHash);
    }

    function setDelegateManager(address _newManager) internal {
        air.setManager(this, _newManager);
    }
}