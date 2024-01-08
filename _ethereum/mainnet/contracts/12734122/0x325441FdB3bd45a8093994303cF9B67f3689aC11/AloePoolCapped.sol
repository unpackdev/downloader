// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";

import "./AloePool.sol";

contract AloePoolCapped is AloePool {
    using SafeERC20 for IERC20;

    address public immutable MULTISIG;
    uint256 public maxTotalSupply;

    constructor(address predictions, address multisig) AloePool(predictions) {
        MULTISIG = multisig;
    }

    function deposit(
        uint256 amount0Max,
        uint256 amount1Max,
        uint256 amount0Min,
        uint256 amount1Min
    )
        public
        override
        lock
        returns (
            uint256 shares,
            uint256 amount0,
            uint256 amount1
        )
    {
        (shares, amount0, amount1) = super.deposit(amount0Max, amount1Max, amount0Min, amount1Min);
        require(totalSupply() <= maxTotalSupply, "Aloe: Pool already full");
    }

    /**
     * @notice Removes tokens accidentally sent to this vault.
     */
    function sweep(
        IERC20 token,
        uint256 amount,
        address to
    ) external {
        require(msg.sender == MULTISIG, "Not authorized");
        require(token != TOKEN0 && token != TOKEN1, "Not sweepable");
        token.safeTransfer(to, amount);
    }

    /**
     * @notice Used to change deposit cap for a guarded launch or to ensure
     * vault doesn't grow too large relative to the UNI_POOL. Cap is on total
     * supply rather than amounts of TOKEN0 and TOKEN1 as those amounts
     * fluctuate naturally over time.
     */
    function setMaxTotalSupply(uint256 _maxTotalSupply) external {
        require(msg.sender == MULTISIG, "Not authorized");
        maxTotalSupply = _maxTotalSupply;
    }
}
