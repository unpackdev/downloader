// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract HapeMfers is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 5555;
    uint256 public constant PUBLIC_PRICE = 0.0069 ether; // 6900000000000000
    bool public SALE_IS_ACTIVE = false;

    string private _baseURIextended;
    
    constructor() ERC721A("Hape Mfers", "HM") {}

    function mint(uint256 nMints) external payable nonReentrant {
        require(SALE_IS_ACTIVE, "Minting is not active now");
        require(totalSupply() + nMints <= MAX_SUPPLY, "Exceeds max supply");
        require(PUBLIC_PRICE * nMints <= msg.value, "Sent incorrect ETH value");

        _safeMint(msg.sender, nMints);
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, (tokenId + 1).toString(),'.json')) : '.json';
    }

    function withdrawAll() external onlyOwner {
        require(address(this).balance > 0, "No funds to withdraw");
        uint256 contractBalance = address(this).balance;
        _withdraw(msg.sender, contractBalance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function flipSaleState() public onlyOwner {
        SALE_IS_ACTIVE = !SALE_IS_ACTIVE;
    }

    receive() external payable {}

}
