// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./DateTime.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";

contract VCPool is DateTime, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public BITFtoken; // BITF Token

    uint8 public constant RELEASE_PERCENTAGE = 7;
    uint256 public PoolSupply;

    mapping(address => uint8) public vcPercentage;
    mapping(address => uint256) public releasedAmount;

    uint256 public releaseTime;

    constructor(uint256 _poolSupply) {
        PoolSupply = _poolSupply;
    }

    /**
     @notice Set BITF Token contract address
     @dev Only Owner is accessible
     @param _bitfToken BITF Token contract address
     */
    function setToken(address _bitfToken) external onlyOwner {
        require(_bitfToken != address(0), "Invalid token address");
        BITFtoken = IERC20(_bitfToken);
    }

    /**
     @notice SetVC wallet address and it's percentage
     @dev Only Owner is accessible
     @param _vcWallet VC wallet address
     @param _percents Assigned percentage for _vcWallet
     */
    function setVC(address _vcWallet, uint8 _percents) external onlyOwner {
        vcPercentage[_vcWallet] = _percents;
    }

    /**
     @notice Set Release Time. Time Stamp Start date for Token release Jun 21 2024
     @dev OnlyOwner is accessible
     */
    function setReleaseTime(
        uint16 _year,
        uint8 _month,
        uint8 _day
    ) external onlyOwner {
        releaseTime = toTimestamp(_year, _month, _day);
    }

    function claimToken() external {
        require(vcPercentage[_msgSender()] > 0, "You are not listed in VC List");
        require(block.timestamp >= releaseTime, "Token is not available to release yet");
        uint256 equity = PoolSupply.mul(vcPercentage[_msgSender()]).div(100);
        uint256 claimAmount = getClaimAmount(equity).sub(releasedAmount[_msgSender()]);
        BITFtoken.safeTransfer(_msgSender(), claimAmount);
        releasedAmount[_msgSender()] = releasedAmount[_msgSender()].add(claimAmount);
    }

    function getClaimAmount(
        uint256 balance
    ) public view returns (uint256) {
        uint256 currentTimeStamp = block.timestamp;
        require(currentTimeStamp >= block.timestamp );
        uint16 currentYear = getYear(currentTimeStamp);
        uint8 currentMonth = getMonth(currentTimeStamp);
        uint16 releaseYear = getYear(releaseTime);
        uint8 releaseMonth = getMonth(releaseTime);
        uint256 months = (currentYear - releaseYear) * 12;
        if(releaseMonth > currentMonth) {
            months -= (releaseMonth - currentMonth);
        } else {
            months += (currentMonth - releaseMonth);
        }
        uint256 amount = balance
            .mul(RELEASE_PERCENTAGE)
            .div(100)
            .mul(months);
        if (amount > balance) return balance;
        return amount;
    }

    function withdrawToken() external onlyOwner {
        uint256 balance = BITFtoken.balanceOf(address(this));
        require(balance > 0, "No BITF tokens to withdraw");
        BITFtoken.safeTransfer(owner(), balance);
    }
}