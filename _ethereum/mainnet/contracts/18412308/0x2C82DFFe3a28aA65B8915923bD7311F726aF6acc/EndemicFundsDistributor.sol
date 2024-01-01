// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./IERC20.sol";

abstract contract EndemicFundsDistributor {
    address public feeRecipientAddress;

    error FeeTransferFailed();
    error RoyaltiesTransferFailed();
    error FundsTransferFailed();

    function _distributeFunds(
        uint256 price,
        uint256 makerCut,
        uint256 totalCut,
        uint256 royaltieFee,
        address royaltiesRecipient,
        address seller,
        address buyer,
        address paymentErc20TokenAddress
    ) internal {
        uint256 sellerProceeds = price - makerCut - royaltieFee;

        if (paymentErc20TokenAddress == address(0)) {
            _distributeEtherFunds(
                royaltieFee,
                totalCut,
                sellerProceeds,
                royaltiesRecipient,
                seller
            );
        } else {
            _distributeErc20Funds(
                royaltieFee,
                totalCut,
                sellerProceeds,
                royaltiesRecipient,
                seller,
                buyer,
                paymentErc20TokenAddress
            );
        }
    }

    function _distributeEtherFunds(
        uint256 royaltieFee,
        uint256 totalCut,
        uint256 sellerProceeds,
        address royaltiesRecipient,
        address seller
    ) internal {
        if (royaltieFee > 0) {
            _transferEtherRoyalties(royaltiesRecipient, royaltieFee);
        }

        if (totalCut > 0) {
            _transferEtherFees(totalCut);
        }

        _transferEtherFunds(seller, sellerProceeds);
    }

    function _distributeErc20Funds(
        uint256 royaltieFee,
        uint256 totalCut,
        uint256 sellerProceeds,
        address royaltiesRecipient,
        address seller,
        address buyer,
        address paymentErc20TokenAddress
    ) internal {
        IERC20 ERC20PaymentToken = IERC20(paymentErc20TokenAddress);

        if (royaltieFee > 0) {
            _transferErc20Royalties(
                ERC20PaymentToken,
                buyer,
                royaltiesRecipient,
                royaltieFee
            );
        }

        if (totalCut > 0) {
            _transferErc20Fees(ERC20PaymentToken, buyer, totalCut);
        }

        _transferErc20Funds(ERC20PaymentToken, buyer, seller, sellerProceeds);
    }

    function _transferEtherFees(uint256 value) internal {
        (bool success, ) = payable(feeRecipientAddress).call{value: value}("");

        if (!success) revert FeeTransferFailed();
    }

    function _transferErc20Fees(
        IERC20 ERC20PaymentToken,
        address sender,
        uint256 value
    ) internal {
        bool success = ERC20PaymentToken.transferFrom(
            sender,
            feeRecipientAddress,
            value
        );

        if (!success) revert FeeTransferFailed();
    }

    function _transferEtherRoyalties(
        address royaltiesRecipient,
        uint256 royaltiesCut
    ) internal {
        (bool success, ) = payable(royaltiesRecipient).call{
            value: royaltiesCut
        }("");

        if (!success) revert RoyaltiesTransferFailed();
    }

    function _transferErc20Royalties(
        IERC20 ERC20PaymentToken,
        address royaltiesSender,
        address royaltiesRecipient,
        uint256 royaltiesCut
    ) internal {
        bool success = ERC20PaymentToken.transferFrom(
            royaltiesSender,
            royaltiesRecipient,
            royaltiesCut
        );

        if (!success) revert RoyaltiesTransferFailed();
    }

    function _transferEtherFunds(address recipient, uint256 value) internal {
        (bool success, ) = payable(recipient).call{value: value}("");

        if (!success) revert FundsTransferFailed();
    }

    function _transferErc20Funds(
        IERC20 ERC20PaymentToken,
        address sender,
        address recipient,
        uint256 value
    ) internal {
        bool success = ERC20PaymentToken.transferFrom(sender, recipient, value);

        if (!success) revert FundsTransferFailed();
    }

    function _updateDistributorConfiguration(
        address _feeRecipientAddress
    ) internal {
        feeRecipientAddress = _feeRecipientAddress;
    }

    /**
     * @notice See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[1000] private __gap;
}
