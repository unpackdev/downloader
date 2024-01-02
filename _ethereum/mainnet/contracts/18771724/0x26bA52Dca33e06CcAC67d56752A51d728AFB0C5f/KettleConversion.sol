// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Math.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./ERC721Holder.sol";
import "./ERC1155Holder.sol";

import "./FlashLoanSimpleReceiverBase.sol";
import "./IPoolAddressesProvider.sol";

import "./IKettleV1.sol";
import "./CollateralVerifier.sol";
import "./Structs.sol";

import "./IKettleV2.sol";
import "./Structs.sol";

import "./Errors.sol";

contract KettleConversion is FlashLoanSimpleReceiverBase, ERC721Holder, ERC1155Holder {
    using Math for uint256;
    using SafeERC20 for IERC20;

    address public immutable KETTLE_V1_ADDRESS;
    address public immutable KETTLE_V2_ADDRESS;

    constructor(
        address _addressProvider,
        address _kettleV1Address,
        address _kettleV2Address
    ) FlashLoanSimpleReceiverBase(IPoolAddressesProvider(_addressProvider)) {
        KETTLE_V1_ADDRESS = _kettleV1Address;
        KETTLE_V2_ADDRESS = _kettleV2Address;
    }

    /// @notice refinance a kettle v1 loan into a kettle v2 loan
    /// @param amount amount of the loan to refinance
    /// @param lienId id of the lien to refinance
    /// @param lien lien to refinance
    /// @param offer loan offer to refinance into
    /// @param auth loan offer auth to refinance into
    /// @param offerSignature loan offer signature to refinance into
    /// @param authSignature loan offer auth signature to refinance into
    function refinanceV1V2(
        uint256 amount,
        uint256 lienId,
        Lien calldata lien,
        LoanOffer calldata offer,
        OfferAuth calldata auth,
        bytes calldata offerSignature,
        bytes calldata authSignature
    ) public returns (uint256) {

        /// check that the caller is the borrower
        if (msg.sender != lien.borrower) {
            revert CallerMustBeBorrower();
        }

        // get repayment amount
        uint256 repaymentAmount = IKettleV1(KETTLE_V1_ADDRESS).getRepaymentAmount(
            lien.borrowAmount,
            lien.rate,
            lien.duration
        );

        // encode params for payback
        bytes memory params = abi.encode(
            amount,
            lienId,
            lien,
            offer,
            auth,
            offerSignature,
            authSignature
        );

        // request funds
        POOL.flashLoanSimple(address(this), lien.currency, repaymentAmount, params, 0);

        return repaymentAmount;
    }

    /// @notice this function is called after your contract has received the flash loaned amount
    /// @param asset address of the asset being flash loaned
    /// @param amount amount of the asset being flash loaned
    /// @param premium amount of the premium being paid
    /// @param initiator address of the flash loan initiator
    /// @param _params encoded parameters for the flash loan
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata _params
    ) external override returns (bool) {

        /// kettle conversion must be the initiator
        if (initiator != address(this)) {
            revert InitiatorMustBeKettle();
        }

        /// pool must be the caller
        if (msg.sender != address(POOL)) {
            revert CallerMustBePool();
        }

        /// decode parameters from params bytes
        (
            uint256 _amount,
            uint256 lienId,
            Lien memory lien,
            LoanOffer memory offer,
            OfferAuth memory auth,
            bytes memory offerSignature,
            bytes memory authSignature
        ) = abi.decode(_params, (uint256, uint256, Lien, LoanOffer, OfferAuth, bytes, bytes));        

        /// check lien collection matches offer collection
        if (lien.collection != offer.collection) {
            revert CollectionsDoNotMatch();
        }

        /// check lien currency matches offer currency
        if (lien.currency != offer.currency) {
            revert CurrenciesDoNotMatch();
        }

        /// check lien size matches offer size
        if (lien.amount != offer.size) {
            revert CollateralSizesDoNotMatch();
        }

        /// check lien collateral type matches offer collateral type
        if (lien.collateralType != CollateralVerifier.mapCollateralType(offer.collateralType)) {
            revert CollateralTypesDoNotMatch();
        }

        /// check lien hash in memory matches lien hash in storage
        bytes32 lienHash = IKettleV1(KETTLE_V1_ADDRESS).liens(lienId);

        /// encode lien hash provided and make sure it matches lienId
        bytes32 _lienHash = keccak256(abi.encode(lien));
        if (lienHash != _lienHash) {
            revert LienHashesDoNotMatch();
        }

        /// grant kettle v1 approvals to withdraw currency
        IERC20(asset).approve(KETTLE_V1_ADDRESS, amount);

        /// repay kettle v1 loan
        IKettleV1(KETTLE_V1_ADDRESS).repay(lien, lienId);

        /// transfer the asset from borrower to contract
        /// grant kettle v2 approvals to withdraw asset
        if (lien.collateralType == uint8(CollateralType.ERC721)) {
            IERC721(lien.collection).safeTransferFrom(
                lien.borrower,
                address(this),
                lien.tokenId
            );

            IERC721(lien.collection).setApprovalForAll(KETTLE_V2_ADDRESS, true);
        } else {
            IERC1155(lien.collection).safeTransferFrom(
                lien.borrower,
                address(this),
                lien.tokenId,
                lien.amount,
                new bytes(0)
            );

            IERC1155(lien.collection).setApprovalForAll(KETTLE_V2_ADDRESS, true);
        }

        /// borrow kettle v2 loan
        IKettleV2(KETTLE_V2_ADDRESS).borrow(
            offer,
            auth,
            offerSignature,
            authSignature,
            _amount,
            lien.tokenId,
            lien.borrower,
            new bytes32[](0)
        );

        /// calculate amount owed
        uint owed = amount + premium;

        /// withdraw fee from borrower
        IERC20(asset).transferFrom(
            lien.borrower,
            address(this),
            owed
        );

        /// set allowance for total repayment
        IERC20(asset).approve(address(POOL), owed);

        return true;
    }
}
