// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./SafeERC20.sol";
import "./IERC20.sol";


contract MiniSwap {
    using SafeERC20 for IERC20;
    IERC20 public offeredToken;
    IERC20 public acceptedToken;

    address public immutable owner;

    uint256 totalAmount;

    bool pause;

    modifier onlyOwner() {
        require(msg.sender == owner, "ERR_ONLY_OWNER");
        _;
    }

    modifier notPause() {
        require(!pause, "ERR_PAUSED");
        _;
    }

    constructor (
        address _offeredToken,
        address _acceptedToken,
        uint256 _totalAmount
    ) {
        owner = msg.sender;
        offeredToken = IERC20(_offeredToken);
        acceptedToken = IERC20(_acceptedToken);
        totalAmount = _totalAmount;
    }

    function deposit(uint256 depositAmount) external onlyOwner {
        require((offeredToken.balanceOf(address(this)) + acceptedToken.balanceOf(address(this)) + depositAmount) == totalAmount, "ERR_SUPPLY_EXCEEDS");
        offeredToken.safeTransferFrom(msg.sender, address(this), depositAmount);
    }

    function swap(uint256 _amount) external notPause {
        require(_amount < totalAmount, "ERR_NOT_ENOUGH_SUPPLY");
        require(offeredToken.balanceOf(address(this)) + acceptedToken.balanceOf(address(this)) == totalAmount, "ERR_SUPPLY_EXCEEDS");
        acceptedToken.safeTransferFrom(msg.sender, address(this), _amount);
        offeredToken.transfer(msg.sender, _amount);
    }

    function pauseSwap() external onlyOwner {
        pause = true;
    }

    function rescue(address _to) external onlyOwner {
        require(_to != address(0), "ERR_ZERO_ADDRESS");
        uint256 offeredTokenRemainingSupply = offeredToken.balanceOf(address(this));
        uint256 acceptedTokenSupply = acceptedToken.balanceOf(address(this));

        // transfer tokens to owner
        offeredToken.transfer(_to, offeredTokenRemainingSupply);
        acceptedToken.transfer(_to, acceptedTokenSupply);
    }
}