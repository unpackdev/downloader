// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./IERC721.sol";
import "./IERC20.sol";

import "./IRoyaltiesProvider.sol";
import "./IPaymentManager.sol";

abstract contract EndemicExchangeCore {
    IRoyaltiesProvider public royaltiesProvider;
    IPaymentManager public paymentManager;
    address public approvedSigner;

    uint16 internal constant MAX_FEE = 10000;
    address internal constant ZERO_ADDRESS = address(0);

    error InvalidAddress();
    error UnsufficientCurrencySupplied();
    error InvalidPaymentMethod();
    error InvalidCaller();
    error InvalidPrice();
    error InvalidConfiguration();
    error AuctionNotStarted();
    error InvalidDuration();

    /// @notice Fired when auction is successfully completed
    event AuctionSuccessful(
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 indexed totalPrice,
        address seller,
        address winner,
        uint256 totalFees,
        address paymentErc20TokenAddress
    );

    modifier onlySupportedERC20Payments(address paymentErc20TokenAddress) {
        if (
            paymentErc20TokenAddress == ZERO_ADDRESS ||
            !paymentManager.isPaymentMethodSupported(paymentErc20TokenAddress)
        ) revert InvalidPaymentMethod();

        _;
    }

    function _calculateFees(
        address paymentMethodAddress,
        address nftContract,
        uint256 tokenId,
        uint256 price
    )
        internal
        view
        returns (
            uint256 makerCut,
            uint256 takerCut,
            address royaltiesRecipient,
            uint256 royaltieFee,
            uint256 totalCut
        )
    {
        (uint256 takerFee, uint256 makerFee) = paymentManager
            .getPaymentMethodFees(paymentMethodAddress);

        takerCut = _calculateCut(takerFee, price);
        makerCut = _calculateCut(makerFee, price);

        (royaltiesRecipient, royaltieFee) = royaltiesProvider
            .calculateRoyaltiesAndGetRecipient(nftContract, tokenId, price);

        totalCut = takerCut + makerCut;
    }

    function _calculateOfferFees(
        address paymentMethodAddress,
        address nftContract,
        uint256 tokenId,
        uint256 price
    )
        internal
        view
        returns (
            uint256 makerCut,
            address royaltiesRecipient,
            uint256 royaltieFee,
            uint256 totalCut,
            uint256 listingPrice
        )
    {
        (uint256 takerFee, uint256 makerFee) = paymentManager
            .getPaymentMethodFees(paymentMethodAddress);

        listingPrice = (price * MAX_FEE) / (takerFee + MAX_FEE);

        uint256 takerCut = price - listingPrice;
        makerCut = _calculateCut(makerFee, listingPrice);

        (royaltiesRecipient, royaltieFee) = royaltiesProvider
            .calculateRoyaltiesAndGetRecipient(
                nftContract,
                tokenId,
                listingPrice
            );

        totalCut = takerCut + makerCut;
    }

    function _calculateTakerCut(
        address paymentErc20TokenAddress,
        uint256 price
    ) internal view returns (uint256) {
        (uint256 takerFee, ) = paymentManager.getPaymentMethodFees(
            paymentErc20TokenAddress
        );

        return _calculateCut(takerFee, price);
    }

    function _calculateCut(
        uint256 fee,
        uint256 amount
    ) internal pure returns (uint256) {
        return (amount * fee) / MAX_FEE;
    }

    function _requireSupportedPaymentMethod(
        address paymentMethodAddress
    ) internal view {
        if (paymentMethodAddress == ZERO_ADDRESS) return;

        if (!paymentManager.isPaymentMethodSupported(paymentMethodAddress)) {
            revert InvalidPaymentMethod();
        }
    }

    function _requireSufficientCurrencySupplied(
        uint256 sufficientAmount,
        address paymentMethodAddress,
        address buyer
    ) internal view {
        if (paymentMethodAddress == ZERO_ADDRESS) {
            _requireSufficientEtherSupplied(sufficientAmount);
        } else {
            _requireSufficientErc20AmountAvailable(
                sufficientAmount,
                paymentMethodAddress,
                buyer
            );
        }
    }

    function _requireSufficientEtherSupplied(
        uint256 sufficientAmount
    ) internal view {
        if (msg.value < sufficientAmount) {
            revert UnsufficientCurrencySupplied();
        }
    }

    function _requireSufficientErc20AmountAvailable(
        uint256 sufficientAmount,
        address paymentMethodAddress,
        address buyer
    ) internal view {
        IERC20 ERC20PaymentToken = IERC20(paymentMethodAddress);

        uint256 contractAllowance = ERC20PaymentToken.allowance(
            buyer,
            address(this)
        );
        if (contractAllowance < sufficientAmount) {
            revert UnsufficientCurrencySupplied();
        }

        uint256 buyerBalance = ERC20PaymentToken.balanceOf(buyer);
        if (buyerBalance < sufficientAmount) {
            revert UnsufficientCurrencySupplied();
        }
    }

    function _updateExchangeConfiguration(
        address _royaltiesProvider,
        address _paymentManager,
        address _approvedSigner
    ) internal {
        if (
            _royaltiesProvider == ZERO_ADDRESS ||
            _paymentManager == ZERO_ADDRESS
        ) revert InvalidAddress();

        royaltiesProvider = IRoyaltiesProvider(_royaltiesProvider);
        paymentManager = IPaymentManager(_paymentManager);
        approvedSigner = _approvedSigner;
    }

    /**
     * @notice See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[999] private __gap;
}
