pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./ERC721Full.sol";
import "./Killable.sol";

/**
 * @title Shit Coins Contract for Snark Art.
 *
 * @notice Smart Contract provides ERC721 functionality with additional options to handle Shit Coins.
 * In addition to standard ERC721 functionality it is possible to open bank, save Poem to the bank
 * and read poem. It is not possible to transfer already opened banks.
 * @author Andrey Skurlatov
 */
contract ShitCoin is ERC721Full, Killable
{
    // Use safeMath library for doing arithmetic with uint256 numbers
    using SafeMath for uint256;

    /**
    * @notice Shit Bank constructor.
    * @dev Constructor calls ERC20Metadata constructor to set name and symbol.
    * @param name ERC721 token name
    * @param symbol ERC721 Symbol
     */
    constructor (string memory name, string memory symbol) public ERC721Full(name,symbol) {

    }

    /**
    * @notice saves Poem to blockchain for specified token id.
    * @dev Can be called only by contract owner. Bank must be already open.
    * @param _id ERC721 token to change for.
    */
    function changeMetadata(uint256 _id, string memory tokenURI) public onlyMortal {
        _setTokenURI(_id, tokenURI);
    }

    /**
    * @notice Gets the list of token IDs of the requested owner
    * @param owner address of token owners
    * @return uint256[] List of token IDs owned by the requested address
    */
    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        return _tokensOfOwner(owner);
    }

    /**
    * @notice Function to mint new token to given address with token URI
    * @dev create new token id that increase the number of total tokens supply
    * mint new token to given address and set token URI and communal it
    * @param to The address that will own the minted token
    * @param tokenURI string The token URI of the minted token
    * @return uint256 is token id of new created token
    */
    function mint(address to, string memory tokenURI) public onlyOwner returns (uint256) {
        uint256 tokenId = totalSupply().add(1);
        _mint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
        return tokenId;
    }
}