// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import "./ECDSA.sol";
import "./MessageHashUtils.sol";
import "./IERC1271.sol";
import "./ERC721.sol";
import "./FixedPointMathLib.sol";

import "./AddressManager.sol";
import "./Hash.sol";
import "./IBaseLoan.sol";
import "./IBaseOfferValidator.sol";
import "./InputChecker.sol";

/// @title BaseLoan
/// @author Florida St
/// @notice Base implementation that we expect all loans to share. Offers can either be
///         for new loans or renegotiating existing ones.
///         Offers are signed off-chain.
///         Offers have a nonce associated that is used for cancelling and
///         marking as executed.
abstract contract BaseLoan is ERC721TokenReceiver, IBaseLoan, InputChecker, Owned {
    using FixedPointMathLib for uint256;
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;
    using Hash for LoanOffer;
    using Hash for ExecutionData;

    /// @notice Used in compliance with EIP712
    uint256 internal immutable INITIAL_CHAIN_ID;
    bytes32 public immutable INITIAL_DOMAIN_SEPARATOR;

    uint256 public constant MAX_PROTOCOL_FEE = 2500;
    uint256 public constant FEE_UPDATE_NOTICE = 30 days;
    uint48 public constant MIN_AUCTION_DURATION = 1 days;
    bytes4 private constant MAGICVALUE_1271 = 0x1626ba7e;

    /// @notice Precision used for calculating interests.
    uint256 internal constant _PRECISION = 10000;

    /// @notice Minimum improvement (in BPS) required for a strict improvement.
    ImprovementMinimum internal _minimum = ImprovementMinimum(500, 100, 100);

    string public name;

    /// @notice Duration of the auction when a loan defaults requires a liquidation.
    uint48 internal _liquidationAuctionDuration = 3 days;

    /// @notice Liquidator used defaulted loans that requires liquidation.
    ILoanLiquidator internal _loanLiquidator;

    /// @notice Protocol fee charged on gains.
    ProtocolFee internal _protocolFee;
    /// @notice Set as the target new protocol fee.
    ProtocolFee internal _pendingProtocolFee;
    /// @notice Set when the protocol fee updating mechanisms starts.
    uint256 internal _pendingProtocolFeeSetTime;

    /// @notice Total number of loans issued. Given it's a serial value, we use it
    ///         as loan id.
    uint256 public override getTotalLoansIssued;

    /// @notice Offer capacity
    mapping(address => mapping(uint256 => uint256)) internal _used;

    /// @notice Used for validate off chain maker offers / canceling one
    mapping(address => mapping(uint256 => bool)) public isOfferCancelled;
    /// @notice Used for validating off chain maker offers / canceling all
    mapping(address => uint256) public minOfferId;

    /// @notice Used in a similar way as `isOfferCancelled` to handle renegotiations.
    mapping(address => mapping(uint256 => bool)) public isRenegotiationOfferCancelled;
    /// @notice Used in a similar way as `minOfferId` to handle renegotiations.
    mapping(address => uint256) public lenderMinRenegotiationOfferId;

    /// @notice Loans are only denominated in whitelisted addresses. Within each struct,
    ///         we save those as their `uint` representation.
    AddressManager internal immutable _currencyManager;

    /// @notice Only whilteslited collections are accepted as collateral. Within each struct,
    ///         we save those as their `uint` representation.
    AddressManager internal immutable _collectionManager;

    /// @notice For security reasons we only allow a whitelisted set of callback contracts.
    mapping(address => bool) internal _isWhitelistedCallbackContract;

    event OfferCancelled(address lender, uint256 offerId);

    event BorrowerOfferCancelled(address borrower, uint256 offerId);

    event AllOffersCancelled(address lender, uint256 minOfferId);

    event RenegotiationOfferCancelled(address lender, uint256 renegotiationId);

    event AllRenegotiationOffersCancelled(address lender, uint256 minRenegotiationId);

    event ProtocolFeeUpdated(ProtocolFee fee);

    event ProtocolFeePendingUpdate(ProtocolFee fee);

    event LoanSentToLiquidator(uint256 loanId, address liquidator);

    event LoanLiquidated(uint256 loanId);

    event LoanForeclosed(uint256 loanId);

    event ImprovementMinimumUpdated(ImprovementMinimum minimum);

    event LiquidationContractUpdated(address liquidator);

    event LiquidationAuctionDurationUpdated(uint256 newDuration);

    error InvalidValueError();

    error LiquidatorOnlyError(address _liquidator);

    error CancelledOrExecutedOfferError(address _lender, uint256 _offerId);

    error CancelledRenegotiationOfferError(address _lender, uint256 _renegotiationId);

    error ExpiredOfferError(uint256 _expirationTime);

    error ExpiredRenegotiationOfferError(uint256 _expirationTime);

    error LowOfferIdError(address _lender, uint256 _newMinOfferId, uint256 _minOfferId);

    error LowRenegotiationOfferIdError(address _lender, uint256 _newMinRenegotiationOfferId, uint256 _minOfferId);

    error CannotLiquidateError();

    error LoanNotDueError(uint256 _expirationTime);

    error InvalidLenderError();

    error InvalidBorrowerError();

    error ZeroDurationError();

    error ZeroInterestError();

    error InvalidSignatureError();

    error InvalidLiquidationError();

    error CurrencyNotWhitelistedError();

    error CollectionNotWhitelistedError();

    error InvalidProtocolFeeError(uint256 _fraction);

    error TooEarlyError(uint256 _pendingProtocolFeeSetTime);

    error MaxCapacityExceededError();

    error InvalidLoanError(uint256 _loanId);

    error InvalidCollateralIdError();

    error OnlyLenderOrBorrowerCallableError();

    error OnlyBorrowerCallableError();

    error OnlyLenderCallableError();

    error NotStrictlyImprovedError();

    error InvalidAmountError(uint256 _amount, uint256 _principalAmount);

    error InvalidDurationError();

    constructor(string memory _name, address currencyManager, address collectionManager) Owned(tx.origin) {
        name = _name;
        _checkAddressNotZero(currencyManager);
        _checkAddressNotZero(collectionManager);

        _currencyManager = AddressManager(currencyManager);
        _collectionManager = AddressManager(collectionManager);
        _pendingProtocolFeeSetTime = type(uint256).max;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = _computeDomainSeparator();
    }

    modifier onlyLiquidator() {
        if (msg.sender != address(_loanLiquidator)) {
            revert LiquidatorOnlyError(address(_loanLiquidator));
        }
        _;
    }

    /// @notice Get the domain separator requried to comply with EIP-712.
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : _computeDomainSeparator();
    }

    /// @return The minimum improvement for a loan to be considered strictly better.
    function getImprovementMinimum() external view returns (ImprovementMinimum memory) {
        return _minimum;
    }

    /// @notice Updates the minimum improvement for a loan to be considered strictly better.
    ///         Only the owner can call this function.
    /// @param _newMinimum The new minimum improvement.
    function updateImprovementMinimum(ImprovementMinimum calldata _newMinimum) external onlyOwner {
        _minimum = _newMinimum;

        emit ImprovementMinimumUpdated(_newMinimum);
    }

    /// @return Address of the currency manager.
    function getCurrencyManager() external view returns (address) {
        return address(_currencyManager);
    }

    /// @return Address of the collection manager.
    function getCollectionManager() external view returns (address) {
        return address(_collectionManager);
    }

    /// @inheritdoc IBaseLoan
    function cancelOffer(uint256 _offerId) external {
        address user = msg.sender;
        isOfferCancelled[user][_offerId] = true;

        emit OfferCancelled(user, _offerId);
    }

    /// @inheritdoc IBaseLoan
    function cancelOffers(uint256[] calldata _offerIds) external virtual {
        address user = msg.sender;
        uint256 total = _offerIds.length;
        for (uint256 i = 0; i < total;) {
            uint256 offerId = _offerIds[i];
            isOfferCancelled[user][offerId] = true;

            emit OfferCancelled(user, offerId);
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IBaseLoan
    function cancelAllOffers(uint256 _minOfferId) external virtual {
        address user = msg.sender;
        uint256 currentMinOfferId = minOfferId[user];
        if (currentMinOfferId >= _minOfferId) {
            revert LowOfferIdError(user, _minOfferId, currentMinOfferId);
        }
        minOfferId[user] = _minOfferId;

        emit AllOffersCancelled(user, _minOfferId);
    }

    /// @inheritdoc IBaseLoan
    function cancelRenegotiationOffer(uint256 _renegotiationId) external virtual {
        address lender = msg.sender;
        isRenegotiationOfferCancelled[lender][_renegotiationId] = true;

        emit RenegotiationOfferCancelled(lender, _renegotiationId);
    }

    /// @inheritdoc IBaseLoan
    function cancelRenegotiationOffers(uint256[] calldata _renegotiationIds) external virtual {
        address lender = msg.sender;
        uint256 total = _renegotiationIds.length;
        for (uint256 i = 0; i < total;) {
            uint256 renegotiationId = _renegotiationIds[i];
            isRenegotiationOfferCancelled[lender][renegotiationId] = true;

            emit RenegotiationOfferCancelled(lender, renegotiationId);
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IBaseLoan
    function cancelAllRenegotiationOffers(uint256 _minRenegotiationId) external virtual {
        address lender = msg.sender;
        uint256 currentMinRenegotiationOfferId = lenderMinRenegotiationOfferId[lender];
        if (currentMinRenegotiationOfferId >= _minRenegotiationId) {
            revert LowRenegotiationOfferIdError(lender, _minRenegotiationId, currentMinRenegotiationOfferId);
        }
        lenderMinRenegotiationOfferId[lender] = _minRenegotiationId;

        emit AllRenegotiationOffersCancelled(lender, _minRenegotiationId);
    }

    /// @notice Returns the remaining capacity for a given loan offer.
    /// @param _lender The address of the lender.
    /// @param _offerId The id of the offer.
    /// @return The amount lent out.
    function getUsedCapacity(address _lender, uint256 _offerId) external view returns (uint256) {
        return _used[_lender][_offerId];
    }

    /// @inheritdoc IBaseLoan
    function getProtocolFee() external view returns (ProtocolFee memory) {
        return _protocolFee;
    }

    /// @inheritdoc IBaseLoan
    function getPendingProtocolFee() external view returns (ProtocolFee memory) {
        return _pendingProtocolFee;
    }

    /// @inheritdoc IBaseLoan
    function getPendingProtocolFeeSetTime() external view returns (uint256) {
        return _pendingProtocolFeeSetTime;
    }

    /// @inheritdoc IBaseLoan
    function setProtocolFee() external onlyOwner {
        if (block.timestamp < _pendingProtocolFeeSetTime + FEE_UPDATE_NOTICE) {
            revert TooEarlyError(_pendingProtocolFeeSetTime);
        }
        _protocolFee = _pendingProtocolFee;

        emit ProtocolFeeUpdated(_pendingProtocolFee);
    }

    /// @inheritdoc IBaseLoan
    function updateProtocolFee(ProtocolFee calldata _newProtocolFee) external onlyOwner {
        if (_newProtocolFee.fraction > MAX_PROTOCOL_FEE) {
            revert InvalidProtocolFeeError(_newProtocolFee.fraction);
        }
        _checkAddressNotZero(_newProtocolFee.recipient);

        _pendingProtocolFee = _newProtocolFee;
        _pendingProtocolFeeSetTime = block.timestamp;

        emit ProtocolFeePendingUpdate(_pendingProtocolFee);
    }

    /// @inheritdoc IBaseLoan
    function getLiquidator() external view returns (address) {
        return address(_loanLiquidator);
    }

    /// @inheritdoc IBaseLoan
    function updateLiquidationContract(ILoanLiquidator loanLiquidator) external onlyOwner {
        _checkAddressNotZero(address(loanLiquidator));
        _loanLiquidator = loanLiquidator;

        emit LiquidationContractUpdated(address(loanLiquidator));
    }

    /// @inheritdoc IBaseLoan
    function updateLiquidationAuctionDuration(uint48 _newDuration) external onlyOwner {
        if (_newDuration < MIN_AUCTION_DURATION) {
            revert InvalidDurationError();
        }
        _liquidationAuctionDuration = _newDuration;

        emit LiquidationAuctionDurationUpdated(_newDuration);
    }

    /// @inheritdoc IBaseLoan
    function getLiquidationAuctionDuration() external view returns (uint48) {
        return _liquidationAuctionDuration;
    }

    /// @notice Call when issuing a new loan to get/set a unique serial id.
    /// @dev This id should never be 0.
    /// @return The new loan id.
    function _getAndSetNewLoanId() internal returns (uint256) {
        unchecked {
            return ++getTotalLoansIssued;
        }
    }

    /// @notice Base ExecutionData Checks
    /// @dev Note that we do not validate fee < principalAmount since this is done in the child class in this case.
    /// @param _executionData Loan execution data.
    /// @param _lender The lender.
    /// @param _borrower The borrower.
    /// @param _offerer The offerrer (either lender or borrower)
    /// @param _lenderOfferSignature The signature of the lender of LoanOffer.
    /// @param _borrowerOfferSignature The signature of the borrower of ExecutionData.
    function _validateExecutionData(
        ExecutionData calldata _executionData,
        address _lender,
        address _borrower,
        address _offerer,
        bytes calldata _lenderOfferSignature,
        bytes calldata _borrowerOfferSignature
    ) internal {
        address lender = _executionData.offer.lender;
        address borrower = _executionData.offer.borrower;
        LoanOffer calldata offer = _executionData.offer;
        uint256 offerId = offer.offerId;

        if (msg.sender != _lender) {
            _checkSignature(lender, offer.hash(), _lenderOfferSignature);
        }
        if (msg.sender != _borrower) {
            _checkSignature(_borrower, _executionData.hash(), _borrowerOfferSignature);
        }

        if (block.timestamp > offer.expirationTime) {
            revert ExpiredOfferError(offer.expirationTime);
        }
        if (block.timestamp > _executionData.expirationTime) {
            revert ExpiredOfferError(_executionData.expirationTime);
        }

        if (isOfferCancelled[_offerer][offerId] || (offerId <= minOfferId[_offerer])) {
            revert CancelledOrExecutedOfferError(_offerer, offerId);
        }

        if (_executionData.amount > offer.principalAmount) {
            revert InvalidAmountError(_executionData.amount, offer.principalAmount);
        }

        if (!_currencyManager.isWhitelisted(offer.principalAddress)) {
            revert CurrencyNotWhitelistedError();
        }
        if (!_collectionManager.isWhitelisted(offer.nftCollateralAddress)) {
            revert CollectionNotWhitelistedError();
        }

        if (lender != address(0) && (lender != _lender)) {
            revert InvalidLenderError();
        }
        if (borrower != address(0) && (borrower != _borrower)) {
            revert InvalidBorrowerError();
        }
        if (offer.duration == 0) {
            revert ZeroDurationError();
        }
        if (offer.aprBps == 0) {
            revert ZeroInterestError();
        }
        if ((offer.capacity > 0) && (_used[_offerer][offer.offerId] + _executionData.amount > offer.capacity)) {
            revert MaxCapacityExceededError();
        }

        _checkValidators(offer, _executionData.tokenId);
    }

    /// @notice Check generic offer validators for a given offer or
    ///         an exact match if no validators are given. The validators
    ///         check is performed only if tokenId is set to 0.
    ///         Having one empty validator is used for collection offers (all IDs match).
    /// @param _loanOffer The loan offer to check.
    /// @param _tokenId The token ID to check.
    function _checkValidators(LoanOffer calldata _loanOffer, uint256 _tokenId) internal {
        uint256 offerTokenId = _loanOffer.nftCollateralTokenId;
        if (_loanOffer.nftCollateralTokenId != 0) {
            if (offerTokenId != _tokenId) {
                revert InvalidCollateralIdError();
            }
        } else {
            uint256 totalValidators = _loanOffer.validators.length;
            if (totalValidators == 0 && _tokenId != 0) {
                revert InvalidCollateralIdError();
            } else if ((totalValidators == 1) && (_loanOffer.validators[0].validator == address(0))) {
                return;
            }
            for (uint256 i = 0; i < totalValidators;) {
                OfferValidator memory thisValidator = _loanOffer.validators[i];
                IBaseOfferValidator(thisValidator.validator).validateOffer(
                    _loanOffer, _tokenId, thisValidator.arguments
                );
                unchecked {
                    ++i;
                }
            }
        }
    }

    /// @notice Check a signature is valid given a hash and signer.
    /// @dev Comply with IERC1271 and EIP-712.
    function _checkSignature(address _signer, bytes32 _hash, bytes calldata _signature) internal view {
        bytes32 offerHash = DOMAIN_SEPARATOR().toTypedDataHash(_hash);

        if (_signer.code.length > 0) {
            if (IERC1271(_signer).isValidSignature(offerHash, _signature) != MAGICVALUE_1271) {
                revert InvalidSignatureError();
            }
        } else {
            address recovered = offerHash.recover(_signature);
            if (_signer != recovered) {
                revert InvalidSignatureError();
            }
        }
    }

    /// @dev Check whether an offer is strictly better than a loan/source.
    function _checkStrictlyBetter(
        uint256 _offerPrincipalAmount,
        uint256 _loanPrincipalAmount,
        uint256 _offerEndTime,
        uint256 _loanEndTime,
        uint256 _offerAprBps,
        uint256 _loanAprBps,
        uint256 _offerFee
    ) internal view {
        ImprovementMinimum memory minimum = _minimum;

        /// @dev If principal is increased, then we need to check net daily interest is better.
        /// interestDelta = (_loanAprBps * _loanPrincipalAmount - _offerAprBps * _offerPrincipalAmount)
        /// We already checked that all sources are strictly better.
        /// We check that the duration is not decreased or the offer charges a fee.
        if (
            (
                (_offerPrincipalAmount - _loanPrincipalAmount > 0)
                    && (
                        (_loanAprBps * _loanPrincipalAmount - _offerAprBps * _offerPrincipalAmount).mulDivDown(
                            _PRECISION, _loanAprBps * _loanPrincipalAmount
                        ) < minimum.interest
                    )
            ) || (_offerFee > 0) || (_offerEndTime < _loanEndTime)
        ) {
            revert NotStrictlyImprovedError();
        }
    }

    /// @notice Compute domain separator for EIP-712.
    /// @return The domain separator.
    function _computeDomainSeparator() private view returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256("2"),
                block.chainid,
                address(this)
            )
        );
    }
}
