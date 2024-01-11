// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./OwnableUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./Initializable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./Errors.sol";
import "./UncheckedIncrement.sol";
import "./ICafeStaking.sol";
import "./IERC20StakingLocker.sol";
import "./IERC721StakingLocker.sol";
import "./IERC1155StakingLocker.sol";
import "./ICafeAccumulator.sol";
import "./StakingCommons.sol";
import "./OnChainRewardsWallet.sol";

struct Stake {
    uint128 reward;
    uint128 paid;
    uint256 balance;
    uint256[50000] ids;
}

struct TokenRange {
    uint128 lower;
    uint128 upper;
    bool enabled;
}

struct Track {
    uint128 rewardPerTokenStored;
    uint128 lastUpdateTime;
    // unixtime stamp
    uint128 start;
    // unixtime stamp
    uint128 end;
    // the total of the Staking Asset deposited
    uint256 staked;
    // reward per second, in $CAFE
    uint256 rps;
    // valid token identity range (for ERC721 and ERC1155)
    TokenRange range;
    // unique track id
    uint32 id;
    /// @custom:security non-reentrant
    OnChainRewardsWallet wallet;
    // staking asset address
    address asset;
    // staking asset type
    TrackType atype;
    // if true, lock through asset transfer
    bool transferLock;
    // if true, prevent staking/unstaking
    bool paused;
}

