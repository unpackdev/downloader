// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./IMaidCafe.sol";
import "./IUniswapV2Router02.sol";
import "./IWETH.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

contract MaidCafe is IMaidCafe, ERC20("Maid Cafe", "$OMU"), Ownable {
    using SafeERC20 for IERC20;
    IMaidCoin public immutable override maidCoin;
    IWETH public immutable WETH;

    constructor(IMaidCoin _maidCoin, IWETH _WETH) {
        maidCoin = _maidCoin;
        WETH = _WETH;
    }

    receive() external payable {}

    // Enter the Maid Café. Pay some $MAIDs. Earn some shares.
    // Locks $MAID and mints $OMU (Omurice)
    function enter(uint256 _amount) public override {
        // Gets the amount of $MAID locked in the Maid Café
        uint256 totalMaidCoin = maidCoin.balanceOf(address(this));
        // Gets the amount of $OMU in existence
        uint256 totalShares = totalSupply();
        // If no $OMU exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalMaidCoin == 0) {
            _mint(msg.sender, _amount);
        }
        // Calculate and mint the amount of $OMU the $MAID is worth. The ratio will change overtime, as $OMU is burned/minted and $MAID deposited + gained from fees / withdrawn.
        else {
            uint256 what = (_amount * totalShares) / totalMaidCoin;
            _mint(msg.sender, what);
        }
        // Lock the $MAID in the Maid Café
        IERC20(address(maidCoin)).safeTransferFrom(msg.sender, address(this), _amount);
        emit Enter(msg.sender, _amount);
    }

    function enterWithPermit(
        uint256 _amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        maidCoin.permit(msg.sender, address(this), _amount, deadline, v, r, s);
        enter(_amount);
    }

    // Leave the Maid Café. Claim back your $MAIDs.
    // Unlocks the staked + gained $MAID and burns $OMU
    function leave(uint256 _share) external override {
        // Gets the amount of $OMU in existence
        uint256 totalShares = totalSupply();
        // Calculates the amount of $MAID the $OMU is worth
        uint256 what = (_share * maidCoin.balanceOf(address(this))) / totalShares;
        _burn(msg.sender, _share);
        IERC20(address(maidCoin)).safeTransfer(msg.sender, what);
        emit Leave(msg.sender, _share);
    }

    function swap(
        address token,
        IUniswapV2Router02 router,
        address[] calldata path,
        uint256 amountOutMin,
        uint256 deadline
    ) external onlyOwner {
        require(token != address(maidCoin), "MaidCafe: Invalid token");
        require(path[path.length - 1] == address(maidCoin), "MaidCafe: Invalid path");
        uint256 amountIn;
        if (token == address(0)) {
            require(path[0] == address(WETH), "MaidCafe: Invalid path");
            amountIn = address(this).balance;
            require(amountIn > 0, "MaidCafe: Invalid amount");
            WETH.deposit{value: amountIn}();
        } else {
            require(path[0] == token, "MaidCafe: Invalid path");
            amountIn = IERC20(token).balanceOf(address(this));
            require(amountIn > 0, "MaidCafe: Invalid amount");
        }
        IERC20(path[0]).approve(address(router), amountIn);
        router.swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), deadline);
    }
}
