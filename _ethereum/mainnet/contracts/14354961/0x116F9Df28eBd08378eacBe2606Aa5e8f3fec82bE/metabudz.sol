// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract MetaBudz is ERC721, ERC721Enumerable, Ownable {
    bool public saleIsActive = false;
    string private _baseURIextended;

    bool public isAllowListActive = false;
    uint256 public constant MAX_SUPPLY = 4420;
    uint256 public constant MAX_WL_SUPPLY = 1420;
    uint256 public constant MAX_TX_MINT = 10;
    uint256 public constant PRICE_PER_TOKEN_PUBLIC_SALE = 0.042 ether;
    uint256 public constant PRICE_PER_TOKEN_PRE_SALE = 0.032 ether;

    mapping(address => bool) private _allowList;

    constructor() ERC721("MetaBudz", "METABUD") {
    }

    function setIsAllowListActive(bool _isAllowListActive) external onlyOwner {
        isAllowListActive = _isAllowListActive;
    }

    function setAllowList(address[] calldata addresses, bool allowed) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = allowed;
        }
    }

    function isAllowedToMint(address addr) external view returns (bool) {
        return _allowList[addr];
    }

    function mintAllowList(uint8 numberOfTokens) external payable {
        uint256 ts = totalSupply();
        require(isAllowListActive, "Allow list is not active");
        require(_allowList[msg.sender], "Address not allowed to purchase");
        require(numberOfTokens <= MAX_TX_MINT, "Exceeded max token purchase");
        require(ts + numberOfTokens <= MAX_WL_SUPPLY, "Purchase would exceed max tokens");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(PRICE_PER_TOKEN_PRE_SALE * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function reserve(uint256 n) public onlyOwner {
      uint supply = totalSupply();
      uint i;
      for (i = 0; i < n; i++) {
          _safeMint(msg.sender, supply + i);
      }
    }

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function mint(uint numberOfTokens) public payable {
        uint256 ts = totalSupply();
        require(saleIsActive, "Sale must be active to mint tokens");
        require(numberOfTokens <= MAX_TX_MINT, "Exceeded max token purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(PRICE_PER_TOKEN_PUBLIC_SALE * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}