// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
import "./ERC721.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Princess.sol";
import "./console.sol";

contract PrincessWrapper is Ownable, Pausable {
    address public immutable PRINCESS_CONTRACT_ADDRESS =
        0x7F5d260de88Acfb9f9A181431e461C5B5409d91E;
    uint256 public pricePerMintInWei = 0.045 ether;

    function mint(uint256 count) external payable whenNotPaused {
        require(count > 0, "!count");
        require(msg.value == count * pricePerMintInWei, "!price");

        // Mint to wrapper
        uint256 startTokenId = Princess(PRINCESS_CONTRACT_ADDRESS)
            .totalSupply() + 1;
        Princess(PRINCESS_CONTRACT_ADDRESS).mintOwner(count);

        // Transfer from wrapper
        for (
            uint256 tokenId = startTokenId;
            tokenId < startTokenId + count;
            tokenId++
        ) {
            ERC721(PRINCESS_CONTRACT_ADDRESS).safeTransferFrom(
                address(this),
                msg.sender,
                tokenId
            );
        }
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{
            value: address(this).balance
        }("");
        require(success, "!withdrawn");
    }

    function setPricePerMint(uint256 priceInWei) external onlyOwner {
        // Safeguard against accidentally setting this price in units
        // of ether instead of wei. Still allows the owner to set the price
        // to zero (wei).
        require(priceInWei == 0 || priceInWei > 0.001 ether, "!wei");
        pricePerMintInWei = priceInWei;
    }

    function executeWrapped(bytes memory _encodedFunctionCall)
        external
        onlyOwner
    {
        (bool success, ) = PRINCESS_CONTRACT_ADDRESS.call(_encodedFunctionCall);
        require(success, "!executed");
    }
}
