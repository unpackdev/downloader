// SPDX-License-Identifier: GPL-2.0-or-later
// (C) Florence Finance, 2022 - https://florence.finance/
pragma solidity 0.8.9;

import "./IERC20.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./Math.sol";
import "./LendingPoolToken.sol";
import "./PeriodStaking.sol";
import "./LinearStaking.sol";
import "./Funding.sol";

/// @title LendingPool
/// @dev
contract LendingPool is Initializable, OwnableUpgradeable, PausableUpgradeable {
    event LendingPoolInitialized(address _address, string id, address lendingPoolToken);

    /// @dev unique identifier
    string public id;

    /// @dev LendingPoolToken of the pool
    LendingPoolToken public lendingPoolToken;

    /// @dev Storage for funding logic
    mapping(uint256 => Funding.FundingStorage) private fundingStorage;

    /// @dev Storage for linear staking logic
    mapping(uint256 => LinearStaking.LinearStakingStorage) private linearStakingStorage;

    /// @dev Storage for period staking logic
    mapping(uint256 => PeriodStaking.PeriodStakingStorage) private periodStakingStorage;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {} // solhint-disable-line

    /// @dev initialization of the lendingPool (required since upgradable contracts can not be initialized via constructor)
    /// @param _lendingPoolId unique identifier
    /// @param _lendingPoolTokenSymbol symbol of the LendingPoolToken
    function initialize(string memory _lendingPoolId, string memory _lendingPoolTokenSymbol) external initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();

        pause();

        id = _lendingPoolId;

        lendingPoolToken = new LendingPoolToken(_lendingPoolId, _lendingPoolTokenSymbol);

        emit LendingPoolInitialized(address(this), _lendingPoolId, address(lendingPoolToken));
    }

    /////////////////////////////////////////////////////////////////////////
    /////////////////////////////////GENERAL/////////////////////////////////
    /////////////////////////////////////////////////////////////////////////

    /// @dev pauses the lendingPool. Only affects function with pausable related modifiers
    function pause() public onlyOwner {
        super._pause();
    }

    /// @dev unpauses the lendingPool. In order to unpause the configuration must be consistent. Only affects function with pausable related modifiers
    function unpause() public onlyOwner {
        super._unpause();
    }

    /// @dev returns the current version of this smart contract
    /// @return the current version of this smart contract
    function getVersion() public pure virtual returns (string memory) {
        return "V1";
    }

    /////////////////////////////////////////////////////////////////////////
    /////////////////////////////////FUNDING/////////////////////////////////
    /////////////////////////////////////////////////////////////////////////

    /// @dev Set whether a token should be accepted for funding the pool
    /// @param fundingToken the funding token
    /// @param accepted whether it is accepted
    function setFundingToken(IERC20 fundingToken, bool accepted) public onlyOwner {
        Funding.setFundingToken(fundingStorage[0], fundingToken, accepted);
    }

    /// @dev returns the accepted funding tokens
    function getFundingTokens() external view returns (IERC20[] memory) {
        return fundingStorage[0]._fundingTokens;
    }

    /// @dev returns true if wallet is whitelisted (primary funder wallet)
    function isPrimaryFunder(address wallet) public view returns (bool) {
        return fundingStorage[0].primaryFunders[wallet] || fundingStorage[0].disablePrimaryFunderCheck;
    }

    /// @dev Change primaryFunder status of an address
    /// @param primaryFunder the address
    /// @param accepted whether its accepted as primaryFunder
    function setPrimaryFunder(address primaryFunder, bool accepted) public onlyOwner {
        Funding.setPrimaryFunder(fundingStorage[0], primaryFunder, accepted);
    }

    /// @dev returns true if wallet is borrower wallet
    function isBorrower(address wallet) external view returns (bool) {
        return fundingStorage[0].borrowers[wallet];
    }

    /// @dev Change borrower status of an address
    /// @param borrower the address
    /// @param accepted whether its accepted as primaryFunder
    function setBorrower(address borrower, bool accepted) public {
        require(_msgSender() == owner() || fundingStorage[0].borrowers[_msgSender()], "caller address is no borrower or owner");
        Funding.setBorrower(fundingStorage[0], borrower, accepted);
    }

    /// @dev returns current and last IDs of funding requests (linked list)
    function getFundingRequestIDs() external view returns (uint256, uint256) {
        return (fundingStorage[0].currentFundingRequestId, fundingStorage[0].lastFundingRequestId);
    }

    /// @dev Borrower adds funding request
    /// @param amount funding request amount
    /// @param durationDays days that funding request is open
    /// @param interestRate interest rate for funding request
    function addFundingRequest(
        uint256 amount,
        uint256 durationDays,
        uint256 interestRate
    ) public whenNotPaused {
        Funding.addFundingRequest(fundingStorage[0], amount, durationDays, interestRate);
    }

    /// @dev Borrower cancels funding request
    /// @param fundingRequestId funding request id to cancel
    function cancelFundingRequest(uint256 fundingRequestId) public whenNotPaused {
        Funding.FundingStorage storage _fundingStorage = fundingStorage[0];
        require(_msgSender() == owner() || fundingStorage[0].borrowers[_msgSender()], "caller address is no borrower");
        require(_msgSender() == owner() || _fundingStorage.fundingRequests[fundingRequestId].state == Funding.FundingRequestState.OPEN, "funding request already processing");
        Funding.cancelFundingRequest(_fundingStorage, fundingRequestId);
    }

    /// @dev Get information about the funding Request with the funding request ID
    /// @param fundingRequestId the funding request ID
    /// @return the FundingRequest structure selected with _fundingRequestID
    function getFundingRequest(uint256 fundingRequestId) public view whenNotPaused returns (Funding.FundingRequest memory) {
        return fundingStorage[0].fundingRequests[fundingRequestId];
    }

    /// @dev Allows primary funders to fund the pool
    /// @param fundingToken token used for the funding
    /// @param fundingTokenAmount funding amount (funding token decimals)
    function fund(IERC20 fundingToken, uint256 fundingTokenAmount) public whenNotPaused {
        Funding.fund(fundingStorage[0], fundingToken, fundingTokenAmount, lendingPoolToken);
    }

    /// @dev Get an exchange rate for an ERC20<>Currnecy conversion
    /// @param token the token
    /// @return the exchange rate and the decimals of the exchange rate
    function getExchangeRate(IERC20 token) public view returns (uint256, uint8) {
        return Funding.getExchangeRate(fundingStorage[0], token);
    }

    /// @dev Adds a mapping between a token, currency and ChainLink price feed
    /// @param token the token
    /// @param chainLinkFeed the ChainLink price feed
    /// @param invertChainLinkFeedAnswer whether the rate returned by the chainLinkFeed needs to be inverted to match the token-currency pair order
    function setFundingTokenChainLinkFeed(
        IERC20 token,
        AggregatorV3Interface chainLinkFeed,
        bool invertChainLinkFeedAnswer
    ) external onlyOwner {
        Funding.setFundingTokenChainLinkFeed(fundingStorage[0], token, chainLinkFeed, invertChainLinkFeedAnswer);
    }

    /// @dev Get a ChainLink price feed for a token-currency pair
    /// @param token the token
    /// @return the ChainLink price feed
    function getFundingTokenChainLinkFeeds(IERC20 token) public view returns (AggregatorV3Interface) {
        return fundingStorage[0].fundingTokenChainLinkFeeds[token];
    }

    function setDisablePrimaryFunderCheck(bool disable) public onlyOwner {
        fundingStorage[0].disablePrimaryFunderCheck = disable;
    }

    /////////////////////////////////////////////////////////////////////////
    /////////////////////////////LINEAR STAKING//////////////////////////////
    /////////////////////////////////////////////////////////////////////////

    /// @dev Sets the rewardTokensPerBlock for a stakedToken-rewardToken pair
    /// @param stakedToken the staked token
    /// @param rewardToken the reward token
    /// @param rewardTokensPerBlock rewardTokens per rewardToken per block (rewardToken decimals)
    function setRewardTokensPerBlockLinear(
        IERC20 stakedToken,
        IERC20 rewardToken,
        uint256 rewardTokensPerBlock
    ) public onlyOwner {
        LinearStaking.setRewardTokensPerBlockLinear(linearStakingStorage[0], stakedToken, rewardToken, rewardTokensPerBlock);
    }

    /// @dev Get tokens that can be staked in linear staking
    function getStakableTokens() external view returns (IERC20[] memory) {
        return linearStakingStorage[0].stakableTokens;
    }

    /// @dev Get available rewards for linear staking
    /// @param rewardToken the reward token
    function getAvailableLinearStakingRewards(IERC20 rewardToken) external view returns (uint256) {
        return linearStakingStorage[0].availableRewards[rewardToken];
    }

    /// @dev Lock or unlock the rewards for a staked token during linear staking
    /// @param stakedToken the staked token
    /// @param rewardToken the reward token
    /// @param rewardsLocked true = lock; false = unlock
    function setRewardsLockedLinear(
        IERC20 stakedToken,
        IERC20 rewardToken,
        bool rewardsLocked
    ) public onlyOwner {
        LinearStaking.setRewardsLockedLinear(linearStakingStorage[0], stakedToken, rewardToken, rewardsLocked);
    }

    /// @dev Staking of a stakable token
    /// @param stakableToken the stakeable token
    /// @param amount the amount to stake (stakableToken decimals)
    function stakeLinear(IERC20 stakableToken, uint256 amount) public whenNotPaused {
        LinearStaking.stakeLinear(linearStakingStorage[0], stakableToken, amount);
    }

    /// @dev Get the staked balance for a specific token and wallet
    /// @param wallet the wallet
    /// @param stakableToken the staked token
    /// @return the staked balance (stakableToken decimals)
    function getStakedBalanceLinear(address wallet, IERC20 stakableToken) public view returns (uint256) {
        return LinearStaking.getStakedBalanceLinear(linearStakingStorage[0], wallet, stakableToken);
    }

    /// @dev Unstaking of a staked token
    /// @param stakedToken the staked token
    /// @param amount the amount to unstake
    function unstakeLinear(IERC20 stakedToken, uint256 amount) public whenNotPaused {
        LinearStaking.unstakeLinear(linearStakingStorage[0], stakedToken, amount);
    }

    /// @dev Calculates the outstanding rewards for a wallet, staked token and reward token
    /// @param wallet the wallet
    /// @param stakedToken the staked token
    /// @param rewardToken the reward token
    /// @return the outstading rewards (rewardToken decimals)
    function calculateRewardsLinear(
        address wallet,
        IERC20 stakedToken,
        IERC20 rewardToken
    ) public view returns (uint256) {
        return LinearStaking.calculateRewardsLinear(linearStakingStorage[0], wallet, stakedToken, rewardToken);
    }

    /// @dev Claims all rewards for a staked tokens
    /// @param stakedToken the staked token
    function claimRewardsLinear(IERC20 stakedToken) public whenNotPaused {
        LinearStaking.claimRewardsLinear(linearStakingStorage[0], stakedToken);
    }

    /// @dev Check if rewards for a staked token are locked or not
    /// @param stakedToken the staked token
    /// @param rewardToken the reward token
    /// @return true = locked; false = unlocked
    function getRewardsLocked(IERC20 stakedToken, IERC20 rewardToken) public view returns (bool) {
        return linearStakingStorage[0].rewardConfigurations[stakedToken].rewardsLocked[rewardToken];
    }

    /// @dev Allows the deposit of reward funds. This is usually used by the borrower or treasury
    /// @param rewardToken the reward token
    /// @param amount the amount of tokens (rewardToken decimals)
    function depositRewardsLinear(IERC20 rewardToken, uint256 amount) public {
        LinearStaking.depositRewardsLinear(linearStakingStorage[0], rewardToken, amount);
    }

    function getRewardTokens(IERC20 stakedToken) public view returns (IERC20[] memory) {
        return linearStakingStorage[0].rewardConfigurations[stakedToken].rewardTokens;
        // return LinearStaking.getRewardTokens(linearStakingStorage[0], stakedToken);
    }

    /// @dev Allows owner to withdraw tokens for maintenance / recovery purposes
    /// @param token the token
    /// @param amount the amount to be withdrawn
    /// @param to the address to withdraw to
    function withdrawTokens(
        IERC20 token,
        uint256 amount,
        address to
    ) public onlyOwner {
        Util.checkedTransfer(token, to, amount);
    }

    /////////////////////////////////////////////////////////////////////////
    /////////////////////////////PERIOD STAKING//////////////////////////////
    /////////////////////////////////////////////////////////////////////////

    /// @dev Set the duration of the reward period
    /// @param duration duration in blocks of the reward period
    function setRewardPeriodDuration(uint256 duration) external onlyOwner {
        periodStakingStorage[0].duration = duration;
    }

    function setEndRewardPeriod(uint256 periodEnd) external onlyOwner {
        PeriodStaking.setEndRewardPeriod(periodStakingStorage[0], periodEnd);
    }

    /// @dev Get variables of the period staking
    /// @return returns the id, duration and the rward token of the current reward period
    function getPeriodStakingInfo()
        external
        view
        returns (
            uint256,
            uint256,
            IERC20
        )
    {
        return (periodStakingStorage[0].currentRewardPeriodId, periodStakingStorage[0].duration, periodStakingStorage[0].rewardToken);
    }

    /// @dev Set the reward token of the reward period
    /// @param rewardToken the rward token of the reward period
    function setRewardPeriodRewardToken(IERC20 rewardToken) external onlyOwner {
        periodStakingStorage[0].rewardToken = rewardToken;
    }

    /// @dev Get the reward period
    /// @return returns the struct of the reward period
    function getRewardPeriod(uint256 rewardPeriodId) external view returns (PeriodStaking.RewardPeriod memory) {
        return periodStakingStorage[0].rewardPeriods[rewardPeriodId];
    }

    /// @dev Get all reward periods
    /// @return returns an array including the structs of all reward periods
    function getRewardPeriods() external view returns (PeriodStaking.RewardPeriod[] memory) {
        return PeriodStaking.getRewardPeriods(periodStakingStorage[0]);
    }

    /// @dev Get all open FundingRequests
    /// @return all open FundingRequests
    function getOpenFundingRequests() external view returns (Funding.FundingRequest[] memory) {
        return Funding.getOpenFundingRequests(fundingStorage[0]);
    }

    /// @dev Start next reward period
    function startNextRewardPeriod() external {
        PeriodStaking.startNextRewardPeriod(periodStakingStorage[0], 0);
    }

    /// @dev Start the next reward period
    /// @param periodStart start block of the period, 0 == follow previous period, 1 == start at current block, >1 use passed value
    function startNextRewardPeriodCustom(uint256 periodStart) external onlyOwner {
        PeriodStaking.startNextRewardPeriod(periodStakingStorage[0], periodStart);
    }

    /// @dev deposit rewards for staking period
    /// @param rewardPeriodId staking period id
    /// @param totalRewards total rewards to be deposited
    function depositRewardPeriodRewards(uint256 rewardPeriodId, uint256 totalRewards) public onlyOwner {
        PeriodStaking.depositRewardPeriodRewards(periodStakingStorage[0], rewardPeriodId, totalRewards);
    }

    /// @dev Get staking score of a wallet for a certain staking period
    /// @param wallet wallet address
    /// @param period staking period id
    function getWalletRewardPeriodStakingScore(address wallet, uint256 period) public view returns (uint256) {
        return PeriodStaking.getWalletRewardPeriodStakingScore(periodStakingStorage[0], wallet, period);
    }

    /// @dev Get the amount of lendingPoolTokens staked with period staking for a wallet
    /// @param wallet wallet address
    function getWalletStakedAmountRewardPeriod(address wallet) public view returns (uint256) {
        return periodStakingStorage[0].walletStakedAmounts[wallet].stakedBalance;
    }

    /// @dev stake Lending Pool Token during reward period
    /// @param amount amount of Lending Pool Token to stake
    function stakeRewardPeriod(uint256 amount) external {
        PeriodStaking.stakeRewardPeriod(periodStakingStorage[0], amount, lendingPoolToken);
    }

    /// @dev unstake Lending Pool Token during reward period
    /// @param amount amount of Lending Pool Token to unstake
    function unstakeRewardPeriod(uint256 amount) external {
        PeriodStaking.unstakeRewardPeriod(periodStakingStorage[0], amount, lendingPoolToken);
    }

    /// @dev claim rewards of staking period
    /// @param rewardPeriodId staking period id
    function claimRewardPeriod(uint256 rewardPeriodId) external {
        PeriodStaking.claimRewardPeriod(periodStakingStorage[0], rewardPeriodId, lendingPoolToken);
    }

    /// @dev calculate rewards for a wallet of a certain staking period
    /// @param wallet wallet address
    /// @param rewardPeriodId staking period id
    /// @param projectedTotalRewards projected total rewards for staking period
    function calculateWalletRewardsPeriod(
        address wallet,
        uint256 rewardPeriodId,
        uint256 projectedTotalRewards
    ) public view returns (uint256) {
        return PeriodStaking.calculateWalletRewardsPeriod(periodStakingStorage[0], wallet, rewardPeriodId, projectedTotalRewards);
    }

    /// @dev calculate rewards for a wallet of a certain staking period providing a yield percentage
    /// @param wallet wallet address
    /// @param rewardPeriodId staking period id
    /// @param yieldPeriod Period based 4-digits precision percentage value e.g 5% p.a. => 50000 (1.25% per 3 months Period)
    function calculateWalletRewardsYieldPeriod(
        address wallet,
        uint256 rewardPeriodId,
        uint256 yieldPeriod
    ) public view returns (uint256) {
        return PeriodStaking.calculateWalletRewardsYieldPeriod(periodStakingStorage[0], wallet, rewardPeriodId, yieldPeriod, lendingPoolToken);
    }
}
