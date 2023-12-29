pragma solidity 0.6.6;

import "./BaseERC20.sol";

contract USDCToken is BaseERC20 {

    /* ============ Variables ============ */

    address public owner;

    /* ============ Constructor ============ */

    constructor(
        string memory name,
        string memory symbol,
        uint256 supplyCap
    )
        public
        BaseERC20(name, symbol, supplyCap)
    {
        _mint(msg.sender, supplyCap);
    }

    /* ============ View only ============ */

    function decimals()
        public
        pure
        override
        returns (uint8)
    {
        return 6;
    }

}