// Parametric Pottery, Anatoly Zenkov, 2023
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Royalty.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./console.sol";

contract SpareBytes is
    ERC721,
    ERC721Burnable,
    ERC721Enumerable,
    ERC721Royalty,
    ReentrancyGuard,
    Pausable,
    Ownable
{

    uint256 public supply = 320;
    uint256 public mintPrice = 0.03 ether;
    string public baseTokenURI = "ipfs://bafybeidqzxfjlywy4eul42l4ripzkuskkpsjarkg6nkjf2aseadxhe3gcu/";
    address payable public withdrawalAddress;

    constructor(address payable _withdrawalAddress) ERC721("Spare Bytes", "SPRBTS") {
        withdrawalAddress = _withdrawalAddress;
    }

    function mint(uint256 tokenId) public payable whenNotPaused nonReentrant returns (uint256) {
        console.log(totalSupply(), supply);
        require(totalSupply() < supply, "MAX SUPPLY REACHED");
        require(tokenId > 0 && tokenId <= supply, "ID OUT OF SUPPLY");
        require(msg.value == mintPrice, "TRANSACTION VALUE DID NOT EQUAL THE MINT PRICE");

        safeMint(tokenId);
        return tokenId;
    }

    function creatorMint(uint256[] memory tokenIds) public onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            safeMint(tokenIds[i]);
        }
    }
    
    function safeMint(uint256 tokenId) internal {
        _safeMint(msg.sender, tokenId);
    }

    function setSupply(uint256 _supply) public onlyOwner {
        supply = _supply;
    }

    function setDefaultRoyalty(uint96 _feeNumerator) public onlyOwner {
        _setDefaultRoyalty(withdrawalAddress, _feeNumerator);
    }

    function setWithdrawalAddress(address payable _withdrawalAddress) public onlyOwner {
        withdrawalAddress = _withdrawalAddress;
    }

    function withdraw() public onlyOwner {
        Address.sendValue(withdrawalAddress, address(this).balance);
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal whenNotPaused override(ERC721, ERC721Enumerable) {
		super._beforeTokenTransfer(from, to, tokenId, batchSize);
	}

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Royalty, ERC721Enumerable) returns (bool) {
		return super.supportsInterface(interfaceId);
	}

    receive() external payable {}

    fallback() external payable {}
}