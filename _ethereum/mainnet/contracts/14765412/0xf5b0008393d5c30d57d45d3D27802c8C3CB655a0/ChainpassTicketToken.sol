//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract ChainpassTicketToken is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public publicSaleDate;
    uint256 public publicPrice;
    uint256 public allowlistPrice;
    string public baseURI;
    string public placeholderURI;
    uint256 public numMinted;
    uint256 public maxSupply;
    bytes32 public allowlistMerkleRoot;
    mapping(address=>uint256) private numClaimedFromAllowlist;

    constructor() ERC721("Chainpass Ticket Token", "CTT") {}

    // minting

    function ownerMint(uint256 amount) external onlyOwner {
        mintMultiple(msg.sender, amount);
    }

    function ownerGiftMint(address addr, uint256 amount) external onlyOwner {
        mintMultiple(addr, amount);
    }

    function publicMint(uint256 amount) external payable nonReentrant {
        require(publicSaleDate != 0, "Public sale date not set yet.");
        require(block.timestamp >= publicSaleDate, "Public sale hasn't started yet.");
        require(msg.value >= amount * publicPrice, "Invalid price.");

        mintMultiple(msg.sender, amount);
    }

    function allowlistMint(uint256 amountAllowed, bytes32[] calldata merkleProof, uint256 amount) external payable nonReentrant {
        require(allowlistMerkleRoot != 0, "Merkle root not set yet.");
        require(msg.value >= amount * allowlistPrice, "Invalid price.");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amountAllowed));
        bool valid = MerkleProof.verify(merkleProof, allowlistMerkleRoot, leaf);
        
        require(valid, "Valid proof required.");
        require(numClaimedFromAllowlist[msg.sender] + amount <= amountAllowed, "Too many.");

        unchecked {
            numClaimedFromAllowlist[msg.sender] += amount;
        }

        mintMultiple(msg.sender, amount);
    }

    function mintMultiple(address addr, uint256 amount) private {
        require(numMinted + amount <= maxSupply, "Cannot mint more than max supply.");

        for (uint256 i=0; i<amount;) {
            _safeMint(addr, numMinted + i);

            unchecked {
                i++;
            }
        }

        unchecked {
            numMinted += amount;
        }
    }

    // getters

    function tokenURI(uint256 id) public view override returns (string memory) {
        require(_ownerOf[id] != address(0), "NOT_MINTED");

        if (bytes(baseURI).length != 0) {
            return string(abi.encodePacked(baseURI, "/", id.toString()));
        }

        return placeholderURI;
    }

    // setters

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setPlaceholderURI(string memory uri) external onlyOwner {
        placeholderURI = uri;
    }

    function setMaxSupply(uint256 supply) external onlyOwner {
        require(supply >= numMinted, "Amount minted cannot be greater than max supply.");
        maxSupply = supply;
    }

    function setPublicSaleDate(uint256 date) external onlyOwner {
        publicSaleDate = date;
    }

    function setPublicPrice(uint256 price) external onlyOwner {
        publicPrice = price;
    }
    
    function setAllowlistPrice(uint256 price) external onlyOwner {
        allowlistPrice = price;
    }

    function setAllowlistMerkleRoot(bytes32 root) external onlyOwner {
        allowlistMerkleRoot = root;
    }

    receive() external payable nonReentrant {}

    function withdraw() public onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }
}
