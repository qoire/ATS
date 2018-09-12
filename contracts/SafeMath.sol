pragma solidity 0.4.15;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 * @notice This is a softer (in terms of throws) variant of SafeMath:
 *         https://github.com/OpenZeppelin/openzeppelin-solidity/pull/1121
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint128 _a, uint128 _b) internal constant returns (uint128 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }
        c = _a * _b;
        require(c / _a == _b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint128 _a, uint128 _b) internal constant returns (uint128) {
        // Solidity automatically throws when dividing by 0
        // therefore require beforehand avoid throw
        require(_b > 0);
        // uint128 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
        return _a / _b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint128 _a, uint128 _b) internal constant returns (uint128) {
        require(_b <= _a);
        return _a - _b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint128 _a, uint128 _b) internal constant returns (uint128 c) {
        c = _a + _b;
        require(c >= _a);
        return c;
    }
}