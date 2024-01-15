//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract LostLand is ERC721Enumerable, Ownable, Pausable {
    string public baseURI;

    mapping(address => bool) public minters;
    modifier onlyMinter() {
        require(minters[_msgSender()], "Mint: caller is not the minter");
        _;
    }

    constructor() ERC721("LostLand", "LAND") {
        minters[_msgSender()] = true;
    }

    function setMinter(address newMinter, bool power) public onlyOwner {
        minters[newMinter] = power;
    }

    function mint(address to, uint256 tokenId) public onlyMinter {
        ERC721._safeMint(to, tokenId);
    }

    function mintBatch(address[] memory to, uint256[] memory tokenIds_) public onlyMinter {
        require(tokenIds_.length > 0 && tokenIds_.length == to.length, "array length unequal");
        for (uint i = 0; i < tokenIds_.length; i++) {
            ERC721._safeMint(to[i], tokenIds_[i]);
        }
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }

    function walletOfOwner(address owner_) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner_);

        uint256[] memory tokensIds = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensIds[i] = tokenOfOwnerByIndex(owner_, i);
        }
        return tokensIds;
    }

    function setURI(string memory newURI_) public onlyOwner {
        baseURI = newURI_;
    }

    function setPause() external onlyOwner {
        _pause();
    }

    function unsetPause() external onlyOwner {
        _unpause();
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal whenNotPaused override(ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
