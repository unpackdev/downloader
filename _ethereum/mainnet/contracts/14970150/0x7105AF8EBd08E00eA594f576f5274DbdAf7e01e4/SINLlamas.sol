// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract SINfulLlamas is Ownable, ReentrancyGuard, ERC721A {
    using Strings for uint256;
    
    uint256 public PUBLIC_PRICE = 0.005 ether;
    uint64 public MAX_SUPPLY = 2222;
    uint32 public PUBLIC_FREE_PER_TX = 1;
    uint64 public PUBLIC_PER_TX = 10;
    uint64 public OG_SUPPLY = 111;
    uint32 public OG_FREE_PER_TX = 3;
    string private baseURI;
    mapping(address => uint256) public minted;

    constructor() ERC721A("SINfulLlamas", "SNLL") {
    }

    function publicMint(uint256 quantity) external payable {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Max supply exceeded");
        require(quantity > 0, "Cannot mint less than 1");
        require(tx.origin == _msgSender(), "No contracts");
        require(quantity <= PUBLIC_PER_TX, "Exceeded per transaction limit");
        uint256 requiredValue = quantity * PUBLIC_PRICE;
        if (totalSupply() >= OG_SUPPLY) {
            if (minted[msg.sender] == 0) requiredValue -= PUBLIC_PRICE;
            require(msg.value >= requiredValue, "Incorrect ETH amount");
            minted[msg.sender] += quantity;
            _safeMint(msg.sender, quantity);
        } else {
            if (quantity <= OG_FREE_PER_TX) {
                _safeMint(msg.sender, quantity);
            } else {
                requiredValue = requiredValue - (OG_FREE_PER_TX*PUBLIC_PRICE);
                require(msg.value >= requiredValue, "Incorrect ETH amount");
                _safeMint(msg.sender, quantity);
            }
        }
    }

   function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : '';
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function godMint(uint256 quantity) external payable onlyOwner {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Max supply exceeded");
        _safeMint(msg.sender, quantity);
    }

    function burnSupply(uint64 newSupply) external onlyOwner {
        require(newSupply < MAX_SUPPLY, "New max supply should be lower than current max supply");
        require(newSupply > totalSupply(), "New max suppy should be higher than current number of minted tokens");
        MAX_SUPPLY = newSupply;
    }

    function withdrawFunds() external onlyOwner {
        (bool success, ) = owner().call{ value: address(this).balance }('');
        require(success, 'Withdraw failed');
    }

}
