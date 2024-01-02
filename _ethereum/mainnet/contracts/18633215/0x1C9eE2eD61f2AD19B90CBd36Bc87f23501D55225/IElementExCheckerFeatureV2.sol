/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IERC20.sol";
import "./LibStructure.sol";

interface IElementExCheckerFeatureV2 {

    struct BuyOrderCheckInfo {
        bool success;               // 所有的检查通过时为true，只要有一项检查未通过时为false
        uint256 hashNonce;
        bytes32 orderHash;
        bool makerCheck;            // check `maker != address(0)`
        bool takerCheck;            // check `taker != ElementEx`
        bool listingTimeCheck;      // check `listingTime < expireTime`
        bool expireTimeCheck;       // check `expireTime > block.timestamp`
        bool nonceCheck;            // 检查订单nonce
        uint256 orderAmount;        // offer的Nft资产总量
        uint256 remainingAmount;    // remainingAmount返回剩余未成交的数量
        bool remainingAmountCheck;  // check `remainingAmount > 0`
        bool feesCheck;             // fee地址不能是0x地址，并且如果有回调，fee地址必须是合约地址
        bool propertiesCheck;       // 属性检查。若order.erc1155Properties不为空,则`order.erc1155TokenId`必须为0，并且property地址必须是address(0)或合约地址
        bool erc20AddressCheck;     // erc20地址检查。该地址必须为一个合约地址，不能是NATIVE_ADDRESS，不能为address(0)
        uint256 erc20TotalAmount;   // erc20TotalAmount = `order.erc20TokenAmount` + totalFeesAmount
        uint256 erc20Balance;       // 买家ERC20余额
        uint256 erc20Allowance;     // 买家ERC20授权额度
        bool erc20BalanceCheck;     // check `erc20Balance >= erc20TotalAmount`
        bool erc20AllowanceCheck;   // check `erc20AllowanceCheck >= erc20TotalAmount`
    }

    function checkERC721BuyOrderV2(
        LibNFTOrder.NFTBuyOrder calldata order,
        LibSignature.Signature calldata signature,
        bytes calldata data
    ) external view returns (
        BuyOrderCheckInfo memory info,
        bool validSignature
    );

    function checkERC1155BuyOrderV2(
        LibNFTOrder.ERC1155BuyOrder calldata order,
        LibSignature.Signature calldata signature,
        bytes calldata data
    ) external view returns (
        BuyOrderCheckInfo memory info,
        bool validSignature
    );

    function getERC721BuyOrderInfo(
        LibNFTOrder.NFTBuyOrder calldata order
    ) external view returns (
        LibNFTOrder.OrderInfo memory orderInfo
    );

    function validateERC721BuyOrderSignatureV2(
        LibNFTOrder.NFTBuyOrder calldata order,
        LibSignature.Signature calldata signature,
        bytes calldata data
    ) external view returns (bool valid);

    function validateERC1155BuyOrderSignatureV2(
        LibNFTOrder.ERC1155BuyOrder calldata order,
        LibSignature.Signature calldata signature,
        bytes calldata data
    ) external view returns (bool valid);
}
