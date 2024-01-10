// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Ownable.sol";
import "./IERC721.sol";
import "./ERC721Holder.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Poolable.sol";
import "./Recoverable.sol";
import "./Registrable.sol";

/** @title FlyzNFTStaking
 */
contract FlyzNFTStaking is Ownable, Poolable, Recoverable, Registrable, ReentrancyGuard, ERC721Holder {
    using SafeERC20 for IERC20;

    struct PoolDeposit {
        address owner;
        uint32 pool;
        uint256 depositDate;
        uint256 claimed;
    }

    struct TokenDefinition {
        address collection;
        uint256 tokenId;
    }

    bool public requiresRegistration;
    IERC20 public immutable rewardToken;

    // poolDeposit per collection & tokenId
    mapping(address => mapping(uint256 => PoolDeposit)) private _deposits;
    // user rewards mapping
    mapping(address => uint256) private _userRewards;

    event Stake(address indexed account, address indexed collection, uint256 tokenId, uint256 poolId);
    event Unstake(address indexed account, address indexed collection, uint256 tokenId);

    event RewardClaim(address indexed account, uint256 amount);
    event RegistrationRequired(bool required);

    constructor(
        IERC20 _rewardToken,
        bool _requiresRegistration,
        uint256 _registrationFee
    ) Registrable(_requiresRegistration, _registrationFee) {
        rewardToken = _rewardToken;
        requiresRegistration = _requiresRegistration;
    }

    function _sendAndUpdateRewards(address account, uint256 amount) internal {
        if (amount > 0) {
            _userRewards[account] += amount;
            rewardToken.safeTransfer(account, amount);
        }
    }

    function _stake(
        address account,
        address collection,
        uint256 tokenId,
        uint32 poolId
    ) internal whenPoolOpened(poolId) {
        require(_deposits[collection][tokenId].owner == address(0), "Stake: Token already staked");
        require(collection == poolCollection(poolId), "Stake: Invalid pool for collection");

        // add deposit
        _deposits[collection][tokenId] = PoolDeposit({
            owner: account,
            pool: poolId,
            depositDate: block.timestamp,
            claimed: 0
        });

        // transfer token
        IERC721(collection).safeTransferFrom(account, address(this), tokenId);
        emit Stake(account, collection, tokenId, poolId);
    }

    /**
     * @notice Stake a token from the collection
     */
    function stake(
        address collection,
        uint256 tokenId,
        uint32 poolId
    ) external payable nonReentrant {
        address account = _msgSender();
        if (requiresRegistration && !isRegistered(account)) {
            require(msg.value >= registrationFee, "Stake: Registration required");
            _tryRegister(account);
        }
        _stake(account, collection, tokenId, poolId);
    }

    function _unstake(
        address account,
        address collection,
        uint256 tokenId
    ) internal returns (uint256) {
        require(_deposits[collection][tokenId].owner == account, "Stake: Not owner of token");

        uint256 poolId = _deposits[collection][tokenId].pool;
        require(isUnlockable(poolId, _deposits[collection][tokenId].depositDate), "Stake: Not yet unstakable");
        (uint256 rewards, ) = getPendingRewards(poolId, _deposits[collection][tokenId].depositDate);

        if (rewards > _deposits[collection][tokenId].claimed) {
            rewards -= _deposits[collection][tokenId].claimed;
        } else {
            rewards = 0;
        }

        // update deposit
        delete _deposits[collection][tokenId];

        // transfer token
        IERC721(collection).safeTransferFrom(address(this), account, tokenId);
        emit Unstake(account, collection, tokenId);

        return rewards;
    }

    /**
     * @notice Unstake a token
     */
    function unstake(address collection, uint256 tokenId) external nonReentrant {
        address account = _msgSender();
        uint256 rewards = _unstake(account, collection, tokenId);
        _sendAndUpdateRewards(account, rewards);
    }

    function _restake(
        address account,
        address collection,
        uint256 tokenId,
        uint32 newPoolId
    ) internal whenPoolOpened(newPoolId) returns (uint256) {
        require(_deposits[collection][tokenId].owner != address(0), "Stake: Token not staked");
        require(_deposits[collection][tokenId].owner == account, "Stake: Not owner of token");
        require(
            isUnlockable(_deposits[collection][tokenId].pool, _deposits[collection][tokenId].depositDate),
            "Stake: Not yet unstakable"
        );

        (uint256 rewards, ) = getPendingRewards(
            _deposits[collection][tokenId].pool,
            _deposits[collection][tokenId].depositDate
        );

        _deposits[collection][tokenId].pool = newPoolId;
        _deposits[collection][tokenId].depositDate = block.timestamp;
        _deposits[collection][tokenId].claimed = 0;

        emit Unstake(account, collection, tokenId);
        emit Stake(account, collection, tokenId, newPoolId);

        return rewards;
    }

    /**
     * @notice Allow a user to [re]stake a token in a new pool without unstaking it first.
     */
    function restake(
        address collection,
        uint256 tokenId,
        uint32 newPoolId
    ) external nonReentrant {
        address account = _msgSender();
        uint256 rewards = _restake(account, collection, tokenId, newPoolId);
        _sendAndUpdateRewards(account, rewards);
    }

    /**
     * @notice Batch stake a list of tokens from the collection
     */
    function batchStake(uint32[] calldata poolIds, TokenDefinition[] calldata tokens) external payable nonReentrant {
        require(poolIds.length == tokens.length, "Stake: Invalid length");

        address account = _msgSender();
        if (requiresRegistration && !isRegistered(account)) {
            require(msg.value >= registrationFee, "Stake: Registration required");
            _tryRegister(account);
        }
        for (uint256 i = 0; i < poolIds.length; i++) {
            _stake(account, tokens[i].collection, tokens[i].tokenId, poolIds[i]);
        }
    }

    /**
     * @notice Batch unstake tokens
     */
    function batchUnstake(TokenDefinition[] calldata tokens) external nonReentrant {
        address account = _msgSender();
        uint256 rewards = 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            rewards += _unstake(account, tokens[i].collection, tokens[i].tokenId);
        }
        _sendAndUpdateRewards(account, rewards);
    }

    /**
     * @notice Batch restake tokens
     */
    function batchRestake(uint32[] memory poolIds, TokenDefinition[] calldata tokens) external nonReentrant {
        require(poolIds.length == tokens.length, "Stake: Invalid length");

        address account = _msgSender();
        uint256 rewards = 0;
        for (uint256 i = 0; i < poolIds.length; i++) {
            rewards += _restake(account, tokens[i].collection, tokens[i].tokenId, poolIds[i]);
        }
        _sendAndUpdateRewards(account, rewards);
    }

    function claim(TokenDefinition[] calldata tokens) external nonReentrant {
        uint256 totalRewards = 0;
        PoolDeposit storage deposit;
        uint256 claimable;

        address account = _msgSender();
        for (uint256 i = 0; i < tokens.length; i++) {
            deposit = _deposits[tokens[i].collection][tokens[i].tokenId];
            require(deposit.owner == account, "Stake: Not owner of token");

            (uint256 rewards, ) = getPendingRewards(deposit.pool, deposit.depositDate);
            claimable = rewards - deposit.claimed;
            if (claimable > 0) {
                totalRewards += claimable;
                deposit.claimed += claimable;
            }
        }

        if (totalRewards > 0) {
            _sendAndUpdateRewards(account, totalRewards);
            emit RewardClaim(account, totalRewards);
        }
    }

    /**
     * @notice Get the stake detail for a token (owner, poolId, min unstakable date, reward unlock date)
     */
    function getStakeInfo(address collection, uint256 tokenId)
        external
        view
        returns (
            address, // owner
            uint32, // poolId
            uint256, // deposit date
            uint256, // min unlock date
            uint256, // rewards
            uint256, // claimed
            uint256 // next/last reward date
        )
    {
        //require(_deposits[collection][tokenId].owner != address(0), "Stake: Token not staked");
        if (_deposits[collection][tokenId].owner == address(0)) {
            return (address(0), 0, 0, 0, 0, 0, 0);
        }

        PoolDeposit memory deposit = _deposits[collection][tokenId];
        (uint256 rewards, uint256 nextRewardDate) = getPendingRewards(deposit.pool, deposit.depositDate);
        return (
            deposit.owner,
            deposit.pool,
            deposit.depositDate,
            deposit.depositDate + getPool(deposit.pool).minDuration,
            rewards,
            deposit.claimed,
            nextRewardDate
        );
    }

    /**
     * @notice Returns the total reward for a user
     */
    function getUserTotalRewards(address account) external view returns (uint256) {
        return _userRewards[account];
    }

    function recoverNonFungibleToken(address _token, uint256 _tokenId) external override onlyOwner {
        // staked tokens cannot be recovered by admin
        require(_deposits[_token][_tokenId].owner == address(0), "Stake: Cannot recover staked token");
        IERC721(_token).transferFrom(address(this), address(msg.sender), _tokenId);
        emit NonFungibleTokenRecovery(_token, _tokenId);
    }

    function setRequiresRegistration(bool required) external onlyOwner {
        requiresRegistration = required;
        emit RegistrationRequired(required);
    }
}
