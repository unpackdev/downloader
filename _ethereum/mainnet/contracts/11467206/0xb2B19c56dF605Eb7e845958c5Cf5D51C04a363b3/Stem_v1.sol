// SPDX-License-Identifier: MIT
pragma solidity >=0.6 <0.7.0;

import "./PollenToken.sol";

/**
 * @title Stem_v1
 * @dev STEM token contract
 */
contract Stem_v1 is PollenToken {
    // ~2021-03-19T01:45:00Z
    uint256 internal constant UNLOCK_BLOCK = 12070000;

    /**
     * @notice Initializes the contract and sets the token name and symbol
     * @dev Sets the contract `owner` account to the deploying account
     */
    function initialize(
        string memory name,
        string memory symbol
    ) external {
        _initialize(name, symbol);
    }

    /**
     * @notice Returns the block when token transfers get allowed
     * ("virtual" to facilitate testing)
     */
    function unlockBlock() public virtual pure returns(uint) {
        return UNLOCK_BLOCK;
    }

    // It disables transfers before `unlockBlock()`
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        if (from != address(0)) {
            require(block.number > unlockBlock(), "STEM: token locked");
        }
        super._beforeTokenTransfer(from, to, amount);
    }
}
