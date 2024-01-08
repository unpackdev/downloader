//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract PetPuppies is Ownable, ERC721Enumerable {
    uint256 public constant MINT_PRICE = 0.07 ether;
    uint256 public constant MAX_PER_TX = 20;
    uint256 public constant MAX_SUPPLY = 10000;

    uint256 public constant RESERVED_COUNT = 200;

    uint256 public currentMintId = 1;
    
    bool mintingStarted = false;

    string public baseURI;
    bool public baseURIFreezed;

    constructor() ERC721("Pet Puppies", "PP") {}

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function startMinting() external onlyOwner {
        mintingStarted = true;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        require(!baseURIFreezed, "base uri is freezed");
        baseURI = newBaseURI;
    }

    function freezeBaseURI() external onlyOwner {
        baseURIFreezed = true;
    }

    function withdrawETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function mintReserved(address account, uint256 tokenId) external onlyOwner {
        require(tokenId > MAX_SUPPLY - RESERVED_COUNT && tokenId <= MAX_SUPPLY, "not in reserved range");
        _mint(account, tokenId);
    }

    function mintPetPuppies(uint256 count) payable external {
        require(mintingStarted && count <= MAX_PER_TX && msg.value == count * MINT_PRICE);

        require(currentMintId + count <= MAX_SUPPLY - RESERVED_COUNT + 1, "can't exceed max supply");

        for (uint256 i = 0; i < count; i ++) {
            _mint(msg.sender, currentMintId);
            currentMintId ++;
        }
    }
}
