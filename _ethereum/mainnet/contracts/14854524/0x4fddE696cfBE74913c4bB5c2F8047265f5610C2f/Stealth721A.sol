// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract StealthERC721A is ERC721A, Ownable, ReentrancyGuard {
    uint256 public constant maxSupply = 3333;
    uint256 public constant publicMintPrice = 0.01 ether;
    uint256 public constant maxPerWallet = 15;    
    uint256 public constant maxFreeMint = 5;
    uint256 public constant totalFreeMint = 333;
    string private _tokenBaseURI;
    address private constant admin = 0xD59e7B84f4A5a4D1F437C7D3187c8aDe7f65C780;    
    bool public paused = true;
    mapping(address => uint256) public mintedOwnerQuantity;

  constructor() ERC721A("Imaginary Heroes", "IHO") {}

    function mintForFree(uint256 _mintQuantity) external payable {{
            require(!paused, "Contract is on pause!");
            require(totalSupply() + _mintQuantity <= maxSupply, "No Hero Left!");
            require(totalSupply() + _mintQuantity <= totalFreeMint, "Free mint is run out, please use public mint!");
            require(
                mintedOwnerQuantity[msg.sender] + _mintQuantity <= maxFreeMint,
                "Already reach limit for free mint quantity"
            );
        }
        mintedOwnerQuantity[msg.sender] += _mintQuantity;
        _safeMint(msg.sender, _mintQuantity);
}

    function mintPublic(uint256 _mintQuantity) external payable {{
            require(!paused, "Contract is on pause!");
            require(totalSupply() + _mintQuantity <= maxSupply, "No Hero Left!");
            require(
                mintedOwnerQuantity[msg.sender] + _mintQuantity <= maxPerWallet,
                "You already reached the max amount per wallet"
            );
            require(msg.value >= publicMintPrice * _mintQuantity, "You don't have enough fund to mint");
        }
        mintedOwnerQuantity[msg.sender] += _mintQuantity;
        _safeMint(msg.sender, _mintQuantity);
}

    function mintByOwner(uint256 _mintQuantity) external onlyOwner payable {{
        require(totalSupply() + _mintQuantity <= maxSupply, "Sold out");
        }
        mintedOwnerQuantity[msg.sender] += _mintQuantity;
        _safeMint(msg.sender, _mintQuantity);
}

    function withdraw() public onlyOwner {
    payable(admin).transfer(address(this).balance);
  }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    function setPaused(bool _paused) public onlyOwner {
    paused = _paused;
  }

    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return _tokenBaseURI;
    }
}