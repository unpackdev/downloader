// SPDX-License-Identifier: MIT
// Contract written by @KfishNFT
// Makes use of ERC721A created by Chiru Labs https://ERC721A.org
// Modified PR for ERC721AUpgradeable by https://github.com/naomsa
// Thanks Chiru Labs & naomsa for improving the space :)

pragma solidity ^0.8.11;

import "./ERC721AUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./StringsUpgradeable.sol";


contract Bibiz is
    Initializable,
    ERC721AUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using StringsUpgradeable for uint256;

    bool public saleActive;
    bool public revealed;

    uint256 public price;
    uint256 public maxPerTx;
    uint256 public maxPerAddress;
    uint256 public totalReserved;
    uint256 public reservedMinted;

    string public baseURI;
    string public unrevealedURI;

    uint256 public constant SUPPLY_LIMIT = 6969;

    function initialize(
        string memory name_,
        string memory symbol_,
        string memory unrevealedURI_
    ) public initializer {
        __ERC721A_init(name_, symbol_);
        __Ownable_init();
        __ReentrancyGuard_init();
        saleActive = false;
        price = 0.079 ether;
        maxPerAddress = maxPerTx = 3;
        totalReserved = 120;
        unrevealedURI = unrevealedURI_;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function withdraw() external payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    /*
        ERC721A Overrides
    */

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        if(revealed) {
            return bytes(baseURI).length != 0 ? string(abi.encodePacked(abi.encodePacked(baseURI, tokenId.toString()), ".json")) : "";
        } else {
            return bytes(unrevealedURI).length != 0 ? unrevealedURI : "";
        }
    }
}
