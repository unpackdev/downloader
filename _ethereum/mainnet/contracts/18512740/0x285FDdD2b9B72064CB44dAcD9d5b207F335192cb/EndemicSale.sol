// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./ReentrancyGuardUpgradeable.sol";
import "./IERC721.sol";
import "./ECDSA.sol";

import "./EndemicFundsDistributor.sol";
import "./EndemicExchangeCore.sol";
import "./EndemicEIP712.sol";
import "./EndemicNonceManager.sol";

abstract contract EndemicSale is
    ReentrancyGuardUpgradeable,
    EndemicFundsDistributor,
    EndemicExchangeCore,
    EndemicEIP712,
    EndemicNonceManager
{
    using ECDSA for bytes32;

    bytes32 private constant SALE_TYPEHASH =
        keccak256(
            "Sale(uint256 orderNonce,address nftContract,uint256 tokenId,address paymentErc20TokenAddress,uint256 price,address buyer,uint256 expiresAt)"
        );

    struct Sale {
        address seller;
        uint256 orderNonce;
        address nftContract;
        uint256 tokenId;
        address paymentErc20TokenAddress;
        uint256 price;
        address buyer;
        uint256 expiresAt;
    }

    event SaleSuccess(
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed seller,
        address buyer,
        uint256 price,
        uint256 totalFees,
        address paymentErc20TokenAddress
    );

    error SaleExpired();

    function buyFromSale(
        uint8 v,
        bytes32 r,
        bytes32 s,
        Sale calldata sale
    ) external payable nonReentrant {
        if (block.timestamp > sale.expiresAt) revert SaleExpired();

        if (
            (sale.buyer != address(0) && sale.buyer != msg.sender) ||
            sale.seller == msg.sender
        ) {
            revert InvalidCaller();
        }

        _verifySignature(v, r, s, sale);

        uint256 takerCut = _calculateTakerCut(
            sale.paymentErc20TokenAddress,
            sale.price
        );

        _requireSupportedPaymentMethod(sale.paymentErc20TokenAddress);
        _requireSufficientCurrencySupplied(
            sale.price + takerCut,
            sale.paymentErc20TokenAddress,
            msg.sender
        );

        _invalidateNonce(sale.seller, sale.orderNonce);

        _finalizeSale(
            sale.nftContract,
            sale.tokenId,
            sale.paymentErc20TokenAddress,
            sale.seller,
            sale.price
        );
    }

    function _finalizeSale(
        address nftContract,
        uint256 tokenId,
        address paymentErc20TokenAddress,
        address seller,
        uint256 price
    ) internal {
        (
            uint256 makerCut,
            ,
            address royaltiesRecipient,
            uint256 royaltieFee,
            uint256 totalCut
        ) = _calculateFees(
                paymentErc20TokenAddress,
                nftContract,
                tokenId,
                price
            );

        IERC721(nftContract).transferFrom(seller, msg.sender, tokenId);

        _distributeFunds(
            price,
            makerCut,
            totalCut,
            royaltieFee,
            royaltiesRecipient,
            seller,
            msg.sender,
            paymentErc20TokenAddress
        );

        emit SaleSuccess(
            nftContract,
            tokenId,
            seller,
            msg.sender,
            price,
            totalCut,
            paymentErc20TokenAddress
        );
    }

    function _verifySignature(
        uint8 v,
        bytes32 r,
        bytes32 s,
        Sale calldata sale
    ) internal view {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _buildDomainSeparator(),
                keccak256(
                    abi.encode(
                        SALE_TYPEHASH,
                        sale.orderNonce,
                        sale.nftContract,
                        sale.tokenId,
                        sale.paymentErc20TokenAddress,
                        sale.price,
                        sale.buyer,
                        sale.expiresAt
                    )
                )
            )
        );

        if (digest.recover(v, r, s) != sale.seller) {
            revert InvalidSignature();
        }
    }

    /**
     * @notice See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[1000] private __gap;
}
