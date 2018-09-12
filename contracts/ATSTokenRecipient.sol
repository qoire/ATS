pragma solidity 0.4.15;

interface ATSTokenRecipient {
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint128 amount,
        bytes userData,
        bytes operatorData
    ) public;
}