// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ICoverFeeReceiver.sol";
import "./IRouter.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract CoverFeeReceiver is Ownable, ICoverFeeReceiver {
    using SafeERC20 for IERC20;
    address public immutable override cover;
    address public override forge;
    address public override treasury;
    uint256 public override feeNumToTreasury;

    constructor(address _cover, address _forge, address _treasury, uint256 _feeNumToTreasury) {
        require(_cover != address(0), "address cannot be 0");
        require(_forge != address(0), "address cannot be 0");
        require(_treasury != address(0), "address cannot be 0");
        require(_feeNumToTreasury <= 10000, "_feeNumToTreasury must be <= 10000");
        cover = _cover;
        forge = _forge;
        treasury = _treasury;
        feeNumToTreasury = _feeNumToTreasury;
    }

    function buyBack(IERC20 _token, IRouter _router, address[] calldata _path, uint256 _maxSwapAmt, uint256 _amountOutMin) external override onlyOwner {
        require(_path[0] == address(_token), "input token != _token");
        require(_path[0] != cover, "input token cannot be COVER");
        require(_path[_path.length - 1] == cover, "output token != COVER");
        require(_maxSwapAmt > 0, "_maxSwapAmt <= 0");
        uint256 balance = _token.balanceOf(address(this));
        require(balance > 0, "_token balance is 0");
        uint256 swapAmt = balance < _maxSwapAmt ? balance : _maxSwapAmt;
        if (feeNumToTreasury > 0) {
            uint256 amtToTreasury = swapAmt * feeNumToTreasury / 10000;
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
        _router.swapExactTokensForTokens(swapAmt, _amountOutMin, _path, forge, block.timestamp + 1 hours);
        emit BuyBack(_token, swapAmt);
    }

    /// @notice For tokens that don't have enough liquidity to swap into COVER
    function collect(IERC20 _token, uint256 _amount) external override onlyOwner {
        uint256 balance = _token.balanceOf(address(this));
        uint256 amount = _amount == 0 ? balance : _amount;
        require(balance >= amount, "amount exceed balance");
        _token.safeTransfer(treasury, amount);
        emit Collected(_token, amount);
    }

    function setForge(address _forge) external override onlyOwner {
        require(_forge != address(0), "address cannot be 0");
        forge = _forge;
    }

    function setTreasury(address _treasury) external override onlyOwner {
        require(_treasury != address(0), "address cannot be 0");
        treasury = _treasury;
    }

    function setFeeNumToTreasury(uint256 _feeNumToTreasury) external override onlyOwner {
        require(_feeNumToTreasury <= 10000, "_feeNumToTreasury must be <= 10000");
        feeNumToTreasury = _feeNumToTreasury;
    }
}