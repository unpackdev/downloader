// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./Address.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./IElementExCheckerFeatureV2.sol";

interface IERC721OrdersFeature {
    function validateERC721BuyOrderSignature(LibNFTOrder.NFTBuyOrder calldata order, LibSignature.Signature calldata signature, bytes calldata takerData) external view;
    function getERC721BuyOrderInfo(LibNFTOrder.NFTBuyOrder calldata order) external view returns (LibNFTOrder.OrderInfo memory);
    function getERC721OrderStatusBitVector(address maker, uint248 nonceRange) external view returns (uint256);
    function getHashNonce(address maker) external view returns (uint256);
}

interface IERC1155OrdersFeature {
    function validateERC1155BuyOrderSignature(LibNFTOrder.ERC1155BuyOrder calldata order, LibSignature.Signature calldata signature, bytes calldata takerData) external view;
    function getERC1155BuyOrderInfo(LibNFTOrder.ERC1155BuyOrder calldata order) external view returns (LibNFTOrder.OrderInfo memory orderInfo);
    function getERC1155OrderNonceStatusBitVector(address maker, uint248 nonceRange) external view returns (uint256);
}

contract ElementExCheckerFeatureV2 is IElementExCheckerFeatureV2 {

    using Address for address;

    address constant internal NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public immutable ELEMENT_EX;

    constructor(address elementEx) {
        ELEMENT_EX = elementEx;
    }

    function checkERC721BuyOrderV2(
        LibNFTOrder.NFTBuyOrder memory order,
        LibSignature.Signature memory signature,
        bytes memory data
    ) external override view returns (
        BuyOrderCheckInfo memory info,
        bool validSignature
    ) {
        info.nonceCheck = !isERC721OrderNonceFilled(order.maker, order.nonce);
        info.propertiesCheck = checkProperties(order.expiry >> 252 == 8, order.nftProperties, order.nftId);
        _checkBuyOrder(order, getERC721BuyOrderInfo(order), info);

        validSignature = validateERC721BuyOrderSignatureV2(order, signature, data);
        return (info, validSignature);
    }

    function checkERC1155BuyOrderV2(
        LibNFTOrder.ERC1155BuyOrder memory order,
        LibSignature.Signature memory signature,
        bytes memory data
    ) external override view returns (
        BuyOrderCheckInfo memory info,
        bool validSignature
    ) {
        info.nonceCheck = !isERC1155OrderNonceCancelled(order.maker, order.nonce);
        info.propertiesCheck = checkProperties(false, order.erc1155TokenProperties, order.erc1155TokenId);

        LibNFTOrder.NFTBuyOrder memory nftOrder;
        assembly { nftOrder := order }
        _checkBuyOrder(nftOrder, getERC1155BuyOrderInfo(order), info);

        validSignature = validateERC1155BuyOrderSignatureV2(order, signature, data);
        return (info, validSignature);
    }

    function _checkBuyOrder(
        LibNFTOrder.NFTBuyOrder memory order,
        LibNFTOrder.OrderInfo memory orderInfo,
        BuyOrderCheckInfo memory info
    ) internal view {
        info.hashNonce = getHashNonce(order.maker);
        info.orderHash = orderInfo.orderHash;
        info.orderAmount = orderInfo.orderAmount;
        info.remainingAmount = orderInfo.remainingAmount;
        info.remainingAmountCheck = (info.remainingAmount > 0);

        info.makerCheck = (order.maker != address(0));
        info.takerCheck = (order.taker != ELEMENT_EX);
        info.listingTimeCheck = checkListingTime(order.expiry);
        info.expireTimeCheck = checkExpiryTime(order.expiry);
        info.feesCheck = checkFees(order.fees);

        info.erc20AddressCheck = checkERC20Address(address(order.erc20Token));
        info.erc20TotalAmount = calcERC20TotalAmount(order.erc20TokenAmount, order.fees);

        (
            info.erc20BalanceCheck,
            info.erc20Balance
        ) = checkERC20Balance(order.maker, address(order.erc20Token), info.erc20TotalAmount);

        (
            info.erc20AllowanceCheck,
            info.erc20Allowance
        ) = checkERC20Allowance(order.maker, address(order.erc20Token), info.erc20TotalAmount);

        info.success = (
            info.makerCheck &&
            info.takerCheck &&
            info.listingTimeCheck &&
            info.expireTimeCheck &&
            info.nonceCheck &&
            info.remainingAmountCheck &&
            info.feesCheck &&
            info.propertiesCheck &&
            info.erc20AddressCheck &&
            info.erc20BalanceCheck &&
            info.erc20AllowanceCheck
        );
    }

    function validateERC721BuyOrderSignatureV2(
        LibNFTOrder.NFTBuyOrder memory order,
        LibSignature.Signature memory signature,
        bytes memory data
    ) public override view returns (bool valid) {
        try IERC721OrdersFeature(ELEMENT_EX).validateERC721BuyOrderSignature(order, signature, data) {
            return true;
        } catch {}
        return false;
    }

    function validateERC1155BuyOrderSignatureV2(
        LibNFTOrder.ERC1155BuyOrder memory order,
        LibSignature.Signature memory signature,
        bytes memory data
    ) public override view returns (bool valid) {
        try IERC1155OrdersFeature(ELEMENT_EX).validateERC1155BuyOrderSignature(order, signature, data) {
            return true;
        } catch {}
        return false;
    }

    function getERC721BuyOrderInfo(
        LibNFTOrder.NFTBuyOrder memory order
    ) public override view returns (
        LibNFTOrder.OrderInfo memory orderInfo
    ) {
        try IERC721OrdersFeature(ELEMENT_EX).getERC721BuyOrderInfo(order) returns (LibNFTOrder.OrderInfo memory _orderInfo) {
            orderInfo = _orderInfo;
        } catch {}
        return orderInfo;
    }

    function getERC1155BuyOrderInfo(
        LibNFTOrder.ERC1155BuyOrder memory order
    ) internal view returns (
        LibNFTOrder.OrderInfo memory orderInfo
    ) {
        try IERC1155OrdersFeature(ELEMENT_EX).getERC1155BuyOrderInfo(order) returns (LibNFTOrder.OrderInfo memory _orderInfo) {
            orderInfo = _orderInfo;
        } catch {}
        return orderInfo;
    }

    function isERC721OrderNonceFilled(address account, uint256 nonce) internal view returns (bool filled) {
        uint256 bitVector = IERC721OrdersFeature(ELEMENT_EX).getERC721OrderStatusBitVector(account, uint248(nonce >> 8));
        uint256 flag = 1 << (nonce & 0xff);
        return (bitVector & flag) != 0;
    }

    function isERC1155OrderNonceCancelled(address account, uint256 nonce) internal view returns (bool filled) {
        uint256 bitVector = IERC1155OrdersFeature(ELEMENT_EX).getERC1155OrderNonceStatusBitVector(account, uint248(nonce >> 8));
        uint256 flag = 1 << (nonce & 0xff);
        return (bitVector & flag) != 0;
    }

    function getHashNonce(address maker) internal view returns (uint256) {
        return IERC721OrdersFeature(ELEMENT_EX).getHashNonce(maker);
    }

    function checkListingTime(uint256 expiry) internal pure returns (bool success) {
        uint256 listingTime = (expiry >> 32) & 0xffffffff;
        uint256 expiryTime = expiry & 0xffffffff;
        return listingTime < expiryTime;
    }

    function checkExpiryTime(uint256 expiry) internal view returns (bool success) {
        uint256 expiryTime = expiry & 0xffffffff;
        return expiryTime > block.timestamp;
    }

    function checkERC20Balance(address buyer, address erc20, uint256 erc20TotalAmount)
        internal
        view
        returns
        (bool success, uint256 balance)
    {
        if (erc20 == address(0) || erc20 == NATIVE_TOKEN_ADDRESS) {
            return (false, 0);
        }

        try IERC20(erc20).balanceOf(buyer) returns (uint256 _balance) {
            balance = _balance;
            success = (balance >= erc20TotalAmount);
        } catch {
            success = false;
            balance = 0;
        }
        return (success, balance);
    }

    function checkERC20Allowance(address buyer, address erc20, uint256 erc20TotalAmount)
        internal
        view
        returns
        (bool success, uint256 allowance)
    {
        if (erc20 == address(0) || erc20 == NATIVE_TOKEN_ADDRESS) {
            return (false, 0);
        }

        try IERC20(erc20).allowance(buyer, ELEMENT_EX) returns (uint256 _allowance) {
            allowance = _allowance;
            success = (allowance >= erc20TotalAmount);
        } catch {
            success = false;
            allowance = 0;
        }
        return (success, allowance);
    }

    function checkERC20Address(address erc20) internal view returns (bool) {
        if (erc20 != address(0) && erc20 != NATIVE_TOKEN_ADDRESS) {
            return erc20.isContract();
        }
        return false;
    }

    function checkFees(LibNFTOrder.Fee[] memory fees) internal view returns (bool success) {
        for (uint256 i = 0; i < fees.length; i++) {
            if (fees[i].recipient == ELEMENT_EX) {
                return false;
            }
            if (fees[i].feeData.length > 0 && !fees[i].recipient.isContract()) {
                return false;
            }
        }
        return true;
    }

    function checkProperties(bool isOfferMultiERC721s, LibNFTOrder.Property[] memory properties, uint256 nftId) internal view returns (bool success) {
        if (isOfferMultiERC721s) {
            if (properties.length == 0) {
                return false;
            }
        }
        if (properties.length > 0) {
            if (nftId != 0) {
                return false;
            }
            for (uint256 i = 0; i < properties.length; i++) {
                address propertyValidator = address(properties[i].propertyValidator);
                if (propertyValidator != address(0) && !propertyValidator.isContract()) {
                    return false;
                }
            }
        }
        return true;
    }

    function calcERC20TotalAmount(uint256 erc20TokenAmount, LibNFTOrder.Fee[] memory fees) internal pure returns (uint256) {
        uint256 sum = erc20TokenAmount;
        for (uint256 i = 0; i < fees.length; i++) {
            sum += fees[i].amount;
        }
        return sum;
    }
}
