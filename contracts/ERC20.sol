pragma solidity 0.4.15;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 *
 * @notice ATS contracts by default are required to implement ERC20 interface
 */
contract ERC20 {
    function totalSupply() public constant returns (uint128);

    function balanceOf(address _who) public constant returns (uint128);

    function allowance(address _owner, address _spender) public constant returns (uint128);

    function transfer(address _to, uint128 _value) public returns (bool);

    function approve(address _spender, uint128 _value) public returns (bool);

    function transferFrom(address _from, address _to, uint128 _value) public returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint128 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint128 value
    );
}