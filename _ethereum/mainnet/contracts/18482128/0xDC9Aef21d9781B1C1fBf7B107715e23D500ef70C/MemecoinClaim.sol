// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeERC20.sol";
import "./IDelegationRegistry.sol";
import "./IDelegateRegistry.sol";
import "./IMemecoinClaim.sol";

/// @title A contract for claiming $MEME over a parameterized vesting schedule
contract MemecoinClaim is
    IMemecoinClaim,
    Initializable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    using SafeERC20 for IERC20;

    uint256 private constant _BASIS_POINTS = 10_000;
    uint256 private constant _LOCK_UP_SLOT = 180;
    uint256 private constant _END_CYCLE = 4;
    uint256 private constant _END_CYCLE_CONTRIBUTORS = 8;
    uint256 private constant _MAX_CLAIM_PERIOD = 69 days;

    address public upgrader; // to be set
    address public multiClaim; // to be set

    IERC721[] public nftCollections;
    IDelegationRegistry public dc;
    IDelegateRegistry public dcV2;

    uint256 public claimStartDate;

    IERC20 public claimToken;
    bool public claimActive;
    bool public claimTokenDeposited;
    bool public unclaimedNFTRewardsWithdrawn;
    bool public upgraderRenounced;

    uint64 public currentNFTUnlockedBP;
    uint64 public previousNFTUnlockedBP;
    uint128 public currentNFTUnlockTimestamp;

    mapping(address userAddress => mapping(ClaimType claimType => ClaimData userClaimData)) public usersClaimData;
    mapping(uint256 collectionId => mapping(uint256 tokenId => NFTClaimData userClaimData)) public nftUsersClaimData;
    mapping(ClaimType claimType => ClaimSchedule claimSchedule) public claimScheduleOf;
    mapping(uint256 collectionId => UnclaimedNFTRewards) public unclaimedNftRewards;

    // required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyUpgrader {}

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _claimTokenAddress,
        address _mvpAddress,
        address _captainzAddress,
        address _potatozAddress
    ) external initializer {
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init_unchained();
        OwnableUpgradeable.__Ownable_init_unchained();
        UUPSUpgradeable.__UUPSUpgradeable_init();
        dc = IDelegationRegistry(0x00000000000076A84feF008CDAbe6409d2FE638B);
        dcV2 = IDelegateRegistry(0x00000000000000447e69651d841bD8D104Bed493);
        claimToken = IERC20(_claimTokenAddress);
        nftCollections = [IERC721(_mvpAddress), IERC721(_captainzAddress), IERC721(_potatozAddress)];
    }

    /// @notice Claim token by claimTypes according to the vesting schedule after claim starts, user won't be able to claim after the allocated $MEME are fully vested for _MAX_CLAIM_PERIOD
    /// @dev ONLY presaleClaim, ecosystem and contributor contract; Verify claim data and transfer claim token to user if needed, should not be called by NFT holder,
    /// emit { UserClaimed } event for amount claimed
    /// @param _vault Vault address of delegate.xyz; pass address(0) if not using delegate wallet
    /// @param _claimTypes Array of ClaimType to claim
    function claim(address _vault, ClaimType[] calldata _claimTypes) external nonReentrant onlyValidClaimSetup {
        address requester = _getRequester(_vault);
        uint256 totalClaimable = _claim(requester, _claimTypes);

        claimToken.safeTransfer(requester, totalClaimable);
    }

    /// @notice Claim OPTIONALLY on NFTAirdrop/NFTRewards/WalletRewards token by all eligible NFTs according to the vesting schedule after claim starts, user won't be able to claim after the allocated $MEME are fully vested for _MAX_CLAIM_PERIOD
    /// @dev ONLY nftClaim contract; ONLY related to NFT claimTypes(i.e. NFTRewards & WalletRewards); Verify claim data and transfer claim token to NFT owner if needed, emit { BulkClaimedInNFTs } event for amount claimed
    /// @param _vault Vault address of delegate.xyz; pass address(0) if not using delegate wallet
    /// @param _nftCollectionClaimRequests Array of NFTCollectionClaimRequest that consists collection ID of the NFT, token ID(s) the owner owns, array of booleans to indicate NFTAirdrop/NFTRewards claim for each token ID
    function claimInNFTs(
        address _vault,
        NFTCollectionClaimRequest[] calldata _nftCollectionClaimRequests,
        bool _withWalletRewards
    ) external nonReentrant onlyValidClaimSetup {
        address requester = _getRequester(_vault);
        uint256 totalClaimable = _claimInNFTs(requester, _nftCollectionClaimRequests, _withWalletRewards);

        claimToken.safeTransfer(requester, totalClaimable);
    }

    // ===================
    // Multicall Functions
    // ===================

    /// @notice Claim token by claimTypes according to the vesting schedule after claim starts
    /// @dev Verify caller is multiClaim, claim data and transfer claim token to _requester if needed, should not be called by NFT holder
    /// emit { UserClaimed } event for amount claimed
    /// @param _requester address of eligible claim wallet
    /// @param _claimTypes Array of ClaimType to claim
    function claimFromMulti(address _requester, ClaimType[] calldata _claimTypes)
        external
        nonReentrant
        onlyValidClaimSetup
        onlyMultiClaim
    {
        uint256 totalClaimable = _claim(_requester, _claimTypes);

        claimToken.safeTransfer(_requester, totalClaimable);
    }

    /// @notice Bulk claim token by claimTypes and eligible NFTs according to the vesting schedule after claim starts
    /// @dev Verify caller is multiClaim, claim data and transfer claim token to NFT owner if needed, emit { BulkClaimedInNFTs } event for amount claimed
    /// @param _requester address of eligible holder wallet
    /// @param _nftCollectionClaimRequests Array of NFTCollectionClaimRequest that consists collection ID of the NFT, token ID(s) the owner owns, array of booleans to indicate NFTAirdrop/NFTRewards claim for each token ID
    function claimInNFTsFromMulti(
        address _requester,
        NFTCollectionClaimRequest[] calldata _nftCollectionClaimRequests,
        bool _withWalletRewards
    ) external nonReentrant onlyValidClaimSetup onlyMultiClaim {
        uint256 totalClaimable = _claimInNFTs(_requester, _nftCollectionClaimRequests, _withWalletRewards);

        claimToken.safeTransfer(_requester, totalClaimable);
    }

    /// @notice Support both v1 and v2 delegate wallet during the v1 to v2 migration
    /// @dev Given _vault (cold wallet) address, verify whether _msgSender() is a permitted delegate to operate on behalf of it
    /// @param _vault Address to verify against _msgSender
    function _getRequester(address _vault) private view returns (address) {
        if (_vault == address(0)) return _msgSender();
        bool isDelegateValid = dcV2.checkDelegateForAll(_msgSender(), _vault, "");
        if (isDelegateValid) return _vault;
        isDelegateValid = dc.checkDelegateForAll(_msgSender(), _vault);
        if (!isDelegateValid) revert InvalidDelegate();
        return _vault;
    }

    function _claim(address _requester, ClaimType[] memory _claimTypes) internal returns (uint128 amountClaimed) {
        amountClaimed = _executeClaim(_requester, _claimTypes);
        if (amountClaimed == 0) revert NoClaimableToken();

        emit UserClaimed(_requester, amountClaimed, block.timestamp);
    }

    function _claimInNFTs(
        address _requester,
        NFTCollectionClaimRequest[] calldata _nftCollectionClaimRequests,
        bool _withWalletRewards
    ) internal returns (uint128 amountClaimed) {
        amountClaimed = _executeClaimInNFTs(_requester, _nftCollectionClaimRequests);

        if (_withWalletRewards) {
            ClaimData storage userClaimData = usersClaimData[_requester][ClaimType.WalletRewards];
            uint128 claimable = _calculateClaimable(userClaimData, ClaimType.WalletRewards);
            if (claimable > 0) {
                /// @dev assume no overflow as the max amountClaimed amount won't exceed uint128 throughout the whole life cycle
                unchecked {
                    userClaimData.claimed += claimable;
                    amountClaimed += claimable;
                }
            }
        }
        if (amountClaimed == 0) revert NoClaimableToken();

        emit ClaimedInNFTs(_requester, amountClaimed, block.timestamp);
    }

    /// @dev Update `claimed` in usersClaimData for the given ClaimTypes
    /// @param _requester Address of the claimer
    /// @param _claimTypes Array of ClaimType to claim
    /// @return totalClaimable Amount of total claimable calculated from the given ClaimTypes
    function _executeClaim(address _requester, ClaimType[] memory _claimTypes)
        private
        returns (uint128 totalClaimable)
    {
        for (uint256 i; i < _claimTypes.length; i++) {
            ClaimData storage userClaimData = usersClaimData[_requester][_claimTypes[i]];
            uint128 claimable = _calculateClaimable(userClaimData, _claimTypes[i]);
            if (claimable > 0) {
                /// @dev assume no overflow as the max totalClaimable amount won't exceed uint128 throughout the whole life cycle
                unchecked {
                    userClaimData.claimed += claimable;
                    totalClaimable += claimable;
                }
            }
        }
    }

    /// @dev Update `airdropClaimed` AND/OR `rewardsClaimed` based on the booleans passed in nftUsersClaimData for the given NFT Collection ID and token ID(s)
    /// @param _requester Address of the claimer
    /// @param _nftCollectionClaimRequests Array of NFTCollectionClaimRequest that consists collection ID of the NFT, token ID(s) the owner owns, array of booleans to indicate NFTAirdrop/NFTRewards claim for each token ID
    /// @return totalNFTClaimable Amount of total NFT claimable calculated from the given NFT Collection ID and token ID(s)
    function _executeClaimInNFTs(address _requester, NFTCollectionClaimRequest[] calldata _nftCollectionClaimRequests)
        private
        returns (uint128 totalNFTClaimable)
    {
        for (uint256 i; i < _nftCollectionClaimRequests.length;) {
            uint256[] calldata tokenIds = _nftCollectionClaimRequests[i].tokenIds;
            bool[] calldata withNFTAirdropList = _nftCollectionClaimRequests[i].withNFTAirdropList;
            bool[] calldata withNFTRewardsList = _nftCollectionClaimRequests[i].withNFTRewardsList;
            uint256 len = tokenIds.length;
            if (len != withNFTAirdropList.length || len != withNFTRewardsList.length) {
                revert MismatchedArrays();
            }
            uint256 collectionId = _nftCollectionClaimRequests[i].collectionId;

            for (uint256 j; j < len;) {
                uint128 claimable;
                if (withNFTAirdropList[j]) {
                    claimable = _verifyNFTClaim(_requester, collectionId, tokenIds[j]);
                    if (claimable > 0) {
                        /// @dev assume no overflow as the max claimable amount won't exceed uint128
                        unchecked {
                            nftUsersClaimData[collectionId][tokenIds[j]].airdropClaimed += claimable;
                            totalNFTClaimable += claimable;
                        }
                    }
                }
                if (withNFTRewardsList[j]) {
                    claimable = _verifyNFTRewardClaim(_requester, collectionId, tokenIds[j]);
                    if (claimable > 0) {
                        unchecked {
                            nftUsersClaimData[collectionId][tokenIds[j]].rewardsClaimed += claimable;
                            totalNFTClaimable += claimable;
                        }
                    }
                }
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Verify if the caller owns the NFT, and return the correct amount of claimable token
    /// @param _requester Address of the claimer
    /// @param _collectionId Collection ID of the NFT
    /// @param _tokenId Token ID that the owner owns
    function _verifyNFTClaim(address _requester, uint256 _collectionId, uint256 _tokenId)
        private
        view
        onlyValidCollectionId(_collectionId)
        returns (uint128)
    {
        if (nftCollections[_collectionId].ownerOf(_tokenId) != _requester) revert Unauthorized();

        return _calculateNFTClaimable(nftUsersClaimData[_collectionId][_tokenId]);
    }

    function _verifyNFTRewardClaim(address _requester, uint256 _collectionId, uint256 _tokenId)
        private
        view
        onlyValidCollectionId(_collectionId)
        returns (uint128)
    {
        if (nftCollections[_collectionId].ownerOf(_tokenId) != _requester) revert Unauthorized();

        return _calculateNFTRewardsClaimable(nftUsersClaimData[_collectionId][_tokenId]);
    }

    function _calculateClaimable(ClaimData memory _userClaimdata, ClaimType _claimType)
        private
        view
        returns (uint128)
    {
        uint128 totalClaimable = _userClaimdata.totalClaimable;
        uint128 claimed = _userClaimdata.claimed;
        if (totalClaimable == 0 || claimed >= totalClaimable) return 0;
        // for WalletRewards claim will expire after _MAX_CLAIM_PERIOD has passed since claim starts
        if (_claimType == ClaimType.WalletRewards) {
            if (block.timestamp > claimStartDate + _MAX_CLAIM_PERIOD) {
                return 0;
            }
            return totalClaimable;
        }

        ClaimSchedule memory claimSchedule = claimScheduleOf[_claimType];
        uint256 numOfLockUpBPs = claimSchedule.lockUpBPs.length;
        if (numOfLockUpBPs == 0) revert InvalidClaimSetup();

        // claim will expire after the allocated $MEME are fully vested for _MAX_CLAIM_PERIOD
        if (block.timestamp > claimStartDate + _LOCK_UP_SLOT * numOfLockUpBPs * 1 days + _MAX_CLAIM_PERIOD) {
            return 0;
        }

        uint256 daysElapsed = (block.timestamp - claimStartDate) / 1 days;
        // count the cycles passed to distinguish which cycle's 180 days is elapsed
        uint256 cyclesPassed = daysElapsed / _LOCK_UP_SLOT;

        // PrivatePresale first cycle unlocked amount locks up until the start of next cycle and allows instant claim
        if (_claimType == ClaimType.PrivatePresale && daysElapsed < _LOCK_UP_SLOT) return 0;

        // Contributors has a different number of cycles, other claim types share the same one
        bool isClaimTypeFullyVested = _claimType != ClaimType.Contributors && cyclesPassed >= _END_CYCLE;
        bool isContributorFullyVested = _claimType == ClaimType.Contributors && cyclesPassed >= _END_CYCLE_CONTRIBUTORS;
        if (isClaimTypeFullyVested || isContributorFullyVested) {
            return _calculateRemainClaimable(totalClaimable, claimed);
        }

        // cyclesPassed + 1 because we want to calculate the current cycle's (with < 180 days elapsed) unlocked amount
        return _calculateRemainClaimable(
            _calculateUnlockedAmount(claimSchedule, numOfLockUpBPs, totalClaimable, cyclesPassed + 1, daysElapsed),
            claimed
        );
    }

    function _calculateNFTClaimable(NFTClaimData memory _nftUserClaimdata) private view returns (uint128) {
        uint256 currentNFTUnlockedBP_ = currentNFTUnlockedBP;
        if (currentNFTUnlockedBP_ == 0) return 0;

        // claim will expire after the allocated $MEME are fully vested for _MAX_CLAIM_PERIOD
        if (currentNFTUnlockedBP_ == _BASIS_POINTS) {
            if (block.timestamp > currentNFTUnlockTimestamp + _MAX_CLAIM_PERIOD) {
                return 0;
            }
        }

        uint128 airdropTotalClaimable = _nftUserClaimdata.airdropTotalClaimable;
        uint128 airdropClaimed = _nftUserClaimdata.airdropClaimed;
        if (airdropTotalClaimable == 0 || airdropClaimed >= airdropTotalClaimable) return 0;

        return _calculateRemainClaimable(_calculateNFTUnlockedAmount(airdropTotalClaimable), airdropClaimed);
    }

    function _calculateNFTRewardsClaimable(NFTClaimData memory _nftUserClaimdata) private view returns (uint128) {
        uint128 rewardsTotalClaimable = _nftUserClaimdata.rewardsTotalClaimable;
        uint128 rewardsClaimed = _nftUserClaimdata.rewardsClaimed;
        if (rewardsTotalClaimable == 0 || rewardsClaimed >= rewardsTotalClaimable) return 0;

        // claim will expire after the allocated $MEME are fully vested for _MAX_CLAIM_PERIOD
        if (block.timestamp > claimStartDate + _MAX_CLAIM_PERIOD) {
            return 0;
        }

        return _calculateRemainClaimable(rewardsTotalClaimable, rewardsClaimed);
    }

    function _calculateRemainClaimable(uint128 _totalClaimable, uint128 _claimed) private pure returns (uint128) {
        /// @dev assume no underflow because we already return zero when _claimed is >= _totalClaimable
        unchecked {
            return _totalClaimable <= _claimed ? 0 : _totalClaimable - _claimed;
        }
    }

    function _calculateUnlockedAmount(
        ClaimSchedule memory _claimSchedule,
        uint256 _numOfLockUpBPs,
        uint128 _totalClaimable,
        uint256 _currentCycle,
        uint256 _daysElapsed
    ) private pure returns (uint128) {
        if (_currentCycle < _claimSchedule.startCycle) return 0;

        if (_currentCycle > _numOfLockUpBPs) return _totalClaimable;

        // _currentCycle == _numOfLockUpBPs means _currentCycle is the last one
        uint256 currentUnlockedBP =
            _currentCycle == _numOfLockUpBPs ? _BASIS_POINTS : _claimSchedule.lockUpBPs[_currentCycle];

        return _calculateUnlockedAmountByDaysElapsed(
            _totalClaimable,
            _claimSchedule.lockUpBPs[_currentCycle - 1],
            currentUnlockedBP,
            _daysElapsed % _LOCK_UP_SLOT
        );
    }

    function _calculateUnlockedAmountByDaysElapsed(
        uint128 _totalClaimable,
        uint256 _previousUnlockedBP,
        uint256 _currentUnlockedBP,
        uint256 _daysElapsedForCurrentCycle
    ) private pure returns (uint128) {
        if (_daysElapsedForCurrentCycle == 0) {
            return _toUint128(_totalClaimable * _previousUnlockedBP / _BASIS_POINTS);
        }

        return _toUint128(
            _totalClaimable * _previousUnlockedBP / _BASIS_POINTS
                + _totalClaimable * (_currentUnlockedBP - _previousUnlockedBP) * _daysElapsedForCurrentCycle / _BASIS_POINTS
                    / _LOCK_UP_SLOT
        );
    }

    function _calculateNFTUnlockedAmount(uint128 _totalClaimable) private view returns (uint128) {
        return block.timestamp < currentNFTUnlockTimestamp
            ? _toUint128(_totalClaimable * previousNFTUnlockedBP / _BASIS_POINTS)
            : _toUint128(_totalClaimable * currentNFTUnlockedBP / _BASIS_POINTS);
    }

    function _toUint128(uint256 value) private pure returns (uint128) {
        if (value >= 1 << 128) revert Uint128Overflow();
        return uint128(value);
    }

    // ====================
    // Validation Modifiers
    // ====================

    modifier onlyUpgrader() {
        if (_msgSender() != upgrader) revert Unauthorized();
        _;
    }

    modifier onlyMultiClaim() {
        if (_msgSender() != multiClaim) revert Unauthorized();
        _;
    }

    modifier onlyClaimNotOpen() {
        if (claimActive) revert ClaimNotClosed();
        _;
    }

    modifier onlyValidClaimSetup() {
        if (!claimActive || claimStartDate == 0 || block.timestamp < claimStartDate) revert ClaimNotAvailable();
        if (address(claimToken) == address(0)) revert ClaimTokenZeroAddress();
        _;
    }

    modifier onlyValidCollectionId(uint256 _collectionId) {
        if (_collectionId >= nftCollections.length) revert InvalidCollectionId();
        _;
    }

    // ==============
    // Claimable Settings
    // ==============

    /// @dev Set `totalClaimable` in usersClaimData for claim type(s)
    /// @param _addresses Array of addresses eligible for the claim
    /// @param _claimables Array of amounts of claim token
    /// @param _claimTypes Array of ClaimType
    function setClaimables(
        address[] calldata _addresses,
        uint128[] calldata _claimables,
        ClaimType[] calldata _claimTypes
    ) external onlyOwner {
        uint256 len = _addresses.length;
        if (len != _claimables.length || len != _claimTypes.length) revert MismatchedArrays();

        for (uint256 i; i < len;) {
            usersClaimData[_addresses[i]][_claimTypes[i]].totalClaimable = _claimables[i];
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Set `airdropTotalClaimable` and `rewardsTotalClaimable` in nftUsersClaimData for token ID(s) of respective collection ID
    /// @param _nftClaimables Array of NFTClaimable which consists of collectionId, tokenId and amount of claim token
    function setNFTClaimables(NFTClaimable[] calldata _nftClaimables) external onlyOwner {
        for (uint256 i; i < _nftClaimables.length;) {
            uint256 collectionId = _nftClaimables[i].collectionId;
            uint256 tokenId = _nftClaimables[i].tokenId;
            uint128 airdropAmount = _nftClaimables[i].airdropTotalClaimable;
            uint128 rewardsAmount = _nftClaimables[i].rewardsTotalClaimable;

            nftUsersClaimData[collectionId][tokenId].airdropTotalClaimable = airdropAmount;
            nftUsersClaimData[collectionId][tokenId].rewardsTotalClaimable = rewardsAmount;
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Add new unlock percentage in Basis Points(BP) for NFT holders to instant claim until _BASIS_POINTS is reached
    /// @param _additionalNFTUnlockedBP Additional unlocked BP, only add up the currentNFTUnlockedBP
    /// @param _newUnlockTimestamp Timestamp for new unlocked BP to take effect
    function addNFTUnlockedBPAndSetUnlockTs(uint64 _additionalNFTUnlockedBP, uint128 _newUnlockTimestamp)
        external
        onlyOwner
    {
        uint64 currentNFTUnlockedBP_ = currentNFTUnlockedBP;
        uint128 currentNFTUnlockTimestamp_ = currentNFTUnlockTimestamp;
        if (
            _additionalNFTUnlockedBP == 0 || currentNFTUnlockedBP_ + _additionalNFTUnlockedBP > _BASIS_POINTS
                || _newUnlockTimestamp <= currentNFTUnlockTimestamp_
        ) revert InvalidClaimSetup();
        previousNFTUnlockedBP = currentNFTUnlockedBP_;
        currentNFTUnlockTimestamp = _newUnlockTimestamp;
        currentNFTUnlockedBP += _additionalNFTUnlockedBP;
    }

    /// @dev Set the unclaimedNFTRewards mapping in order to withdraw unclaimed NFTRewards after they are expired
    /// @param _collectionId Respective collection ID with unclaimed NFTRewards
    /// @param _unclaimTokenIds Array of token IDs with NFTRewards that are left unclaimed
    function setUnclaimedNFTRewards(uint256 _collectionId, uint128[] calldata _unclaimTokenIds)
        external
        onlyValidCollectionId(_collectionId)
        onlyOwner
    {
        if (block.timestamp <= claimStartDate + _MAX_CLAIM_PERIOD) revert NFTRewardsNotExpired();

        UnclaimedNFTRewards storage _unclaimedNftRewards = unclaimedNftRewards[_collectionId];
        uint256 len = _unclaimTokenIds.length;
        if (len == 0 || _unclaimedNftRewards.lastTokenId > _unclaimTokenIds[0]) revert InvalidWithdrawalSetup();

        uint128 totalRewardsUnclaimed;
        for (uint256 i; i < len;) {
            // ensure the next tokenId is bigger than the prev one
            if (i != 0) {
                if (_unclaimTokenIds[i] < _unclaimTokenIds[i - 1]) revert InvalidWithdrawalSetup();
            }
            NFTClaimData memory nftUserClaimData = nftUsersClaimData[_collectionId][_unclaimTokenIds[i]];
            uint128 rewardsUnclaimed = nftUserClaimData.rewardsTotalClaimable - nftUserClaimData.rewardsClaimed;
            if (rewardsUnclaimed > 0) totalRewardsUnclaimed += rewardsUnclaimed;
            unchecked {
                ++i;
            }
        }
        _unclaimedNftRewards.lastTokenId = _unclaimTokenIds[len - 1];
        _unclaimedNftRewards.totalUnclaimed += totalRewardsUnclaimed;
    }

    /// @dev Set `airdropTotalClaimable` in nftUsersClaimData specifically for single token ID of a newly revelaed Captainz
    /// @param _tokenId Token ID of the newly revealed Captainz
    /// @param _additionalAirdropTotalClaimable Additional airdropTotalClaimable, only add up since a base amount will be set for unrevealed Captainz
    function setRevealedCaptainzClaimable(uint256 _tokenId, uint128 _additionalAirdropTotalClaimable)
        external
        onlyOwner
    {
        nftUsersClaimData[1][_tokenId].airdropTotalClaimable += _additionalAirdropTotalClaimable;
    }

    // ==============
    // Claim Settings
    // ==============

    /// @dev Deposit claim token to contract and start the claim, to be called ONCE only
    /// @param _tokenAmount Amount of claim token to be deposited
    /// @param _claimStartDate Unix timestamp of the claim start date
    function depositClaimTokenAndStartClaim(uint256 _tokenAmount, uint256 _claimStartDate) external onlyOwner {
        if (claimTokenDeposited) revert AlreadyDeposited();
        if (address(claimToken) == address(0)) revert ClaimTokenZeroAddress();
        if (_tokenAmount == 0) revert InvalidClaimSetup();
        if (_claimStartDate == 0) revert InvalidClaimSetup();

        claimToken.safeTransferFrom(_msgSender(), address(this), _tokenAmount);
        claimStartDate = _claimStartDate;
        claimActive = true;
        claimTokenDeposited = true;

        emit ClaimTokenDepositedAndClaimStarted(_tokenAmount, _claimStartDate);
    }

    /// @dev Withdraw claim token from contract only when claim is not open
    /// @param _receiver Address to receive the token
    /// @param _amount Amount of claim token to be withdrawn
    function withdrawClaimToken(address _receiver, uint256 _amount) external onlyOwner onlyClaimNotOpen {
        if (address(claimToken) == address(0)) revert ClaimTokenZeroAddress();

        claimToken.safeTransfer(_receiver, _amount);
    }

    /// @dev Withdraw unclaimed NFTRewards after they are expired when _MAX_CLAIM_PERIOD has passed since claim starts, to be called ONCE only
    /// @param _receiver Address to receive the token
    function withdrawUnclaimedNFTRewards(address _receiver) external onlyOwner {
        if (unclaimedNFTRewardsWithdrawn) revert AlreadyWithdrawn();
        if (block.timestamp <= claimStartDate + _MAX_CLAIM_PERIOD) revert NFTRewardsNotExpired();
        if (_receiver == address(0)) revert InvalidWithdrawalSetup();

        uint256 totalWithdrawn;
        for (uint256 i; i < nftCollections.length;) {
            UnclaimedNFTRewards storage _unclaimedNftRewards = unclaimedNftRewards[i];

            uint128 unclaimed = _unclaimedNftRewards.totalUnclaimed;
            if (unclaimed > 0) {
                claimToken.safeTransfer(_receiver, unclaimed);
                totalWithdrawn += unclaimed;
            }
            unchecked {
                ++i;
            }
        }
        unclaimedNFTRewardsWithdrawn = true;

        emit UnclaimedNFTRewardsWithdrawn(totalWithdrawn, block.timestamp);
    }

    /// @dev Set claim schedule(s) for claim type(s)
    /// @param _claimTypes Array of ClaimType
    /// @param _claimSchedules Array of ClaimSchedule for each claim type
    function setClaimSchedules(ClaimType[] calldata _claimTypes, ClaimSchedule[] calldata _claimSchedules)
        external
        onlyOwner
        onlyClaimNotOpen
    {
        uint256 len = _claimSchedules.length;
        if (_claimTypes.length != len) revert MismatchedArrays();
        for (uint256 i; i < len;) {
            uint256[] memory lockUpBPs = _claimSchedules[i].lockUpBPs;
            for (uint256 j; j < lockUpBPs.length;) {
                if (lockUpBPs[j] > _BASIS_POINTS) revert InvalidClaimSetup();
                // ensure the accumulated lockupBP is bigger than the prev one
                if (j != 0) {
                    if (lockUpBPs[j] < lockUpBPs[j - 1]) revert InvalidClaimSetup();
                }
                unchecked {
                    ++j;
                }
            }
            claimScheduleOf[_claimTypes[i]] = _claimSchedules[i];
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Start/stop the claim
    /// @param _claimActive New boolean to indicate active or not
    function setClaimActive(bool _claimActive) external onlyOwner {
        claimActive = _claimActive;

        emit ClaimStatusUpdated(_claimActive);
    }

    /// @dev Set the new claim start date, allow flexibility on setting as past date to unlock claim earlier
    /// @param _claimStartDate New date to start the claim
    function setClaimStartDate(uint256 _claimStartDate) external onlyOwner {
        claimStartDate = _claimStartDate;
    }

    /// @dev Set the new MultiClaim contract address
    /// @param _multiClaim New MultiClaim contract address
    function setMultiClaimAddress(address _multiClaim) external onlyOwner {
        multiClaim = _multiClaim;
    }

    /// @dev Set the new UUPS proxy upgrader, allow setting address(0) to disable upgradeability
    /// @param _upgrader New upgrader
    function setUpgrader(address _upgrader) external onlyOwner {
        if (upgraderRenounced) revert UpgraderRenounced();
        upgrader = _upgrader;

        emit UpgraderUpdated(_upgrader);
    }

    /// @notice Renounce the upgradibility of this contract
    function renounceUpgrader() external onlyOwner {
        if (upgraderRenounced) revert UpgraderRenounced();

        upgraderRenounced = true;
        upgrader = address(0);

        emit UpgraderUpdated(address(0));
    }

    // =======
    // Getters
    // =======

    /// @notice Get claim info of a user after claim starts
    /// @param _user Address of user
    /// @return claimableAmount Amount of claimable tokens for a user
    /// @return claimableExpiry Timestamp of the claim expiry date for the respective _claimType
    function getClaimInfo(address _user, ClaimType _claimType)
        public
        view
        onlyValidClaimSetup
        returns (uint128 claimableAmount, uint256 claimableExpiry)
    {
        uint256 numOfLockUpBPs = claimScheduleOf[_claimType].lockUpBPs.length;

        claimableAmount = _calculateClaimable(usersClaimData[_user][_claimType], _claimType);
        claimableExpiry = _claimType == ClaimType.WalletRewards
            ? claimStartDate + _MAX_CLAIM_PERIOD
            : claimStartDate + _LOCK_UP_SLOT * numOfLockUpBPs * 1 days + _MAX_CLAIM_PERIOD;
    }

    /// @notice Get claim info of one eligible NFT after claiming starts
    /// @param _collectionId Address of the eligible NFT
    /// @param _tokenId Token ID that the owner owns
    /// @return claimableAmount Amount of claimable tokens for the NFT
    /// @return claimableExpiry Timestamp of the claim expiry date for NFT airdrop
    function getClaimInfoByNFT(uint256 _collectionId, uint256 _tokenId)
        public
        view
        onlyValidClaimSetup
        onlyValidCollectionId(_collectionId)
        returns (uint128 claimableAmount, uint256 claimableExpiry)
    {
        NFTClaimData memory nftUserClaimData = nftUsersClaimData[_collectionId][_tokenId];

        claimableAmount = _calculateNFTClaimable(nftUserClaimData);
        claimableExpiry = currentNFTUnlockedBP == _BASIS_POINTS ? currentNFTUnlockTimestamp + _MAX_CLAIM_PERIOD : 0;
    }

    /// @notice Get rewards claim info of one eligible NFT after claiming starts
    /// @param _collectionId Address of the eligible NFT
    /// @param _tokenId Token ID that the owner owns
    /// @return claimableAmount Amount of claimable tokens for the NFT
    /// @return claimableExpiry Timestamp of the claim expiry date for NFT rewards
    function getRewardsClaimInfoByNFT(uint256 _collectionId, uint256 _tokenId)
        public
        view
        onlyValidClaimSetup
        onlyValidCollectionId(_collectionId)
        returns (uint128 claimableAmount, uint256 claimableExpiry)
    {
        NFTClaimData memory nftUserClaimData = nftUsersClaimData[_collectionId][_tokenId];

        claimableAmount = _calculateNFTRewardsClaimable(nftUserClaimData);
        claimableExpiry = claimStartDate + _MAX_CLAIM_PERIOD;
    }

    /// @notice Get total amounts of claimable tokens of multiple tokenIds in one eligible collection after claiming starts
    /// @param _collectionId ID of NFT collection
    /// @param _tokenIds Array of all token IDs the owner owns in that collection
    function getTotalClaimableAmountsByNFTs(uint256 _collectionId, uint256[] calldata _tokenIds)
        public
        view
        returns (uint128 totalClaimable)
    {
        for (uint256 i; i < _tokenIds.length; i++) {
            (uint128 claimable,) = getClaimInfoByNFT(_collectionId, _tokenIds[i]);
            if (claimable == 0) continue;

            totalClaimable += claimable;
        }
    }

    /// @notice Get user claim data of multiple tokenIds in multiple eligible collections
    /// @param _nftCollectionsInfo Array of NFTCollectionInfo with collectionId and tokenId(s)
    /// @return collectionClaimInfo Array of CollectionClaimData that includes claim data for each tokenId of respective collection
    function getUserClaimDataByCollections(NFTCollectionInfo[] calldata _nftCollectionsInfo)
        public
        view
        returns (CollectionClaimData[] memory collectionClaimInfo)
    {
        uint256 numOfTokenIds;
        uint256 len = _nftCollectionsInfo.length;
        for (uint256 i = 0; i < len; i++) {
            numOfTokenIds += _nftCollectionsInfo[i].tokenIds.length;
        }
        collectionClaimInfo = new CollectionClaimData[](numOfTokenIds);
        uint256 activeId = 0;
        for (uint256 i; i < len; i++) {
            uint256 collectionId = _nftCollectionsInfo[i].collectionId;
            uint256[] memory tokenIds = _nftCollectionsInfo[i].tokenIds;
            for (uint256 j; j < tokenIds.length; j++) {
                (uint128 airdropClaimable, uint256 airdropClaimableExpiry) =
                    getClaimInfoByNFT(collectionId, tokenIds[j]);
                (uint128 rewardsClaimable, uint256 rewardClaimableExpiry) =
                    getRewardsClaimInfoByNFT(collectionId, tokenIds[j]);
                collectionClaimInfo[activeId++] = CollectionClaimData(
                    collectionId,
                    tokenIds[j],
                    airdropClaimable,
                    airdropClaimableExpiry,
                    nftUsersClaimData[collectionId][tokenIds[j]].airdropTotalClaimable,
                    nftUsersClaimData[collectionId][tokenIds[j]].airdropClaimed,
                    rewardsClaimable,
                    rewardClaimableExpiry,
                    nftUsersClaimData[collectionId][tokenIds[j]].rewardsTotalClaimable,
                    nftUsersClaimData[collectionId][tokenIds[j]].rewardsClaimed
                );
            }
        }
    }

    /// @notice Get the claim schedule of a certain claim type
    function getClaimSchedule(ClaimType _claimType) public view returns (ClaimSchedule memory) {
        return claimScheduleOf[_claimType];
    }
}
