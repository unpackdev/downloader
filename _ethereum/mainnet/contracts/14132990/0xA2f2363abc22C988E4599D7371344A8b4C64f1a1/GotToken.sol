// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./IERC721.sol";

/**
 * @title Checks if a given address owns a token from a given ERC721 contract or the CryptoPunks contract (which does not implement ERC721)
 * @author nfttank.eth
 */
contract GotToken {
    
    /**
     * @dev Checks whether a given address (possibleOwner) owns a given token by its contract address and the token id itself.
     * This method can only check contracts implementing the ERC721 standard and in addition the CryptoPunks contract
     * (with a custom implementation because CryptoPunks do not implement the ERC721 standard).
     *
     * Does not throw errors but returns false if the real token owner could not be found or the token does not exist.
     *
     * Sample contract addresses on Mainnet
     *   CryptoPunks:           0x3C6D0C0d7c818474A93a8A271e0BBdb2e52E71d8     
     *   Bored Ape Yacht Club:  0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D
     *   Cool Cats:             0x1A92f7381B9F03921564a437210bB9396471050C
     *   CrypToadz:             0x1CB1A5e65610AEFF2551A50f76a87a7d3fB649C6
     */     
    function ownsTokenOfContract(address possibleOwner, address contractAddress, uint256 tokenId) public view returns (bool) {
        try this.unsafeOwnsTokenOfContract(possibleOwner, contractAddress, tokenId) returns (bool b) {
            return b;
        } catch { 
            return false; 
        }  
    }
        
    /**
     * @dev Checks whether a given address (possibleOwner) owns a given token by its contract address and the token id itself.
     * This method can only check contracts implementing the ERC721 standard and in addition the CryptoPunks contract
     * (with a custom implementation because CryptoPunks do not implement the ERC721 standard).
     *
     * Might revert execution if the contract address does not exist on the current net.
     *
     * Sample contract addresses on Mainnet
     *   CryptoPunks:           0x3C6D0C0d7c818474A93a8A271e0BBdb2e52E71d8     
     *   Bored Ape Yacht Club:  0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D
     *   Cool Cats:             0x1A92f7381B9F03921564a437210bB9396471050C
     *   CrypToadz:             0x1CB1A5e65610AEFF2551A50f76a87a7d3fB649C6
     */ 
    function unsafeOwnsTokenOfContract(address possibleOwner, address contractAddress, uint256 tokenId) public view returns (bool) {

        address CryptoPunksContractMainnet = 0x3C6D0C0d7c818474A93a8A271e0BBdb2e52E71d8;
        address realTokenOwner = address(0);

        if (contractAddress == CryptoPunksContractMainnet) {
            CryptoPunksInterface punksContract = CryptoPunksInterface(CryptoPunksContractMainnet);
            realTokenOwner = punksContract.punkIndexToAddress(tokenId);
        }
        else {
            IERC721 ercContract = IERC721(contractAddress);
            realTokenOwner = ercContract.ownerOf(tokenId);
        }

        return possibleOwner == realTokenOwner && realTokenOwner != address(0);
    }
    

    /**
     * @dev Checks whether a given address (possibleOwner) owns a given token by given contract addresses and the token id itself.
     * This method can only check contracts implementing the ERC721 standard and in addition the CryptoPunks contract
     * (with a custom implementation because CryptoPunks do not implement the ERC721 standard).
     * Does not throw errors but returns false if the real token owner could not be found or the token does not exist.
     * 
     * Returns an array with the results at the given index of the array.
     *
     * Sample contract addresses on Mainnet
     *   CryptoPunks:           0x3C6D0C0d7c818474A93a8A271e0BBdb2e52E71d8     
     *   Bored Ape Yacht Club:  0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D
     *   Cool Cats:             0x1A92f7381B9F03921564a437210bB9396471050C
     *   CrypToadz:             0x1CB1A5e65610AEFF2551A50f76a87a7d3fB649C6
     */ 
    function ownsTokenOfContracts(address possibleOwner, address[] calldata contractAddresses, uint256 tokenId) public view returns (bool[] memory) {

        bool[] memory result = new bool[](contractAddresses.length);

        for (uint256 i = 0; i < contractAddresses.length; i++) {
            result[i] = ownsTokenOfContract(possibleOwner, contractAddresses[i], tokenId);
        }

        return result;
    }
}

/**
 * The CryptoPunks contract doesn't implement the ERC721 standard so we have to use this interface to call their method punkIndexToAddress()
 */
interface CryptoPunksInterface {
    function punkIndexToAddress(uint tokenId) external view returns(address);
}