// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Ownable.sol";
import "./Counters.sol";
import "./Recoverable.sol";
import "./ITokenStake.sol";

/**
 * @title MetaPopitStaking
 * @notice MetaPopit Staking contract
 * https://www.metapopit.com
 */
contract MetaPopitStaking is Ownable, Recoverable {
    using Counters for Counters.Counter;

    struct TokenInfo {
        uint256 level;
        uint256 pool;
        bool redeemed;
    }
    struct OwnerInfo {
        uint256 hints;
        uint256 staked;
        uint256 startHintTime;
        bool redeemed;
    }
    struct PoolInfo {
        uint256 depositTime;
        uint256 levelSpeed;
        uint256[] tokens;
        address owner;
    }

    uint256 public constant SPEED_RESOLUTION = 1000;

    bool public isStakingClosed;
    uint256 public stakedTokenCount;
    uint256 public maxLevelTeamSize;
    uint256 public maxHintTeamSize;
    address public immutable collection;

    Counters.Counter private _poolCounter;

    // speeds per number of NFT
    mapping(uint256 => uint256) private _levelSpeed;
    mapping(uint256 => uint256) private _hintSpeed;

    // mapping poolId => PoolInfo
    mapping(uint256 => PoolInfo) private _poolInfos;
    // mapping tokenId => TokenInfo
    mapping(uint256 => TokenInfo) private _tokenInfos;
    // mapping owner => OwnerInfo
    mapping(address => OwnerInfo) private _ownerInfos;

    event Stake(address indexed account, uint256 poolIndex, uint256[] tokenIds);
    event UnStake(address indexed account, uint256 poolIndex, uint256[] tokenIds);
    event RedeemToken(uint256 tokenId, uint256 level);
    event RedeemAccount(address indexed account, uint256 hints);
    event StakingClosed();

    modifier whenTokensNotStaked(uint256[] memory tokenIds) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(!ITokenStake(collection).isTokenStaked(tokenIds[i]), "MetaPopitStaking: Token already staked");
        }
        _;
    }

    modifier whenStakingOpened() {
        require(!isStakingClosed, "MetaPopitStaking: staking closed");
        _;
    }

    constructor(address _collection) {
        collection = _collection;
    }

    function _getNextPoolId() internal returns (uint256) {
        _poolCounter.increment();
        return _poolCounter.current();
    }

    /**
     * @dev returns the current pending reward based on current value and speed
     */
    function _getPendingRewards(
        uint256 currentValue,
        uint256 depositTime,
        uint256 speed
    ) internal view returns (uint256 pendingReward, uint256 nextRewardDate) {
        pendingReward = currentValue;
        nextRewardDate = 0;

        if (speed > 0) {
            uint256 currentDate = depositTime * SPEED_RESOLUTION;
            uint256 maxDate = block.timestamp * SPEED_RESOLUTION;
            uint256 increment = speed;

            pendingReward = 0;
            while (currentDate <= maxDate) {
                pendingReward += 1;

                if (pendingReward > currentValue) {
                    currentDate += increment;
                }

                increment *= 2;
            }

            nextRewardDate = currentDate / SPEED_RESOLUTION;
        }
    }

    /**
     * @dev Apply completed pending level rewards for a token
     */
    function _applyPendingLevel(
        uint256 tokenId,
        uint256 depositTime,
        uint256 levelSpeed
    ) internal {
        if (depositTime > 0 && levelSpeed > 0) {
            (uint256 pendingLevel, ) = _getPendingRewards(_tokenInfos[tokenId].level, depositTime, levelSpeed);
            if (pendingLevel > 0) _tokenInfos[tokenId].level = pendingLevel - 1;
        }
    }

    /**
     * @dev Apply completed pending hints rewards for a user
     */
    function _applyPendingHints(address account) internal {
        if (_ownerInfos[account].staked == 0 || _ownerInfos[account].redeemed || _ownerInfos[account].startHintTime == 0) return;

        uint256 hintSpeed = getHintSpeed(_ownerInfos[account].staked);
        if (hintSpeed > 0) {
            (uint256 pendingHints, ) = _getPendingRewards(
                _ownerInfos[account].hints,
                _ownerInfos[account].startHintTime,
                hintSpeed
            );

            if (pendingHints > 0) {
                _ownerInfos[account].hints = pendingHints - 1;
            }
        }

        _ownerInfos[account].startHintTime = 0;
    }

    /**
     * @dev returns the current level state for token
     */
    function getLevel(uint256 tokenId)
        public
        view
        returns (
            uint256 level,
            uint256 pendingLevel,
            uint256 nextLevelDate,
            uint256 levelSpeed,
            uint256 poolId,
            bool redeemed
        )
    {
        level = _tokenInfos[tokenId].level;
        poolId = _tokenInfos[tokenId].pool;
        redeemed = _tokenInfos[tokenId].redeemed;
        levelSpeed = 0;

        if (_tokenInfos[tokenId].pool != 0) {
            (pendingLevel, nextLevelDate) = _getPendingRewards(
                _tokenInfos[tokenId].level,
                _poolInfos[_tokenInfos[tokenId].pool].depositTime,
                _poolInfos[_tokenInfos[tokenId].pool].levelSpeed
            );
            levelSpeed = _poolInfos[_tokenInfos[tokenId].pool].levelSpeed;
        }
    }

    /**
     * @dev returns the current hint state for a user
     */
    function getHints(address account)
        public
        view
        returns (
            uint256 hints,
            uint256 pendingHints,
            uint256 nextHintDate,
            uint256 hintSpeed,
            bool redeemed
        )
    {
        hints = _ownerInfos[account].hints;
        redeemed = _ownerInfos[account].redeemed;
        hintSpeed = 0;

        if (_ownerInfos[account].startHintTime != 0) {
            hintSpeed = getHintSpeed(_ownerInfos[account].staked);
            (pendingHints, nextHintDate) = _getPendingRewards(
                _ownerInfos[account].hints,
                _ownerInfos[account].startHintTime,
                hintSpeed
            );
        }
    }

    /**
     * @dev returns `true` if `tokenId` is staked
     */
    function isStaked(uint256 tokenId) public view returns (bool) {
        return _tokenInfos[tokenId].pool != 0;
    }

    /**
     * @dev returns stake info for a token (poolIndex, deposit time and rewards speed)
     */
    function getStakeInfo(uint256 tokenId)
        public
        view
        returns (
            uint256 poolIndex,
            uint256 depositTime,
            uint256 levelSpeed
        )
    {
        uint256 poolId = _tokenInfos[tokenId].pool;
        if (poolId == 0) {
            poolIndex = 0;
            depositTime = 0;
            levelSpeed = 0;
        } else {
            poolIndex = poolId;
            depositTime = _poolInfos[poolId].depositTime;
            levelSpeed = _poolInfos[poolId].levelSpeed;
        }
    }

    /**
     * @dev returns the info for a pool
     */
    function getPoolInfo(uint256 poolIndex) public view returns (PoolInfo memory pool) {
        pool = _poolInfos[poolIndex];
    }

    /**
     * @dev returns the info for a token
     */
    function getTokenInfo(uint256 tokenId) public view returns (TokenInfo memory tokenInfo) {
        tokenInfo = _tokenInfos[tokenId];
    }

    function _redeemToken(uint256 tokenId) internal {
        require(_tokenInfos[tokenId].pool == 0, "MetaPopitStaking: Must unstake before redeem");
        _tokenInfos[tokenId].redeemed = true;
        emit RedeemToken(tokenId, _tokenInfos[tokenId].level);
    }

    function _redeemAccount(address account) internal {
        _applyPendingHints(account);
        _ownerInfos[account].redeemed = true;
        _ownerInfos[account].startHintTime = 0;
        emit RedeemAccount(account, _ownerInfos[account].hints);
    }

    /**
     * @dev returns `true` if `tokenId` is redeemed
     */
    function isTokenRedeemed(uint256 tokenId) public view returns (bool) {
        return _tokenInfos[tokenId].redeemed;
    }

    /**
     * @dev returns `true` if `tokenId` is redeemed
     */
    function isAccountRedeemed(address account) public view returns (bool) {
        return _ownerInfos[account].redeemed;
    }

    function _stake(address tokenOwner, uint256[] memory tokenIds)
        internal
        whenStakingOpened
        whenTokensNotStaked(tokenIds)
    {
        uint256 poolIndex = _getNextPoolId();
        _poolInfos[poolIndex] = PoolInfo({
            depositTime: block.timestamp,
            levelSpeed: getLevelSpeed(tokenIds.length),
            tokens: tokenIds,
            owner: tokenOwner
        });

        if (_ownerInfos[tokenOwner].staked < maxHintTeamSize) {
            _applyPendingHints(tokenOwner);
            _ownerInfos[tokenOwner].startHintTime = block.timestamp;
        }
        _ownerInfos[tokenOwner].staked += tokenIds.length;
        stakedTokenCount += tokenIds.length;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(!_tokenInfos[tokenId].redeemed, "MetaPopitStaking: Rewards already redeemed");
            require(ITokenStake(collection).ownerOf(tokenId) == tokenOwner, "MetaPopitStaking: Not owner");
            _tokenInfos[tokenId].pool = poolIndex;
            ITokenStake(collection).stakeToken(tokenId);
        }

        emit Stake(tokenOwner, poolIndex, tokenIds);
    }

    function _unstake(uint256 poolId, bool redeemRewards) internal {
        require(_poolInfos[poolId].owner != address(0), "MetaPopitStaking: invalid pool");
        PoolInfo memory pool = _poolInfos[poolId];
        delete _poolInfos[poolId];

        if (_ownerInfos[pool.owner].staked - pool.tokens.length < maxHintTeamSize) {
            _applyPendingHints(pool.owner);
            _ownerInfos[pool.owner].startHintTime = block.timestamp;
        }
        _ownerInfos[pool.owner].staked -= pool.tokens.length;

        for (uint256 i = 0; i < pool.tokens.length; i++) {
            _tokenInfos[pool.tokens[i]].pool = 0;
            _applyPendingLevel(pool.tokens[i], pool.depositTime, pool.levelSpeed);
            if (redeemRewards) _redeemToken(pool.tokens[i]);
            ITokenStake(collection).unstakeToken(pool.tokens[i]);
        }

        stakedTokenCount -= pool.tokens.length;
        emit UnStake(pool.owner, poolId, pool.tokens);
    }

    /**
     * @dev Stake a group of tokens in a pool
     */
    function stake(uint256[] calldata tokenIds) external {
        require(tokenIds.length <= maxLevelTeamSize, "MetaPopitStaking: above max team size");
        _stake(_msgSender(), tokenIds);
    }

    /**
     * @dev Ustake tokens from `poolId``
     * @param redeemRewards : redeem rewards for token if set to `true`
     */
    function unstake(uint256 poolId, bool redeemRewards) external {
        require(_poolInfos[poolId].owner == _msgSender(), "MetaPopitStaking: not owner of pool");
        _unstake(poolId, redeemRewards);
    }

    /**
     * @dev Batch stake a group of tokens in multiple pools
     */
    function batchStake(uint256[][] calldata batchTokenIds) external {
        for (uint256 i = 0; i < batchTokenIds.length; i++) {
            require(batchTokenIds[i].length <= maxLevelTeamSize, "MetaPopitStaking: above max team size");
            _stake(_msgSender(), batchTokenIds[i]);
        }
    }

    /**
     * @dev Batch unstake token from a list of pools
     * @param redeemRewards : redeem rewards for token if set to `true`
     */
    function batchUnstake(uint256[] calldata poolIds, bool redeemRewards) external {
        for (uint256 i = 0; i < poolIds.length; i++) {
            require(_poolInfos[poolIds[i]].owner == _msgSender(), "MetaPopitStaking: not owner of pool");
            _unstake(poolIds[i], redeemRewards);
        }
    }

    /**
     * @dev Stake `tokenIds` in a existing pool
     */
    function addToPool(uint256 poolId, uint256[] calldata tokenIds)
        external
        whenStakingOpened
        whenTokensNotStaked(tokenIds)
    {
        require(_poolInfos[poolId].owner == _msgSender(), "MetaPopitStaking: not owner of pool");
        require(
            _poolInfos[poolId].tokens.length + tokenIds.length <= maxLevelTeamSize,
            "MetaPopitStaking: above max team size"
        );

        // apply pending rewards
        if (_ownerInfos[_msgSender()].staked < maxHintTeamSize) {
            _applyPendingHints(_msgSender());
            _ownerInfos[_msgSender()].startHintTime = block.timestamp;
        }
        _ownerInfos[_msgSender()].staked += tokenIds.length;

        uint256 oldLength = _poolInfos[poolId].tokens.length;
        uint256[] memory newTokenIds = new uint256[](oldLength + tokenIds.length);
        for (uint256 i = 0; i < _poolInfos[poolId].tokens.length; i++) {
            _applyPendingLevel(
                _poolInfos[poolId].tokens[i],
                _poolInfos[poolId].depositTime,
                _poolInfos[poolId].levelSpeed
            );
            newTokenIds[i] = _poolInfos[poolId].tokens[i];
        }

        // stake new tokens
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(!_tokenInfos[tokenIds[i]].redeemed, "MetaPopitStaking: Rewards already redeemed");
            require(ITokenStake(collection).ownerOf(tokenIds[i]) == _msgSender(), "MetaPopitStaking: Not owner");
            ITokenStake(collection).stakeToken(tokenIds[i]);
            newTokenIds[oldLength + i] = tokenIds[i];
            _tokenInfos[tokenIds[i]].pool = poolId;
        }

        // update pool infos
        _poolInfos[poolId].depositTime = block.timestamp;
        _poolInfos[poolId].levelSpeed = getLevelSpeed(newTokenIds.length);
        _poolInfos[poolId].tokens = newTokenIds;

        stakedTokenCount += tokenIds.length;
        emit Stake(_msgSender(), poolId, tokenIds);
    }

    /**
     * @dev Redeem the final rewards for a token.
     * Once redeemed a token cannot be staked in this contract anymore
     */
    function redeemToken(uint256 tokenId) external {
        require(!_tokenInfos[tokenId].redeemed, "MetaPopitStaking: Token already redeemed");
        require(ITokenStake(collection).ownerOf(tokenId) == _msgSender(), "MetaPopitStaking: not owner");
        _redeemToken(tokenId);
    }

    /**
     * @dev Redeem the final rewards for an account.
     * Once redeemed hints are not incremented any more
     */
    function redeemAccount() external {
        require(!_ownerInfos[_msgSender()].redeemed, "MetaPopitStaking: Account already redeemed");
        _redeemAccount(_msgSender());
    }

    /**
     * @dev returns the level speed for a `teamSize`
     */
    function getLevelSpeed(uint256 teamSize) public view returns (uint256) {
        if (teamSize > maxLevelTeamSize) {
            return _levelSpeed[maxLevelTeamSize];
        }
        return _levelSpeed[teamSize];
    }

    /**
     * @dev returns the hint speed for a `teamSize`
     */
    function getHintSpeed(uint256 teamSize) public view returns (uint256) {
        if (teamSize > maxHintTeamSize) {
            return _hintSpeed[maxHintTeamSize];
        }
        return _hintSpeed[teamSize];
    }

    /**
     * @dev Update the base speed of level and hint rewards
     * only callable by owner
     */
    function setSpeeds(uint256[] calldata levelSpeed, uint256[] calldata hintSpeed) external onlyOwner {
        maxLevelTeamSize = levelSpeed.length;
        maxHintTeamSize = hintSpeed.length;

        for (uint256 i = 0; i < levelSpeed.length; i++) {
            _levelSpeed[i + 1] = levelSpeed[i];
        }

        for (uint256 i = 0; i < hintSpeed.length; i++) {
            _hintSpeed[i + 1] = hintSpeed[i];
        }
    }

    /**
     * @dev Close the staking
     * only callable by owner
     */
    function closeStaking() external onlyOwner {
        require(!isStakingClosed, "MetaPopitStaking: staking already closed");
        isStakingClosed = true;
        emit StakingClosed();
    }
}
