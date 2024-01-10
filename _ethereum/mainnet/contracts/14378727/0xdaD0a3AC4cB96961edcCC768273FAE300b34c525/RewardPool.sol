// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.4;

import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Initializable.sol";
import "./ICash.sol";
import "./IRewardPool.sol";
import "./IAgent.sol";
import "./TransferHelper.sol";

contract RewardPool is Initializable, IRewardPool, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    // reference to $CASH for burning on mint
    ICASH public cash;
    IAgent public agent;
    uint256 public constant ROUND_TIME = 1 weeks - 1 hours; // 1 hour for execution time
    uint256 public totalReward;
    mapping(address => uint256) public rewards;

    address public operatorAddress; // address of the operator
    mapping(address => uint256) public totalBurnMap;
    uint256 public lastExecuteTime;

    event NewOperatorAddress(address operator);
    event PayTax(address user, uint256 amount);
    event Claimed(address user, uint256 amount);

    modifier onlyOperator() {
        require(msg.sender == operatorAddress, "Not operator");
        _;
    }

    function initialize(address _cash) external initializer {
        OwnableUpgradeable.__Ownable_init();
        PausableUpgradeable.__Pausable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

        cash = ICASH(_cash);
        lastExecuteTime = block.timestamp; // solhint-disable-line not-rely-on-time
    }

    /**
     * @notice Set operator address
     * @dev Callable by admin
     */
    function setOperator(address _operatorAddress) external onlyOwner {
        require(_operatorAddress != address(0), "Cannot be zero address");
        operatorAddress = _operatorAddress;

        emit NewOperatorAddress(_operatorAddress);
    }

    function setContracts(address _agent) external onlyOwner {
        require(_agent != address(0), "Cannot be zero address");
        agent = IAgent(_agent);
    }

    // owner calls to update leaderboard
    function payTax(address account, uint256 burnAmount) external override {
        require(account == _msgSender() || _msgSender() == address(agent), "Invalid account");
        require(burnAmount > 0, "Invalid amount");
        if ( _msgSender() != address(agent)) {
            cash.burn(account, burnAmount);
        }
        uint256 totalBurn = totalBurnMap[account];
        totalBurn += burnAmount;
        totalBurnMap[account] = totalBurn;

        emit PayTax(account, burnAmount);
    }

    /**
     * @notice Start the next round 
     * @dev Callable by operator
     */
    function executeRound(address[] memory winners) external whenNotPaused onlyOperator {
        require(
            block.timestamp > lastExecuteTime + ROUND_TIME, // solhint-disable-line not-rely-on-time
            "Not already to executed"
        );
        require(winners.length <= 300, "Too many winners");
        lastExecuteTime = block.timestamp; // solhint-disable-line not-rely-on-time
        uint256 totalPrize = address(this).balance - totalReward;
        uint256 totalRewardThisRound = 0;
        
        // distribute prize
        // 1-10: 10%
        uint256 prize = ((totalPrize * 10) / 100) / 10;
        uint256 from = 0;
        uint256 to = 9;
        if (winners.length <= to) {
            to = winners.length - 1;
        }
        for (uint256 i = from; i <= to; i++) {
            address winner = winners[i];
            require(totalBurnMap[winner] > 0, "Invalid total burn");
            totalBurnMap[winner] = 0;
            rewards[winner] += prize;
            totalRewardThisRound += prize;
        }
        
        // 11-50: 20%
        prize = ((totalPrize * 20) / 100) / 40;
        from = 10;
        to = 49;
        if (winners.length <= to) {
            to = winners.length - 1;
        }
        for (uint256 i = from; i <= to; i++) {
            address winner = winners[i];
            require(totalBurnMap[winner] > 0, "Invalid total burn");
            totalBurnMap[winner] = 0;
            rewards[winner] += prize;
            totalRewardThisRound += prize;
        }

        // 51-150: 30%
        prize = (totalPrize * 30 / 100) / 100;
        from = 50;
        to = 149;
        if (winners.length <= to) {
            to = winners.length - 1;
        }
        for (uint256 i = from; i <= to; i++) {
            address winner = winners[i];
            require(totalBurnMap[winner] > 0, "Invalid total burn");
            totalBurnMap[winner] = 0;
            rewards[winner] += prize;
            totalRewardThisRound += prize;
        }

        // 151-300: 40%
        prize = (totalPrize * 40 / 100) / 150;
        from = 150;
        to = 299;
        if (winners.length <= to) {
            to = winners.length - 1;
        }
        for (uint256 i = from; i <= to; i++) {
            address winner = winners[i];
            require(totalBurnMap[winner] > 0, "Invalid total burn");
            totalBurnMap[winner] = 0;
            rewards[winner] += prize;
            totalRewardThisRound += prize;
        }

        totalReward += totalRewardThisRound; // for saving gas fee
    }

    function claim() external whenNotPaused nonReentrant {
        require(rewards[msg.sender] > 0, "No rewards to claim");

        TransferHelper.safeTransfer(msg.sender, rewards[msg.sender]);
        emit Claimed(msg.sender, rewards[msg.sender]);
        rewards[msg.sender] = 0;
    }

    /**
     * @notice called by the admin to pause, triggers stopped state
     * @dev Callable by admin or operator
     */
    function pause() external whenNotPaused onlyOwner {
        _pause();
    }

    /**
     * @notice called by the admin to unpause, returns to normal state
     * Reset genesis state. Once paused, the rounds would need to be kickstarted by genesis
     */
    function unpause() external whenPaused onlyOwner {
        _unpause();
    }

    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}
