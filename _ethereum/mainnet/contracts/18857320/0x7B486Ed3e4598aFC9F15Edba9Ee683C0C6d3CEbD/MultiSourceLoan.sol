// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import "./IDelegateRegistry.sol";
import "./ERC20.sol";
import "./ERC721.sol";
import "./FixedPointMathLib.sol";
import "./ReentrancyGuard.sol";
import "./SafeTransferLib.sol";

import "./INFTFlashAction.sol";
import "./IMultiSourceLoan.sol";
import "./ILoanLiquidator.sol";
import "./Hash.sol";
import "./Interest.sol";
import "./Multicall.sol";
import "./WithCallbacks.sol";

contract MultiSourceLoan is IMultiSourceLoan, Multicall, ReentrancyGuard, WithCallbacks {
    using FixedPointMathLib for uint256;
    using Hash for Loan;
    using Hash for SignableRepaymentData;
    using Hash for RenegotiationOffer;
    using Interest for uint256;
    using MessageHashUtils for bytes32;
    using SafeTransferLib for ERC20;

    /// @notice Loan Id to hash
    mapping(uint256 => bytes32) private _loans;

    /// @notice Maximum number of sources per loan
    uint256 private _maxSources;

    /// @notice Min lock period for a source
    uint256 private _minLockPeriod;

    /// @notice If we have N max sources, then the min principal of any given source
    /// at the time of repayment needs to be Total Principal / (N * _MAX_RATIO_SOURCE_MIN_PRINCIPAL)
    /// This is captured in _getMinSourcePrincipal.
    uint256 private constant _MAX_RATIO_SOURCE_MIN_PRINCIPAL = 2;

    /// @notice delegate registry
    IDelegateRegistry private _delegateRegistry;

    /// @notice Contract to execute flash actions.
    INFTFlashAction private _flashActionContract;

    event MaxSourcesUpdated(uint256 newMax);

    event LoanEmitted(uint256 loanId, uint256 offerId, Loan loan, address lender, address borrower, uint256 fee);

    event LoanRefinanced(uint256 renegotiationId, uint256 oldLoanId, uint256 newLoanId, Loan loan, uint256 fee);

    event LoanRepaid(uint256 loanId, uint256 totalRepayment, uint256 fee);

    event DelegateRegistryUpdated(address newdelegateRegistry);

    event Delegated(uint256 loanId, address delegate, bool value);

    event FlashActionContractUpdated(address newFlashActionContract);

    event FlashActionExecuted(uint256 loanId, address target, bytes data);

    event RevokeDelegate(address delegate, address collection, uint256 tokenId);

    event LoanExtended(uint256 oldLoanId, uint256 newLoanId, Loan loan, uint256 _extension);

    event MinLockPeriodUpdated(uint256 minLockPeriod);

    error InvalidMethodError();

    error InvalidRenegotiationOfferError();

    error TooManySourcesError(uint256 sources);

    error MinLockPeriodTooHighError(uint256 minLockPeriod);

    error PartialOfferCannotChangeDurationError();

    error PartialOfferCannotHaveFeeError();

    error LoanExpiredError();

    error RefinanceFullError();

    error LengthMismatchError();

    error TargetPrincipalTooLowError(uint256 sourcePrincipal, uint256 loanPrincipal);

    error NFTNotReturnedError();

    error ExtensionNotAvailableError();

    error SourceCannotBeRefinancedError(uint256 minTimestamp);

    /// @param loanLiquidator Address of the liquidator contract.
    /// @param protocolFee Protocol fee charged on gains.
    /// @param currencyManager Address of the currency manager.
    /// @param collectionManager Address of the collection manager.
    /// @param maxSources Maximum number of sources per loan.
    /// @param delegateRegistry Address of the delegate registry (Delegate.xyz).
    /// @param flashActionContract Address of the flash action contract.
    constructor(
        address loanLiquidator,
        ProtocolFee memory protocolFee,
        address currencyManager,
        address collectionManager,
        uint256 maxSources,
        uint256 minLockPeriod,
        address delegateRegistry,
        address flashActionContract
    ) WithCallbacks("GONDI_MULTI_SOURCE_LOAN", currencyManager, collectionManager) {
        _checkAddressNotZero(loanLiquidator);

        _loanLiquidator = ILoanLiquidator(loanLiquidator);
        _protocolFee = protocolFee;
        _maxSources = maxSources;
        _minLockPeriod = minLockPeriod;
        _delegateRegistry = IDelegateRegistry(delegateRegistry);
        _flashActionContract = INFTFlashAction(flashActionContract);
    }

    /// @inheritdoc IMultiSourceLoan
    function emitLoan(LoanExecutionData calldata _executionData) external nonReentrant returns (uint256, Loan memory) {
        address lender = _executionData.lender;
        address borrower = _executionData.borrower;
        LoanOffer calldata offer = _executionData.executionData.offer;
        address offerer = offer.lender == address(0) ? borrower : lender;
        _validateExecutionData(
            _executionData.executionData,
            lender,
            borrower,
            offerer,
            _executionData.lenderOfferSignature,
            _executionData.borrowerOfferSignature
        );

        uint256 loanId = _getAndSetNewLoanId();
        uint256 amount = _executionData.executionData.amount;

        Source[] memory source = new Source[](1);
        source[0] = Source(loanId, lender, amount, 0, block.timestamp, offer.aprBps);
        Loan memory loan = Loan(
            borrower,
            _executionData.executionData.tokenId,
            offer.nftCollateralAddress,
            offer.principalAddress,
            amount,
            block.timestamp,
            offer.duration,
            source
        );

        _loans[loanId] = loan.hash();
        uint256 fee = offer.fee.mulDivUp(amount, offer.principalAmount);
        ProtocolFee memory protocolFee = _protocolFee;
        _handleProtocolFeeForFee(
            offer.principalAddress, lender, fee.mulDivUp(protocolFee.fraction, _PRECISION), protocolFee
        );

        ERC20(offer.principalAddress).safeTransferFrom(lender, borrower, amount - fee);

        /// @dev After sending the principal to the borrower, check if there's an action to be taken (eg: use it to buy the collateral).
        uint128 tax = _handleAfterPrincipalTransferCallback(loan, _executionData.executionData.callbackData, fee);
        if (tax > 0) {
            uint256 taxCost = amount.mulDivUp(tax, _PRECISION);
            uint256 feeTax = taxCost.mulDivUp(protocolFee.fraction, _PRECISION);

            ERC20(offer.principalAddress).safeTransferFrom(borrower, lender, taxCost - feeTax);
            if (feeTax > 0) {
                ERC20(offer.principalAddress).safeTransferFrom(borrower, protocolFee.recipient, feeTax);
            }
        }

        ERC721(offer.nftCollateralAddress).transferFrom(borrower, address(this), _executionData.executionData.tokenId);

        emit LoanEmitted(loanId, offer.offerId, loan, lender, borrower, offer.fee);

        if (offer.capacity > 0) {
            _used[offerer][offer.offerId] += amount;
        } else {
            isOfferCancelled[offerer][offer.offerId] = true;
        }

        return (loanId, loan);
    }

    /// @inheritdoc IMultiSourceLoan
    function refinanceFull(
        RenegotiationOffer calldata _renegotiationOffer,
        Loan memory _loan,
        bytes calldata _renegotiationOfferSignature
    ) external returns (uint256, Loan memory) {
        uint256 loanId = _renegotiationOffer.loanId;
        address sender = msg.sender;
        bool clearsInterest = false;

        _baseLoanChecks(loanId, _loan);

        _baseRenegotiationChecks(_renegotiationOffer, _loan);

        bool strictImprovement = msg.sender == _renegotiationOffer.lender;

        (uint256 totalDelta, uint256 totalAccruedInterest, uint256 totalNewSources, uint256 totalAnnualInterest) =
            _processOldSources(_renegotiationOffer, _loan, strictImprovement);
        if (totalNewSources > 1) {
            revert RefinanceFullError();
        }
        /// @dev If it's lender initiated, needs to be strictly better.
        if (strictImprovement) {
            _checkStrictlyBetter(
                _renegotiationOffer.principalAmount,
                totalDelta,
                _renegotiationOffer.duration + block.timestamp,
                _loan.duration + _loan.startTime,
                _renegotiationOffer.aprBps,
                totalAnnualInterest / _loan.principalAmount,
                _renegotiationOffer.fee
            );
        } else if (sender != _loan.borrower) {
            revert OnlyLenderOrBorrowerCallableError();
        } else {
            clearsInterest = true;
            _checkSignature(_renegotiationOffer.lender, _renegotiationOffer.hash(), _renegotiationOfferSignature);
        }

        uint256 netNewLender = _renegotiationOffer.principalAmount - _renegotiationOffer.fee;

        if (clearsInterest) {
            netNewLender -= totalAccruedInterest;
            totalAccruedInterest = 0;
        }

        if (totalDelta > netNewLender) {
            ERC20(_loan.principalAddress).safeTransferFrom(
                _loan.borrower, _renegotiationOffer.lender, totalDelta - netNewLender
            );
        } else if (totalDelta < netNewLender) {
            ERC20(_loan.principalAddress).safeTransferFrom(
                _renegotiationOffer.lender, _loan.borrower, netNewLender - totalDelta
            );
        }

        uint256 newLoanId = _getAndSetNewLoanId();
        Source[] memory newSources = new Source[](1);

        newSources[0] = _getSourceFromOffer(_renegotiationOffer, totalAccruedInterest, newLoanId);
        _loan.source = newSources;
        _loan.duration = (block.timestamp - _loan.startTime) + _renegotiationOffer.duration;
        _loan.principalAmount = _renegotiationOffer.principalAmount;

        _loans[newLoanId] = _loan.hash();
        delete _loans[loanId];

        emit LoanRefinanced(_renegotiationOffer.renegotiationId, loanId, newLoanId, _loan, _renegotiationOffer.fee);

        return (newLoanId, _loan);
    }

    /// @inheritdoc IMultiSourceLoan
    function refinancePartial(RenegotiationOffer calldata _renegotiationOffer, Loan memory _loan)
        external
        returns (uint256, Loan memory)
    {
        uint256 loanId = _renegotiationOffer.loanId;
        if (_renegotiationOffer.principalAmount < _getMinSourcePrincipal(_loan.principalAmount)) {
            revert TargetPrincipalTooLowError(_renegotiationOffer.principalAmount, _loan.principalAmount);
        }
        if (msg.sender != _renegotiationOffer.lender) {
            revert OnlyLenderCallableError();
        }

        _baseLoanChecks(loanId, _loan);

        _baseRenegotiationChecks(_renegotiationOffer, _loan);

        if (_renegotiationOffer.duration > 0) {
            revert PartialOfferCannotChangeDurationError();
        }
        if (_renegotiationOffer.fee > 0) {
            revert PartialOfferCannotHaveFeeError();
        }

        (uint256 totalDelta, uint256 totalAccruedInterest, uint256 totalNewSources,) =
            _processOldSources(_renegotiationOffer, _loan, true);

        if (totalDelta != _renegotiationOffer.principalAmount) {
            revert InvalidRenegotiationOfferError();
        }
        if (totalNewSources > _maxSources) {
            revert TooManySourcesError(totalNewSources);
        }

        uint256 newLoanId = _getAndSetNewLoanId();
        Source[] memory newSources = new Source[](totalNewSources);
        newSources[0] = _getSourceFromOffer(_renegotiationOffer, totalAccruedInterest, newLoanId);
        /// @dev Index = 0 is taken by the new source
        uint256 j = 1;
        for (uint256 i = 0; i < _renegotiationOffer.targetPrincipal.length;) {
            if (_renegotiationOffer.targetPrincipal[i] > 0) {
                newSources[j] = _loan.source[i];
                newSources[j].principalAmount = _renegotiationOffer.targetPrincipal[i];
                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }

        _loan.source = newSources;

        _loans[newLoanId] = _loan.hash();
        delete _loans[loanId];

        /// @dev Here fee is always 0
        emit LoanRefinanced(_renegotiationOffer.renegotiationId, loanId, newLoanId, _loan, 0);

        return (newLoanId, _loan);
    }

    /// @inheritdoc IMultiSourceLoan
    function extendLoan(uint256 _loanId, Loan memory _loan, uint256 _extension)
        external
        returns (uint256, Loan memory)
    {
        _baseLoanChecks(_loanId, _loan);

        if (_loan.source.length > 1) {
            revert ExtensionNotAvailableError();
        }
        uint256 unlockedTime = _getUnlockedTime(_loan.source[0].startTime, _loan.startTime + _loan.duration);
        if (unlockedTime > block.timestamp) {
            revert SourceCannotBeRefinancedError(unlockedTime);
        }
        if (_loan.source[0].lender != msg.sender) {
            revert OnlyLenderCallableError();
        }
        _loan.duration += _extension;
        uint256 newLoanId = _getAndSetNewLoanId();
        _loans[newLoanId] = _loan.hash();

        delete _loans[_loanId];

        emit LoanExtended(_loanId, newLoanId, _loan, _extension);

        return (newLoanId, _loan);
    }

    /// @inheritdoc IMultiSourceLoan
    function repayLoan(LoanRepaymentData calldata _repaymentData) external override nonReentrant {
        uint256 loanId = _repaymentData.data.loanId;
        Loan calldata loan = _repaymentData.loan;
        /// @dev If the caller is not the borrower itself, check the signature to avoid someone else forcing an unwanted repayment.
        if (msg.sender != loan.borrower) {
            _checkSignature(loan.borrower, _repaymentData.data.hash(), _repaymentData.borrowerSignature);
        }

        _baseLoanChecks(loanId, loan);

        /// @dev Unlikely this is used outside of the callback with a seaport sell, but leaving here in case that's not correct.
        if (_repaymentData.data.shouldDelegate) {
            _delegateRegistry.delegateERC721(
                loan.borrower, loan.nftCollateralAddress, loan.nftCollateralTokenId, bytes32(""), true
            );
        }

        ERC721(loan.nftCollateralAddress).transferFrom(address(this), loan.borrower, loan.nftCollateralTokenId);

        /// @dev After returning the NFT to the borrower, check if there's an action to be taken (eg: sell it to cover repayment).
        uint128 taxBps = _handleAfterNFTTransferCallback(loan, _repaymentData.data.callbackData);

        /// @dev Bring to memory
        ProtocolFee memory protocolFee = _protocolFee;
        bool withProtocolFee = protocolFee.fraction > 0;
        uint256 totalProtocolFee = 0;

        ERC20 asset = ERC20(loan.principalAddress);
        uint256 totalRepayment = 0;
        for (uint256 i = 0; i < loan.source.length;) {
            Source memory source = loan.source[i];

            uint256 newInterest = source.principalAmount.getInterest(source.aprBps, block.timestamp - source.startTime);
            uint256 tax = source.principalAmount.mulDivUp(taxBps, _PRECISION);

            uint256 thisProtocolFee = 0;
            uint256 thisTaxFee = 0;
            if (withProtocolFee) {
                thisProtocolFee = newInterest.mulDivUp(protocolFee.fraction, _PRECISION);
                thisTaxFee = tax.mulDivUp(protocolFee.fraction, _PRECISION);
                totalProtocolFee += thisProtocolFee + thisTaxFee;
            }

            uint256 repayment =
                source.principalAmount + source.accruedInterest + newInterest - thisProtocolFee + tax - thisTaxFee;
            asset.safeTransferFrom(loan.borrower, source.lender, repayment);

            totalRepayment += repayment;

            unchecked {
                ++i;
            }
        }

        emit LoanRepaid(loanId, totalRepayment, totalProtocolFee);

        if (withProtocolFee) {
            asset.safeTransferFrom(loan.borrower, protocolFee.recipient, totalProtocolFee);
        }

        /// @dev Reclaim space.
        delete _loans[loanId];
    }

    /// @inheritdoc IMultiSourceLoan
    function liquidateLoan(uint256 _loanId, Loan calldata _loan)
        external
        override
        nonReentrant
        returns (bytes memory)
    {
        if (_loan.hash() != _loans[_loanId]) {
            revert InvalidLoanError(_loanId);
        }
        uint256 expirationTime = _loan.startTime + _loan.duration;
        address collateralAddress = _loan.nftCollateralAddress;
        ERC721 collateralCollection = ERC721(collateralAddress);

        if (expirationTime > block.timestamp) {
            revert LoanNotDueError(expirationTime);
        }
        bytes memory liquidation;
        if (_loan.source.length == 1) {
            collateralCollection.transferFrom(address(this), _loan.source[0].lender, _loan.nftCollateralTokenId);

            emit LoanForeclosed(_loanId);

            /// @dev Reclaim space.
            delete _loans[_loanId];
        } else {
            collateralCollection.transferFrom(address(this), address(_loanLiquidator), _loan.nftCollateralTokenId);
            liquidation = _loanLiquidator.liquidateLoan(
                _loanId,
                collateralAddress,
                _loan.nftCollateralTokenId,
                _loan.principalAddress,
                _liquidationAuctionDuration,
                msg.sender
            );

            emit LoanSentToLiquidator(_loanId, address(_loanLiquidator));
        }
        return liquidation;
    }

    /// @inheritdoc IMultiSourceLoan
    function loanLiquidated(uint256 _loanId, Loan calldata _loan) external override onlyLiquidator {
        if (_loan.hash() != _loans[_loanId]) {
            revert InvalidLoanError(_loanId);
        }

        emit LoanLiquidated(_loanId);

        /// @dev Reclaim space.
        delete _loans[_loanId];
    }

    function getMinSourcePrincipal(uint256 _loanPrincipal) external view returns (uint256) {
        return _getMinSourcePrincipal(_loanPrincipal);
    }

    /// @inheritdoc IMultiSourceLoan
    function delegate(uint256 _loanId, Loan calldata loan, address _delegate, bytes32 _rights, bool _value) external {
        if (loan.hash() != _loans[_loanId]) {
            revert InvalidLoanError(_loanId);
        }
        if (msg.sender != loan.borrower) {
            revert OnlyBorrowerCallableError();
        }
        _delegateRegistry.delegateERC721(
            _delegate, loan.nftCollateralAddress, loan.nftCollateralTokenId, _rights, _value
        );

        emit Delegated(_loanId, _delegate, _value);
    }

    /// @inheritdoc IMultiSourceLoan
    function revokeDelegate(address _delegate, address _collection, uint256 _tokenId) external {
        if (ERC721(_collection).ownerOf(_tokenId) == address(this)) {
            revert InvalidMethodError();
        }

        _delegateRegistry.delegateERC721(_delegate, _collection, _tokenId, "", false);

        emit RevokeDelegate(_delegate, _collection, _tokenId);
    }

    /// @inheritdoc IMultiSourceLoan
    function getDelegateRegistry() external view returns (address) {
        return address(_delegateRegistry);
    }

    /// @inheritdoc IMultiSourceLoan
    function setDelegateRegistry(address _newDelegateRegistry) external onlyOwner {
        _delegateRegistry = IDelegateRegistry(_newDelegateRegistry);

        emit DelegateRegistryUpdated(_newDelegateRegistry);
    }

    /// @inheritdoc IMultiSourceLoan
    function getMaxSources() external view returns (uint256) {
        return _maxSources;
    }

    /// @inheritdoc IMultiSourceLoan
    function setMaxSources(uint256 __maxSources) external onlyOwner {
        _maxSources = __maxSources;

        emit MaxSourcesUpdated(__maxSources);
    }

    /// @inheritdoc IMultiSourceLoan
    function getMinLockPeriod() external view returns (uint256) {
        return _minLockPeriod;
    }

    /// @inheritdoc IMultiSourceLoan
    function setMinLockPeriod(uint256 __minLockPeriod) external onlyOwner {
        _minLockPeriod = __minLockPeriod;

        emit MinLockPeriodUpdated(__minLockPeriod);
    }

    /// @inheritdoc IMultiSourceLoan
    function getLoanHash(uint256 _loanId) external view returns (bytes32) {
        return _loans[_loanId];
    }

    /// @inheritdoc IMultiSourceLoan
    function executeFlashAction(uint256 _loanId, Loan calldata _loan, address _target, bytes calldata _data) external {
        if (_loan.hash() != _loans[_loanId]) {
            revert InvalidLoanError(_loanId);
        }
        if (msg.sender != _loan.borrower) {
            revert OnlyBorrowerCallableError();
        }

        ERC721(_loan.nftCollateralAddress).transferFrom(
            address(this), address(_flashActionContract), _loan.nftCollateralTokenId
        );
        _flashActionContract.execute(_loan.nftCollateralAddress, _loan.nftCollateralTokenId, _target, _data);

        if (ERC721(_loan.nftCollateralAddress).ownerOf(_loan.nftCollateralTokenId) != address(this)) {
            revert NFTNotReturnedError();
        }

        emit FlashActionExecuted(_loanId, _target, _data);
    }

    /// @inheritdoc IMultiSourceLoan
    function getFlashActionContract() external view returns (address) {
        return address(_flashActionContract);
    }

    /// @inheritdoc IMultiSourceLoan
    function setFlashActionContract(address _newFlashActionContract) external onlyOwner {
        _flashActionContract = INFTFlashAction(_newFlashActionContract);

        emit FlashActionContractUpdated(_newFlashActionContract);
    }

    /// @notice Update old sources and return the total delta, accrued interest, new sources and
    /// transfer the protocol fee.
    /// @param _renegotiationOffer The refinance offer.
    /// @param _loan The loan to be refinanced.
    /// @param _isStrictlyBetter Every source's apr needs to be improved.
    /// @return totalDelta The total delta is the sum of all deltas across existing sources. This must be equal
    /// to the new supplied (the total principal cannot change).
    /// @return totalAccruedInterest Total accrued interest across all sources paid.
    /// @return totalNewSources Total new sources, including new lender, left after the refinance.
    /// @return totalAnnualInterest Total annual interest across all sources.
    function _processOldSources(
        RenegotiationOffer calldata _renegotiationOffer,
        Loan memory _loan,
        bool _isStrictlyBetter
    )
        private
        returns (uint256 totalDelta, uint256 totalAccruedInterest, uint256 totalNewSources, uint256 totalAnnualInterest)
    {
        /// @dev Bring var to memory
        ProtocolFee memory protocolFee = _protocolFee;

        uint256 totalProtocolFee = 0;
        if (protocolFee.fraction > 0 && _renegotiationOffer.fee > 0) {
            totalProtocolFee = _renegotiationOffer.fee.mulDivUp(protocolFee.fraction, _PRECISION);
        }

        totalNewSources = 1;
        for (uint256 i = 0; i < _renegotiationOffer.targetPrincipal.length;) {
            Source memory source = _loan.source[i];
            uint256 targetPrincipal = _renegotiationOffer.targetPrincipal[i];
            (
                uint256 delta,
                uint256 accruedInterest,
                uint256 isNewSource,
                uint256 annualInterest,
                uint256 thisProtocolFee
            ) = _processOldSource(
                _renegotiationOffer.lender,
                _loan.principalAddress,
                source,
                _loan.startTime + _loan.duration,
                targetPrincipal,
                protocolFee
            );

            _checkSourceStrictly(_isStrictlyBetter, delta, source.aprBps, _renegotiationOffer.aprBps, _minimum.interest);

            totalAnnualInterest += annualInterest;
            totalDelta += delta;
            totalAccruedInterest += accruedInterest;
            totalProtocolFee += thisProtocolFee;
            totalNewSources += isNewSource;

            unchecked {
                ++i;
            }
        }

        _handleProtocolFeeForFee(_loan.principalAddress, _renegotiationOffer.lender, totalProtocolFee, protocolFee);
    }

    /// @notice Process the current source during a renegotiation.
    /// @param _lender The new lender.
    /// @param _principalAddress The principal address of the loan.
    /// @param _source The source to be processed.
    /// @param _endTime The end time of the loan.
    /// @param _targetPrincipal The target principal of the source.
    /// @param protocolFee The protocol fee.
    /// @return delta The delta between the old and new principal.
    /// @return accruedInterest The accrued interest paid.
    /// @return isNewSource Whether the source is kept.
    /// @return annualInterest The total annual interest paid (times 10000 since we have it in BPS)
    /// @return thisProtocolFee The protocol fee paid for this source.
    function _processOldSource(
        address _lender,
        address _principalAddress,
        Source memory _source,
        uint256 _endTime,
        uint256 _targetPrincipal,
        ProtocolFee memory protocolFee
    )
        private
        returns (
            uint256 delta,
            uint256 accruedInterest,
            uint256 isNewSource,
            uint256 annualInterest,
            uint256 thisProtocolFee
        )
    {
        uint256 unlockedTime = _getUnlockedTime(_source.startTime, _endTime);
        if (unlockedTime > block.timestamp) {
            revert SourceCannotBeRefinancedError(unlockedTime);
        }
        delta = _source.principalAmount - _targetPrincipal;
        annualInterest = _source.principalAmount * _source.aprBps;
        if (delta == 0) {
            return (0, 0, 1, annualInterest, 0);
        }
        accruedInterest = delta.getInterest(_source.aprBps, block.timestamp - _source.startTime);

        if (protocolFee.fraction > 0) {
            thisProtocolFee = accruedInterest.mulDivUp(protocolFee.fraction, _PRECISION);
        }

        uint256 proportionalAccrued = _source.accruedInterest.mulDivDown(delta, _source.principalAmount);
        if (_targetPrincipal > 0) {
            _source.accruedInterest -= proportionalAccrued;
            isNewSource = 1;
        }

        accruedInterest += proportionalAccrued;

        ERC20(_principalAddress).safeTransferFrom(_lender, _source.lender, delta + accruedInterest - thisProtocolFee);
    }

    function _baseLoanChecks(uint256 _loanId, Loan memory _loan) private view {
        if (_loan.hash() != _loans[_loanId]) {
            revert InvalidLoanError(_loanId);
        }
        if (_loan.startTime + _loan.duration < block.timestamp) {
            revert LoanExpiredError();
        }
    }

    function _baseRenegotiationChecks(RenegotiationOffer calldata _renegotiationOffer, Loan memory _loan)
        private
        view
    {
        if (
            (_renegotiationOffer.principalAmount == 0)
                || (_loan.source.length != _renegotiationOffer.targetPrincipal.length)
        ) {
            revert InvalidRenegotiationOfferError();
        }
        if (block.timestamp > _renegotiationOffer.expirationTime) {
            revert ExpiredRenegotiationOfferError(_renegotiationOffer.expirationTime);
        }
        uint256 renegotiationId = _renegotiationOffer.renegotiationId;
        address lender = _renegotiationOffer.lender;
        if (
            isRenegotiationOfferCancelled[lender][renegotiationId]
                || lenderMinRenegotiationOfferId[lender] >= renegotiationId
        ) {
            revert CancelledRenegotiationOfferError(lender, renegotiationId);
        }
    }

    function _getSourceFromOffer(
        RenegotiationOffer memory _renegotiationOffer,
        uint256 _accruedInterest,
        uint256 _loanId
    ) private view returns (Source memory) {
        return Source({
            loanId: _loanId,
            lender: _renegotiationOffer.lender,
            principalAmount: _renegotiationOffer.principalAmount,
            accruedInterest: _accruedInterest,
            startTime: block.timestamp,
            aprBps: _renegotiationOffer.aprBps
        });
    }

    function _getMinSourcePrincipal(uint256 _loanPrincipal) private view returns (uint256) {
        return _loanPrincipal / (_MAX_RATIO_SOURCE_MIN_PRINCIPAL * _maxSources);
    }

    /// @notice Protocol fee for fees charged on offers/renegotationOffers.
    /// @param _principalAddress The principal address of the loan.
    /// @param _lender The lender of the loan.
    /// @param _fee The fee to be charged.
    /// @param protocolFee The protocol fee variable brought to memory.
    function _handleProtocolFeeForFee(
        address _principalAddress,
        address _lender,
        uint256 _fee,
        ProtocolFee memory protocolFee
    ) private {
        if (protocolFee.fraction > 0 && _fee > 0) {
            ERC20(_principalAddress).safeTransferFrom(_lender, protocolFee.recipient, _fee);
        }
    }

    /// @notice Check condition for strictly better sources
    /// @param _isStrictlyBetter Whether the new source needs to be strictly better than the old one.
    /// @param _delta The delta between the old and new principal. 0 if unchanged.
    /// @param _currentAprBps The current apr of the source.
    /// @param _targetAprBps The target apr of the source.
    /// @param _minImprovement The minimum improvement required.
    function _checkSourceStrictly(
        bool _isStrictlyBetter,
        uint256 _delta,
        uint256 _currentAprBps,
        uint256 _targetAprBps,
        uint256 _minImprovement
    ) private pure {
        /// @dev If _isStrictlyBetter is set, and the new apr is higher, then it'll underflow.
        if (
            _isStrictlyBetter && _delta > 0
                && ((_currentAprBps - _targetAprBps).mulDivDown(_PRECISION, _currentAprBps) < _minImprovement)
        ) {
            revert InvalidRenegotiationOfferError();
        }
    }

    function _getUnlockedTime(uint256 _sourceStartTime, uint256 _loanEndTime) private view returns (uint256) {
        return _sourceStartTime + (_loanEndTime - _sourceStartTime).mulDivUp(_minLockPeriod, _PRECISION);
    }
}
