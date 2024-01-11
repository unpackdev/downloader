// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";

contract SpinelloSativaRemix is ERC721, Ownable {
    using Strings for uint256;

    string private baseTokenURI = "https://api.abanamusic.com/spinelloremix/";
    string private baseTokenURISpark;
    uint256 private currentIndex;

    mapping (uint256 => bool) public sparkedTokens;

    constructor() ERC721("SpinelloSativaRemix", "SPNLOSATRMX") {
        for(uint256 i; i < 4; i++){
            _mint(msg.sender,i+1);
        }
        currentIndex = 4;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function _baseURISpark() internal view returns (string memory) {
        return baseTokenURISpark;
    }

    /**
     * Set baseTokenURISpark to enable sparking
     */
    function setBaseURISpark(string calldata baseURISpark) external onlyOwner {
        baseTokenURISpark = baseURISpark;
    }

    function spark(uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");
        require(bytes(baseTokenURISpark).length != 0, "Sparking the joint is not yet permitted");
        sparkedTokens[tokenId] = true;        
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        if (sparkedTokens[tokenId]) {
            string memory baseURI = _baseURISpark();
            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
        }

        return super.tokenURI(tokenId);
    }

    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");
        currentIndex--;
        _burn(tokenId);
    }

    function totalSupply() public view returns (uint256) {
        return currentIndex;
    }
}