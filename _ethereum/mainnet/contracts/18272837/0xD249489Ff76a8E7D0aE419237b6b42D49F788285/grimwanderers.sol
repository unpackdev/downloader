// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract GrimWanderers is ERC721A, Ownable {
    bytes32 private _root;
    string private _metadataURI;
    
    bool public revealOpen;
    mapping(uint256 => bool) public revealed;
    uint256 public maxSupply = 3355;
    uint256 public price = 0.0033 ether;
    uint256 public maxPerWallet = 5;
    bool public open;

    constructor() ERC721A("GrimWanderers", "GRIMW") {}

    function mint(uint64 quantity_) external payable {
        require(msg.sender == tx.origin, "Nop");
        require(msg.value == price * quantity_, "Invalid price");
        require(open, "Closed");
        require(_totalMinted() + quantity_ <= maxSupply, "No supply left");
        require(_numberMinted(msg.sender) + quantity_ <= maxPerWallet + _getAux(msg.sender), "Reached maximum allowed per address");
        
        _mint(msg.sender, quantity_);
    }

    function claim(bytes32[] memory proof_, uint64 quantity_) external {
        require(_getAux(msg.sender) == 0, "Already claimed");
        require(_totalMinted() + quantity_ <= maxSupply, "No supply left");
        
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(msg.sender, quantity_)))
        );

        require(MerkleProof.verify(proof_, _root, leaf), "Invalid proof");
        
        _setAux(msg.sender, quantity_);

        _mint(msg.sender, quantity_);
    }

    function tokenURI(uint256 id_)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(id_)) revert URIQueryForNonexistentToken();

        return bytes(_metadataURI).length != 0 ? string(abi.encodePacked(_metadataURI, _toString(id_), ".json")) : "";
    }

    function airdrop(address to_, uint256 quantity_) external onlyOwner {
        require(_totalMinted() + quantity_ <= maxSupply, "No supply left");

        _mint(to_, quantity_);
    }

    function batchAirdrop(address[] memory tos_, uint256[] memory quantities_) external onlyOwner {
        require(tos_.length == quantities_.length, "Not the same size");

        for (uint256 i; i < tos_.length; i++) {
            if (quantities_[i] == 0 || _totalMinted() + quantities_[i] > maxSupply) {
                break;
            }
            
            _mint(tos_[i], quantities_[i]);
        }
    }

    function toggleOpen() external onlyOwner {
        open = !open;
    }

    function toggleReveal() external onlyOwner {
        revealOpen = !revealOpen;
    }

    function setRoot(bytes32 root_) external onlyOwner {
        _root = root_;
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    function setMaxSupply(uint256 maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
    }

    function setMaxPerWallet(uint256 maxPerWallet_) external onlyOwner {
        maxPerWallet = maxPerWallet_;
    }

    function setMetadataURI(string memory metadataURI_) external onlyOwner {
        _metadataURI = metadataURI_;
    }

    function reveal(uint256 id_) external {
        if (!_exists(id_)) revert URIQueryForNonexistentToken();
        
        if (!revealOpen) {
            revert("Reveal closed");
        }

        if (ownerOf(id_) != msg.sender) {
            revert("Incorrect owner");
        }

        revealed[id_] = true;
    }
    
}