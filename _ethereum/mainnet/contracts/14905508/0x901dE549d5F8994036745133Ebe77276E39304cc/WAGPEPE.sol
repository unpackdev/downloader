// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract WAGPEPE is Ownable, ReentrancyGuard, ERC721A {
    using Strings for uint256;

    uint256 public publicPrice = 0.005 ether;
    uint64 public publicPerWallet = 15;
    uint64 public maxSupply = 6666;
    string private baseURI;

    bool public isPublicSaleActive;
    mapping(address => uint256) public minted;

    constructor() ERC721A("We Are All Going to Pepe", "WAGPEPE") {
    }

    function publicMint(uint256 quantity) external payable {
        require(isPublicSaleActive, "Mint has not started yet");
        require(totalSupply() + quantity <= maxSupply, "Max supply exceeded");
        require(quantity > 0, "Cannot mint less than 1");
        require(tx.origin == _msgSender(), "No contracts");
        require(minted[msg.sender] + quantity <= publicPerWallet, "Exceeded per wallet limit");
        uint256 requiredValue = quantity * publicPrice;
        if (minted[msg.sender] == 0) requiredValue -= publicPrice;
        require(msg.value >= requiredValue, "Incorrect ETH amount");
        minted[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

   function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : '';
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function flipPublicSaleState() external onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }

    function godMint(uint256 quantity) external payable onlyOwner {
        require(totalSupply() + quantity <= maxSupply, "Max supply exceeded");
        _safeMint(msg.sender, quantity);
    }

    function withdrawFunds() external onlyOwner {
        (bool success, ) = owner().call{ value: address(this).balance }('');
        require(success, 'Withdraw failed');
    }

}
