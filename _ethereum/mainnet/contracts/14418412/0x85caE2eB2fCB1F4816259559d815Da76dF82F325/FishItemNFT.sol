// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./FishItemNFTCategory.sol";
import "./ERC20Interface.sol";

contract FishItemNFT is FishItemNFTCategory {
    string private _uri = "";
    address private _fishChipsAddress;

    event BaseURISet(string indexed baseURI);
    event FishChipsAddressSet(address indexed newAddress);

    function purchase(uint256[] memory categories, uint256[] memory amounts)
        external
    {
        require(categories.length > 0, "minimum one");
        require(categories.length == amounts.length, "length not match");

        uint256 totalPrice;

        for (uint256 i = 0; i < categories.length; i++) {
            uint256 category = categories[i];
            uint256 amount = amounts[i];
            uint256 categoryPrice = getCategoryPrice(category);
            uint256 price = categoryPrice * amount;

            totalPrice = totalPrice + price;
        }

        ERC20Interface erc20 = ERC20Interface(_fishChipsAddress);

        bool result = erc20.transferFrom(msg.sender, owner(), totalPrice);
        require(result, "transferFrom failed");

        for (uint256 i = 0; i < categories.length; i++) {
            uint256 category = categories[i];
            uint256 amount = amounts[i];
            for (uint256 j = 0; j < amount; j++) {
                super._mint(msg.sender, category);
            }
        }
    }

    function setBaseURI(string memory uri) external onlyOwner {
        _uri = uri;
        emit BaseURISet(uri);
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function setFishChipsAddress(address newAddress) external onlyOwner {
        _fishChipsAddress = newAddress;
        emit FishChipsAddressSet(newAddress);
    }

    function getFishChipsAddress() external view returns (address) {
        return _fishChipsAddress;
    }

    /// @notice Returns all the tokenIds from an owner
    /// @dev This method MUST NEVER be called by smart contract code.
    function getTokenIds(address owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(owner);

        uint256[] memory result = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            result[i] = tokenOfOwnerByIndex(owner, i);
        }

        return result;
    }
}
