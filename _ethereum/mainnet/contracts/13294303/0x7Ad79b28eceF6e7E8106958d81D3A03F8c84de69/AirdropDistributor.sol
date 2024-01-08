// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC721.sol";

contract AirdropDistributor is Ownable {
    // The NFT contract on which we operate
    IERC721 public nftContract;

    // The address from which to take the Donuts
    address public vaultAddress;

    // Limit of transfers
    uint256 public limit = type(uint256).max;

    // Counter of transfers
    uint256 public transferred = 0;

    constructor(address vault, address contractAddress) {
        vaultAddress = vault;
        setContractAddress(contractAddress);
    }

    /**
     * @dev Sets the address of the vault from which to transfer tokens to `newVault`
     */
    function setVaultAddress(address newVault) public onlyOwner {
        vaultAddress = newVault;
    }
    /**
     * @dev Sets the address of the NFT contract whose tokens are to be airdropped to `newContractAddress`.
     * Doesn't check for ERC721 compatibility.
     */
    function setContractAddress(address newContractAddress) public onlyOwner {
        require(newContractAddress != address(0), "AirdropDistributor: Address must not be the zero address");
        nftContract = IERC721(newContractAddress);
    }
    /**
     * @dev Sets the transfer limit to `newLimit`.
     * Does NOT guarantee that {limit} <= {transferred}
     */
    function setLimit(uint256 newLimit) public onlyOwner {
        limit = newLimit;
    }
    /**
     * @dev Airdrops `amount` tokens to each address in the given `addresses` -
     * starting from token ID `startingTokenId` and up.
     */
    function airdrop(address[] calldata addresses, uint256 amount, uint256 startingTokenId) public onlyOwner {
        uint256 tokenId = startingTokenId;
        for (uint256 i = 0; i < addresses.length; i++) {
            address to = addresses[i];
            for (uint256 j = 0; j < amount; j++) {
                nftContract.safeTransferFrom(vaultAddress, to, tokenId);
                tokenId += 1;
            }
            transferred += amount;
        }
    }
}