// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Votes.sol";

contract SANSHU is ERC20Votes {
    /**
     * @notice Constructor.
     *
     * @param  name         The token name, i.e., SANSHU!.
     * @param  symbol       The token symbol, i.e., SANSHU.
     * @param  totalSupply_ Initial total token supply.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 totalSupply_
    ) ERC20(name, symbol) ERC20Permit(name) {
        _mint(msg.sender, totalSupply_);
    }
}
