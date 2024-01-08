// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./IMXMethods.sol";

contract CryptoXolos is ERC721, IMXMethods {
    string public baseTokenURI;
    // Blueprints storage, uncomment this lane if you are storing on-chain metadata
    // mapping(uint256 => bytes) public metadata;

    constructor(
        string memory _name, // Token name (eg. BoredApeYatchClub)
        // symbol of your Token (reg. "BAYC")
        string memory _symbol, // Token Symbol (eg. BAYC)
        // IMX Smart Contract address that gets passed to IMXMethods.sol
        address _imx
    ) ERC721(_name, _symbol) IMXMethods(_imx) {}


    /**
     * @dev Called by IMX, receives the parsed version of the blueprint the forward address of the contract.
     */
    function _mintFor(
        // Address of the recieving wallet, must be registered in IMX.
        address user,
        // ID of the Token that will be minted
        uint256 id,
        // Parsed blueprint without the TokenID prefix
        bytes memory blueprint
    ) internal override {
        _safeMint(user, id);
        // Mapping implementation of blueprint metada, uncomment this 
        // line if you are storing on-chain metadata
        // metadata[id] = blueprint;
    }

    /**
     * @dev Overwrite OpenZepellin _baseURI to get the base for TokenURI
     * from a variable
     */
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @dev Allow contract owner to update BaseTokenURI in case
     * Metadata URL changes or for late reveal 
     */
    function setBaseTokenURI(string memory uri) public onlyOwner {
        baseTokenURI = uri;
    }
}
