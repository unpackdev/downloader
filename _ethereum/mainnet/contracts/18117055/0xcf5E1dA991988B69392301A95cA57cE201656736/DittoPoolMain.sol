// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import "./Math.sol";
import "./OwnerTwoStep.sol";
import "./LpNft.sol";
import "./IOwnerTwoStep.sol";
import "./IDittoPool.sol";
import "./IDittoPoolFactory.sol";
import "./IPermitter.sol";
import "./FactoryTemplates.sol";
import "./LpIdToTokenBalance.sol";
import "./ERC20.sol";
import { ReentrancyGuard } from
    "../../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "./IERC721.sol";
import { EnumerableSet } from
    "../../lib/openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import { EnumerableMap } from
    "../../lib/openzeppelin-contracts/contracts/utils/structs/EnumerableMap.sol";

/**
 * @title DittoPool
 * @notice Contract that defines basic pool functionality used in DittoPoolMarketMake and DittoPoolTrade contracts
 * @notice Also defines admin functions for changing pool variables
 */
abstract contract DittoPoolMain is OwnerTwoStep, IDittoPool, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToUintMap;

    ///@dev Indication of whether or not this pool has more than one possible liquidity provider
    bool internal _isPrivatePool;
    ///@dev The ID of the LP Position that owns the pool if it is a private pool
    uint256 public _privatePoolOwnerLpId;

    ///@dev The full list of NFT ids owned by this pool that the pool is tracking. 
    EnumerableSet.UintSet internal _poolOwnedNftIds;

    ///@dev Stores which Lp Position owns which NFT in the pool
    mapping(uint256 => uint256) internal _nftIdToLpId;

    ///@dev Stores how many NFTs each Lp Position owns in the pool
    mapping(uint256 => uint256) internal _lpIdToNftBalance;

    ///@dev Stores how much erc20 liquidity that a given Lp Position owns within the pool.
    ///@dev Also stores list of all LP Position Token IDs representing liquidity in this specific DittoPool:
    ///   a position that has 0 tokens will return 0 but still will be included in .tryGet, .contains() and .length()
    EnumerableMap.UintToUintMap internal _lpIdToTokenBalance;

    ///@dev LP Position NFT contract that tokenizes liquidity provisions in the protocol
    LpNft internal _lpNft;
    ///@dev Permitter contract that decides which NFT tokenIds are permitted in this pool. If not set, all ids allowed
    IPermitter internal _permitter;

    ///@dev flag to prevent pool variables from being set multiple times. Pack with previous address.
    bool internal _initialized;

    ///@dev The ERC721 collection stored in this pool
    IERC721 internal _nft;
    ///@dev The ERC20 collection stored in this pool
    ERC20 internal _token;
    ///@dev The DittoPoolFactory contract that created this pool. Used to fetch up to date protocol fee values
    IDittoPoolFactory internal _dittoPoolFactory;

    ///@dev The fee charged by and paid to the administrator of this pool on each trade. Packed with previous address.
    uint96 internal _feeAdmin;

    ///@dev The recipient address of admin fee.
    address internal _adminFeeRecipient;

    ///@dev The lp fee charged on trades and provided to the liquidit provider. Packed with previous address.
    uint96 internal _feeLp;

    ///@dev A variable used differently by each bonding curve type to update the price after each trade
    uint128 internal _delta;
    ///@dev The current price of the pool, used differently by each bonding curve type
    uint128 internal _basePrice;

    ///@dev the maximum permissible admin fee and Lp value (both capped at 10%)
    uint96 internal constant MAX_FEE = 0.10e18;

    ///@dev which DittoPoolTemplate address was used when creating this pool
    address internal _template;

    // ***************************************************************
    // * ========================= EVENTS ========================== *
    // ***************************************************************
    event DittoPoolMainPoolInitialized(address template, address lpNft, address permitter);
    event DittoPoolMainAdminChangedBasePrice(uint128 newBasePrice);
    event DittoPoolMainAdminChangedDelta(uint128 newDelta);
    event DittoPoolMainAdminChangedAdminFeeRecipient(address adminFeeRecipient);
    event DittoPoolMainAdminChangedAdminFee(uint256 newAdminFee);
    event DittoPoolMainAdminChangedLpFee(uint256 newLpFee);

    // ***************************************************************
    // * ========================= ERRORS ========================== *
    // ***************************************************************

    error DittoPoolMainInvalidAdminFeeRecipient();
    error DittoPoolMainInvalidPermitterData();
    error DittoPoolMainAlreadyInitialized();
    error DittoPoolMainInvalidBasePrice(uint128 basePrice);
    error DittoPoolMainInvalidDelta(uint128 delta);
    error DittoPoolMainInvalidOwnerOperation();
    error DittoPoolMainNoDirectNftTransfers();
    error DittoPoolMainInvalidMsgSender();
    error DittoPoolMainInvalidFee();

    // ***************************************************************
    // * ================ OWNERSHIP FUNCTIONS ====================== *
    // ***************************************************************

    ///@inheritdoc OwnerTwoStep
    function owner() public view virtual override(IOwnerTwoStep, OwnerTwoStep) returns (address) {
        if(_isPrivatePool) {
            return _lpNft.ownerOf(_privatePoolOwnerLpId);
        }
        return OwnerTwoStep.owner();
    }

    ///@inheritdoc OwnerTwoStep
    function _onlyOwner() internal view override(OwnerTwoStep) {
        if(msg.sender != owner()) {
            revert DittoPoolMainInvalidMsgSender();
        }
    }

    ///@inheritdoc OwnerTwoStep
    function acceptOwnership() public override (IOwnerTwoStep, OwnerTwoStep) nonReentrant onlyPendingOwner {
        if(_isPrivatePool) {
            revert DittoPoolMainInvalidOwnerOperation();
        }
        super.acceptOwnership();
        _lpNft.emitMetadataUpdateForAll();
    }

    // ***************************************************************
    // * ============= CONSTRUCTOR AND MODIFIERS =================== *
    // ***************************************************************

    /**
     * @inheritdoc IDittoPool
     */
    function initPool(
        PoolTemplate calldata params_,
        address template_,
        LpNft lpNft_,
        IPermitter permitter_
    ) external {
        // CHECK PRECONDITIONS
        if (_initialized) {
            revert DittoPoolMainAlreadyInitialized();
        }
        _initialized = true;

        // SET STATE
        _isPrivatePool = params_.isPrivatePool;
        _nft = IERC721(params_.nft);
        _token = ERC20(params_.token);
        _lpNft = lpNft_;
        _permitter = permitter_;
        _changeFeeLp(params_.feeLp);
        _changeFeeAdmin(params_.feeAdmin);
        _adminChangeDelta(params_.delta);
        _adminChangeBasePrice(params_.basePrice);
        _transferOwnership(params_.owner);
        _adminFeeRecipient = params_.owner;
        _dittoPoolFactory = IDittoPoolFactory(msg.sender);
        _template = template_;

        _initializeCustomPoolData(params_.templateInitData);

        emit DittoPoolMainPoolInitialized(template_, address(lpNft_), address(permitter_));
    }

    // ***************************************************************
    // * =============== ADMINISTRATIVE FUNCTIONS ================== *
    // ***************************************************************

    ///@inheritdoc IDittoPool
    function changeBasePrice(uint128 newBasePrice_) external virtual onlyOwner {
        _adminChangeBasePrice(newBasePrice_);
    }

    ///@inheritdoc IDittoPool
    function changeDelta(uint128 newDelta_) external virtual onlyOwner {
        _adminChangeDelta(newDelta_);
    }

    ///@inheritdoc IDittoPool
    function changeLpFee(uint96 newFeeLp_) external onlyOwner {
        _changeFeeLp(newFeeLp_);
    }

    ///@inheritdoc IDittoPool
    function changeAdminFee(uint96 newFeeAdmin_) external onlyOwner {
        _changeFeeAdmin(newFeeAdmin_);
    }

    ///@inheritdoc IDittoPool
    function changeAdminFeeRecipient(address newAdminFeeRecipient_) external onlyOwner {
        if (newAdminFeeRecipient_ == address(0)) {
            revert DittoPoolMainInvalidAdminFeeRecipient();
        }

        _adminFeeRecipient = newAdminFeeRecipient_;

        emit DittoPoolMainAdminChangedAdminFeeRecipient(newAdminFeeRecipient_);
    }

    // ***************************************************************
    // * ======= EXTERNALLY CALLABLE READ-ONLY VIEW FUNCTIONS ====== *
    // ***************************************************************

    ///@inheritdoc IDittoPool
    function isPrivatePool() external view returns (bool isPrivatePool_) {
        isPrivatePool_ = _isPrivatePool;
    }

    ///@inheritdoc IDittoPool
    function initialized() external view returns (bool) {
        return _initialized;
    }

    ///@inheritdoc IDittoPool
    function template() external view returns (address) {
        return _template;
    }

    ///@inheritdoc IDittoPool
    function adminFee() external view returns (uint96 feeAdmin_) {
        feeAdmin_ = _feeAdmin;
    }

    ///@inheritdoc IDittoPool
    function lpFee() external view returns (uint96 feeLp_) {
        feeLp_ = _feeLp;
    }

    ///@inheritdoc IDittoPool
    function protocolFee() external view returns (uint256 feeProtocol_) {
        feeProtocol_ = _dittoPoolFactory.getProtocolFee();
    }

    ///@inheritdoc IDittoPool
    function fee() public view returns (uint256 fee_) {
        fee_ = _feeLp + _feeAdmin + _dittoPoolFactory.getProtocolFee();
    }

    ///@inheritdoc IDittoPool
    function delta() external view returns (uint128) {
        return _delta;
    }

    ///@inheritdoc IDittoPool
    function basePrice() external view returns (uint128) {
        return _basePrice;
    }

    ///@inheritdoc IDittoPool
    function dittoPoolFactory() external view returns (address) {
        return address(_dittoPoolFactory);
    }

    ///@inheritdoc IDittoPool
    function adminFeeRecipient() external view returns (address) {
        return _adminFeeRecipient;
    }

    ///@inheritdoc IDittoPool
    function getLpNft() external view returns (address) {
        return address(_lpNft);
    }

    ///@inheritdoc IDittoPool
    function nft() external view returns (IERC721) {
        return _nft;
    }

    ///@inheritdoc IDittoPool
    function token() external view returns (address) {
        return address(_token);
    }

    ///@inheritdoc IDittoPool
    function permitter() public view returns (IPermitter) {
        return _permitter;
    }

    ///@inheritdoc IDittoPool
    function getTokenBalanceForLpId(uint256 lpId_) public view returns (uint256 tokenBalance) {
        (, tokenBalance) = _lpIdToTokenBalance.tryGet(lpId_);
    }

    ///@inheritdoc IDittoPool
    function getNftIdsForLpId(uint256 lpId_) public view returns (uint256[] memory nftIds) {
        nftIds = new uint256[](_lpIdToNftBalance[lpId_]);

        uint256 nftId;
        uint256 nftIdIndex;
        uint256 countOwnedNftIds = _poolOwnedNftIds.length();

        for (uint256 i = 0; i < countOwnedNftIds;) {
            nftId = _poolOwnedNftIds.at(i);
            if (lpId_ == _nftIdToLpId[nftId]) {
                nftIds[nftIdIndex] = nftId;
                unchecked {
                    ++nftIdIndex;
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    ///@inheritdoc IDittoPool
    function getNftCountForLpId(uint256 lpId_) public view returns (uint256) {
        return _lpIdToNftBalance[lpId_];
    }

    ///@inheritdoc IDittoPool
    function getTotalBalanceForLpId(uint256 lpId_)
        public
        view
        returns (uint256 tokenBalance, uint256 nftBalance)
    {
        (, tokenBalance) = _lpIdToTokenBalance.tryGet(lpId_);
        nftBalance = _lpIdToNftBalance[lpId_];
    }

    ///@inheritdoc IDittoPool
    function getLpIdForNftId(uint256 nftId_) public view returns (uint256 lpId) {
        lpId = _nftIdToLpId[nftId_];
    }

    ///@inheritdoc IDittoPool
    function getAllPoolHeldNftIds() external view returns (uint256[] memory) {
        return _poolOwnedNftIds.values();
    }

    ///@inheritdoc IDittoPool
    function getPoolTotalNftBalance() external view returns (uint256) {
        return _poolOwnedNftIds.length();
    }

    ///@inheritdoc IDittoPool
    function getAllPoolLpIds() external view returns (uint256[] memory lpIds) {
        uint256 countLpIds = _lpIdToTokenBalance.length();
        lpIds = new uint256[](countLpIds);

        for (uint256 i = 0; i < countLpIds;) {
            (lpIds[i],) = _lpIdToTokenBalance.at(i);
            unchecked {
                ++i;
            }
        }
    }

    ///@inheritdoc IDittoPool
    function getPoolTotalTokenBalance() external view returns (uint256 totalTokenBalance) {
        uint256 countLpIds = _lpIdToTokenBalance.length();
        uint256 tokenBalance;
        for (uint256 i = 0; i < countLpIds;) {
            (, tokenBalance) = _lpIdToTokenBalance.at(i);
            totalTokenBalance += tokenBalance;
            unchecked {
                ++i;
            }
        }
    }

    ///@inheritdoc IDittoPool
    function getAllLpIdTokenBalances()
        external
        view
        returns (LpIdToTokenBalance[] memory balances)
    {
        uint256 countLpIds = _lpIdToTokenBalance.length();
        balances = new LpIdToTokenBalance[](countLpIds);

        for (uint256 i = 0; i < countLpIds;) {
            (balances[i].lpId, balances[i].tokenBalance) = _lpIdToTokenBalance.at(i);
            unchecked {
                ++i;
            }
        }
    }

    // ***************************************************************
    // * ============= INTERNAL HELPER FUNCTIONS =================== *
    // ***************************************************************

    /**
     * @dev multiply two values that are scaled by 1e18
     */
    function _mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return Math.mulDiv(a, b, 1e18);
    }

    /**
     * @notice check if the tokens being added to the pool are permitted to be added 
     * @param tokenIds_ the token ids to check
     * @param permitterData_ data to pass to permitter for determining validity (e.g. merkle proofs)
     */
    function _checkPermittedTokens(
        uint256[] calldata tokenIds_,
        bytes calldata permitterData_
    ) internal view {
        if (
            address(_permitter) != address(0)
            && !_permitter.checkPermitterData(tokenIds_, permitterData_)
        ) {
            revert DittoPoolMainInvalidPermitterData();
        }
    }

    /**
     * @notice A function to be called to change the _feeAdmin state variable
     * @param newFeeAdmin_ The proposedvalue.
     */
    function _changeFeeAdmin(uint96 newFeeAdmin_) internal virtual {
        _requireValidFee(newFeeAdmin_);
        _feeAdmin = newFeeAdmin_;
        emit DittoPoolMainAdminChangedAdminFee(newFeeAdmin_);
    }

    /**
     * @notice A function to be called to change the _feeLp state variable
     * @param newFeeLp_ The proposed value.
     */
    function _changeFeeLp(uint96 newFeeLp_) internal virtual {
        _requireValidFee(newFeeLp_);
        _feeLp = newFeeLp_;
        emit DittoPoolMainAdminChangedLpFee(newFeeLp_);
    }

    /**
     * @dev Ensure the proosed admin fee is below the max threshold (0.10e18)
     */
    function _requireValidFee(uint96 fee_) internal pure {
        if (fee_ > MAX_FEE) {
            revert DittoPoolMainInvalidFee();
        }
    }

    /**
     * @notice Helper function to change the base price of the pool used by extending contracts
     * @param newBasePrice_ The new base price to set
     */
    function _changeBasePrice(uint128 newBasePrice_) internal {
        if (_invalidBasePrice(newBasePrice_)) {
            revert DittoPoolMainInvalidBasePrice(newBasePrice_);
        }
        _basePrice = newBasePrice_;
    }

    /**
     * @notice Helper function to update the pool's basePrice and log
     * 
     * @param newBasePrice_ The new base price to set
     */
    function _adminChangeBasePrice(uint128 newBasePrice_) internal {
        _changeBasePrice(newBasePrice_);

        emit DittoPoolMainAdminChangedBasePrice(newBasePrice_);
    }

    /**
     * @notice Helper function to change the delta of the pool used by extending contracts
     * @param newDelta_ The new delta to set
     */
    function _changeDelta(uint128 newDelta_) internal {
        if (_invalidDelta(newDelta_)) {
            revert DittoPoolMainInvalidDelta(newDelta_);
        }
        _delta = newDelta_;
    }

    /**
     * @notice Helper function to update the pool's delta and log
     * 
     * @param newDelta_ The new delta to set
     */
    function _adminChangeDelta(uint128 newDelta_) internal {
        _changeDelta(newDelta_);

        emit DittoPoolMainAdminChangedDelta(newDelta_);
    }

    // ***************************************************************
    // * ================== CURVE CUSTOM HOOKS ===================== *
    // ***************************************************************

    /**
     * @notice A function to be called when the pool is initialized. Each curve type
     *   can choose to override this function to introduce custom behavior. 
     */
    function _initializeCustomPoolData(bytes calldata /*templateInitData*/) internal virtual { }

    /**
     * @notice A function to be called when nft liquidity is added. Each curve type
     *   can choose to override this function to introduce custom behavior.
     * @param count_ The count of nft liquidity added.
     */
    function _nftLiquidityAdded(uint256 count_) internal virtual { }

    /**
     * @notice A function to be called when nft liquidity is removed. Each curve type
     *   can choose to override this function to introduce custom behavior.
     * @param count_ The count of nft liquidity removed.
     */
    function _nftLiquidityRemoved(uint256 count_) internal virtual { }

    /**
     * @notice A function to be called when token liquidity is added. Each curve type
     *   can choose to override this function to introduce custom behavior.
     * @param count_ The count of token liquidity added.
     */
    function _tokenLiquidityAdded(uint256 count_) internal virtual { }

    /**
     * @notice A function to be called when token liquidity is removed. Each curve type
     *   can choose to override this function to introduce custom behavior.
     * @param count_ The count of token liquidity removed.
     */
    function _tokenLiquidityRemoved(uint256 count_) internal virtual { }

    /**
     * @notice Validates if a delta value is valid for the curve. The criteria for
     * validity can be different for each type of curve, for instance ExponentialCurve
     * requires delta to be greater than 1.
     * @param delta_ The delta value to be validated
     * @return valid True if delta is invalid, false otherwise
     */
    function _invalidDelta(uint128 delta_) internal pure virtual returns (bool valid);

    /**
     * @notice Validates if a new base price is valid for the curve.
     *   Spot price is generally assumed to be the immediate sell price of 1 NFT to the pool,
     *   in units of the pool's paired token.
     * @param newBasePrice_ The new base price to be set
     * @return valid True if the new base price is invalid, false otherwise
     */
    function _invalidBasePrice(uint128 newBasePrice_) internal pure virtual returns (bool valid);

    // ***************************************************************
    // * ================== ON ERC721 RECEIVED ===================== *
    // ***************************************************************
    ///@inheritdoc IDittoPool
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        revert DittoPoolMainNoDirectNftTransfers();
    }
}
