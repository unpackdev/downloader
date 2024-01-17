// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "ERC721A.sol";

contract SJGStudentID is ERC721A, Ownable{
    using Strings for uint256;

    uint256 public  MAX_SUPPLY = 366;     // Max Supply
    string  private baseTokenURI;         // Base TokenURI  

    // We are only inheriting ERC721A straight.
    constructor() ERC721A("SJGStudentID", "SID"){}

    // Returns total number of tokens minted (different from totalSupply() inherited)
    // Total supply would disregard burned tokens. 
    // This contract is essentially not burnable so it should be fine tho.
    function totalMinted() external view returns (uint256){
        return _totalMinted();
    }

    // This modifier make sure that it is not another contract calling this contract.
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // Airdrop.
    function airdrop(address[] memory addresses) external callerIsUser onlyOwner{
        require((_totalMinted() + addresses.length) <= MAX_SUPPLY, "You cannot exceed max supply.");

        // Airdrop to each adddress
        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], 1);
        }
    }

    // TokenURI Function to be called.
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // Else return the true address
        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    // This _baseURI function is inherited from 721A
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // Setter for base token URI.
    function setBaseTokenUri(string memory _baseTokenUri) external onlyOwner{
        baseTokenURI = _baseTokenUri;
    }
}