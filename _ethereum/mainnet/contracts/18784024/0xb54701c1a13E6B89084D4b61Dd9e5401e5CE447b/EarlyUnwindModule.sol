// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IERC721.sol";

import "./IModule.sol";
import "./Utils.sol";
import "./ISeaport.sol";
import "./IWETH.sol";
import "../core/Lockers.sol" as Lockers;
import "./AddressProvider.sol";

/// @title Cyan Wallet EarlyUnwindModule Module for OpenSea
/// @author Bulgantamir Gankhuyag - <bulgaa@usecyan.com>
/// @author Naranbayar Uuganbayar - <naba@usecyan.com>
/// @author Munkhzul Boldbaatar
contract EarlyUnwindModule is IModule {
    AddressProvider private constant addressProvider = AddressProvider(0xCF9A19D879769aDaE5e4f31503AAECDa82568E55);

    /// @inheritdoc IModule
    function handleTransaction(
        address collection,
        uint256 value,
        bytes calldata data
    ) public payable override returns (bytes memory) {
        return Utils._execute(collection, value, data);
    }

    /// @notice Allows operators to sell the locked token.
    ///     Note: Can only sell if token is locked.
    function earlyUnwind(
        uint256 payAmount,
        uint256 sellPrice,
        address collectionAddress,
        uint256 tokenId,
        ISeaport.OfferData calldata offerInput
    ) external {
        IWETH weth = IWETH(addressProvider.addresses("WETH"));
        IERC721 collection = IERC721(collectionAddress);

        require(!Lockers.isLockedByApePlan(address(collection), tokenId), "Token has ape lock");
        require(payAmount <= sellPrice, "Selling price must be higher than payment amount");
        require(collection.ownerOf(tokenId) == address(this), "Token is not owned by the wallet");
        collection.approve(addressProvider.addresses("SEAPORT_CONDUIT"), tokenId);

        uint256 userBalance = weth.balanceOf(address(this));

        ISeaport(addressProvider.addresses("SEAPORT_1_5")).matchAdvancedOrders(
            offerInput.orders,
            offerInput.criteriaResolvers,
            offerInput.fulfillments,
            address(this)
        );
        require(userBalance + sellPrice == weth.balanceOf(address(this)), "Insufficient balance");
        require(collection.ownerOf(tokenId) != address(this), "Token is owned by the wallet");
        weth.approve(msg.sender, payAmount);
    }
}
