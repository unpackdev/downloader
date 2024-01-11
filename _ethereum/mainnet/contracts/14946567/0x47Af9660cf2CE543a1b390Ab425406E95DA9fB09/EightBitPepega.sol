// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract EightBitPepega is Ownable, ReentrancyGuard, ERC721A {
    using Strings for uint256;

    uint256 public PUBLIC_PRICE = 0.005 ether;
    uint64 public FREE_PER_TX = 5;
    uint64 public FREE_SUPPLY = 333;
    uint64 public PUBLIC_PER_TX = 10;
    uint64 public MAX_SUPPLY = 888;
    string private baseURI;

    constructor() ERC721A("EightBitPepega", "EBT") {
    }

    function publicMint(uint256 quantity) external payable {
        address caller_ = _msgSender();
        require(totalSupply() + quantity <= MAX_SUPPLY, "Max supply exceeded");
        require(quantity > 0, "Cannot mint less than 1");
        require(tx.origin == caller_, "No contracts");
        require(quantity <= PUBLIC_PER_TX, "Exceeded per transaction limit");
        if (totalSupply() >= FREE_SUPPLY) {
            require(msg.value == quantity * PUBLIC_PRICE, "Incorrect ETH amount");
        } else {
            require(quantity <= FREE_PER_TX, "Exceeded free per transaction limit");
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

    function godMint(uint256 quantity) external payable onlyOwner {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Max supply exceeded");
        _safeMint(msg.sender, quantity);
    }

    function withdrawFunds() external onlyOwner {
        (bool success, ) = owner().call{ value: address(this).balance }('');
        require(success, 'Withdraw failed');
    }

}