contract CafeStakingV3 is
    ICafeStaking,
    Initializable,
    OwnableUpgradeable,
    IERC721ReceiverUpgradeable,
    IERC1155ReceiverUpgradeable
{
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for IERC20StakingLocker;
    using UncheckedIncrement for uint256;

    /// @custom:security non-reentrant
    IERC20Upgradeable public cafeToken;

    mapping(uint256 => Track) public tracks;

    uint256 public tracksCount;

    // staker => asset => Stake
    mapping(address => mapping(address => Stake)) public stakes;

    /* ========== INITIALIZER ========== */

    function initialize(address cafeToken_) external initializer {
        if (!cafeToken_.isContract())
            revert ContractAddressExpected(cafeToken_);

        __Ownable_init();

        cafeToken = IERC20Upgradeable(cafeToken_);
    }

    /* ========== PUBLIC MUTATORS ========== */

    /// @dev Batch process Stake Requests.
    /// @param msr Multiple stake requests.
    /// @param actions Multiple corresponding actions.
    function execute(
        StakeRequest[] calldata msr,
        StakeAction[][] calldata actions
    ) external {
        _execute(msg.sender, msr, actions);
    }

    /// @dev Batch process Stake Requests. For autostaking purposes,
    ///      so only callable from asset contracts.
    /// @param msr Multiple stake requests.
    /// @param actions Multiple corresponding actions.
    function execute4(
        address account,
        StakeRequest[] calldata msr,
        StakeAction[][] calldata actions
    ) external {
        if (msg.sender != tracks[msr[0].trackId].asset) revert Unauthorized();

        _execute(account, msr, actions);
    }


    /* ========== ADMIN-ONLY MUTATORS ========== */

    /// @dev Create a staking track. Assign id automatically. Emit {TrackCreated} on success.
    ///      Transfers staking rewards to the track's On-Chain Rewards Wallet.
    ///
    /// @param asset Stakable asset address.
    /// @param totalRewards Total $CAFE to allocate (from address(this)'s balance.)
    /// @param atype Asset type.
    /// @param start Begin rewards accrual at this time.
    /// @param end Expire the track at this time.
    /// @param lower Set the lower token range boundary.
    ///        Disable token range by making `lower` higher than `upper`.
    /// @param upper Set the upper token range boundary.
    /// @param transferLock Define the track as custodial (with `true`.)
    ///
    /// Requirements:
    /// - Caller must be the contract owner.
    /// - `asset` must be a contract.
    /// - `totalRewards` must be positive.
    /// - CafeStaking must hold at least `totalRewards` of $CAFE
    /// - `start` must be in the future
    /// - `end` must exceed start
    function createTrack(
        address asset,
        uint256 totalRewards,
        TrackType atype,
        uint256 start,
        uint256 end,
        uint256 lower,
        uint256 upper,
        bool transferLock
    ) external {
        _onlyOwner();

        if (!asset.isContract()) revert ContractAddressExpected(asset);
        if (totalRewards == 0) revert ZeroAmount();
        if (end <= start) revert InvalidTrackTiming();
        if (block.timestamp >= start) revert InvalidTrackStart();

        address thisContract = address(this);

        if (cafeToken.balanceOf(thisContract) < totalRewards)
            revert InsufficientCAFE();

        Track storage track = tracks[tracksCount];

        track.wallet = new OnChainRewardsWallet(thisContract);
        track.asset = asset;
        track.rps = totalRewards / (end - start);

        if (upper >= lower) {
            track.range = TokenRange(uint128(lower), uint128(upper), true);
        }

        track.start = uint128(start);
        track.end = uint128(end);
        track.atype = atype;
        track.transferLock = transferLock;
        track.id = uint32(tracksCount);

        emit TrackCreated(tracksCount, asset, track.rps);

        tracksCount++;

        track.wallet.approve(address(cafeToken), thisContract, true);
        cafeToken.safeTransfer(address(track.wallet), totalRewards);
    }

    /// @dev Pause/resume an existing track. Emit {TrackToggled} on success.
    /// @param trackId Identity of the track to pause/resume.
    ///
    /// Requirements:
    /// - Caller must be the contract owner
    /// - The track in question must exist
    function toggleTrack(uint256 trackId) external {
        _onlyOwner();

        _trackExists(trackId);

        Track storage track = tracks[trackId];

        track.paused = !track.paused;

        emit TrackToggled(track.id, track.paused);
    }

    /// @dev Transfer an amount of $CAFE from the contract's balance to a track's wallet.
    ///      Automatically update the track's RPS.
    /// @param trackId The destination track.
    /// @param amount The amount to transfer.
    ///
    /// Requirements:
    /// - The track in question must exist.
    /// - The track in question must be non-expired.
    /// - The amount must be positive.
    /// - CafeStaking must hold at least `amount` of $CAFE
    function replenishTrack(uint256 trackId, uint256 amount) external {
        _onlyOwner();
        _trackExists(trackId);

        _replenishTrack(trackId, amount, false);
    }

    /// @dev Pull all the accumulated $CAFE from an external accumulator asset
    ///      and transfer it to a track's wallet.
    /// @param trackId The destination track.
    /// @param accumulator The accumulator asset address.
    ///
    /// Requirements:
    /// - The track in question must exist.
    /// - The track in question must be non-expired.
    /// - The amount pulled must be positive.
    function replenishTrackFrom(uint256 trackId, address accumulator) external {
        _onlyOwner();
        _trackExists(trackId);

        Track storage track = tracks[trackId];

        _replenishTrack(
            trackId,
            ICafeAccumulator(accumulator).pull(address(track.wallet)),
            true
        );
    }

    /* ========== VIEWS ========== */

    /// @dev Get staked balance of an account for a given ERC20 track.
    /// @param trackId The track (asset) to read from.
    /// @param account The account to fetch the balance for.
    ///
    /// Requirements:
    /// - The track in question must exist
    function stakeInfoERC20(uint256 trackId, address account)
        external
        view
        returns (uint256 bal)
    {
        _trackExists(trackId);

        Track storage track = tracks[trackId];

        if (track.transferLock) {
            bal = stakes[account][track.asset].balance;
        } else {
            bal = IERC20StakingLocker(track.asset).locked(account);
        }
    }

    /// @dev Get token identities and balance of an account for a given ERC721 track.
    /// @param trackId The track (asset) to read from.
    /// @param account The account to fetch the balance for.
    /// @param page Read data starting at the top of this page.
    /// @param records Records per page.
    ///
    /// Requirements:
    /// - The track in question must exist
    function stakeInfoERC721(
        uint256 trackId,
        address account,
        uint256 page,
        uint256 records
    ) external view returns (uint256[] memory, uint256) {
        _trackExists(trackId);

        Track storage track = tracks[trackId];
        uint256 from = page * records;
        uint256 to = from + records;
        uint256[] memory result = new uint256[](records);
        bool transferLock = track.transferLock;

        for (uint256 r = from; r < to; r = r.inc()) {
            uint256 amount = transferLock
                ? stakes[account][track.asset].ids[r]
                : (IERC721StakingLocker(track.asset).isLocked(r) &&
                    IERC721StakingLocker(track.asset).ownerOf(r) == account)
                ? 1
                : 0;

            if (amount > 0) {
                result[r - from] = 1;
            }
        }

        return (result, stakes[account][track.asset].balance);
    }

    /// Get token identities, token count, and balance of an account for a given ERC1155 track.
    /// @param trackId The track (asset) to read from.
    /// @param account The account to fetch the balance for.
    /// @param page Read data starting at the top of this page.
    /// @param records Records per page.
    ///
    /// Requirements:
    /// - The track in question must exist
    function stakeInfoERC1155(
        uint256 trackId,
        address account,
        uint256 page,
        uint256 records
    )
        external
        view
        returns (
            uint256[] memory,
            uint256,
            uint256
        )
    {
        _trackExists(trackId);

        Track storage track = tracks[trackId];
        uint256 from = page * records;
        uint256 to = from + records;

        uint256[] memory result = new uint256[](records);
        bool transferLock = track.transferLock;
        uint256 count = 0;

        for (uint256 r = from; r < to; r = r.inc()) {
            uint256 amount = transferLock
                ? stakes[account][track.asset].ids[r]
                : IERC1155StakingLocker(track.asset).locked(account, r);

            if (amount > 0) {
                count += amount;
                result[r - from] = amount;
            }
        }
        return (result, count, stakes[account][track.asset].balance);
    }

    /// @dev Get yield per token.
    function rewardPerToken(uint256 trackId) public view returns (uint256) {
        _trackExists(trackId);

        Track storage track = tracks[trackId];

        if (track.staked == 0) {
            return 0;
        }

        uint256 scale = (track.atype == TrackType.ERC20)? 1e18 : 1;

        uint256 rpts = 
            track.rewardPerTokenStored +
            ((track.rps *
                (block.timestamp - track.lastUpdateTime) * scale) /
                track.staked);

        return rpts;
    }

    /// @dev Get the amount earned
    function earned(uint256 trackId, address account)
        public
        view
        returns (uint256 res)
    {
        _trackExists(trackId);

        Track storage track = tracks[trackId];

        Stake storage stake_ = stakes[account][track.asset];

        uint256 balance;
        uint256 scale;

        if (track.atype == TrackType.ERC20) {
            balance = track.transferLock
                ? stake_.balance
                : IERC20StakingLocker(track.asset).locked(account);
            scale = 1e18;
        } else {
            balance = stake_.balance;
            scale = 1;
        }

        if (balance == 0) {
            res = stake_.reward;
        } else {
            res =
                (balance * (rewardPerToken(trackId) - stake_.paid) / scale) +
                stake_.reward;
        }
    }

    /* ========== INTERNALS/MODIFIERS ========== */

    function _replenishTrack(
        uint256 trackId,
        uint256 amount,
        bool directTransfer
    ) internal {
        if (amount == 0) revert ZeroAmount();

        Track storage track = tracks[trackId];

        if (!directTransfer && (cafeToken.balanceOf(address(this)) < amount))
            revert InsufficientCAFE();

        if (block.timestamp >= track.end) revert TrackExpired();

        uint256 newBalance = cafeToken.balanceOf(address(track.wallet)) +
            (directTransfer ? 0 : amount);

        track.rps = newBalance / (track.end - block.timestamp);

        emit TrackReplenished(trackId, amount, track.rps);

        if (!directTransfer)
            cafeToken.safeTransfer(address(track.wallet), amount);
    }

    function _execute(
        address account,
        StakeRequest[] calldata msr,
        StakeAction[][] calldata actions
    ) internal {
        for (uint256 sr = 0; sr < msr.length; sr = sr.inc()) {
            _trackExists(msr[sr].trackId);
        }

        for (uint256 sr = 0; sr < msr.length; sr = sr.inc()) {
            Track storage track = tracks[msr[sr].trackId];
            _updateRewards(track, account);

            for (uint256 a = 0; a < actions[sr].length; a = a.inc()) {
                if (actions[sr][a] == StakeAction.Stake) {
                    _stake(account, tracks[msr[sr].trackId], msr[sr]);
                } else if (actions[sr][a] == StakeAction.Unstake) {
                    _unstake(account, tracks[msr[sr].trackId], msr[sr]);
                } else {
                    _collect(account, tracks[msr[sr].trackId]);
                }
            }
        }
    }

    function _stake(
        address account,
        Track storage track,
        StakeRequest calldata sr
    ) internal {
        _inStakingPeriod(track);

        if (track.atype == TrackType.ERC20) {
            _stake(account, track, sr.amounts[0]);
        } else if (track.atype == TrackType.ERC1155) {
            _stake(account, track, sr.ids, sr.amounts);
        } else {
            // TrackType.ERC721
            _stake(account, track, sr.ids);
        }
    }

    function _unstake(
        address account,
        Track storage track,
        StakeRequest calldata sr
    ) internal {
        if (track.atype == TrackType.ERC20) {
            _unstake(account, track, sr.amounts[0]);
        } else if (track.atype == TrackType.ERC1155) {
            _unstake(account, track, sr.ids, sr.amounts);
        } else {
            // TrackType.ERC721
            _unstake(account, track, sr.ids);
        }
    }

    // ERC20
    function _stake(
        address account,
        Track storage track,
        uint256 amount
    ) internal {
        _whenNotPaused(track);
        _erc20StakeRequestValid(amount);

        IERC20StakingLocker erc20_ = IERC20StakingLocker(track.asset);

        track.staked += amount;

        emit AssetStaked(track.asset, account, amount);

        if (track.transferLock) {
            Stake storage stake_ = stakes[account][track.asset];
            stake_.balance += amount;

            erc20_.safeTransferFrom(account, address(this), amount);
        } else {
            erc20_.lock(account, amount);
        }
    }

    // ERC1155
    function _stake(
        address account,
        Track storage track,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) internal {
        _whenNotPaused(track);
        _erc1155StakeRequestValid(track, ids, amounts);

        uint256 subtotal;
        Stake storage stake_ = stakes[account][track.asset];

        IERC1155StakingLocker erc1155_ = IERC1155StakingLocker(track.asset);

        for (uint256 t = 0; t < ids.length; t = t.inc()) {
            stake_.ids[ids[t]] += amounts[t];
            subtotal += amounts[t];
        }

        stake_.balance += subtotal;
        track.staked += subtotal;

        emit AssetStaked(track.asset, account, subtotal);

        if (track.transferLock) {
            erc1155_.safeBatchTransferFrom(
                account,
                address(this),
                ids,
                amounts,
                ""
            );
        } else {
            erc1155_.lock(account, ids, amounts);
        }
    }

    // ERC721
    function _stake(
        address account,
        Track storage track,
        uint256[] calldata ids
    ) internal {
        _whenNotPaused(track);
        _erc721StakeRequestValid(track, ids);

        Stake storage stake_ = stakes[account][track.asset];
        emit AssetStaked(track.asset, account, ids.length);
        IERC721StakingLocker erc721_ = IERC721StakingLocker(track.asset);

        stake_.balance += ids.length;
        track.staked += ids.length;

        if (track.transferLock) {
            for (uint256 t = 0; t < ids.length; t = t.inc()) {
                stake_.ids[ids[t]] = 1;
                erc721_.safeTransferFrom(account, address(this), ids[t]);
            }
        } else {
            erc721_.lock(account, ids);
        }
    }

    // ERC20
    function _unstake(
        address account,
        Track storage track,
        uint256 amount
    ) internal {
        _whenNotPaused(track);
        _erc20StakeRequestValid(amount);

        IERC20StakingLocker erc20_ = IERC20StakingLocker(track.asset);

        if (amount > track.staked) revert AmountExceedsLocked();

        track.staked -= amount;

        emit AssetUnstaked(track.asset, account, amount);

        if (track.transferLock) {
            Stake storage stake_ = stakes[account][track.asset];
            if (amount > stake_.balance) revert AmountExceedsLocked();

            stake_.balance -= amount;

            erc20_.safeTransfer(account, amount);
        } else {
            // will revert on insufficient balance
            erc20_.unlock(account, amount);
        }
    }

    // ERC1155
    function _unstake(
        address account,
        Track storage track,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) internal {
        _whenNotPaused(track);
        _erc1155StakeRequestValid(track, ids, amounts);

        uint256 subtotal;
        Stake storage stake_ = stakes[account][track.asset];

        IERC1155StakingLocker erc1155_ = IERC1155StakingLocker(track.asset);

        for (uint256 t = 0; t < ids.length; t = t.inc()) {
            if (stake_.ids[ids[t]] < amounts[t]) revert AmountExceedsLocked();

            stake_.ids[ids[t]] -= amounts[t];
            subtotal += amounts[t];
        }

        stake_.balance -= subtotal;
        track.staked -= subtotal;

        emit AssetUnstaked(track.asset, account, subtotal);

        if (track.transferLock) {
            erc1155_.safeBatchTransferFrom(
                address(this),
                account,
                ids,
                amounts,
                ""
            );
        } else {
            erc1155_.unlock(account, ids, amounts);
        }
    }

    // ERC721
    function _unstake(
        address account,
        Track storage track,
        uint256[] calldata ids
    ) internal {
        _whenNotPaused(track);
        _erc721StakeRequestValid(track, ids);

        Stake storage stake_ = stakes[account][track.asset];
        IERC721StakingLocker erc721_ = IERC721StakingLocker(track.asset);

        if (stake_.balance < ids.length || track.staked < ids.length)
            revert AmountExceedsLocked();

        stake_.balance -= ids.length;
        track.staked -= ids.length;

        emit AssetUnstaked(track.asset, account, ids.length);

        if (track.transferLock) {
            for (uint256 t = 0; t < ids.length; t = t.inc()) {
                if (stake_.ids[ids[t]] != 1) revert TokenNotOwn();

                delete stake_.ids[ids[t]];

                erc721_.safeTransferFrom(address(this), account, ids[t]);
            }
        } else {
            erc721_.unlock(account, ids);
        }
    }

    function _collect(address account, Track storage track) internal {
        _whenNotPaused(track);
        Stake storage stake_ = stakes[account][track.asset];
        uint256 reward = stake_.reward;

        if (reward > 0) {
            stake_.reward = 0;
            emit RewardPaid(account, reward);
            cafeToken.safeTransferFrom(address(track.wallet), account, reward);
        }
    }

    function _updateRewards(Track storage track, address account) internal {
        uint128 rewardPerTokenStored = uint128(rewardPerToken(track.id));

        track.rewardPerTokenStored = rewardPerTokenStored;
        track.lastUpdateTime = _restrictedBlockTimestamp(track.end);
        Stake storage stake_ = stakes[account][track.asset];
        stake_.reward = uint128(earned(track.id, account));
        stake_.paid = rewardPerTokenStored;
    }

    function _onlyOwner() internal view {
        if (msg.sender != owner()) revert Unauthorized();
    }

    function _whenNotPaused(Track storage track) internal view {
        if (track.paused) revert TrackPaused(track.id);
    }

    function _trackExists(uint256 trackId) internal view {
        if (trackId >= tracksCount) revert UnknownTrack();
    }

    function _inStakingPeriod(Track storage track) internal view {
        if (!(block.timestamp >= track.start && block.timestamp <= track.end))
            revert NotInStakingPeriod();
    }

    function _restrictedBlockTimestamp(uint128 trackEnd)
        internal
        view
        returns (uint128)
    {
        uint256 blockstamp = block.timestamp;
        return (blockstamp <= trackEnd) ? uint128(blockstamp) : trackEnd;
    }

    function _erc20StakeRequestValid(uint256 amount) internal pure {
        if (amount == 0) revert ZeroAmount();
    }

    function _erc1155StakeRequestValid(
        Track storage track,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) internal view {
        if (ids.length != amounts.length) revert InvalidArrayLength();
        if (ids.length == 0) revert NoTokensGiven();

        if (track.range.enabled) {
            _checkRange(ids, track.range.lower, track.range.upper);
        }
    }

    function _erc721StakeRequestValid(
        Track storage track,
        uint256[] calldata ids
    ) internal view {
        if (ids.length == 0) revert NoTokensGiven();

        if (track.range.enabled) {
            _checkRange(ids, track.range.lower, track.range.upper);
        }
    }

    function _checkRange(
        uint256[] calldata ids,
        uint128 lower,
        uint128 upper
    ) internal view {
        for (uint256 t = 0; t < ids.length; t = t.inc()) {
            if (ids[t] < lower || ids[t] > upper) revert TokenOutOfRange();
        }
    }

    function supportsInterface(bytes4 interfaceId)
        external
        view
        returns (bool)
    {
        interfaceId;
        return false;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        operator;
        from;
        tokenId;
        data;
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        operator;
        from;
        id;
        value;
        data;
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4) {
        operator;
        from;
        ids;
        values;
        data;
        return
            bytes4(
                keccak256(
                    "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
                )
            );
    }
}
