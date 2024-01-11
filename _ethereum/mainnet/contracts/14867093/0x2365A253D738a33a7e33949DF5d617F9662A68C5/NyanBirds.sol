// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract NyanBirds is Ownable, ReentrancyGuard, ERC721A {
    using Strings for uint256;

    uint256 public publicPrice = 0.003 ether;
    uint64 public freePerTxn = 2;
    uint64 public freeSupply = 2500;
    uint64 public publicPerTxn = 10;
    uint64 public maxSupply = 5555;
    string private baseURI;

    bool public isPublicSaleActive;

    constructor() ERC721A("NyanBirds", "NB") {
    }

    function publicMint(uint256 quantity) external payable {
        require(isPublicSaleActive, "Mint has not started yet");
        require(totalSupply() + quantity <= maxSupply, "Max supply exceeded");
        require(quantity > 0, "Cannot mint less than 1");
        address caller_ = _msgSender();
        require(tx.origin == caller_, "No contracts");
        require(quantity <= publicPerTxn, "Exceeded per transaction limit");
        if (totalSupply() >= freeSupply) {
            require(msg.value == quantity * publicPrice, "Incorrect ETH amount");
        } else {
            require(quantity <= freePerTxn, "Exceeded free per transaction limit");
        }
        
        _safeMint(msg.sender, quantity);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : '';
    }

    function setBaseURI(string calldata data) external onlyOwner {
        baseURI = data;
    }

    function setPublicPrice(uint256 price_) external onlyOwner {
        publicPrice = price_;
    }

    function flipPublicSaleState() external onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }

    function batchMint(uint256 quantity) external payable onlyOwner {
        require(totalSupply() + quantity <= maxSupply, "Max supply exceeded");
        _safeMint(msg.sender, quantity);
    }

    function withdrawFunds() external onlyOwner {
        (bool success, ) = owner().call{ value: address(this).balance }('');
        require(success, 'Withdraw failed');
    }

}
