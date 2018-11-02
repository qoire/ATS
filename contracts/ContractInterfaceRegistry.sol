pragma solidity 0.4.15;

/// Based on: https://github.com/ethereum/EIPs/issues/820
/// Rationale for moving away from ERC820 naming is that
/// support for ERC165 (which is one of the proposed features)
/// for 820 has been removed.

/// @@@ DEPRECATED see AionInterfaceRegistry.sol
/// @@@ DEPRECATED see https://github.com/aionnetwork/AIP/pull/11
interface ContractInterfaceRegistryImplementer {
    /// @notice Contracts that implement an interferce in behalf of another contract must return true
    /// @param addr Address that the contract woll implement the interface in behalf of
    /// @param interfaceHash keccak256 of the name of the interface
    /// @return CIR_ACCEPT_MAGIC if the contract can implement the interface represented by
    ///  `ìnterfaceHash` in behalf of `addr`
    function canImplementInterfaceForAddress(address addr, bytes32 interfaceHash) view public returns(bytes32);
}

contract ContractInterfaceRegistry {
    bytes32 constant CIR_ACCEPT_MAGIC = keccak256("CIR_ACCEPT_MAGIC");

    mapping (address => mapping(bytes32 => address)) interfaces;
    mapping (address => address) managers;

    modifier canManage(address addr) {
        require(getManager(addr) == msg.sender);
        _;
    }

    event InterfaceImplementerSet(address indexed addr, bytes32 indexed interfaceHash, address indexed implementer);
    event ManagerChanged(address indexed addr, address indexed newManager);

    /// @notice Query the hash of an interface given a name
    /// @param interfaceName Name of the interfce
    function interfaceHash(string interfaceName) public pure returns(bytes32) {
        return keccak256(interfaceName);
    }

    /// @notice GetManager
    function getManager(address addr) public view returns(address) {
        // By default the manager of an address is the same address
        if (managers[addr] == 0) {
            return addr;
        } else {
            return managers[addr];
        }
    }

    /// @notice Sets an external `manager` that will be able to call `setInterfaceImplementer()`
    ///  on behalf of the address.
    /// @param addr Address that you are defining the manager for.
    /// @param newManager The address of the manager for the `addr` that will replace
    ///  the old one.  Set to 0x0 if you want to remove the manager.
    function setManager(address addr, address newManager) public canManage(addr) {
        managers[addr] = newManager == addr ? 0 : newManager;
        ManagerChanged(addr, newManager);
    }

    /// @notice Query if an address implements an interface and thru which contract
    /// @param addr Address that is being queried for the implementation of an interface
    /// @param iHash SHA3 of the name of the interface as a string
    ///  Example `web3.utils.sha3('ERC777Token`')`
    /// @return The address of the contract that implements a specific interface
    ///  or 0x0 if `addr` does not implement this interface
    function getInterfaceImplementer(address addr, bytes32 iHash) constant public returns (address) {
        return interfaces[addr][iHash];
    }

    /// @notice Sets the contract that will handle a specific interface; only
    ///  the address itself or a `manager` defined for that address can set it
    /// @param addr Address that you want to define the interface for
    /// @param iHash SHA3 of the name of the interface as a string
    ///  For example `web3.utils.sha3('Ierc777')` for the Ierc777
    function setInterfaceImplementer(address addr, bytes32 iHash, address implementer) public canManage(addr)  {
        if ((implementer != 0) && (implementer != msg.sender)) {
            require(ContractInterfaceRegistryImplementer(implementer).canImplementInterfaceForAddress(addr, iHash)
                        == CIR_ACCEPT_MAGIC);
        }
        interfaces[addr][iHash] = implementer;
        InterfaceImplementerSet(addr, iHash, implementer);
    }
}