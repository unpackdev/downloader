// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ReentrancyGuardUpgradeable.sol";

import "./Constants.sol";

import "./Core.sol";

import "./Payment.sol";

/*
 * @notice revert in case of price below MIN_PRICE
 */
error Direct_Sale_Price_Too_Low();
/*
 * @notice revert in case of nft is been on list
 */
error Direct_Sale_Not_The_Owner(address msgSender, address seller);

error Direct_Sale_Amount_Cannot_Be_Zero();

error Direct_Sale_Contract_Address_Is_Not_Approved(address nftAddress);

error Direct_Sale_Not_A_Valid_Params_For_Buy();

error Direct_Sale_Required_Amount_To_Big_To_Buy();

error Direct_Sale_Buyer_Is_Not_Exist();

error Direct_Sale_Not_Enough_Ether_To_Buy();

abstract contract DirectSale is
    Constants,
    Core,
    Payment,
    ReentrancyGuardUpgradeable
{
    struct DirectSaleList {
        address seller;
        uint256 amount;
        uint256 price;
    }

    uint256 internal _directSaleId;

    mapping(address => mapping(uint256 => mapping(uint256 => DirectSaleList)))
        private _assetAndSaleIdToDirectSale;

    uint256[1000] private ______gap;

    event ListDirectSale(
        uint256 saleId,
        address indexed nftAddress,
        uint256 tokenId,
        address indexed seller,
        uint256 amount,
        uint256 price,
        address[] royaltiesPayees,
        uint256[] royaltiesShares
    );

    event UpdateDirectSale(
        uint256 saleId,
        address indexed nftAddress,
        uint256 tokenId,
        address indexed seller,
        uint256 price,
        address[] royaltiesPayees,
        uint256[] royaltiesShares
    );

    event CancelDirectSale(
        address indexed nftAddress,
        uint256 tokenId,
        uint256 saleId,
        address indexed seller
    );

    event BuyDirectSale(
        address indexed nftAddress,
        uint256 tokenId,
        uint256 saleId,
        uint256 amount,
        address indexed buyer,
        uint256 dissrupCut,
        address indexed seller,
        uint256 sellerCut,
        address[] royalties,
        uint256[] royaltiesCuts
    );

    function listDirectSale(
        address nftAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        address[] calldata royaltiesPayees,
        uint256[] calldata royaltiesShares
    ) external nonReentrant {
        if (price < Constants.MIN_PRICE) {
            // revert in case of price below MIN_PRICE
            revert Direct_Sale_Price_Too_Low();
        }

        if (amount == 0) {
            // revert in case amount is 0
            revert Direct_Sale_Amount_Cannot_Be_Zero();
        }

        if (_saleContractAllowlist[nftAddress] == false) {
            // revert in case contract is not approved by dissrup
            revert Direct_Sale_Contract_Address_Is_Not_Approved(nftAddress);
        }
        if (royaltiesPayees.length > 0) {
            _checkRoyalties(royaltiesPayees, royaltiesShares);
        }

        DirectSaleList storage directSale = _assetAndSaleIdToDirectSale[
            nftAddress
        ][tokenId][++_directSaleId];

        address seller = msg.sender;

        // transfer asset to contract
        _trasferNFT(seller, address(this), nftAddress, tokenId, amount);

        _setRoyalties(
            SaleType.DirectSale,
            _directSaleId,
            royaltiesPayees,
            royaltiesShares
        );

        // save to local map  the sale params
        directSale.seller = seller;
        directSale.amount = amount;
        directSale.price = price;

        emit ListDirectSale(
            _directSaleId,
            nftAddress,
            tokenId,
            seller,
            amount,
            price,
            royaltiesPayees,
            royaltiesShares
        );
    }

    function updateDirectSale(
        address nftAddress,
        uint256 tokenId,
        uint256 saleId,
        uint256 price,
        address[] calldata royaltiesPayees,
        uint256[] calldata royaltiesShares
    ) external nonReentrant {
        DirectSaleList storage directSale = _assetAndSaleIdToDirectSale[
            nftAddress
        ][tokenId][saleId];

        address seller = directSale.seller;

        if (seller != msg.sender) {
            //revert in case the msg.sender is not the owner (the lister) of the list
            revert Direct_Sale_Not_The_Owner(msg.sender, seller);
        }

        // check price
        if (price < MIN_PRICE) {
            revert Direct_Sale_Price_Too_Low();
        }

        // update price in storage
        directSale.price = price;

        if (royaltiesPayees.length > 0) {
            _checkRoyalties(royaltiesPayees, royaltiesShares);

            _setRoyalties(
                SaleType.DirectSale,
                saleId,
                royaltiesPayees,
                royaltiesShares
            );
        }
        emit UpdateDirectSale(
            saleId,
            nftAddress,
            tokenId,
            seller,
            price,
            royaltiesPayees,
            royaltiesShares
        );
    }

    function cancelDirectSale(
        address nftAddress,
        uint256 tokenId,
        uint256 saleId
    ) external nonReentrant {
        DirectSaleList memory directSale = _assetAndSaleIdToDirectSale[
            nftAddress
        ][tokenId][saleId];

        if (msg.sender != directSale.seller) {
            revert Direct_Sale_Not_The_Owner(msg.sender, directSale.seller);
        }

        _trasferNFT(
            address(this),
            directSale.seller,
            nftAddress,
            tokenId,
            directSale.amount
        );

        _unlistDirect(nftAddress, tokenId, saleId);

        emit CancelDirectSale(nftAddress, tokenId, saleId, directSale.seller);
    }

    function buyDirectSale(
        address nftAddress,
        uint256 tokenId,
        uint256 saleId,
        uint256 amount
    ) external payable nonReentrant {
        DirectSaleList storage directSale = _assetAndSaleIdToDirectSale[
            nftAddress
        ][tokenId][saleId];

        if (directSale.seller == address(0)) {
            // revert in case of a direct sale list is not exist
            revert Direct_Sale_Not_A_Valid_Params_For_Buy();
        }

        if (directSale.amount < amount) {
            // revert in case the require to buy is more then exist in marketplace
            revert Direct_Sale_Required_Amount_To_Big_To_Buy();
        }

        uint256 totalPrice = directSale.price * amount;
        address buyer = msg.sender;

        uint256 payment = msg.value;

        if (payment < totalPrice) {
            revert Direct_Sale_Not_Enough_Ether_To_Buy();
        }

        if (payment > totalPrice) {
            uint256 refund = payment - totalPrice;
            payable(buyer).transfer(refund);
        }

        _trasferNFT(address(this), buyer, nftAddress, tokenId, amount);

        directSale.amount = directSale.amount - amount;

        (
            uint256 dissrupCut,
            uint256 sellerCut,
            address[] memory royaltiesPayees,
            uint256[] memory royaltiesCuts
        ) = _splitPayment(
                directSale.seller,
                totalPrice,
                SaleType.DirectSale,
                saleId
            );

        emit BuyDirectSale(
            nftAddress,
            tokenId,
            saleId,
            amount,
            buyer,
            dissrupCut,
            directSale.seller,
            sellerCut,
            royaltiesPayees,
            royaltiesCuts
        );
        if (directSale.amount == 0) {
            _unlistDirect(nftAddress, tokenId, saleId);
        }
    }

    function _unlistDirect(
        address nftAddress,
        uint256 tokenId,
        uint256 saleId
    ) private {
        delete _saleToRoyalties[SaleType.DirectSale][saleId];
        delete _assetAndSaleIdToDirectSale[nftAddress][tokenId][saleId];
    }
}
