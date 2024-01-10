// SPDX-License-Identifier: MIT

/// @dev SWC-103 (Floating pragma)
// you need ^ in the version for remix
pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Mintable.sol";

/// @title Supernovas Immutable X test contract on Ropsten
/// @author kyle reynolds
contract Supernovas2 is ERC721Enumerable, Ownable, Mintable {
    /// @notice storage variables
    /// @dev An uint256 can be easily converted into a string. ex: value.toString()
    using Strings for uint256;
    /// @dev baseURI for example: https://bitbirds.herokuapp.com/metadata/
    string public baseURI;
    /// @dev you can set baseExtension to .json if the baseURI ends with .json
    string public baseExtension = "";

    /// @notice modifiers placeholder

    /// @notice constructor
    /// @dev SWC-118 (Incorrect Constructor Name)
    /// @dev Initializes the contract setting the name, symbol and baseURI. Also mints 5 NFTs to the contract owner.
    /// @param _name is the name of the NFT collection
    /// @param _symbol is the symbol of the NFT collection
    /// @param _initBaseURI is the baseURI of the NFT collection
    constructor(
        address _owner,
        string memory _name,
        string memory _symbol,
        address _imx,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) Mintable(_owner, _imx) {
        setBaseURI(_initBaseURI);
    }

    /// @dev override _safeMint function for immutable x
    function _mintFor(
        address user,
        uint256 id,
        bytes memory
    ) internal override {
        _safeMint(user, id);
    }

    /// @notice internal functions
    /// @dev returns baseURI and overrides built in function
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /// @notice passes in the wallet address and returns what token ids that wallet owns
    /// @param _owner is the wallet address the function takes in
    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            // returns the id of the token the wallet owns at 0, 1, 2, etc. these ids could be different then i
            // _addTokenToOwnerEnumeration is called in _beforeTokenTransfer in the _mint function in open zeppelin ERC721.sol
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    /// @notice pass in the tokenId and return the baseURI for that token
    /// @param tokenId you want to get the baseURI for
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)) : "";
    }

    /// @notice override renounce ownership so you don't accidently call it
    /// @dev if this is called, the contract does not have an owner anymore
    function renounceOwnership() public pure override {
        revert("Can't renounce ownership here");
    }

    /// @notice set base uri function
    /// @param _newBaseURI the new base URI for the tokens
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    /// @notice set base extension function
    /// @param _newBaseExtension the new base extension instead of .json
    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    /// @notice withdraw to owner
    /// @dev SWC-105 (Unprotected Ether Withdrawal)
    function withdraw() public payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
