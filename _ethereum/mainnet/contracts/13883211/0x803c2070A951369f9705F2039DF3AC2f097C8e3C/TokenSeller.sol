// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Pausable.sol";
import "./IERC721.sol";
import "./IERC1155.sol";

contract TokenSeller is Pausable {

// Cost to buy out token
    uint256 public immutable COST_PER_TOKEN = 0.01 ether;

// Initialization

    constructor() {}

// Selling

    modifier costs(uint256 howMany) {

        uint256 price = COST_PER_TOKEN * howMany;

        require(msg.value >= price, '402');
        _;

        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function purchaseERC721Tokens(address contractAddress, uint256[] memory tokenIds)
        public
        payable
        whenNotPaused
        costs(tokenIds.length)
    {
        IERC721 erc721Contract = IERC721(contractAddress);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _transferERC721Token(erc721Contract, tokenIds[i]);
        }
    }

    function purchaseERC1155Tokens(address contractAddress, uint256 id, uint256 quantity)
        public
        payable
        whenNotPaused
        costs(quantity)
    {
        _transferERC1155Tokens(IERC1155(contractAddress), id, quantity);
    }

    function _transferERC721Token(IERC721 erc721Contract, uint256 tokenId) internal {
        require(erc721Contract.ownerOf(tokenId) == address(this), '403');
        erc721Contract.transferFrom(address(this), msg.sender, tokenId);
    }

    function _transferERC1155Tokens(IERC1155 erc1155Contract, uint256 id, uint256 quantity) internal {
        require(erc1155Contract.balanceOf(address(this), id) >= quantity, '403');
        erc1155Contract.safeTransferFrom(address(this), msg.sender, id, quantity, '');
    }
}
