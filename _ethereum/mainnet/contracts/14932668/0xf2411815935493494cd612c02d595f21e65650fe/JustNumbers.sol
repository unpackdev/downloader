// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";   
import "./ReentrancyGuard.sol";

contract JustNumbers is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public MAX_SUPPLY = 2501;
    uint256 public supply;
    uint256 public startWhitelistMint;
    uint256 public startPublicMint;
    string public baseURI;
    bool ownerHasMinted;
    mapping(address => bool) public whitelist;

    constructor(uint256 _startTime) ERC721("JustNumbers", "JN") {
        startPublicMint = _startTime;
        startWhitelistMint = startPublicMint - 600;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newuri) external onlyOwner {
        baseURI = newuri;
    }

    function addWhitelist(address[] memory users, bool approved) external onlyOwner {
        uint length = users.length;
        for (uint i; i < length;) {
            whitelist[users[i]] = approved;
            unchecked {
                ++i;
            }
        }
    } 

    function safeMint(uint256 amount, address to) internal {
        for (uint i; i < amount;) {
            uint256 tokenId = _tokenIdCounter.current();
            require(tokenId + 1 <= MAX_SUPPLY, "max supply reached");
            _tokenIdCounter.increment();
            _safeMint(to, tokenId);
            supply += 1;
            unchecked {
                ++i;
            }
        }
        
    }

    function mint(uint256 amount) external nonReentrant {
        if (block.timestamp > startPublicMint) {
            require(balanceOf(msg.sender) + amount <= 2, "already minted");
            safeMint(amount, msg.sender);
        } else if (block.timestamp > startWhitelistMint) {
            require(whitelist[msg.sender], "not whitelisted");
            require(balanceOf(msg.sender) + amount <= 2, "already minted");
            safeMint(amount, msg.sender);            
        } else {
            revert("mint has not started");
        }
    }

    function ownerMint() external onlyOwner {
        require(!ownerHasMinted, "owner already minted");
        for (uint i; i < 300;) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(owner(), tokenId);
            supply += 1;
            unchecked {
                ++i;
            }
        }
        ownerHasMinted = true;
    }

    function batchTransferFromOwner(
        address to,
        uint256[] memory tokenId
    ) external onlyOwner {
        uint256 length = tokenId.length;
        for (uint i; i < length;) {
            require(_isApprovedOrOwner(_msgSender(), tokenId[i]), "ERC721: transfer caller is not owner nor approved");
            _transfer(owner(), to, tokenId[i]);
            unchecked {
                ++i;
            }
        }
    }

    function mintLeftover() external onlyOwner {
        uint length = MAX_SUPPLY - supply;
        for (uint i; i < length;) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(owner(), tokenId);
            supply += 1;
            unchecked {
                ++i;
            }
        } 
    }

    function withdraw() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "eth transfer failed");
    }
}