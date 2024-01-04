// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ICoverForge.sol";
import "./IERC20Permit.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./ERC20Permit.sol";
import "./SafeERC20.sol";

contract CoverForge is ERC20("CoverForge", "xCOVER"), ERC20Permit("CoverForge"), ICoverForge, Ownable {
    using SafeERC20 for IERC20;
    IERC20 public immutable cover;

    constructor(IERC20 _cover) {
        cover = _cover;
    }

    function getShareValue() external view override returns (uint256) {
        uint256 multiplier = 10 ** 18;
        return totalSupply() > 0 
            ? multiplier * cover.balanceOf(address(this)) / totalSupply() 
            : multiplier;
    }

    function deposit(uint256 _amount) public override {
        uint256 totalCover = cover.balanceOf(address(this));
        uint256 totalShares = totalSupply();
        // if user is first depositer, mint _amount of xCOVER
        if (totalShares == 0 || totalCover == 0) {
            _mint(msg.sender, _amount);
        } else {
            // loss of precision if totalCover is significantly greater than totalShares
            // seeding the pool with decent amount of COVER prevents this
            uint256 myShare = _amount * totalShares / totalCover;
            _mint(msg.sender, myShare);
        }
        cover.safeTransferFrom(msg.sender, address(this), _amount);
        emit Deposit(msg.sender, _amount);
    }

    function depositWithPermit(uint256 _amount, Permit calldata permit) external override {
        IERC20Permit(address(cover)).permit(
            permit.owner,
            permit.spender,
            permit.amount,
            permit.deadline,
            permit.v,
            permit.r,
            permit.s
        );
        deposit(_amount);
    }

    function withdraw(uint256 _share) external override {
        uint256 totalShares = totalSupply();
        uint256 myShare = _share * cover.balanceOf(address(this)) / totalShares;
        _burn(msg.sender, _share);
        cover.safeTransfer(msg.sender, myShare);
        emit Withdraw(msg.sender, _share, myShare);
    }

    /// @notice Tokens that are accidentally sent to this contract can be recovered
    function collect(IERC20 _token) external override onlyOwner {
        if (totalSupply() > 0) {
            require(_token != cover, "cannot collect COVER");
        }
        uint256 balance = _token.balanceOf(address(this));
        require(balance > 0, "_token balance is 0");
        _token.safeTransfer(msg.sender, balance);
    }
}