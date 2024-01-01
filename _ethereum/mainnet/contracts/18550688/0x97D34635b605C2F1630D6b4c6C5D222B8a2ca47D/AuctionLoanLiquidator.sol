// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import "./EnumerableSet.sol";
import "./Owned.sol";
import "./FixedPointMathLib.sol";
import "./ReentrancyGuard.sol";
import "./SafeTransferLib.sol";
import "./ERC20.sol";
import "./ERC721.sol";

import "./ILiquidationDistributor.sol";
import "./IAuctionLoanLiquidator.sol";
import "./ILoanLiquidator.sol";
import "./IMultiSourceLoan.sol";
import "./AddressManager.sol";
import "./InputChecker.sol";
import "./Hash.sol";

/// @title Auction Loan Liquidator
/// @author Florida St
/// @notice Receives an NFT to be auctioned when a loan defaults.
///         Mainly taking Zora's implementation.
contract AuctionLoanLiquidator is
    ERC721TokenReceiver,
    IAuctionLoanLiquidator,
    ILoanLiquidator,
    InputChecker,
    Owned,
    ReentrancyGuard
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using FixedPointMathLib for uint256;
    using Hash for Auction;
    using SafeTransferLib for ERC20;

    /// @notice The maximum trigger fee expressed in bps.
    uint256 public constant MAX_TRIGGER_FEE = 500;
    /// @notice The minimum increment expressed in bps to become highest bid.
    uint256 public constant MIN_INCREMENT_BPS = 500;
    /// @notice BPS definition.
    uint256 private constant _BPS = 10000;
    /// @notice The minimum time that must pass after the last bid before the auction can be settled.
    uint96 private constant _MIN_NO_ACTION_MARGIN = 10 minutes;
    /// @notice The Liquidation Distributor.
    ILiquidationDistributor private _liquidationDistributor;
    /// @notice The currency manager.
    AddressManager private immutable _currencyManager;
    /// @notice The collection manager.
    AddressManager private immutable _collectionManager;
    /// @notice The trigger fee.
    uint256 private _triggerFee;
    /// @notice The valid loan contracts.
    EnumerableSet.AddressSet private _validLoanContracts;

    mapping(address => mapping(uint256 => bytes32)) private _auctions;

    event LoanContractAdded(address loan);

    event LoanContractRemoved(address loan);

    event LiquidationDistributorUpdated(address liquidationDistributor);

    event LoanLiquidationStarted(address collection, uint256 tokenId, Auction auction);

    event BidPlaced(
        address collection, uint256 tokenId, address newBidder, uint256 bid, address loanAddress, uint256 loanId
    );

    event AuctionSettled(
        address loanContract,
        uint256 loanId,
        address auctionContract,
        uint256 tokenId,
        address asset,
        uint256 proceeds,
        address settler,
        uint256 triggerFee
    );

    event TriggerFeeUpdated(uint256 triggerFee);

    error InvalidHashAuctionError();

    error NFTNotOwnedError(address _owner);

    error MinBidError(uint256 _minBid);

    error AuctionOverError(uint96 _expiration);

    error AuctionNotOverError(uint96 _expiration);

    error AuctionAlreadyInProgressError();

    error NoBidsError();

    error CurrencyNotWhitelistedError();

    error CollectionNotWhitelistedError();

    error LoanNotAcceptedError(address _loan);

    error ZeroAddressError();

    error InvalidTriggerFee(uint256 triggerFee);

    error CouldNotModifyValidLoansError();

    /// @param liquidationDistributor Contract that distributes the proceeds of an auction.
    /// @param currencyManager The address manager for currencies (check whitelisting).
    /// @param collectionManager The address manager for collections (check whitelisting).
    /// @param triggerFee The trigger fee. Given to the originator/settler of an auction. Expressed in bps.
    constructor(address liquidationDistributor, address currencyManager, address collectionManager, uint256 triggerFee)
        Owned(tx.origin)
    {
        if (liquidationDistributor == address(0) || currencyManager == address(0) || collectionManager == address(0)) {
            revert ZeroAddressError();
        }
        _liquidationDistributor = ILiquidationDistributor(liquidationDistributor);
        _currencyManager = AddressManager(currencyManager);
        _collectionManager = AddressManager(collectionManager);
        _updateTriggerFee(triggerFee);
    }

    /// @inheritdoc IAuctionLoanLiquidator
    function addLoanContract(address _loanContract) external onlyOwner {
        if (!_validLoanContracts.add(_loanContract)) {
            revert CouldNotModifyValidLoansError();
        }

        emit LoanContractAdded(_loanContract);
    }

    /// @inheritdoc IAuctionLoanLiquidator
    function removeLoanContract(address _loanContract) external onlyOwner {
        if (!_validLoanContracts.remove(_loanContract)) {
            revert CouldNotModifyValidLoansError();
        }

        emit LoanContractRemoved(_loanContract);
    }

    /// @inheritdoc IAuctionLoanLiquidator
    function getValidLoanContracts() external view returns (address[] memory) {
        return _validLoanContracts.values();
    }

    /// @inheritdoc IAuctionLoanLiquidator
    function updateLiquidationDistributor(address __liquidationDistributor) external onlyOwner {
        _checkAddressNotZero(__liquidationDistributor);

        _liquidationDistributor = ILiquidationDistributor(__liquidationDistributor);

        emit LiquidationDistributorUpdated(__liquidationDistributor);
    }

    /// @return The liquidation distributor address.
    function getLiquidationDistributor() external view returns (address) {
        return address(_liquidationDistributor);
    }

    /// @inheritdoc IAuctionLoanLiquidator
    function updateTriggerFee(uint256 triggerFee) external onlyOwner {
        _updateTriggerFee(triggerFee);
    }

    /// @inheritdoc IAuctionLoanLiquidator
    function getTriggerFee() external view returns (uint256) {
        return _triggerFee;
    }

    /// @inheritdoc ILoanLiquidator
    function liquidateLoan(
        uint256 _loanId,
        address _contract,
        uint256 _tokenId,
        address _asset,
        uint96 _duration,
        address _originator
    ) external override nonReentrant returns (bytes memory) {
        address _owner = ERC721(_contract).ownerOf(_tokenId);
        if (_owner != address(this)) {
            revert NFTNotOwnedError(_owner);
        }

        if (!_validLoanContracts.contains(msg.sender)) {
            revert LoanNotAcceptedError(msg.sender);
        }

        if (!_currencyManager.isWhitelisted(_asset)) {
            revert CurrencyNotWhitelistedError();
        }

        if (!_collectionManager.isWhitelisted(_contract)) {
            revert CollectionNotWhitelistedError();
        }

        if (_auctions[_contract][_tokenId] != bytes32(0)) {
            revert AuctionAlreadyInProgressError();
        }

        uint96 currentTimestamp = uint96(block.timestamp);
        Auction memory auction = Auction(
            msg.sender,
            _loanId,
            0,
            _triggerFee,
            address(0),
            _duration,
            _asset,
            currentTimestamp,
            _originator,
            currentTimestamp
        );
        _auctions[_contract][_tokenId] = auction.hash();
        emit LoanLiquidationStarted(_contract, _tokenId, auction);

        return abi.encode(auction);
    }

    /// @inheritdoc IAuctionLoanLiquidator
    function placeBid(address _contract, uint256 _tokenId, Auction memory _auction, uint256 _bid)
        external
        nonReentrant
        returns (Auction memory)
    {
        _checkAuction(_contract, _tokenId, _auction);

        uint256 currentHighestBid = _auction.highestBid;
        if (_bid == 0 || (currentHighestBid.mulDivDown(_BPS + MIN_INCREMENT_BPS, _BPS) >= _bid)) {
            revert MinBidError(_bid);
        }

        uint256 currentTime = block.timestamp;
        uint96 expiration = _auction.startTime + _auction.duration;
        uint96 withMargin = _auction.lastBidTime + _MIN_NO_ACTION_MARGIN;
        uint96 max = withMargin > expiration ? withMargin : expiration;
        if (max < currentTime && currentHighestBid > 0) {
            revert AuctionOverError(max);
        }

        ERC20 token = ERC20(_auction.asset);
        if (currentHighestBid > 0) {
            token.safeTransfer(_auction.highestBidder, currentHighestBid);
        }

        address newBidder = msg.sender;
        token.safeTransferFrom(newBidder, address(this), _bid);

        _auction.highestBidder = newBidder;
        _auction.highestBid = _bid;
        _auction.lastBidTime = uint96(currentTime);

        _auctions[_contract][_tokenId] = _auction.hash();

        emit BidPlaced(_contract, _tokenId, newBidder, _bid, _auction.loanAddress, _auction.loanId);
        return _auction;
    }

    /// @inheritdoc IAuctionLoanLiquidator
    function settleAuction(Auction calldata _auction, IMultiSourceLoan.Loan calldata _loan) external nonReentrant {
        address collateralAddress = _loan.nftCollateralAddress;
        uint256 tokenId = _loan.nftCollateralTokenId;
        _checkAuction(collateralAddress, tokenId, _auction);

        if (_auction.highestBidder == address(0)) {
            revert NoBidsError();
        }

        uint256 currentTime = block.timestamp;
        uint96 expiration = _auction.startTime + _auction.duration;
        uint96 withMargin = _auction.lastBidTime + _MIN_NO_ACTION_MARGIN;
        if ((withMargin > currentTime) || (currentTime < expiration)) {
            uint96 max = withMargin > expiration ? withMargin : expiration;
            revert AuctionNotOverError(max);
        }

        ERC721(collateralAddress).transferFrom(address(this), _auction.highestBidder, tokenId);

        uint256 highestBid = _auction.highestBid;
        uint256 triggerFee = highestBid.mulDivDown(_auction.triggerFee, _BPS);
        uint256 proceeds = highestBid - 2 * triggerFee;
        ERC20 asset = ERC20(_auction.asset);

        asset.safeTransfer(_auction.originator, triggerFee);
        asset.safeTransfer(msg.sender, triggerFee);
        asset.approve(address(_liquidationDistributor), proceeds);
        _liquidationDistributor.distribute(proceeds, _loan);
        IMultiSourceLoan(_auction.loanAddress).loanLiquidated(_auction.loanId, _loan);
        emit AuctionSettled(
            _auction.loanAddress,
            _auction.loanId,
            collateralAddress,
            tokenId,
            _auction.asset,
            proceeds,
            msg.sender,
            triggerFee
        );

        /// @dev Save gas + allow for future auctions for the same NFT
        delete _auctions[collateralAddress][tokenId];
    }

    /// @inheritdoc IAuctionLoanLiquidator
    function getAuctionHash(address _contract, uint256 _tokenId) external view returns (bytes32) {
        return _auctions[_contract][_tokenId];
    }

    function _updateTriggerFee(uint256 triggerFee) private {
        if (triggerFee > MAX_TRIGGER_FEE) {
            revert InvalidTriggerFee(triggerFee);
        }
        _triggerFee = triggerFee;

        emit TriggerFeeUpdated(triggerFee);
    }

    /// @dev check it the auction provided matches the one saved (using hashes)
    function _checkAuction(address _contract, uint256 _tokenId, Auction memory _auction) private view {
        if (_auctions[_contract][_tokenId] != _auction.hash()) {
            revert InvalidHashAuctionError();
        }
    }
}
