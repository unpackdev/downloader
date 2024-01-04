// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IRulerFeeReceiver.sol";
import "./IRouter.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract RulerFeeReceiver is Ownable, IRulerFeeReceiver {
    using SafeERC20 for IERC20;
    address public immutable override ruler;
    address public override xruler;
    address public override treasury;
    uint256 public override feeRateToTreasury = 1e18; // 1e18

    constructor(address _ruler, address _xruler, address _treasury) {
        require(_ruler != address(0), "RulerFE: _ruler cannot be 0");
        require(_xruler != address(0), "RulerFE: _xruler cannot be 0");
        require(_treasury != address(0), "RulerFE: _treasury cannot be 0");
        ruler = _ruler;
        xruler = _xruler;
        treasury = _treasury;
    }

    function buyBack(IERC20 _token, IRouter _router, address[] calldata _path, uint256 _maxSwapAmt, uint256 _amountOutMin) external override onlyOwner {
        require(_path[0] == address(_token), "RulerFE: input token != _token");
        require(_path[0] != ruler, "RulerFE: input token cannot be RULER");
        require(_path[_path.length - 1] == ruler, "RulerFE: output token != RULER");
        require(_maxSwapAmt > 0, "RulerFE: _maxSwapAmt <= 0");
        uint256 balance = _token.balanceOf(address(this));
        require(balance > 0, "RulerFE: _token balance is 0");
        uint256 swapAmt = balance < _maxSwapAmt ? balance : _maxSwapAmt;
        if (feeRateToTreasury > 0) {
            uint256 amtToTreasury = swapAmt * feeRateToTreasury / 1e18;
            _token.safeTransfer(treasury, amtToTreasury);
            swapAmt = swapAmt - amtToTreasury;
        }
        uint256 allowance = _token.allowance(address(this), address(_router));
        if (allowance < swapAmt) {
            if (allowance != 0) {
                _token.safeApprove(address(_router), 0);
            }
            _token.safeApprove(address(_router), type(uint256).max);
        }
        _router.swapExactTokensForTokens(swapAmt, _amountOutMin, _path, xruler, block.timestamp + 1 hours);
        emit BuyBack(_token, swapAmt);
    }

    /// @notice For tokens that don't have enough liquidity to swap into RULER
    function collect(IERC20 _token, uint256 _amount) external override onlyOwner {
        uint256 balance = _token.balanceOf(address(this));
        uint256 amount = _amount == 0 ? balance : _amount;
        require(balance >= amount, "RulerFE: amount exceed balance");
        _token.safeTransfer(treasury, amount);
        emit Collected(_token, amount);
    }

    function setXruler(address _xruler) external override onlyOwner {
        require(_xruler != address(0), "RulerFE: _xruler cannot be 0");
        xruler = _xruler;
    }

    function setTreasury(address _treasury) external override onlyOwner {
        require(_treasury != address(0), "RulerFE: _treasury cannot be 0");
        treasury = _treasury;
    }

    function setFeeRateToTreasury(uint256 _feeRateToTreasury) external override onlyOwner {
        require(_feeRateToTreasury <= 1e18, "RulerFE: feeRate must be < 1");
        feeRateToTreasury = _feeRateToTreasury;
    }
}