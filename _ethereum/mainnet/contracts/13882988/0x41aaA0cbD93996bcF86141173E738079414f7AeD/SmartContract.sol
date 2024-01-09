pragma solidity >=0.8.0 <0.9.0;

//SPDX-License-Identifier: MIT
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC1155.sol";
import "./IERC1155Receiver.sol";

contract SmartContract is ReentrancyGuard, Ownable, IERC721Receiver, IERC1155Receiver {

    uint256 public perc_gasFee = 5;
    uint256 public gasFee721 = 130000;
    uint256 public gasFee1155S = 85000;
    uint256 public gasFee1155B = 130000;
    address public vault = address(0);

    function supportsInterface(bytes4 interfaceID) public virtual override view returns (bool) {
      return  interfaceID == 0x4e2312e0;
    }

    function setVault(address newVault) onlyOwner public {
        vault = newVault;
    }

    function setPercentageGas(uint256 percentage) onlyOwner public {
        perc_gasFee = percentage;
    }

    function _gasReturn(uint256 gasFee, uint256 perc, uint256 gasPrice) internal pure returns (uint256) {
        uint256 amount = (((gasFee * perc) / 100) * gasPrice);  
        return amount;
    }

    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) public virtual override returns (bytes4) {
        require(vault != address(0), "Vault cannot be the 0x0 address");
        uint256 gasReturn = (((gasFee721 * perc_gasFee) / 100) * tx.gasprice);
        require(address(this).balance > gasReturn, "Not enough ether in contract.");

        IERC721(msg.sender).safeTransferFrom(address(this), vault, tokenId);
        (bool sent, ) = payable(from).call{ value: gasReturn}("");
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
        uint256 gasReturn = (((gasFee1155S * perc_gasFee) / 100) * tx.gasprice);
        require(address(this).balance > gasReturn, "Not enough ether in contract.");

        IERC1155(msg.sender).safeTransferFrom(address(this), vault, id, value, data);

        (bool sent, ) = payable(from).call{ value: gasReturn }("");
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

        uint256 gasReturn = _gasReturn(gasFee1155B, perc_gasFee, tx.gasprice);
        require(address(this).balance > gasReturn, "Not enough ether in contract.");

        IERC1155(msg.sender).safeBatchTransferFrom(address(this), vault, ids, values, data);

        (bool sent, ) = payable(from).call{ value: gasReturn}("");
        require(sent, "Failed to send ether.");

        return this.onERC1155BatchReceived.selector;
    }

    function recieve () external payable { }
}
