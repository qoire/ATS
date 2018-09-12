pragma solidity 0.4.15;

contract ContractInterfaceRegistry {
    function getManager(address _addr) public constant returns(address);
    function setManager(address _addr, address _newManager) external;
    function getInterfaceImplementer(address _addr, bytes32 _interfaceHash) external constant returns (address);
    function setInterfaceImplementer(address _addr, bytes32 _interfaceHash, address _implementer) external;
}

contract ContractInterfaceImplementer {
    // TODO: this needs to be deployed, this is just a placeholder address
    ContractInterfaceRegistry contractInterfaceRegistry = ContractInterfaceRegistry(0x0000000000000000000000000000000000000000000000000000000000000000);

    function setInterfaceImplementation(string _interfaceLabel, address impl) internal {
        bytes32 interfaceHash = keccak256(_interfaceLabel);
        contractInterfaceRegistry.setInterfaceImplementer(this, interfaceHash, impl);
    }

    function interfaceAddr(address addr, string _interfaceLabel) internal constant returns(address) {
        bytes32 interfaceHash = keccak256(_interfaceLabel);
        return contractInterfaceRegistry.getInterfaceImplementer(addr, interfaceHash);
    }

    function delegateManagement(address _newManager) internal {
        contractInterfaceRegistry.setManager(this, _newManager);
    }
}