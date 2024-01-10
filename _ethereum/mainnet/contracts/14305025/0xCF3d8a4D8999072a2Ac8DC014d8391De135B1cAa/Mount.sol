// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Mintable.sol";
import "./Strings.sol";

/**
 * @title Mount ERC721Tradable
 * ERC721Tradable - ERC721 contract that accepts minting by IMX via mintFor
 */
contract Mount is ERC721, Mintable {
    using Address for address;

    uint256 public currentSupply;

    string private baseURI = "https://api.pxquest.com/meta/mounts/";
    string private contURI = "https://api.pxquest.com/meta/contracts/1/mounts";

    constructor(
        address _owner,
        string memory _name,
        string memory _symbol,
        address _imx
    ) ERC721(_name, _symbol) Mintable(_owner, _imx) {
        currentSupply = 0;
    }

    /** *********************************** **/
    /** ********* Minting Functions ******* **/
    /** *********************************** **/

    function _mintFor(
        address user,
        uint256 id,
        bytes memory
    ) internal override {
        _safeMint(user, id);
        currentSupply++;
    }

    /** *********************************** **/
    /** ********* Owner Functions ********* **/
    /** *********************************** **/

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setContractURI(string memory uri) public onlyOwner {
        contURI = uri;
    }

    /** *********************************** **/
    /** ********* View Functions ********* **/
    /** *********************************** **/

    function totalSupply() public view returns (uint256) {
        return currentSupply;
    }

    //base url for returning info about an individual adventurer
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    //base url for returning info about the token collection contract
    function contractURI() external view returns (string memory) {
        return contURI;
    }
}
