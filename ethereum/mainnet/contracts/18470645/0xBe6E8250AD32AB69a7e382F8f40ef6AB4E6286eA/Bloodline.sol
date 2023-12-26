// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./IPoolInitializer.sol";

/// Permission to mint tokens is not exist.
error NotAllowedToMint();

/**
 * @title Bloodline - an ERC20 token that is allowed to be minted only by `rewardLocker`.
 */
contract Bloodline is ERC20 {
    /// @notice Contract which is allowed to mint tokens.
    address public rewardLocker;
    /// @notice Uniswap V3 pool with 1% fee, underlying tokens: WETH and this.
    address public uniV3Pool;

    /**
     * @notice Constructor initialize solmate ERC20 and deploys Uniswap V3 pool.
     * @param _weth address of WETH9 contract.
     * @param _nfPositionManager address of NonfungiblePositionManager (Uniswap V3) contract.
     * @param _sqrtPricesX96 an array of 2 initial prices for Uniswap V3 pool:
     *                       first price is picked if WETH9 is token1,
     *                       second price is picked if WETH9 is token0.
     */
    constructor(
        address _rewardLocker,
        address _weth,
        address _nfPositionManager,
        uint160[2] memory _sqrtPricesX96
    )
        ERC20("Bloodline", "BLOOD", uint8(18))
    {
        rewardLocker = _rewardLocker;
        if (address(this) < _weth) {
            uniV3Pool = IPoolInitializer(_nfPositionManager).createAndInitializePoolIfNecessary(
                address(this), _weth, uint24(10_000), _sqrtPricesX96[0]
            );
        } else {
            uniV3Pool = IPoolInitializer(_nfPositionManager).createAndInitializePoolIfNecessary(
                _weth, address(this), uint24(10_000), _sqrtPricesX96[1]
            );
        }
        require(uniV3Pool != address(0));
    }

    /**
     * @notice Method mints tokens.
     * @dev Method could be called only by `rewardLocker`.
     * @param account address which should receive newly minted tokens.
     * @param amount of tokens which should be minted.
     */
    function mintBloodline(address account, uint256 amount) external {
        if (msg.sender != rewardLocker) {
            revert NotAllowedToMint();
        }
        _mint(account, amount);
    }

    /**
     * @notice Method burns tokens.
     * @param amount of tokens which should be burned.
     */
    function burn(uint256 amount) external returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }
}
