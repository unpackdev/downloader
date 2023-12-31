// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "./IAcrossMessageHandler.sol";
import "./IAcceleratingDistributor.sol";
import "./IHubPool.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract CrossChainStaker is IAcrossMessageHandler {
    using SafeERC20 for IERC20;

    error MessageWrongLength(uint256 length);

    IHubPool public immutable hubPool;
    IAcceleratingDistributor public immutable acceleratingDistributor;

    constructor(IHubPool _hubPool, IAcceleratingDistributor _acceleratingDistributor) {
        hubPool = _hubPool;
        acceleratingDistributor = _acceleratingDistributor;
    }

    function depositAndStake(IERC20 token, uint256 amount) external {
        depositAndDonateStake(token, amount, msg.sender);
    }

    function handleAcrossMessage(address tokenSent, uint256 amount, bool, address, bytes memory message) external {
        (address beneficiary) = abi.decode(message, (address));
        _depositAndStake(IERC20(tokenSent), amount, beneficiary);
    }

    function depositAndDonateStake(IERC20 token, uint256 amount, address beneficiary) public {
        token.safeTransferFrom(msg.sender, address(this), amount);
        _depositAndStake(token, amount, beneficiary);
    }

    function _depositAndStake(IERC20 token, uint256 amount, address beneficiary) private {
        (IERC20 lpToken, uint256 lpAmount) = _deposit(token, amount);
        _stake(lpToken, lpAmount, beneficiary);
    }

    function _deposit(IERC20 token, uint256 depositAmount) private returns (IERC20 lpToken, uint256 lpAmount) {
        IHubPool.PooledToken memory pooledToken = hubPool.pooledTokens(address(token));
        token.safeIncreaseAllowance(address(hubPool), depositAmount);

        hubPool.addLiquidity(address(token), depositAmount);
        lpToken = IERC20(pooledToken.lpToken);
        lpAmount = lpToken.balanceOf(address(this));
    }

    function _stake(IERC20 lpToken, uint256 lpAmount, address beneficiary) private {
        lpToken.safeIncreaseAllowance(address(acceleratingDistributor), lpAmount);
        acceleratingDistributor.stakeFor(address(lpToken), lpAmount, beneficiary);
    }
}
