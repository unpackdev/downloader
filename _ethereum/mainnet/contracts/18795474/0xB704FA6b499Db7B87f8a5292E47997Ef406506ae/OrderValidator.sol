// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
/* Gambulls Order Validator 2023 */

import "./LibSignature.sol";

import "./ContextUpgradeable.sol";
import "./EIP712Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC1155Upgradeable.sol";
import "./LibOrder.sol";
import "./SafeMathUpgradeable.sol";
import "./LibTransfer.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./BpLibrary.sol";
import "./LibOrderData.sol";
import "./IERC20Upgradeable.sol";
import "./LibAsset.sol";

abstract contract OrderValidator is Initializable, ContextUpgradeable, EIP712Upgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using LibSignature for bytes32;
    using LibTransfer for address;
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;
    using BpLibrary for uint256;

    bytes4 constant internal MAGICVALUE = 0x1626ba7e;

    function __OrderValidator_init_unchained(string memory name_, string memory version_) internal initializer {
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __EIP712_init_unchained(name_, version_);
    }

    function getPaymentAssetType(address token) internal pure returns(LibAsset.AssetType memory){
        LibAsset.AssetType memory result;
        if(token == address(0)) {
            result.assetClass = LibAsset.ETH_ASSET_CLASS;
            result.data = hex"0000000000000000000000000000000000000000";
        } else {
            result.assetClass = LibAsset.ERC20_ASSET_CLASS;
            result.data = abi.encode(token);
        }
        return result;
    }

    function isMatchAsset(LibOrder.Order memory orderLeft, LibOrder.Order memory orderRight) internal pure returns (bool) {
        if (orderRight.orderType == LibOrder.ORDER_BUY_TYPE) {
            require(keccak256(orderLeft.makeAsset.assetType.data) == keccak256(orderRight.takeAsset.assetType.data), "asset do not match");
            require(orderRight.takeAsset.value <= orderLeft.makeAsset.value, "invalid value");
            return true;
        } else if (orderRight.orderType == LibOrder.ORDER_SELL_TYPE) {
            require(keccak256(orderRight.makeAsset.assetType.data) == keccak256(orderLeft.takeAsset.assetType.data), "asset do not match");
            require(orderRight.makeAsset.value <= orderLeft.takeAsset.value, "invalid value");
            return true;
        } else {
            return false;
        }
    }

    function deal(LibOrder.Order memory orderLeft, LibOrder.Order memory orderRight, uint256 orderPaymentAmount)
    internal
    {
        require(isMatchAsset(orderLeft, orderRight) == true, "unsupported order type");
        uint256 payoutsAndOriginFeesAmount = transferPayoutsAndOriginFees(orderLeft, orderRight);

        uint256 currentAmount = orderPaymentAmount.sub(payoutsAndOriginFeesAmount);

        if (orderRight.orderType == LibOrder.ORDER_BUY_TYPE) {
            transferNFT(orderRight.takeAsset, orderLeft.maker, orderRight.maker);
            transferAmount(orderRight.makeAsset, orderRight.maker, orderLeft.maker, currentAmount);
        } else if (orderRight.orderType == LibOrder.ORDER_SELL_TYPE) {
            transferNFT(orderRight.makeAsset, orderRight.maker, orderLeft.maker);
            transferAmount(orderRight.takeAsset, orderLeft.maker, orderRight.maker, currentAmount);
        } else {
            revert("no order type");
        }
        
    }

    function transferNFT(LibAsset.Asset memory asset, address from, address to) internal {
        (address tokenAddress, uint tokenId) = abi.decode(asset.assetType.data, (address, uint256));
        if (asset.assetType.assetClass == LibAsset.ERC721_ASSET_CLASS) {
            require(asset.value == 1, "erc721 value error");
            IERC721Upgradeable(tokenAddress).safeTransferFrom(from, to, tokenId);
        } else if (asset.assetType.assetClass == LibAsset.ERC1155_ASSET_CLASS) {
            IERC1155Upgradeable(tokenAddress).safeTransferFrom(from, to, tokenId, asset.value, "");
        } else {
            revert("unsupported NFT");
        }
    }

    function transferPayoutsAndOriginFees(LibOrder.Order memory orderLeft, LibOrder.Order memory orderRight) internal returns (uint256) {
        (LibPart.Part[] memory leftPayouts, LibPart.Part[] memory leftOriginFees) = LibOrderData.parse(orderLeft.orderData);
        (LibPart.Part[] memory rightPayouts, LibPart.Part[] memory rightOriginFees) = LibOrderData.parse(orderRight.orderData);
        uint256 amount = 0;
        address from = orderLeft.maker;
        //transferPayouts left
        if (leftPayouts.length > 0) {
            LibAsset.AssetType memory leftAsset;
            uint256 leftPaymentAmount = 0;
            if (orderLeft.orderType == LibOrder.ORDER_SELL_TYPE) {
                leftAsset = orderLeft.takeAsset.assetType;
                leftPaymentAmount = orderLeft.takeAsset.value.mul(orderRight.takeAsset.value);
            } else if (orderLeft.orderType == LibOrder.ORDER_OFFER_TYPE) {
                leftAsset = orderLeft.makeAsset.assetType;
                leftPaymentAmount = orderLeft.makeAsset.value.mul(orderRight.makeAsset.value);
            } else {
                revert("no order type");
            }
            amount += transferParts(from, leftPaymentAmount, leftPayouts, leftAsset);
        }

        //transferPayouts right
        if (rightPayouts.length > 0) {
            LibAsset.AssetType memory rightAsset;
            uint256 rightPaymentAmount = 0;
            if (orderRight.orderType == LibOrder.ORDER_SELL_TYPE) {
                rightPaymentAmount = orderLeft.makeAsset.value.mul(orderRight.makeAsset.value);
                rightAsset = orderRight.takeAsset.assetType;
            } else if (orderRight.orderType == LibOrder.ORDER_BUY_TYPE) {
                rightPaymentAmount = orderLeft.takeAsset.value.mul(orderRight.takeAsset.value);
                rightAsset = orderLeft.takeAsset.assetType;
            } else {
                revert("no order type");
            }
            amount += transferParts(from, rightPaymentAmount, rightPayouts, rightAsset);
        }

        //transferOriginFees left
        if (leftOriginFees.length > 0) {
            LibAsset.AssetType memory leftAsset;
            uint256 leftPaymentAmount = 0;
            if (orderLeft.orderType == LibOrder.ORDER_SELL_TYPE) {
                leftPaymentAmount = orderLeft.takeAsset.value.mul(orderRight.takeAsset.value);
                leftAsset = orderLeft.takeAsset.assetType;
            } else if (orderLeft.orderType == LibOrder.ORDER_OFFER_TYPE) {
                leftPaymentAmount = orderLeft.makeAsset.value.mul(orderRight.makeAsset.value);
                leftAsset = orderLeft.makeAsset.assetType;
            } else {
                revert("no order type");
            }
            amount += transferParts(from, leftPaymentAmount, leftOriginFees, leftAsset);
        }

        //transferOriginFees right
        if (rightOriginFees.length > 0) {
            LibAsset.AssetType memory rightAsset;
            uint256 rightPaymentAmount = 0;
            if (orderRight.orderType == LibOrder.ORDER_SELL_TYPE) {
                rightPaymentAmount = orderLeft.makeAsset.value.mul(orderRight.makeAsset.value);
                rightAsset = orderRight.takeAsset.assetType;
            } else if (orderRight.orderType == LibOrder.ORDER_BUY_TYPE) {
                rightPaymentAmount = orderLeft.takeAsset.value.mul(orderRight.takeAsset.value);
                rightAsset = orderLeft.takeAsset.assetType;
            } else {
                revert("no order type");
            }
            amount += transferParts(from, rightPaymentAmount, rightOriginFees, rightAsset);
        }

        return amount;
    }

    function transferParts(address from, uint256 amount, LibPart.Part[] memory parts, LibAsset.AssetType memory asset) internal returns (uint256){
        require(parts.length > 0, "transferParts: nothing to transfer");
        uint256 totalAmount = 0;
        if (asset.assetClass == LibAsset.ETH_ASSET_CLASS) {
            for(uint256 i = 0; i < parts.length; ++i) {
                uint256 currentAmount = amount.bp(parts[i].value);
                if (currentAmount > 0) {
                    LibTransfer.transferPayableAmount(parts[i].account, currentAmount);
                    totalAmount += currentAmount;
                }
            }
            return totalAmount;
        }
        if (asset.assetClass == LibAsset.ERC20_ASSET_CLASS) {
            for(uint256 i = 0; i < parts.length; ++i) {
                uint256 currentAmount = amount.bp(parts[i].value);
                if (currentAmount > 0) {
                    (address tokenAddress) = abi.decode(asset.data, (address));
                    require(IERC20Upgradeable(tokenAddress).transferFrom(from, parts[i].account, currentAmount), "failed to transfer");
                    totalAmount += currentAmount;
                }
            }
            return totalAmount;
        }
        revert("no assets class");
    }

    function validate(LibOrder.Order memory order_, bytes memory signature_) internal view {
        if (order_.salt == 0) {
            if (order_.maker != address(0)) {
                require(_msgSender() == order_.maker, "maker is not tx sender");
            }
        } else {
            if (_msgSender() != order_.maker) {
                bytes32 hash = LibOrder.hash(order_);
                    // if maker is not contract then checking ECDSA signature
                    if (_hashTypedDataV4(hash).recover(signature_) != order_.maker) {
                        revert("order signature verification error");
                    } else {
                        require (order_.maker != address(0), "no maker");
                    }
            }
        }
    }

    function transferAmount(LibAsset.Asset memory asset_,address from_, address to_, uint256 amount_) internal {
        if (asset_.assetType.assetClass == LibAsset.ETH_ASSET_CLASS) {
            LibTransfer.transferPayableAmount(to_, amount_);
        } else if (asset_.assetType.assetClass == LibAsset.ERC20_ASSET_CLASS) {
            (address tokenAddress) = abi.decode(asset_.assetType.data, (address));
            require(IERC20Upgradeable(tokenAddress).transferFrom(from_, to_, amount_), "failed to transfer amount");
        } else {
            revert("unsupported asset");
        }
    }

    uint256[50] private __gap;
}