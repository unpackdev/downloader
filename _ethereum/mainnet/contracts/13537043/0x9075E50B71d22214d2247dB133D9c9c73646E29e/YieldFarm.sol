// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.4;

import "./IERC20.sol";
import "./IERC721.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./IYieldFarm.sol";
import "./IEqzYieldNft.sol";
import "./EqzYieldNft.sol";

contract YieldFarm is ReentrancyGuard, Ownable, IYieldFarm {
    IERC20 public immutable poolToken;
    IERC20 public immutable rewardToken;
    IEqzYieldNft public eqzYieldNft;

    uint256 public multiplier;
    uint128 constant multiplierDecimals = 10**5;

    uint128 public maxLockTime = 365 days;
    uint128 public minLockTime = 1 days;

    // pool
    uint256 public rewardPool;
    uint256 public reservedPool;

    // nft
    uint256 public tokenId;
    mapping(uint256 => NFTMetadata) nftMetadata;

    bool private setupCalled;

    modifier onlyOnce {
        require(setupCalled == false, 'ONLY_ONCE');
        _;
        setupCalled = true;
    }

    constructor(
        address _owner,
        address _poolToken,
        address _rewardToken,
        uint256 _multiplier
    ) {
        require(_poolToken != address(0), 'INVALID_POOL_TOKEN');
        require(_rewardToken != address(0), 'INVALID_REWARD_TOKEN');
        require(_rewardToken != _poolToken, 'REWARD_TOKEN_EQUAL_POOL_TOKEN');
        require(_multiplier > 0, 'INVALID_MULTIPLIER');

        transferOwnership(_owner);

        poolToken = IERC20(_poolToken);
        rewardToken = IERC20(_rewardToken);
        multiplier = _multiplier;
    }

    /*
     * @dev Sets eqzYieldNft from deployed contract address
     * @param eqzYieldNftToken address of deployed EqzYieldNft contract
     */
    function setup(address eqzYieldNftToken) external override onlyOnce {
        require(eqzYieldNftToken != address(0), 'INVALID_ADDRESS');
        eqzYieldNft = IEqzYieldNft(eqzYieldNftToken);
    }

    /*
     * @dev Deposits desiredAmount into YF contract and creates NFTs for principal and reward
     * @param desiredAmount Desired stake amount
     * @param interval Lock time interval (in seconds)
     */
    function stake(uint256 desiredAmount, uint256 interval) external override nonReentrant {
        require(desiredAmount > 0, 'INVALID_DESIRED_AMOUNT');
        require(interval >= minLockTime, 'INVALID_MIN_INTERVAL');
        require(interval <= maxLockTime, 'INVALID_MAX_INTERVAL');

        // compute reward
        (uint256 stakedAmount, uint256 reward) = _computeReward(desiredAmount, interval);
        require(stakedAmount > 0, 'INVALID_STAKE_AMOUNT');
        require(poolToken.transferFrom(msg.sender, address(this), stakedAmount), 'TRANSFER_FAIL');

        rewardPool = rewardPool - reward;
        reservedPool = reservedPool + reward;

        // mint NFT for staked amount
        uint256 stakedAmountTokenId = _mintNft(
            address(poolToken),
            stakedAmount,
            interval,
            NftTypes.principal
        );

        // mint NFT for reword
        uint256 rewardTokenId = _mintNft(address(rewardToken), reward, interval, NftTypes.bonus);

        emit StakeEvent(
            msg.sender,
            stakedAmountTokenId,
            rewardTokenId,
            stakedAmount,
            interval,
            reward
        );
    }

    /*
     * @dev Adds tokens to the rewardPool
     * @param amount added
     */
    function addReward(uint256 amount) external override {
        require(amount > 0, 'INVALID_AMOUNT');

        rewardPool = rewardPool + amount;
        require(rewardToken.transferFrom(msg.sender, address(this), amount), 'TRANSFER_FAIL');

        emit AddRewardEvent(msg.sender, amount);
    }

    /*
     * @dev Removes tokens to the rewardPool, callable by owner
     * @param amount removed
     */
    function removeReward(uint256 amount) external override onlyOwner {
        require(amount > 0, 'INVALID_AMOUNT');
        require(amount <= rewardPool, 'AMOUNT_EXCEEDS_POOL');

        rewardPool = rewardPool - amount;
        require(rewardToken.transfer(msg.sender, amount), 'TRANSFER_FAIL');

        emit RemoveRewardEvent(amount);
    }

    /*
     * @dev Burns the nft with the given _tokenId and sets `claimed` true
     */
    function claim(uint256 _tokenId) external override nonReentrant {
        require(nftMetadata[_tokenId].token != address(0), 'INVALID_TOKEN_ID');
        require(nftMetadata[_tokenId].claimed == false, 'ALREADY_CLAIMED');
        require(block.timestamp >= nftMetadata[_tokenId].endTime, 'NFT_LOCKED');

        address owner = eqzYieldNft.ownerOf(_tokenId);

        nftMetadata[_tokenId].claimed = true;
        if (nftMetadata[_tokenId].nftType == NftTypes.bonus) {
            reservedPool = reservedPool - nftMetadata[_tokenId].amount;
        }

        eqzYieldNft.burn(_tokenId);
        require(
            IERC20(nftMetadata[_tokenId].token).transfer(owner, nftMetadata[_tokenId].amount),
            'TRANSFER_FAIL'
        );

        emit ClaimEvent(owner, _tokenId, nftMetadata[_tokenId].amount);
    }

    /*
     * @dev Returns stakedAmount and reward
     * maxStaked = rewardPool / [multiplier * (interval / maxLockTime)^2]
     * reward = multiplier * stakeAmount * (interval / maxLockInterval)^2
     */
    function _computeReward(uint256 desiredAmount, uint256 interval)
        internal
        view
        returns (uint256 stakeAmount, uint256 rewardAmount)
    {
        uint256 maxStaked = _getMaxStake(interval);
        stakeAmount = desiredAmount;
        if (stakeAmount > maxStaked) {
            stakeAmount = maxStaked;
        }
        rewardAmount = _getRewardAmount(stakeAmount, interval);
    }

    function _getMaxStake(uint256 interval) internal view returns (uint256) {
        return (rewardPool * maxLockTime**2 * multiplierDecimals) / (multiplier * interval**2);
    }

    function getMaxStake(uint256 interval) external view returns (uint256) {
        return _getMaxStake(interval);
    }

    function _getRewardAmount(uint256 stakeAmount, uint256 interval)
        internal
        view
        returns (uint256)
    {
        return (multiplier * stakeAmount * interval**2) / (multiplierDecimals * maxLockTime**2);
    }

    /*
     * @dev Returns stakedAmount and reward
     * @param desiredAmount Amount staked by user, it can be limited to a max value
     * @param interval Lock period for the staked amount
     * @return stakeAmount The actual amount that was deposited
     * @return rewardAmount Reward computed for the `interval` and `stakeAmount`
     */
    function computeReward(uint256 desiredAmount, uint256 interval)
        external
        view
        override
        returns (uint256 stakeAmount, uint256 rewardAmount)
    {
        (stakeAmount, rewardAmount) = _computeReward(desiredAmount, interval);
    }

    /*
     * @dev Mint eqzYieldNft to sender, creates and adds nft metadata
     */
    function _mintNft(
        address tokenAddress,
        uint256 amount,
        uint256 interval,
        NftTypes nftType
    ) internal returns (uint256) {
        tokenId++;
        uint256 currentTokenId = tokenId;
        eqzYieldNft.mint(msg.sender, currentTokenId);
        nftMetadata[currentTokenId] = NFTMetadata(
            tokenAddress,
            amount,
            block.timestamp,
            block.timestamp + interval,
            false,
            nftType
        );
        return currentTokenId;
    }

    /*
     * @dev getNftMetadata Returns nftMetadata for _tokenId, callable by the contract owner
     */
    function getNftMetadata(uint256 _tokenId) external view returns (NFTMetadata memory) {
        return nftMetadata[_tokenId];
    }

    /*
     * @dev setMinLockTime Setter for minLockTime
     */
    function setMinLockTime(uint128 _minLockTime) external onlyOwner {
        minLockTime = _minLockTime;
        emit MinLockTimeChangedEvent(_minLockTime);
    }

    /*
     * @dev setMaxLockTime Setter for maxLockTime
     */
    function setMaxLockTime(uint128 _maxLockTime) external onlyOwner {
        maxLockTime = _maxLockTime;
        emit MaxLockTimeChangedEvent(_maxLockTime);
    }

    /*
    * @dev setMultiplier Setter for multiplier
    */
    function setMultiplier(uint256 _multiplier) external onlyOwner {
        multiplier = _multiplier;
        emit MultiplierChangedEvent(_multiplier);
    }
}
