// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./ERC721AQueryable.sol";
import "./console.sol";

interface WOCInterface {
    function balanceOf(address owner) external view returns (uint256);

    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

contract MenOfCrypto is ERC721A, ERC721AQueryable, Ownable, ReentrancyGuard {
    bool public isMintActive = false;
    string private _baseURIextended;
    address public immutable WOC_CONTRACT;
    mapping(uint256 => bool) public isClaimed;

    constructor(address woc) ERC721A("Men of Crypto", "MOC") {
        WOC_CONTRACT = woc;
    }

    function mint() public nonReentrant {
        require(msg.sender == tx.origin, "Cant mint from another contract");
        require(isMintActive, "Mint is not active");
        uint256 WOCBalance = checkWOCBalance(msg.sender);
        require(WOCBalance > 0, "You need to own at least one Women of Crypto to mint!");

        uint256 counter;
        for (uint256 i = 0; i < WOCBalance; i++) {
            uint256 tokenId = callTokenOfOwnerByIndex(msg.sender, i);
            if (!isClaimed[tokenId]) {
                counter++;
                isClaimed[tokenId] = true;
            }
        }
        require(counter != 0, "All your WOC have been used to mint");
        require(totalSupply() + counter <= 8888, "Exceeds total supply");
        _safeMint(msg.sender, counter);
    }

    function callTokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        return WOCInterface(WOC_CONTRACT).tokenOfOwnerByIndex(owner, index);
    }

    function checkWOCBalance(address owner) public view returns (uint256) {
        return WOCInterface(WOC_CONTRACT).balanceOf(owner);
    }

    function toggleIsMintActive() external onlyOwner {
        isMintActive = !isMintActive;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        require(bytes(baseURI_).length != 0, "Can't update to an empty value");
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIextended;
    }
}
