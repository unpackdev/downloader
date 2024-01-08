// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract ChibisByNFG is ERC721, ERC721Enumerable, Ownable {
    bool public saleIsActive = false;
    bool public isAllowListActive = false;
    uint256 public constant MAX_SUPPLY = 8888;
    uint256 public constant MAX_PUBLIC_MINT = 10;
    uint256 public constant PRICE_PER_TOKEN = 0.08 ether;

    string private _baseURIextended;
    address private FUND_ONE;
    address private FUND_TWO;

    mapping(address => bool) public allowList;

    constructor() ERC721("Chibis by NFG", "NFG") {}

    function setIsAllowListActive(bool newState) external onlyOwner {
        isAllowListActive = newState;
    }

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function setFundAddress(address fundOne, address fundTwo) external onlyOwner {
        FUND_ONE = fundOne;
        FUND_TWO = fundTwo;
    }

    function setAllowList(address[] calldata addresses, bool newState) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            allowList[addresses[i]] = newState;
        }
    }  

    function mintAllowList(uint8 numberOfTokens) external payable {
        require(isAllowListActive, "Allow list is not active");
        require(allowList[msg.sender], "Not whitelisted");
        _internalMint(numberOfTokens);
        _fundTransfer(msg.value);
    }   

    function mint(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint tokens");
        _internalMint(numberOfTokens);
        _fundTransfer(msg.value);
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

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _internalMint(uint numberOfTokens) internal {
        uint256 ts = totalSupply();
        require(numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for (uint256 i = 1; i <= numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

    function _fundTransfer(uint256 amount) internal {
        (bool success,) = FUND_ONE.call{value: amount/2}("");
        require(success);
        (success,) = FUND_TWO.call{value: amount/2}("");
        require(success);
    }
}