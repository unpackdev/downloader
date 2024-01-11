// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./console.sol";

contract TruleeHall is Ownable, ERC721 {
    using Strings for uint256;

    /// @dev number of token minted
    uint256 public currentSupply;
   
    /// @dev maximun supply of collection
    uint256 public MAX_SUPPLY;

    /// @dev price of the NFT
    uint256 public PRICE;

    /// @dev the new baseURI
    string private baseURIExtendend;

    receive() external payable {
    }

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) 
        ERC721(name_, symbol_)
    {
        baseURIExtendend = baseURI_;
        MAX_SUPPLY = 1;
    }

    /// @dev Update the baseURI of the contract
    /// @param to_ address that the nft will be minted
    /// @param tokenId_ the id of the nft
    function mint(address to_, uint256 tokenId_) public onlyOwner {
        uint256 _maxSupply = MAX_SUPPLY;

        require(totalSupply() + 1 <= _maxSupply, 'Sold out');
        require(tokenId_ <= _maxSupply, "Token not found");

        _safeMint(to_, tokenId_);

        currentSupply++;
    }

    /// @dev Update the baseURI of the contract
    /// @param baseURI_ the new baseURI
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURIExtendend = baseURI_;
    }

    /// @dev Get the tokenURI of a token
    /// @param tokenId_ the tokenId
    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
        require(_exists(tokenId_), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = baseURIExtendend;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId_.toString())) : "";
    }

    /// @dev Get total supply of a token
    function totalSupply() public view returns (uint256) {
        return currentSupply;
    }

    /// @dev Set the max supply of NFT
    /// @param newSupply the new supply of NFT
    function setMaxSupply(uint256 newSupply) public onlyOwner {
        MAX_SUPPLY += newSupply;
    }
}
