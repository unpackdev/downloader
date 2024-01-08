pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC1155.sol";
import "./IERC1155Receiver.sol";

contract HarvestArt is ReentrancyGuard, Ownable, IERC721Receiver, IERC1155Receiver {

    uint256 public amountPerTx = 1 gwei;
    address public vault = address(0);

    function supportsInterface(bytes4 interfaceID) public virtual override view returns (bool) {
      return  interfaceID == 0x4e2312e0;
    }

    function setVault(address newVault) onlyOwner public {
        vault = newVault;
    }

    function setAmount(uint256 newAmountPerTx) onlyOwner public {
        amountPerTx = newAmountPerTx;
    }

    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) public virtual override returns (bytes4) {
        require(vault != address(0), "Vault cannot be the 0x0 address");
        require(address(this).balance > amountPerTx, "Not enough ether in contract.");

        IERC721(msg.sender).safeTransferFrom(address(this), vault, tokenId);
        
        (bool sent, ) = payable(from).call{ value: amountPerTx }("");
        require(sent, "Failed to send ether.");

        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) public virtual override returns (bytes4) {
        require(vault != address(0), "Vault cannot be the 0x0 address");
        require(address(this).balance > amountPerTx * value, "Not enough ether in contract.");

        IERC1155(msg.sender).safeTransferFrom(address(this), vault, id, value, data);

        (bool sent, ) = payable(from).call{ value: amountPerTx * value }("");
        require(sent, "Failed to send ether.");

        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) public virtual override returns (bytes4) {
        require(vault != address(0), "Vault cannot be the 0x0 address");

        uint totalNFTs = 0;
        for (uint i = 0; i < values.length; i++) {
            totalNFTs += values[i];
        }

        require(address(this).balance > amountPerTx * totalNFTs, "Not enough ether in contract.");

        IERC1155(msg.sender).safeBatchTransferFrom(address(this), vault, ids, values, data);

        (bool sent, ) = payable(from).call{ value: amountPerTx * totalNFTs }("");
        require(sent, "Failed to send ether.");

        return this.onERC1155BatchReceived.selector;
    }

    receive () external payable { }
}