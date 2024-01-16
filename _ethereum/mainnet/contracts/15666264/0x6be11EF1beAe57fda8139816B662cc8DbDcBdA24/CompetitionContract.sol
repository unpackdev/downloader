// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./SafeERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ICompetitionContract.sol";
import "./ISportManager.sol";

/*
CC01: No betable
CC02: Only owner
CC03: Only creator
CC04: Only Configurator
CC05: Required NOT start
CC06: Required Open
*/
abstract contract CompetitionContract is ICompetitionContract, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address private configurator;
    address public owner;
    address public creator;
    ISportManager public sportManager;
    address public tokenAddress;

    uint256 public totalFee;
    uint256 public minEntrant;
    uint256 internal entryFee;
    uint256 internal fee;

    uint256 public startBetTime;
    uint256 public endBetTime;

    bool public stopBet;
    Status public status = Status.Lock;

    mapping(address => bool) public betOrNotYet;
    address[] public listBuyer;

    function initialize(
        address _owner,
        address _creator,
        address _tokenAddress,
        address _configurator,
        uint256 _fee
    ) public initializer {
        owner = _owner;
        creator = _creator;
        tokenAddress = _tokenAddress;
        fee = _fee;
        configurator = _configurator;
        __ReentrancyGuard_init();
    }

    modifier betable(address user) {
        require(!betOrNotYet[user], "CC01");
        require(!stopBet, "CC01");
        require(
            block.timestamp >= startBetTime && block.timestamp <= endBetTime,
            "CC01"
        );
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "CC02");
        _;
    }

    modifier onlyCreator() {
        require(creator == msg.sender, "CC03");
        _;
    }

    modifier onlyConfigurator() {
        require(configurator == msg.sender, "CC04");
        _;
    }

    modifier onlyLock() {
        require(status == Status.Lock, "CC05");
        _;
    }

    modifier onlyOpen() {
        require(status == Status.Open, "CC06");
        _;
    }

    function getEntryFee() external view override returns (uint256) {
        return entryFee;
    }

    function getFee() external view override returns (uint256) {
        return fee;
    }

    function toggleStopBet() external onlyCreator {
        stopBet = !stopBet;
    }

    function getTotalToken(address _token) public view returns (uint256) {
        return IERC20Upgradeable(_token).balanceOf(address(this));
    }

    function _checkEntrantCodition() internal view returns (bool) {
        if (listBuyer.length >= minEntrant) {
            return true;
        } else {
            return false;
        }
    }

    function _sendRewardToWinner(address[] memory winners, uint256 winnerReward)
        internal
    {
        if (winners.length == 0 || winnerReward == 0) return;

        uint256 reward = winnerReward / winners.length;
        for (uint256 i = 0; i < winners.length - 1; i++) {
            IERC20Upgradeable(tokenAddress).safeTransfer(winners[i], reward);
        }

        uint256 remaining = winnerReward - (winners.length - 1) * reward;
        IERC20Upgradeable(tokenAddress).safeTransfer(
            winners[winners.length - 1],
            remaining
        );
    }
}
