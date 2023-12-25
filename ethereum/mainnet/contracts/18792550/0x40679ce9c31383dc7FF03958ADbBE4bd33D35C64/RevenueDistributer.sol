// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./Context.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./TransferHelper.sol";
import "./FullMath.sol";

contract RevenueDistributer is Context, ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    event WithdrawalCmbot(address indexed user, uint256 amount);
    event ClaimedTreasury(uint256 amount);
    event enteredRevenueSharing(address indexed user, uint256 amount);
    event UnstakeTokens(address indexed user, uint256 amount);

    address public cmbotCa;
    uint256 public minForRevenue = 10_000 * 1e8;
    uint256 public minForGodTier = 30_000 * 1e8;
    uint256 public minTimeRequired = 1 days;

    uint256 public overallStakedCmbot;
    uint256 public constant divisor = 10_000;
    uint256 public penalty = 1_000;

    address private _penaltyReceiver;

    bool public isStopped = false; //Emergency stop of staking

    struct ChadData {
        uint256 stakeEntryTimestamp;
        uint256 minReleaseTimestamp;
        uint256 lockedBalance;
        uint256 ethClaimed;
    }

    mapping(address => uint256) private _userEthPerTokenPaid;
    mapping(address => uint256) private _pendingRewards;
    mapping(address => ChadData) public chadData;

    uint256 private _totalEthPerToken;
    uint256 public totalDistributted;

    receive() external payable {
        if (overallStakedCmbot > 0) {
            uint256 precisionMultiplier = 1e18;
            _totalEthPerToken += (msg.value.mul(precisionMultiplier) /
                overallStakedCmbot);
        }
    }

    constructor(address cmbot, address penaltyReceiver_) {
        cmbotCa = cmbot;
        _penaltyReceiver = penaltyReceiver_;
    }

    function setMinForRevenue(uint256 _minForRevenue) public onlyOwner {
        minForRevenue = _minForRevenue;
    }

    function setMinForGodTier(uint256 _minForGodTier) public onlyOwner {
        minForGodTier = _minForGodTier;
    }

    function setMinTimeRequired(uint256 _minTimeRequired) public onlyOwner {
        minTimeRequired = _minTimeRequired; // In seconds
    }

    function changePenalty(uint256 newPenalty) public onlyOwner {
        require(newPenalty <= 9_000, "Penatly is too high");
        penalty = newPenalty;
    }

    //Used in emergencies only. Can be called only once
    function stopStaking() public onlyOwner {
        isStopped = true;
    }

    function isGodMode(address chad) public view returns (bool) {
        ChadData storage user = chadData[chad];
        uint256 balance = user.lockedBalance;

        return balance >= minForGodTier;
    }

    function enterToRevenueSharing(uint256 cmbotAmount) public nonReentrant {
        require(cmbotAmount >= minForRevenue, "Amount is below requirement");
        require(
            IERC20(cmbotCa).balanceOf(_msgSender()) >= cmbotAmount,
            "Insufficient token balance"
        );

        updateRewards(_msgSender());

        uint256 poolJoiningTs = chadData[_msgSender()].stakeEntryTimestamp != 0
            ? chadData[_msgSender()].stakeEntryTimestamp
            : block.timestamp;
        uint256 stakedBalance = chadData[_msgSender()].lockedBalance;
        uint256 ethChadClaimed = chadData[_msgSender()].ethClaimed;

        chadData[_msgSender()] = ChadData({
            stakeEntryTimestamp: poolJoiningTs,
            minReleaseTimestamp: poolJoiningTs + minTimeRequired,
            lockedBalance: stakedBalance += cmbotAmount,
            ethClaimed: ethChadClaimed
        });

        TransferHelper._safeTransferFromEnsureExactAmount(
            cmbotCa,
            _msgSender(),
            address(this),
            cmbotAmount
        );

        overallStakedCmbot += cmbotAmount;
        emit enteredRevenueSharing(_msgSender(), cmbotAmount);
    }

    function updateRewards(address chad) public {
        uint256 precisionMultiplier = 1e18;

        uint256 owedPerToken = _totalEthPerToken.sub(
            _userEthPerTokenPaid[chad]
        );
        uint256 owed = chadData[chad].lockedBalance.mul(owedPerToken).div(
            precisionMultiplier
        );

        _pendingRewards[chad] = _pendingRewards[chad].add(owed);
        _userEthPerTokenPaid[chad] = _totalEthPerToken;
    }

    function chadShare(address chad) public view returns (uint256) {
        uint256 chadBalance = chadData[chad].lockedBalance;

        return
            chadBalance > 0
                ? FullMath.mulDiv(chadBalance, divisor, overallStakedCmbot)
                : 0;
    }

    function claimRewards() public nonReentrant returns (bool success) {
        uint256 minReleaseTs = chadData[_msgSender()].minReleaseTimestamp;
        require(block.timestamp > minReleaseTs, "Tokens are not mature");

        updateRewards(_msgSender());

        uint256 reward = _pendingRewards[_msgSender()];
        require(reward > 0, "No rewards to claim");

        _pendingRewards[_msgSender()] = 0;

        (success, ) = address(_msgSender()).call{value: reward}("");
        require(success, "Transfer failed");

        _userEthPerTokenPaid[_msgSender()] = _totalEthPerToken;
        chadData[_msgSender()].ethClaimed += reward;
        totalDistributted += reward;

        emit WithdrawalCmbot(_msgSender(), reward);
    }

    function pendingRewards(address user) public view returns (uint256) {
        uint256 userStaked = chadData[user].lockedBalance;
        uint256 accruedRewardPerToken = _totalEthPerToken -
            _userEthPerTokenPaid[user];
        uint256 pendingReward = (userStaked.mul(accruedRewardPerToken) / 1e18);
        return pendingReward;
    }

    function unstakeTokens() public nonReentrant {
        ChadData storage user = chadData[_msgSender()];
        uint256 balance = user.lockedBalance;
        require(balance >= 0, "Insufficient staked balance");

        updateRewards(_msgSender());

        uint256 penaltyAmount = 0;
        if (block.timestamp < user.minReleaseTimestamp) {
            penaltyAmount = balance.mul(penalty).div(divisor);
        }

        uint256 returnAmount = balance.sub(penaltyAmount);
        IERC20(cmbotCa).transfer(_msgSender(), returnAmount);

        if (penaltyAmount > 0) {
            IERC20(cmbotCa).transfer(_penaltyReceiver, penaltyAmount);
        }

        user.lockedBalance = 0;
        user.stakeEntryTimestamp = 0;
        user.minReleaseTimestamp = 0;
        overallStakedCmbot -= balance;

        emit UnstakeTokens(_msgSender(), balance);
    }

    /**
     * @dev Emergency function that allows to withdraw tokens and ETH without any penalties.
     * Can only be called when staking is stopped (isStopped = true).
     */

    function emergencyWithdraw() public nonReentrant {
        require(isStopped, "Staking is active");

        ChadData storage user = chadData[_msgSender()];
        uint256 balance = user.lockedBalance;
        require(balance > 0, "Insufficient staked balance");

        user.lockedBalance = 0;

        overallStakedCmbot -= balance;

        IERC20(cmbotCa).transfer(_msgSender(), balance);

        emit UnstakeTokens(_msgSender(), balance);
    }

    function emergencyWithdrawEth() public nonReentrant onlyOwner {
        require(isStopped, "Staking is active");

        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No ETH to withdraw");

        (bool success, ) = owner().call{value: contractBalance}("");
        require(success, "Transfer failed");
    }
}
