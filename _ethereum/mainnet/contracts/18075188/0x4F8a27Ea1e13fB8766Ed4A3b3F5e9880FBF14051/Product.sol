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
import "./Counters.sol";
import "./Ownable.sol";
import "./IProduct.sol";

contract Product is IProduct, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _productIdCounter;

    mapping(uint256 => ProductInfo) public productMap;

    constructor() {
        _productIdCounter.increment(); // 初始化为 1
    }

    function createProduct(
        string memory appId,
        uint256 weekPrice,
        uint256 yearPrice,
        uint256 permanentPrice
    ) public onlyOwner {
        // 1e8  == $1
        require(
            weekPrice >= 1e8 && yearPrice >= 1e8 && permanentPrice >= 1e8,
            "Prices must be greater than $1"
        );

        uint256 productId = _productIdCounter.current();
        _productIdCounter.increment();

        ProductInfo memory newProduct = ProductInfo({
            appId: appId,
            id: productId,
            weekPrice: weekPrice,
            yearPrice: yearPrice,
            permanentPrice: permanentPrice
        });

        // productMap
        productMap[productId] = newProduct;
        emit ProductCreated(appId, productId);
    }

    function queryProductById(
        uint256 id
    ) public view returns (ProductInfo memory product) {
        require(
            bytes(productMap[id].appId).length > 0,
            "Product does not exist"
        );
        return productMap[id];
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IProduct).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}
