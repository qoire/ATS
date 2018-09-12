pragma solidity 0.4.15;

interface ATSTokenSender {
    function tokensToSend(
        address operator,
        address from,
        address to,
        uint128 amount,
        bytes userData,
        bytes operatorData
    ) public;
}