// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./IERC721.sol";
import "./IERC721Receiver.sol";

contract ERC721Harvest is IERC721Receiver {
    
// Amount per token purchased
    uint256 public constant AMOUNT_PER_TOKEN = 1 gwei;

// Contract owner
    address public owner;

// Initialization

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

// Ownable

    modifier onlyOwner() {
        require(owner == msg.sender, "X");
        _;
    }
    
    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }

// Harvest

    modifier hasAvailableBalance(uint256 howMany) {
        require(address(this).balance > AMOUNT_PER_TOKEN * howMany, "$");
        _;
    }

    function sellTokenIds(address erc721Contract, uint256[] memory tokenIds)
        external
        hasAvailableBalance(tokenIds.length)
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _receiveToken(erc721Contract, tokenIds[i]);
        }

        _payForTransaction(msg.sender, tokenIds.length);
    }

    function onERC721Received(address operator, address, uint256, bytes calldata)
        external
        override
        hasAvailableBalance(1)
        returns (bytes4)
    {
        _payForTransaction(operator, 1);
        return this.onERC721Received.selector;
    }

    function _receiveToken(address erc721Contract, uint256 tokenId) internal {
        IERC721(erc721Contract).transferFrom(msg.sender, address(this), tokenId);
    }

    function _payForTransaction(address to, uint256 howMany) internal {
        (bool sent, ) = payable(to).call{ value: AMOUNT_PER_TOKEN * howMany }("");
        require(sent, "$");
    }

// Recover

    function recover(address erc721Contract, uint256 tokenId, address to) external onlyOwner {
        IERC721(erc721Contract).transferFrom(address(this), to, tokenId);
    }
}
