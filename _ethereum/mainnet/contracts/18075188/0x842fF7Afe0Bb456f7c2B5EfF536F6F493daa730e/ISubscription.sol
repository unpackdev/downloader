/**
 * https://biubiu.tools
 */
// /\\\\\\\\   /\\\\\\\\  /\\\    /\\\  /\\\\\\\\   /\\\\\\\\  /\\\    /\\\  /\\\\\\\\\\\\  /\\\\\\\\      /\\\\\\\\    /\\\          /\\\\\\\\\\
// \/\\\   \\\ \/_/\\\_/  \/\\\   \/\\\ \/\\\   \\\ \/_/\\\_/  \/\\\   \/\\\ \/___/\\\___/ /\\\_____/\\\  /\\\_____/\\\ \/\\\        /\\\_______/
//  \/\\\   \\\   \/\\\    \/\\\   \/\\\ \/\\\   \\\   \/\\\    \/\\\   \/\\\     \/\\\    \/\\\    \/\\\ \/\\\    \/\\\ \/\\\       \/\\\
//   \/\\\\\\\     \/\\\    \/\\\   \/\\\ \/\\\\\\\     \/\\\    \/\\\   \/\\\     \/\\\    \/\\\    \/\\\ \/\\\    \/\\\ \/\\\       \/\\\\\\\\\\
//    \/\\\   \\\\  \/\\\    \/\\\   \/\\\ \/\\\   \\\\  \/\\\    \/\\\   \/\\\     \/\\\    \/\\\    \/\\\ \/\\\    \/\\\ \/\\\       \/_______/\\\
//     \/\\\    \\\  \/\\\    \/\\\   \/\\\ \/\\\    \\\  \/\\\    \/\\\   \/\\\     \/\\\    \/\\\    \/\\\ \/\\\    \/\\\ \/\\\               \/\\\
//      \/\\\\\\\\\  /\\\\\\\\ \/_/\\\\\\\\  \/\\\\\\\\\  /\\\\\\\\ \/_/\\\\\\\\      \/\\\    \/_/\\\\\\\\\  \/_/\\\\\\\\\  \/\\\\\\\\\\ /\\\\\\\\\/
//       \/______/   \/______/   \/_______/   \/______/   \/______/   \/_______/       \/_/       \/_______/     \/_______/   \/________/ \/_______/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./IERC165.sol";
import "./IProduct.sol";

enum SubscriptionTier {
    Week,
    Year,
    Permanent
}

struct Sales {
    uint256 totalOrders;
    uint256 totalAmount;
}

interface ISubscription is IERC165 {
    event NewSubscription(
        string indexed appId,
        uint256 indexed productId,
        address indexed referrer
    );

    function subscribe(
        uint256 productId,
        SubscriptionTier tier, //0 week  1 year 2  permanent
        address referrer,
        uint8 discount,
        uint8 ratio,
        uint256 expiration, // Referral code 过期时间
        bytes calldata signature //  Referral code 凭据
    ) external payable;

    function querySalesByReferrer(
        address referrer
    ) external view returns (Sales memory sales, uint8 ratio);

    function querySalesByAppId(
        string memory appId
    ) external view returns (Sales memory sales);

    function queryNFTContract() external view returns (address c);

    function queryProductContract() external view returns (address c);

    function updatePriceOracle(address po) external;

    function updateTreasury(address t) external;

    function updateReferrerRatio(address r, uint8 ratio) external;

    function calcDiscountPrice(
        uint256 productId,
        address referrer,
        uint8 discount,
        uint8 ratio,
        uint256 expiration,
        bytes calldata signature
    ) external view returns (ProductInfo memory product, bool isValidCode);
}
