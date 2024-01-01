// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./DateTime.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";

contract BITFPool is DateTime, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public BITFtoken; // BITF Token

    string public PoolName;
    uint8 public isFounderPool;

    uint8 public firstReleasePercent;
    uint8 public secondReleasePercent;
    uint8 public thirdReleasePercent;
    uint256 public firstReleaseTime;
    uint256 public secondReleaseTime;
    uint256 public thirdReleaseTime;

    uint256 public PoolSupply;

    mapping(address => uint8) public founders; // founder Address => Percentages
    mapping(address => mapping(uint8 => uint8)) public unlocked; // founder Address => Released Times

    event Released(
        string PoolName,
        string ReleaseRound,
        address Recipient,
        uint256 Amount,
        uint16 Year,
        uint8 Month,
        uint8 Day,
        uint8 Hour,
        uint8 Minute,
        uint8 Second
    );

    constructor(string memory _name, uint256 _poolSupply) {
        PoolName = _name;
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

    function setFirstRelease(
        uint8 releasePercent,
        uint16 _year,
        uint8 _month,
        uint8 _day
    ) external onlyOwner {
        firstReleasePercent = releasePercent;
        firstReleaseTime = toTimestamp(_year, _month, _day);
    }

    function setSecondRelease(
        uint8 releasePercent,
        uint16 _year,
        uint8 _month,
        uint8 _day
    ) external onlyOwner {
        secondReleasePercent = releasePercent;
        secondReleaseTime = toTimestamp(_year, _month, _day);
    }

    function setThirdRelease(
        uint8 releasePercent,
        uint16 _year,
        uint8 _month,
        uint8 _day
    ) external onlyOwner {
        thirdReleasePercent = releasePercent;
        thirdReleaseTime = toTimestamp(_year, _month, _day);
    }

    function enableFounderPool() external onlyOwner {
        isFounderPool = 1;
    }

    function setFounders(
        address[] memory _founders,
        uint8[] memory _percents
    ) external onlyOwner {
        require(isFounderPool > 0, "This pool is not for founders");
        for (uint256 i = 0; i < _founders.length; i++) {
            founders[_founders[i]] = _percents[i];
        }
    }

    function firstRelease(address _toRelease) external onlyOwner {
        uint256 current = block.timestamp;
        require(isFounderPool == 0, "Founder Pool!");
        require(
            current >= firstReleaseTime && firstReleasePercent > 0,
            "First release is not started yet"
        );
        uint256 equity = PoolSupply.mul(firstReleasePercent).div(100);
        BITFtoken.transfer(_toRelease, equity);
        firstReleasePercent = 0;
        emit Released(
            PoolName,
            "First Release",
            _toRelease,
            equity,
            getYear(current),
            getMonth(current),
            getDay(current),
            getHour(current),
            getMinute(current),
            getSecond(current)
        );
    }

    function secondRelease(address _toRelease) external onlyOwner {
        uint256 current = block.timestamp;
        require(isFounderPool == 0, "Founder Pool!");
        require(
            current >= secondReleaseTime && secondReleasePercent > 0,
            "Second release is not started yet"
        );
        uint256 equity = PoolSupply.mul(secondReleasePercent).div(100);
        BITFtoken.transfer(_toRelease, equity);
        secondReleasePercent = 0;
        emit Released(
            PoolName,
            "Second Release",
            _toRelease,
            equity,
            getYear(current),
            getMonth(current),
            getDay(current),
            getHour(current),
            getMinute(current),
            getSecond(current)
        );
    }

    function thirdRelease(address _toRelease) external onlyOwner {
        uint256 current = block.timestamp;
        require(isFounderPool == 0, "Founder Pool!");
        require(
            current >= secondReleaseTime && secondReleasePercent > 0,
            "Third release is not started yet"
        );
        uint256 equity = PoolSupply.mul(secondReleasePercent).div(100);
        BITFtoken.transfer(_toRelease, equity);
        secondReleasePercent = 0;
        emit Released(
            PoolName,
            "Third Release",
            _toRelease,
            equity,
            getYear(current),
            getMonth(current),
            getDay(current),
            getHour(current),
            getMinute(current),
            getSecond(current)
        );
    }

    /// @notice This function is used for only founders.
    function getFirstRelease() external {
        uint256 current = block.timestamp;
        require(
            current >= firstReleaseTime,
            "First release is not started yet"
        );
        require(
            founders[_msgSender()] > 0 && unlocked[_msgSender()][1] < 1,
            "Not have equity."
        );
        uint256 equity = PoolSupply
            .mul(founders[_msgSender()])
            .div(100)
            .mul(firstReleasePercent)
            .div(100);
        BITFtoken.transfer(_msgSender(), equity);
        unlocked[_msgSender()][1] += 1;
        emit Released(
            PoolName,
            "First Release",
            _msgSender(),
            equity,
            getYear(current),
            getMonth(current),
            getDay(current),
            getHour(current),
            getMinute(current),
            getSecond(current)
        );
    }

    /// @notice This function is used for only founders.
    function getSecondRelease() external {
        uint256 current = block.timestamp;
        require(
            current >= secondReleaseTime,
            "Second release is not started yet"
        );
        require(
            founders[_msgSender()] > 0 && unlocked[_msgSender()][2] < 1,
            "Not have equity."
        );
        uint256 equity = PoolSupply
            .mul(founders[_msgSender()])
            .div(100)
            .mul(secondReleasePercent)
            .div(100);
        BITFtoken.transfer(_msgSender(), equity);
        unlocked[_msgSender()][2] += 1;
        emit Released(
            PoolName,
            "Second Release",
            _msgSender(),
            equity,
            getYear(current),
            getMonth(current),
            getDay(current),
            getHour(current),
            getMinute(current),
            getSecond(current)
        );
    }

    /// @notice This function is used for only founders.
    function getThirdRelease() external {
        uint256 current = block.timestamp;
        require(
            current >= thirdReleaseTime,
            "Third release is not started yet"
        );
        require(
            founders[_msgSender()] > 0 && unlocked[_msgSender()][3] < 1,
            "Not have equity."
        );
        uint256 equity = PoolSupply
            .mul(founders[_msgSender()])
            .div(100)
            .mul(thirdReleasePercent)
            .div(100);
        BITFtoken.transfer(_msgSender(), equity);
        unlocked[_msgSender()][3] += 1;
        emit Released(
            PoolName,
            "Third Release",
            _msgSender(),
            equity,
            getYear(current),
            getMonth(current),
            getDay(current),
            getHour(current),
            getMinute(current),
            getSecond(current)
        );
    }

    function withdrawToken() external onlyOwner {
        uint256 balance = BITFtoken.balanceOf(address(this));
        require(balance > 0, "No USDT tokens to withdraw");
        BITFtoken.safeTransfer(owner(), balance);
    }
}
