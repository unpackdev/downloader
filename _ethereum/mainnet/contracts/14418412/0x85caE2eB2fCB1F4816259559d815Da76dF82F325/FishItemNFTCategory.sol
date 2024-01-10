// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract FishItemNFTCategory is ERC721Enumerable, Ownable {
    struct Category {
        uint256 cap;
        uint256 supply;
        uint256 price;
    }

    uint256 private constant CATEGORY_SEPARATOR = 1_000;

    // Mapping from Category number to Category
    mapping(uint256 => Category) private _categoryMap;
    uint256[] private _categories;

    event CategoryCreated(uint256 indexed category, uint256 indexed cap);

    constructor() ERC721("Fish-Tank-Item NFT", "FISH-TANK-ITEM") {}

    function createCategory(
        uint256 category,
        uint256 cap,
        uint256 price
    ) external onlyOwner {
        require(cap > 0, "cap 0 not allowed");
        require(cap <= 1000, "cap max exceeded");
        require(price > 0, "price 0 not allowed");
        require(_categoryMap[category].cap == 0, "Already initialized");
        _categories.push(category);

        _categoryMap[category].cap = cap;
        _categoryMap[category].price = price;

        emit CategoryCreated(category, cap);
    }

    function getCategoryCap(uint256 category) external view returns (uint256) {
        return _categoryMap[category].cap;
    }

    function getCategoryTotalSupply(uint256 category)
        external
        view
        returns (uint256)
    {
        return _categoryMap[category].supply;
    }

    function getCategoryPrice(uint256 category) public view returns (uint256) {
        return _categoryMap[category].price;
    }

    function _mint(address to, uint256 category) internal override {
        uint256 categoryCap = _categoryMap[category].cap;
        uint256 categorySupply = _categoryMap[category].supply;

        require(categoryCap > 0, "Not initialized");
        require(categorySupply < categoryCap, "Cap reached");

        uint256 tokenId = (category * CATEGORY_SEPARATOR) + categorySupply;

        _categoryMap[category].supply = categorySupply + 1;

        super._mint(to, tokenId);
    }

    function extractCategory(uint256 tokenId) external pure returns (uint256) {
        return tokenId / CATEGORY_SEPARATOR;
    }

    function getCategories() external view returns (uint256[] memory) {
        return _categories;
    }
}
