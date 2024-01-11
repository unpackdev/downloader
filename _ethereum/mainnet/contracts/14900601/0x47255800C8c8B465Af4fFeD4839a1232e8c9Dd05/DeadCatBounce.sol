// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./Ownable.sol";
import "./ERC721A.sol";

contract DeadCatBounce is ERC721A, Ownable {
    string private baseURI;

    bool public started = false;
    bool public claimed = false;
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_MINT = 10;
    uint256 public constant TOKEN_PRICE = .005 ether;

    mapping(address => uint) public addressClaimed;

    constructor() ERC721A("Dead Cat Bounce", "DeadCatBounce") {}

    function mint(uint256 _quantity) external payable {
        require(started, "Sale not yet started");
        require(addressClaimed[_msgSender()] + _quantity <= MAX_MINT, "You have already claimed");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "All cats have been claimed");
        require(msg.value >= TOKEN_PRICE * _quantity, "Need to send more ETH.");
        // mint
        addressClaimed[_msgSender()] += _quantity;
        _safeMint(msg.sender, 1);
    }

    function teamClaim(uint256 _quantity) external onlyOwner {
        _safeMint(msg.sender, _quantity);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");

        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId, ".json")) : '';
    }

    function withdrawFunds() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function withdrawFundsToAddress(address _address, uint256 amount) external onlyOwner {
        (bool success, ) =_address.call{value: amount}("");
        require(success, "Transfer failed.");
    }

    function enableMint(bool mintStarted) external onlyOwner {
        started = mintStarted;
    }
}
