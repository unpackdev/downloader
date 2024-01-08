pragma solidity ^0.8.4;
// SPDX-License-Identifier: GPL-3.0-or-later

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ERC20Burnable.sol";

import "./TempleERC20Token.sol";

/**
 * Newly minted temple allocated to various temple strategies
 *
 * Any temple held by this contract is assumed to be unused,
 * and hence doesn't effect the intrinsinc value calculation.
 *
 * It's only considered in circulation once a pool pulls
 * it's allowance.
 */
contract MintAllowance is Ownable {
    // DAI contract address
    TempleERC20Token TEMPLE;

    constructor(TempleERC20Token _TEMPLE) {
      TEMPLE = _TEMPLE;
    }

    /**
     * Increase mint allowance for the given pool
     *
     * Atomically pulls amount from treasury before increasing allownance
     * as an extra check and balance
     */
    function increaseMintAllowance(address _pool, uint256 _amount) external onlyOwner {
      SafeERC20.safeTransferFrom(TEMPLE, msg.sender, address(this), _amount);
      SafeERC20.safeIncreaseAllowance(TEMPLE, _pool, _amount);
    }

    /**
     * Burn any unused mint allowance for a given pool
     */
    function burnUnusedMintAllowance(address _pool) external onlyOwner {
      uint256 unusedMintAllowance = TEMPLE.allowance(address(this), _pool);
      SafeERC20.safeDecreaseAllowance(TEMPLE, _pool, unusedMintAllowance);
      TEMPLE.burn(unusedMintAllowance);
    }
}