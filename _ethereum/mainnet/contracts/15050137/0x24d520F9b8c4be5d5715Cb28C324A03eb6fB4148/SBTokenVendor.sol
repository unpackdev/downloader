// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./Ownable.sol";

contract SBTokenVendor is Ownable {
    using SafeERC20 for IERC20;

    struct Product {
        uint256 minAmt;
        uint256 maxAmt;
        uint256 pricePerToken;
        uint256 limitPerAddress;
        address erc20Address;
        bool isActive;
    }
    Product[] public products;
    // Address to product index to amount purchased
    mapping(address => mapping(uint256 => uint256)) public purchases;

    constructor(Product[] memory products_) {
        for (uint256 i; i < products_.length; ) {
            products.push(products_[i]);
            ++i;
        }
    }

    // Events
    event Purchase(
        address indexed purchaser,
        uint256 indexed productIndex,
        uint256 amountPurchased
    );

    function purchase(uint256 amountToPurchase, uint256 productIndex)
        external
        payable
    {
        Product memory product = products[productIndex];
        require(product.isActive, "PRODUCT INACTIVE");
        require(
            amountToPurchase >= product.minAmt &&
                amountToPurchase <= product.maxAmt,
            "INVALID AMOUNT"
        );
        if (product.limitPerAddress > 0) {
            require(
                purchases[msg.sender][productIndex] + amountToPurchase <=
                    product.limitPerAddress,
                "LIMIT REACHED"
            );
        }
        IERC20 erc20Token = IERC20(product.erc20Address);
        uint256 totalPurchase = amountToPurchase * product.pricePerToken;
        if (product.erc20Address != address(0)) {
            require(
                erc20Token.balanceOf(msg.sender) >= totalPurchase,
                "NOT ENOUGH BALANCE"
            );
        } else {
            require(msg.value == totalPurchase, "INVALID ETH AMOUNT");
        }
        purchases[msg.sender][productIndex] += amountToPurchase;
        if (product.erc20Address != address(0)) {
            require(
                erc20Token.allowance(msg.sender, address(this)) >=
                    totalPurchase,
                "NOT ALLOWED"
            );
            erc20Token.safeTransferFrom(
                msg.sender,
                address(this),
                totalPurchase
            );
        }
        emit Purchase(msg.sender, productIndex, amountToPurchase);
    }

    // Owner Functions
    function addProduct(Product calldata product) external onlyOwner {
        products.push(product);
    }

    function updateProduct(Product calldata product, uint256 productIndex)
        external
        onlyOwner
    {
        products[productIndex] = product;
    }

    function productActive(uint256 productIndex, bool flag) external onlyOwner {
        products[productIndex].isActive = flag;
    }

    function withdrawEth(address payable to) external onlyOwner {
        require(to != address(0), "NO 0 ADDRESS");
        to.transfer(address(this).balance);
    }

    function withdrawERC20(address to, address erc20Address)
        external
        onlyOwner
    {
        require(to != address(0), "NO 0 ADDRESS");
        IERC20 erc20Token = IERC20(erc20Address);
        erc20Token.safeTransfer(to, erc20Token.balanceOf(address(this)));
    }
}
