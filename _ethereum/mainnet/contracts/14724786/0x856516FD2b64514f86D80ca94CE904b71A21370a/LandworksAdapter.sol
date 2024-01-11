// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./IERC721.sol";
import "./Address.sol";
import "./ILandworks.sol";
import "./BaseRentAdapter.sol";
import "./ITribeOne.sol";
import "./DataTypes.sol";
import "./LibLandworks.sol";
import "./TribeOneHelper.sol";

contract LandworksAdapter is BaseRentAdapter {
    using Address for address;
    enum RentStatus {
        NONE,
        RENTAL,
        DELISTED,
        WITHDRAWN
    }

    address constant LANDWORKS_ETHEREUM_PAYMENT_TOKEN = address(1);
    address constant TRIBEONE_ETHEREUM_PAYMENT_TOKEN = address(0);
    address public immutable LAND_WORKS_ADDRESS;
    // loanId => assetId
    mapping(uint256 => uint256) public rentAssetIdMap;
    mapping(uint256 => RentStatus) public rentStatusMap;

    bytes4 public constant ERC721_Interface = bytes4(0x80ac58cd);

    event LoanRented(uint256 indexed loanId, uint256 indexed assetId);
    event RentDelisted(uint256 indexed loanId, uint256 indexed assetId);
    event RentWithdraw(uint256 indexed loanId, uint256 indexed assetId);
    event ClaimRentFee(uint256 indexed loanId, address token, uint256 amount);
    event AdjustRentFee(uint256 indexed loanId, address token, uint256 totalRentFee, uint256 paidDebt);
    event ForceWithdraw(uint256 indexed loanId, bool isWithdraw);

    constructor(
        address _LAND_WORKS_ADDRESS,
        address _TRIBE_ONE_ADDRESS,
        address __devWallet
    ) BaseRentAdapter(_TRIBE_ONE_ADDRESS, __devWallet) {
        LAND_WORKS_ADDRESS = _LAND_WORKS_ADDRESS;
    }

    receive() external payable {}

    function listNFTforRenting(
        uint256 _metaverseId,
        uint256 _minPeriod,
        uint256 _maxPeriod,
        uint256 _maxFutureTime,
        address _paymentToken,
        uint256 _pricePerSecond,
        uint256 _loanId
    ) external {
        // Validate Listing
        DataTypes.NFTItem memory nftItem = ITribeOne(TRIBE_ONE_ADDRESS).getLoanNFTItem(_loanId);

        ITribeOne(TRIBE_ONE_ADDRESS).listNFTForRent(_loanId, msg.sender);

        _requireERC721(nftItem.nftAddress);

        IERC721(nftItem.nftAddress).approve(LAND_WORKS_ADDRESS, nftItem.nftId);

        // call list function in Landworks smart contract
        uint256 assetId = ILandworks(LAND_WORKS_ADDRESS).list(
            _metaverseId,
            nftItem.nftAddress, // _metaverseRegistry
            nftItem.nftId, // _metaverseAssetId
            _minPeriod,
            _maxPeriod,
            _maxFutureTime,
            _paymentToken,
            _pricePerSecond
        );

        rentAssetIdMap[_loanId] = assetId;
        rentStatusMap[_loanId] = RentStatus.RENTAL;

        emit LoanRented(_loanId, assetId);
    }

    function delistNFTFromRenting(uint256 _loanId) external nonReentrant {
        _delistNFTFromRenting(_loanId, false);
    }

    function _delistNFTFromRenting(uint256 _loanId, bool isForce) private {
        DataTypes.NFTItem memory nftItem = ITribeOne(TRIBE_ONE_ADDRESS).getLoanNFTItem(_loanId);

        require(
            ITribeOne(TRIBE_ONE_ADDRESS).isAvailableRentalAction(_loanId, msg.sender) || isForce,
            "Only loan borrower or T1 can delist."
        );

        uint256 assetId = rentAssetIdMap[_loanId];

        address paymentToken = ILandworks(LAND_WORKS_ADDRESS).assetAt(assetId).paymentToken;
        uint256 feeAmount = _getRentFeeAmount(assetId, paymentToken);

        ILandworks(LAND_WORKS_ADDRESS).delist(assetId);
        if (IERC721(nftItem.nftAddress).ownerOf(nftItem.nftId) == address(this)) {
            // NFT was withdrawn
            IERC721(nftItem.nftAddress).approve(TRIBE_ONE_ADDRESS, nftItem.nftId);
            ITribeOne(TRIBE_ONE_ADDRESS).withdrawNFTFromRent(_loanId);
            rentStatusMap[_loanId] = RentStatus.WITHDRAWN;

            if (feeAmount > 0) {
                isForce
                    ? _safeTransferAsset(paymentToken, devWallet, feeAmount)
                    : _safeTransferAsset(paymentToken, msg.sender, feeAmount);
            }
            emit RentWithdraw(_loanId, assetId);
            if (!isForce) {
                emit ClaimRentFee(_loanId, paymentToken, feeAmount);
            }
        } else {
            // remain NFT in Landworks because someone is leasing it now
            rentStatusMap[_loanId] = RentStatus.DELISTED;

            emit RentDelisted(_loanId, assetId);
        }
    }

    function withdrawNFTFromRenting(uint256 _loanId) external nonReentrant {
        _withdraw(_loanId, false);
    }

    function _withdraw(uint256 _loanId, bool isForce) private {
        require(rentStatusMap[_loanId] == RentStatus.DELISTED, "LandworksAdapter: NFT shoud be delisted first");
        // DataTypes.Loan memory _loan = ITribeOne(TRIBE_ONE_ADDRESS).getLoans(_loanId);
        DataTypes.NFTItem memory nftItem = ITribeOne(TRIBE_ONE_ADDRESS).getLoanNFTItem(_loanId);

        require(
            ITribeOne(TRIBE_ONE_ADDRESS).isAvailableRentalAction(_loanId, msg.sender) || isForce,
            "Only loan borrower or T1 can withdraw"
        );

        uint256 assetId = rentAssetIdMap[_loanId];

        address paymentToken = ILandworks(LAND_WORKS_ADDRESS).assetAt(assetId).paymentToken;
        uint256 feeAmount = _getRentFeeAmount(assetId, paymentToken);

        ILandworks(LAND_WORKS_ADDRESS).withdraw(assetId);

        require(IERC721(nftItem.nftAddress).ownerOf(nftItem.nftId) == address(this), "LandworksAdapter: Withdraw was failed");

        if (feeAmount > 0) {
            isForce
                ? _safeTransferAsset(paymentToken, devWallet, feeAmount)
                : _safeTransferAsset(paymentToken, msg.sender, feeAmount);
        }
        IERC721(nftItem.nftAddress).approve(TRIBE_ONE_ADDRESS, nftItem.nftId);

        ITribeOne(TRIBE_ONE_ADDRESS).withdrawNFTFromRent(_loanId);

        rentStatusMap[_loanId] = RentStatus.WITHDRAWN;

        emit RentWithdraw(_loanId, assetId);
        if (!isForce) {
            emit ClaimRentFee(_loanId, paymentToken, feeAmount);
        }
    }

    function forceWithdrawNFTFromRent(uint256 loanId) external onlyTribeOne {
        if (rentStatusMap[loanId] == RentStatus.RENTAL) {
            _delistNFTFromRenting(loanId, true);
            emit ForceWithdraw(loanId, false);
        } else if (rentStatusMap[loanId] == RentStatus.DELISTED) {
            _withdraw(loanId, true);
            emit ForceWithdraw(loanId, true);
        }
    }

    function claimRentFee(uint256 loanId) external nonReentrant {
        require(
            ITribeOne(TRIBE_ONE_ADDRESS).isAvailableRentalAction(loanId, msg.sender),
            "Only loan borrower or T1 can withdraw"
        );

        uint256 assetId = rentAssetIdMap[loanId];

        address paymentToken = ILandworks(LAND_WORKS_ADDRESS).assetAt(assetId).paymentToken;

        uint256 feeAmount = _getRentFeeAmount(assetId, paymentToken);

        if (feeAmount > 0) {
            _claimFeeFromRental(assetId);

            _safeTransferAsset(paymentToken, msg.sender, feeAmount);

            emit ClaimRentFee(loanId, paymentToken, feeAmount);
        }
    }

    function adjustRentFee(uint256 loanId) external nonReentrant {
        // DataTypes.Loan memory _loan = ITribeOne(TRIBE_ONE_ADDRESS).getLoans(loanId);
        require(ITribeOne(TRIBE_ONE_ADDRESS).isAvailableRentalAction(loanId, msg.sender), "Only loan borrower can withdraw");

        uint256 assetId = rentAssetIdMap[loanId];
        address paymentToken = ILandworks(LAND_WORKS_ADDRESS).assetAt(assetId).paymentToken;

        (, address loanCurrency) = ITribeOne(TRIBE_ONE_ADDRESS).getLoanAsset(loanId);

        require(
            (paymentToken == LANDWORKS_ETHEREUM_PAYMENT_TOKEN && loanCurrency == TRIBEONE_ETHEREUM_PAYMENT_TOKEN) ||
                paymentToken == loanCurrency,
            "Rent payment token is not same as loan asset"
        );

        uint256 feeAmount = _getRentFeeAmount(assetId, paymentToken);

        if (feeAmount > 0) {
            _claimFeeFromRental(assetId);

            uint256 debtAmount = ITribeOne(TRIBE_ONE_ADDRESS).currentDebt(loanId);

            if (feeAmount > debtAmount) {
                TribeOneHelper.safeTransferAsset(loanCurrency, msg.sender, feeAmount - debtAmount);
            } else {
                debtAmount = feeAmount;
            }

            if (paymentToken == LANDWORKS_ETHEREUM_PAYMENT_TOKEN) {
                ITribeOne(TRIBE_ONE_ADDRESS).payInstallment{value: debtAmount}(loanId, debtAmount);
            } else {
                TribeOneHelper.safeApprove(paymentToken, TRIBE_ONE_ADDRESS, debtAmount);
                ITribeOne(TRIBE_ONE_ADDRESS).payInstallment(loanId, debtAmount);
            }

            emit AdjustRentFee(loanId, paymentToken, feeAmount, debtAmount);
        }
    }

    function _claimFeeFromRental(uint256 assetId) private {
        ILandworks(LAND_WORKS_ADDRESS).claimRentFee(assetId);
    }

    function getRentFeeAmount(uint256 loanId) external view returns (uint256) {
        uint256 assetId = rentAssetIdMap[loanId];
        address paymentToken = ILandworks(LAND_WORKS_ADDRESS).assetAt(assetId).paymentToken;

        return _getRentFeeAmount(assetId, paymentToken);
    }

    function _getRentFeeAmount(uint256 assetId, address paymentToken) private view returns (uint256) {
        return ILandworks(LAND_WORKS_ADDRESS).assetRentFeesFor(assetId, paymentToken);
    }

    function _safeTransferAsset(
        address token,
        address to,
        uint256 amount
    ) private {
        if (token == LANDWORKS_ETHEREUM_PAYMENT_TOKEN) {
            TribeOneHelper.safeTransferETH(to, amount);
        } else {
            TribeOneHelper.safeTransfer(token, to, amount);
        }
    }

    function _requireERC721(address nftAddress) internal view {
        require(nftAddress.isContract(), "The NFT Address should be a contract");

        // ERC721Interface nftRegistry = ERC721Interface(nftAddress);
        require(IERC165(nftAddress).supportsInterface(ERC721_Interface), "The NFT contract has an invalid ERC721 implementation");
    }
}
