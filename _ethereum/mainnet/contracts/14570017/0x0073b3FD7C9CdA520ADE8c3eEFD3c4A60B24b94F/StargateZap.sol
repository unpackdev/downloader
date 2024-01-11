// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./ILPToken.sol";
import "./IStargateRouter.sol";
import "./IVault.sol";

contract StargateZap {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IStargateRouter public immutable router;

    constructor(address _router) public {
        router = IStargateRouter(_router);
    }

    function zapIn(address _vault, uint256 _amount) external returns (uint256) {
        ILPToken want = ILPToken(address(IVault(_vault).want()));
        IERC20 underlyingToken = IERC20(want.token());

        underlyingToken.safeTransferFrom(msg.sender, address(this), _amount);

        _approveTokenIfNeeded(underlyingToken, address(router));
        uint256 wantBalBefore = want.balanceOf(address(this));
        router.addLiquidity(want.poolId(), _amount, address(this));
        uint256 wantBalAfter = want.balanceOf(address(this));
        uint256 wantAmount = wantBalAfter.sub(wantBalBefore);

        _approveTokenIfNeeded(want, address(_vault));
        uint256 shares = IVault(_vault).deposit(wantAmount);
        IERC20(_vault).safeTransfer(msg.sender, shares);

        return shares;
    }

    function zapOut(address _vault, uint256 _amount)
        external
        returns (uint256)
    {
        ILPToken want = ILPToken(address(IVault(_vault).want()));
        IERC20 underlyingToken = IERC20(want.token());

        IERC20(_vault).safeTransferFrom(msg.sender, address(this), _amount);

        uint256 wantAmount = IVault(_vault).withdraw(_amount);

        _approveTokenIfNeeded(want, address(router));
        uint256 underlyingBalBefore = underlyingToken.balanceOf(address(this));
        router.instantRedeemLocal(
            uint16(want.poolId()),
            wantAmount,
            address(this)
        );
        uint256 underlyingBalAfter = underlyingToken.balanceOf(address(this));
        uint256 underlyingAmount = underlyingBalAfter.sub(underlyingBalBefore);

        underlyingToken.safeTransfer(msg.sender, underlyingAmount);

        return underlyingAmount;
    }

    function _approveTokenIfNeeded(IERC20 _token, address _spender) private {
        if (_token.allowance(address(this), _spender) == 0) {
            _token.safeApprove(_spender, type(uint256).max);
        }
    }
}
