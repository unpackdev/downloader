// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";

import "./ITransferProxy.sol";
import "./MessageSigning.sol";
import "./IERC2981Royalties.sol";

contract BaseExchange is OwnableUpgradeable, MessageSigning {
    address payable public beneficiary;
    ITransferProxy public transferProxy;

    struct OrderTransfers {
        /* total order value */
        uint256 total;
        /* total value for seller (total - sellerServiceFees - royalties) */
        uint256 sellerEndValue;
        /* total transaction */
        uint256 totalTransaction;
        /* all service fees */
        uint256 serviceFees;
        /* royalties amount to transfer */
        uint256 royaltiesAmount;
        /* royalties recipient */
        address royaltiesRecipient;
    }

    function __BaseExchange_init(
        address payable _beneficiary,
        address _transferProxy
    ) internal initializer {
        __Ownable_init();

        setBeneficiary(_beneficiary);
        setTransferProxy(_transferProxy);
    }

    function setTransferProxy(address transferProxy_) public virtual onlyOwner {
        require(transferProxy_ != address(0));
        transferProxy = ITransferProxy(transferProxy_);
    }

    function setBeneficiary(address payable beneficiary_)
        public
        virtual
        onlyOwner
    {
        require(beneficiary_ != address(0));
        beneficiary = beneficiary_;
    }

    function _computeValues(
        uint256 unitPrice,
        address token,
        uint256 tokenId,
        uint256 amount,
        uint256 buyerServiceFee,
        uint256 sellerServiceFee
    ) internal view returns (OrderTransfers memory orderTransfers) {
        orderTransfers.total = unitPrice * amount;
        uint256 buyerFee = (orderTransfers.total * buyerServiceFee) / 10000;
        uint256 sellerFee = (orderTransfers.total * sellerServiceFee) / 10000;

        // total of transaction value (price + buyerFee)
        orderTransfers.totalTransaction = orderTransfers.total + buyerFee;
        // seller end value: price - sellerFee
        orderTransfers.sellerEndValue = orderTransfers.total - sellerFee;
        // all fees
        orderTransfers.serviceFees = sellerFee + buyerFee;

        (address royaltiesRecipient, uint256 royaltiesAmount) = _getRoyalties(
            token,
            tokenId,
            orderTransfers.total
        );

        // if there are royalties
        if (
            royaltiesAmount > 0 &&
            royaltiesAmount <= orderTransfers.sellerEndValue
        ) {
            orderTransfers.royaltiesRecipient = royaltiesRecipient;
            orderTransfers.royaltiesAmount = royaltiesAmount;
            // substract royalties to end value
            orderTransfers.sellerEndValue =
                orderTransfers.sellerEndValue -
                royaltiesAmount;
        }
    }

    function _getRoyalties(
        address token,
        uint256 tokenId,
        uint256 saleValue
    )
        internal
        view
        virtual
        returns (address royaltiesRecipient, uint256 royaltiesAmount)
    {
        IERC2981Royalties withRoyalties = IERC2981Royalties(token);
        if (
            withRoyalties.supportsInterface(type(IERC2981Royalties).interfaceId)
        ) {
            (royaltiesRecipient, royaltiesAmount) = withRoyalties.royaltyInfo(
                tokenId,
                saleValue
            );
        }
    }
}
