//SPDX-License-Identifier: MIT
/*
This Contract is coded and developed by Vihali Technology MTV Company Limited and is entirely transferred to Dopa JSC Limited under the Contract for Software Development Services. Accordingly, the ownership and all intellectual property rights including but not limited to rights which arise in the course of or in connection with the Contract shall belong to and are the sole property of Dopa JSC Limited
*/
pragma solidity ^0.8.7;

import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Math.sol";
import "./ITimeLockPool.sol";

/**
 * @dev Implement Initial Bonding Curve Offering for Sipher Token.
 */
contract SipherIBCO is Ownable {
    using SafeERC20 for IERC20;

    event Claim(address indexed account, uint256 userShare, uint256 sipherAmount);
    event Deposit(address indexed account, uint256 amount);
    event Withdraw(address indexed account, uint256 amount);
    event ClaimAndDepositToStake(address indexed account, uint256 amount, uint256 duration);

    
    uint256 public constant DECIMALS = 10 ** 18; // Sipher Token has the same decimals as Ether (18)
    uint256 public constant START = 1638752400; // Monday, December 6, 2021 1:00 AM UTC
    uint256 public constant END = START + 3 days; // Thursday, December 9, 2021 1:00 AM UTC
    uint256 public constant TOTAL_DISTRIBUTE_AMOUNT = 40000000 * DECIMALS;
    uint256 public constant MINIMAL_PROVIDE_AMOUNT = 3200 ether;
    uint256 public totalProvided = 0;
    ITimeLockPool public SipherStakingPool;

    mapping(address => uint256) public provided;
    mapping(address => uint256) private accumulated;

    IERC20 public immutable SIPHER;

    constructor(IERC20 sipher) {
        SIPHER = sipher;
    }

    /**
     * @dev Deposits ETH into contract.
     *
     * Requirements:
     * - The offering must be ongoing.
     */
    function deposit() external payable {
        require(START <= block.timestamp, "The offering has not started yet");
        require(block.timestamp <= END, "The offering has already ended");
        require(SIPHER.balanceOf(address(this)) == TOTAL_DISTRIBUTE_AMOUNT, "Insufficient SIPHER token in contract");

        totalProvided += msg.value;
        provided[msg.sender] += msg.value;

        accumulated[msg.sender] = Math.max(accumulated[msg.sender], provided[msg.sender]);

        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev Returns total ETH deposited in the contract of an address.
     */
    function getUserDeposited(address _user) external view returns (uint256) {
        return provided[_user];
    }

    /**
     * @dev Claims SIPHER token from contract by amount calculated on deposited ETH.
     *
     * Requirement:
     * - The offering must have been already ended.
     * - Address has ether deposited in the contract.
     */
    function claim() external {
        require(block.timestamp > END, "The offering has not ended");
        require(provided[msg.sender] > 0, "Empty balance");

        uint256 userShare = provided[msg.sender];
        uint256 sipherAmount = _getEstReceivedToken(msg.sender);
        provided[msg.sender] = 0;

        SIPHER.safeTransfer(msg.sender, sipherAmount);

        emit Claim(msg.sender, userShare, sipherAmount);
    }

    /**
     * @dev Calculate withdrawCap based on accumulated ether
     */
    function _withdrawCap(uint256 userAccumulated) internal pure returns (uint256 withdrawableAmount) {
        if (userAccumulated <= 1 ether) {
            return userAccumulated;
        }

        if (userAccumulated <= 150 ether) {
            uint256 accumulatedTotalInETH = userAccumulated / DECIMALS;
            uint256 takeBackPercentage = (3 * accumulatedTotalInETH**2 + 70897 - 903 * accumulatedTotalInETH) / 1000;
            return (userAccumulated * takeBackPercentage) / 100;
        }

        return (userAccumulated * 3) / 100;
    }

    /**
     * @dev Calculate the amount of Ether that can be withdrawn by user
     */
    function _getWithdrawableAmount(address _user) internal view returns (uint256) {
        uint256 userAccumulated = accumulated[_user];
        return Math.min(_withdrawCap(userAccumulated), provided[_user] - _getLockedAmount(_user));
    }

    function getWithdrawableAmount(address _user) external view returns (uint256) {
        return _getWithdrawableAmount(_user);
    }

    /**
     * @dev Estimate the amount of $Sipher that can be claim by user
     */
    function _getEstReceivedToken(address _user) internal view returns (uint256) {
        uint256 userShare = provided[_user];
        return (TOTAL_DISTRIBUTE_AMOUNT * userShare) / Math.max(totalProvided, MINIMAL_PROVIDE_AMOUNT);
    }

    /**
     * @dev Calculate locked amount after deposit
     */
    function getLockAmountAfterDeposit(address _user, uint256 amount) external view returns (uint256) {
        uint256 userAccumulated = Math.max(provided[_user] + amount, accumulated[_user]);
        return userAccumulated - _withdrawCap(userAccumulated);
    }

    /**
     * @dev Get user's accumulated amount after deposit
     */
    function getAccumulatedAfterDeposit(address _user, uint256 amount) external view returns (uint256) {
        return Math.max(provided[_user] + amount, accumulated[_user]);
    }

    /**
     * @dev Withdraws ether early
     *
     * Requirements:
     * - The offering must be ongoing.
     * - Amount to withdraw must be less than withdrawable amount
     */
    function withdraw(uint256 amount) external {
        require(block.timestamp > START && block.timestamp < END, "Only withdrawable during the Offering duration");

        require(amount <= provided[msg.sender], "Insufficient balance");

        require(amount <= _getWithdrawableAmount(msg.sender), "Invalid amount");

        provided[msg.sender] -= amount;

        totalProvided -= amount;

        payable(msg.sender).transfer(amount);

        emit Withdraw(msg.sender, amount);
    }

    /**
     * @dev Get estimated SIPHER token price
     */
    function getEstTokenPrice() public view returns (uint256) {
        return (Math.max(totalProvided, MINIMAL_PROVIDE_AMOUNT) * DECIMALS) / TOTAL_DISTRIBUTE_AMOUNT;
    }

    /**
     * @dev Get estimated amount of SIPHER token an address will receive
     */
    function getEstReceivedToken(address _user) external view returns (uint256) {
        return _getEstReceivedToken(_user);
    }

    /**
     * @dev Get total locked ether of a user
     */
    function getLockedAmount(address _user) external view returns (uint256) {
        return _getLockedAmount(_user);
    }

    function _getLockedAmount(address _user) internal view returns (uint256) {
        uint256 userAccumulated = accumulated[_user];
        return userAccumulated - _withdrawCap(userAccumulated);
    }

    /**
     * @dev Withdraw total ether to owner's wallet
     *
     * Requirements:
     * - Only the owner can withdraw
     * - The offering must have been already ended.
     * - The contract must have ether left.
     */
    function withdrawSaleFunds() external onlyOwner {
        require(END < block.timestamp, "The offering has not ended");
        require(address(this).balance > 0, "Contract's balance is empty");

        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @dev Withdraw the remaining SIPHER tokens to owner's wallet
     *
     * Requirements:
     * - Only the owner can withdraw.
     * - The offering must have been already ended.
     * - Total SIPHER provided is smaller than MINIMAL_PROVIDE_AMOUNT
     */
    function withdrawRemainedSIPHER() external onlyOwner {
        require(END < block.timestamp, "The offering has not ended");
        require(totalProvided < MINIMAL_PROVIDE_AMOUNT, "Total provided must be less than minimal provided");

        uint256 remainedSipher = TOTAL_DISTRIBUTE_AMOUNT -
            ((TOTAL_DISTRIBUTE_AMOUNT * totalProvided) / MINIMAL_PROVIDE_AMOUNT);
        SIPHER.safeTransfer(owner(), remainedSipher);
    }

    /**
     * @dev Withdraw the SIPHER tokens that are unclaimed (YES! They are abandoned!)
     *
     * Requirements:
     * - Only the owner can withdraw.
     * - Withdraw date must be more than 30 days after the offering ended.
     */
    function withdrawUnclaimedSIPHER() external onlyOwner {
        require(END + 30 days < block.timestamp, "Withdrawal is unavailable");
        require(SIPHER.balanceOf(address(this)) != 0, "No token to withdraw");

        SIPHER.safeTransfer(owner(), SIPHER.balanceOf(address(this)));
    }

    /**
     * @dev Set approval for Sipher Staking Pool
     */
    function setApproveForStaking(address _sipherStakingPool) external onlyOwner {
        require(block.timestamp < END, "Only allow edit before the Offer ends");
        require(_sipherStakingPool != address(0), "Invalid address");

        SipherStakingPool = ITimeLockPool(_sipherStakingPool);
        SIPHER.safeApprove(_sipherStakingPool, type(uint256).max);
    }

    /**
     * @dev Customer claim their $SIPHER and deposit to Sipher Staking Contract
     */
    function claimAndDepositForStaking(uint256 amount, uint256 duration) external {
        require(block.timestamp > END, "The offering has not ended");
        require(duration >= 600, "Minimum duration is 10 minutes");
        require(amount <= _getEstReceivedToken(msg.sender) && amount > 0, "Invalid amount");

        provided[msg.sender] -= (amount * getEstTokenPrice()) / DECIMALS;

        SipherStakingPool.deposit(amount, duration, msg.sender);

        emit ClaimAndDepositToStake(msg.sender, amount, duration);
    }
}
