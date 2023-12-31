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
import "./Ownable.sol";
import "./ECDSA.sol";
import "./SignatureChecker.sol";
import "./SafeMath.sol";
import "./ISubscription.sol";
import "./NFT.sol";
import "./Product.sol";

interface IPriceOracle {
    function latestAnswer() external view returns (uint256 price);
}

contract Subscription is ISubscription, Ownable {
    using SafeMath for uint256;
    struct ReferrerInfo {
        uint8 ratio;
        Sales salesinfo;
    }

    uint256 public constant WEEK = 604800; // 1week
    uint256 public constant YEAR = 31622400; // 1years
    uint256 public constant PERMANENT = 3162240000; //100 years

    mapping(address => ReferrerInfo) public referrerSalesMap;
    mapping(string => Sales) public appSaleMap;

    address public treasury;
    address public priceOracle;
    SubscriptionProofNFT public subscriptionProofNFTContract;
    Product public productContract;
    uint8 public gasCoinDecimals;

    constructor(
        address treasury_,
        address priceOracle_,
        uint8 gasCoinDecimals_,
        string memory name,
        string memory symbol
    ) {
        gasCoinDecimals = gasCoinDecimals_;
        treasury = treasury_;
        priceOracle = priceOracle_;
        subscriptionProofNFTContract = new SubscriptionProofNFT(name, symbol);
        productContract = new Product();
    }

    function createProduct(
        string memory appId,
        uint256 weekPrice,
        uint256 yearPrice,
        uint256 permanentPrice
    ) public onlyOwner {
        IProduct(productContract).createProduct(
            appId,
            weekPrice,
            yearPrice,
            permanentPrice
        );
    }

    function subscribe(
        uint256 productId,
        SubscriptionTier tier, //0 week  1 year 2  permanent
        address referrer,
        uint8 discount,
        uint8 ratio,
        uint256 expiration, // Referral code 过期时间
        bytes calldata signature //  Referral code 凭据
    ) public payable {
        ProductInfo memory product = IProduct(productContract).queryProductById(
            productId
        );

        require(product.weekPrice > 0, "Subscription: Invalid product");

        // Calculate discount price.
        (ProductInfo memory newProduct, bool isValidCode) = calcDiscountPrice(
            productId,
            referrer,
            discount,
            ratio,
            expiration,
            signature
        );

        require(
            msg.value >=
                getTierPrice(newProduct, tier).mul(10 ** gasCoinDecimals).div(
                    IPriceOracle(priceOracle).latestAnswer()
                ),
            "Subscription: Insufficient amount"
        );

        if (isValidCode) {
            // allocateFunds
            allocateFunds(msg.value, referrer, ratio);
        } else {
            // allocateFunds
            allocateFunds(msg.value, referrer, 0);
        }

        appSaleMap[newProduct.appId].totalAmount =
            appSaleMap[newProduct.appId].totalAmount +
            msg.value;
        appSaleMap[newProduct.appId].totalOrders =
            appSaleMap[newProduct.appId].totalOrders +
            1;

        // mint
        // uri  e.g. eth-tx-builder|1693829838|604800
        uint256 duration = getDurations(tier);
        subscriptionProofNFTContract.safeMint(
            msg.sender,
            string(
                abi.encodePacked(
                    product.appId,
                    "|",
                    uintToString(block.timestamp),
                    "|",
                    uintToString(duration)
                )
            )
        );
        emit NewSubscription(product.appId, productId, referrer);
    }

    function querySalesByReferrer(
        address referrer
    ) public view returns (Sales memory sales, uint8 ratio) {
        sales = referrerSalesMap[referrer].salesinfo;
        ratio = referrerSalesMap[referrer].ratio;
    }

    function querySalesByAppId(
        string memory appId
    ) public view returns (Sales memory sales) {
        return appSaleMap[appId];
    }

    function queryNFTContract() public view returns (address c) {
        return address(subscriptionProofNFTContract);
    }

    function queryProductContract() public view returns (address c) {
        return address(productContract);
    }

    function updatePriceOracle(address po) public onlyOwner {
        require(
            IPriceOracle(po).latestAnswer() > 0,
            "Invalid price oracle address"
        );
        priceOracle = po;
    }

    function updateTreasury(address t) public onlyOwner {
        treasury = t;
    }

    function updateReferrerRatio(address r, uint8 ratio) public onlyOwner {
        ReferrerInfo storage referrer = referrerSalesMap[r];
        if (ratio >= 50) {
            ratio = 50;
        }
        if (ratio >= referrer.ratio) {
            referrer.ratio = ratio;
        }
    }

    function calcDiscountPrice(
        uint256 productId,
        address referrer,
        uint8 discount,
        uint8 ratio,
        uint256 expiration,
        bytes calldata signature
    ) public view returns (ProductInfo memory p, bool isValidCode) {
        // address|discount|ratio|expiration   e.g. 0xd9...0432|60|20|1793929838
        ProductInfo memory product = IProduct(productContract).queryProductById(
            productId
        );

        bytes memory message = bytes(
            string(
                abi.encodePacked(
                    Strings.toHexString(referrer),
                    "|",
                    uintToString(discount),
                    "|",
                    uintToString(ratio),
                    "|",
                    uintToString(expiration)
                )
            )
        );
        if (isValid(message, owner(), signature)) {
            // Valid Referral code
            if (block.timestamp <= expiration) {
                ProductInfo memory newProduct = ProductInfo({
                    appId: product.appId,
                    id: product.id,
                    weekPrice: (product.weekPrice * discount) / 100,
                    yearPrice: (product.yearPrice * discount) / 100,
                    permanentPrice: (product.permanentPrice * discount) / 100
                });

                return (newProduct, true);
            }
        }

        // Invalid Referral code
        // Return original price.
        return (product, false);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual returns (bool) {
        return interfaceId == type(ISubscription).interfaceId;
    }

    // internal
    function allocateFunds(uint256 fee, address inviter, uint8 ratio) internal {
        if (inviter == address(0)) {
            transferETH(treasury, fee);
        } else {
            ReferrerInfo storage reseller = referrerSalesMap[inviter];
            uint8 realRatio = ratio;
            if (reseller.ratio > ratio) {
                realRatio = reseller.ratio;
            }
            uint256 commission = fee.mul(realRatio).div(100);
            transferETH(treasury, fee - commission);
            transferETH(inviter, commission);

            reseller.salesinfo.totalAmount =
                reseller.salesinfo.totalAmount +
                fee;
            reseller.salesinfo.totalOrders = reseller.salesinfo.totalOrders + 1;
        }
    }

    function transferETH(address recipient_, uint256 amount) internal {
        address payable recipient = payable(recipient_);
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    function getTierPrice(
        ProductInfo memory product,
        SubscriptionTier tier
    ) internal pure returns (uint256) {
        if (tier == SubscriptionTier.Week) {
            return product.weekPrice;
        }

        if (tier == SubscriptionTier.Year) {
            return product.yearPrice;
        }

        if (tier == SubscriptionTier.Permanent) {
            return product.permanentPrice;
        }
        return product.permanentPrice;
    }

    function getDurations(
        SubscriptionTier tier
    ) internal pure returns (uint256) {
        if (tier == SubscriptionTier.Week) {
            return WEEK;
        }

        if (tier == SubscriptionTier.Year) {
            return YEAR;
        }

        if (tier == SubscriptionTier.Permanent) {
            return PERMANENT;
        }
        return WEEK;
    }

    // utils
    function uintToString(uint256 num) public pure returns (string memory) {
        return Strings.toString(num);
    }

    function isValid(
        bytes memory message,
        address target,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 hash = ECDSA.toEthSignedMessageHash(message);
        return SignatureChecker.isValidSignatureNow(target, hash, signature);
    }
}
