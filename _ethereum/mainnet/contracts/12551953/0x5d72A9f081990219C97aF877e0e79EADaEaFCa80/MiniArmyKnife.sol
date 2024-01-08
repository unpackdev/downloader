// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Pausable.sol";
import "./IVesperPool.sol";

// Migration flow
// User approves VAK for vToken
// User calls migrate, and receives vToken2
contract MiniArmyKnife is Pausable, Ownable {
    using SafeERC20 for IERC20;

    receive() external payable {
        revert("we-do-not-want-your-money");
    }

    modifier live() {
        require(
            !paused() || _msgSender() == owner(),
            "contract-has-been-paused"
        );
        _;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function approveToken(
        address token,
        uint256 amount,
        address spender
    ) external onlyOwner {
        _approveToken(token, amount, spender);
    }

    function approveTokens(
        address[] memory tokens,
        uint256[] memory amounts,
        address[] memory spenders
    ) external onlyOwner {
        require(
            tokens.length == amounts.length && tokens.length == spenders.length,
            "invalid-token-list"
        );
        for (uint256 i = 0; i < tokens.length; i++) {
            _approveToken(tokens[i], amounts[i], spenders[i]);
        }
    }

    function _approveToken(
        address token,
        uint256 amount,
        address spender
    ) internal {
        IERC20(token).approve(spender, amount);
    }

    function setPool(address pool) external onlyOwner {
        address poolToken = address(IVesperPool(pool).token());
        _approveToken(poolToken, 0, pool);
        _approveToken(poolToken, type(uint256).max, pool);
    }

    function unsetPool(address pool) external onlyOwner {
        _approveToken(address(IVesperPool(pool).token()), 0, pool);
    }

    function _permitToken(
        address token,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        IVesperPool(token).permit(from, to, amount, deadline, v, r, s);
    }

    function simpleMigrate(
        address vTokenA,
        address vTokenB,
        uint256 amountA
    ) public live {
        IVesperPool poolA = IVesperPool(vTokenA);
        IVesperPool poolB = IVesperPool(vTokenB);
        require(poolA.token() == poolB.token(), "Unmatched underlying tokens");
        address user = _msgSender();
        IERC20 collToken = IERC20(poolA.token());
        uint256 collBalanceBefore = collToken.balanceOf(address(this));
        poolA.transferFrom(user, address(this), amountA);
        poolA.withdraw(amountA);
        uint256 collBalanceAfter = collToken.balanceOf(address(this));
        uint256 userCollateralBalance = collBalanceAfter - collBalanceBefore;
        uint256 bBalanceBefore = poolB.balanceOf(address(this));
        poolB.deposit(userCollateralBalance);
        uint256 bBalanceAfter = poolB.balanceOf(address(this));
        uint256 userFinalBalance = bBalanceAfter - bBalanceBefore;
        poolB.transfer(user, userFinalBalance);
    }

    function simpleMigrateWithPermit(
        address vTokenA,
        address vTokenB,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        // simpleMigrate checks for "live" so we dont need that modifier on this
        require(to == address(this), "invalid-receiver");
        _permitToken(vTokenA, from, to, amount, deadline, v, r, s);
        simpleMigrate(vTokenA, vTokenB, amount);
    }
}
