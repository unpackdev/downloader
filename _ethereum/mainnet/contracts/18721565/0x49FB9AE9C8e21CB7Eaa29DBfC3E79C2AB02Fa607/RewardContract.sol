// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract RewardContract {
    address public owner;
    IERC20 public tokenContract;
    uint256 public totalSupply;
    uint256 public claimStartHourUTC;
    uint256 public claimEndHourUTC;

    constructor(address _tokenContract) {
        owner = msg.sender;
        tokenContract = IERC20(_tokenContract);
        totalSupply = tokenContract.totalSupply();
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function setClaimTime(uint256 _startHourUTC, uint256 _endHourUTC) external onlyOwner {
        require(_startHourUTC < 24 && _endHourUTC < 24, "Invalid hour format");
        claimStartHourUTC = _startHourUTC;
        claimEndHourUTC = _endHourUTC;
    }

    function isClaimTime() public view returns (bool) {
        uint256 currentHourUTC = (block.timestamp / 3600) % 24;
        if (claimStartHourUTC < claimEndHourUTC) {
            return currentHourUTC >= claimStartHourUTC && currentHourUTC < claimEndHourUTC;
        } else {
            return currentHourUTC >= claimStartHourUTC || currentHourUTC < claimEndHourUTC;
        }
    }

    function claimReward(address recipient) external {
        require(isClaimTime(), "Claim time not reached");
        require(recipient != address(0), "Invalid recipient address");

        uint256 userBalance = tokenContract.balanceOf(msg.sender);
        uint256 rewardPool = tokenContract.balanceOf(address(this));
        uint256 userShare = rewardPool * userBalance / totalSupply;

        require(userShare > 0, "No rewards available");
        require(tokenContract.transfer(recipient, userShare), "Transfer failed");
    }
    function withdrawStuckTokens (address stoken, address receiver) external onlyOwner {
        require(IERC20(stoken).balanceOf(address(this)) > 0, "Can't withdraw 0");
        IERC20(stoken).transfer(receiver, IERC20(stoken).balanceOf(address(this)));

    }

    function withdrawStuckETH() external onlyOwner{
        require (address(this).balance > 0, "Can't withdraw negative or zero");
        payable(owner).transfer(address(this).balance);
    }
}