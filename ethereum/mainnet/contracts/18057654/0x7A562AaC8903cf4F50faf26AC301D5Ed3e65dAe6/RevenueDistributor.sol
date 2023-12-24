// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

contract RevenueDistributor is Ownable, ReentrancyGuard {
    IERC20 public token;
    uint256 public revenuePeriod;
    uint256 public totalRewardDistributed;
    uint256 public lastDistributionTimestamp;
    uint256 private distributedAmount;


    struct UserDetails {
        address  user;
        uint256[]  timestamp;
        uint256[]  amount;
        uint256  last24HourBalance;
    }

    mapping(address => uint256) public rewardClaimable;

    constructor(address _tokenAddress) {
        require(_tokenAddress != address(0), "Invalid tokenAddress");
        token = IERC20(_tokenAddress);
        revenuePeriod = 1 days;
    }

    receive() external payable {}


    function setTokenAddress(address _tokenAddress) external onlyOwner {
        require(_tokenAddress != address(0), "Invalid tokenAddress");
        token = IERC20(_tokenAddress);
    }

    function getLastDistributionTime() view  external returns(uint256){
        return lastDistributionTimestamp;
    }

    function distribute(UserDetails[] calldata  _userDetails) external payable onlyOwner{
        distributedAmount = msg.value;
        for (uint256 i = 0; i < _userDetails.length; i++) {
            uint256 userClaimAmount = calculateShare(
                _userDetails[i].user, 
                _userDetails[i].amount, 
                _userDetails[i].timestamp, 
                _userDetails[i].last24HourBalance
            );

            if (userClaimAmount > 0) {
                rewardClaimable[_userDetails[i].user] += userClaimAmount;
                totalRewardDistributed += userClaimAmount;
            }
        }
        lastDistributionTimestamp = block.timestamp;
    }

    function claim() external nonReentrant {
        uint256 userClaimAmount = rewardClaimable[msg.sender];
        require(userClaimAmount > 0);
        require(address(this).balance >= userClaimAmount);

        rewardClaimable[msg.sender] = 0;
        (bool sent, ) = payable(msg.sender).call{value: userClaimAmount}("");
        require(sent, "Failed to send Ether");
    }

 
    function pendingRewards(address account) external view returns (uint256) {
        return rewardClaimable[account];
    }



    /*
    Gets distributed to all holders of fbt tokens depending on how much fbt tokens they hold

    The more they hold the more rewards they get
     * @dev Calculate pending rewards
     * @param account user address
     * @param amounts array of user additional amounts in last 24hr
     * @param timestamps array of timestamps in last 24hr transactions
     * @param initialBalance user balance in last 24hr
     * @return Peding rewards
     */
    function calculateShare(
        address account,
        uint256[] memory amounts,
        uint256[] memory timestamps,
        uint256 initialBalance
    ) public view returns (uint256) {
        require(amounts.length == timestamps.length);

        uint256 timeSinceLastDistribute = block.timestamp - lastDistributionTimestamp;
        uint256 additionalTokens;
        uint256 firstTxnTimestamp = 0;
        uint256 lastTxnTimestamp = 0;

        for (uint256 i = 0; i < amounts.length; i++) {
            additionalTokens += amounts[i];
            if (timestamps[i] < firstTxnTimestamp) {
                firstTxnTimestamp = timestamps[i];
            }
            if (timestamps[i] > lastTxnTimestamp) {
                lastTxnTimestamp = timestamps[i];
            }
        }

        uint256 elapsedTimeTxn = lastTxnTimestamp - firstTxnTimestamp;
        uint256 elapsedTimeInitial = firstTxnTimestamp == 0 ? revenuePeriod : firstTxnTimestamp - timeSinceLastDistribute;

        uint256 elapsedTimeCurrent = lastTxnTimestamp == 0 ? 0 :  block.timestamp - lastTxnTimestamp;

        uint256 reward = _calculateShare(
            account,
            elapsedTimeInitial,
            elapsedTimeTxn,
            elapsedTimeCurrent,
            initialBalance,
            additionalTokens
        );

        return reward;
    }



    /* function to calculate the share of the caller address, summation of percentage of the last 24hrs balance, 
    addtional amounts gotten from transactions within 24hrs and the user current balance multiple by their respective elapsed timestamps
    */
    function _calculateShare(
        address _account,
        uint256 elapsedTimeInitial,
        uint256 elapsedTimeTxn,
        uint256 elapsedTimeCurrent,
        uint256 initialBalance,
        uint256 additionalTokens
    ) internal view returns (uint256) {
        uint256 hoursToSeconds = 3600;
        uint256 accountBalance = token.balanceOf(_account);
        uint256 totalSupply = token.totalSupply();

        uint256 userHoldPercent = (accountBalance * 10000) / totalSupply;
        uint256 userAdditionalPercent = (additionalTokens * 10000) / totalSupply;
        uint256 userInitialPercent = (initialBalance * 10000) / totalSupply;

        uint256 initialBalanceShare = (userInitialPercent * elapsedTimeInitial) / (hoursToSeconds * 24);
        uint256 additionalTokenShare = (userAdditionalPercent * elapsedTimeTxn) / (hoursToSeconds * 24);
        uint256 currentBalanceShare = (userHoldPercent * elapsedTimeCurrent) / (hoursToSeconds * 24);

        uint256 calculatedRewardPercent = initialBalanceShare + additionalTokenShare + currentBalanceShare;

        return calculatedRewardPercent * distributedAmount / 10000;
    }

    
}
