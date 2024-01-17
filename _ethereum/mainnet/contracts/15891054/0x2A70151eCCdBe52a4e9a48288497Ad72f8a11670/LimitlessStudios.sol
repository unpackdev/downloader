// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./MerkleProof.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract LimitlessStudios is ERC721, ERC721Burnable, ERC721URIStorage, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    uint256 public constant PRICE = 0.05 ether;
    uint256 public constant MAX_SUPPLY = 1000;

    string public baseURI;
    string public provenanceHash;
    bytes32 public whitelistMerkleTreeRoot;
    bool public isReveald = false;
    bool public aeFeeClaimed = false;

    enum DistributionPhase {
        closed,
        preSale,
        sale,
        ended
    }

    Counters.Counter private _tokenIdCounter;
    DistributionPhase public distributionPhase;
    mapping(address => uint) public buyers;

    constructor(
        string memory _baseURIc,
        string memory _provenanceHash,
        bytes32 _whitelistMerkleTreeRoot
    ) ERC721("LimitlessStudios", "LS") {
        baseURI = _baseURIc;
        provenanceHash = _provenanceHash;
        whitelistMerkleTreeRoot = _whitelistMerkleTreeRoot;
    }

    modifier whenDistributionEnded() {
        require(
            distributionPhase == DistributionPhase.ended,
            "Distribution not ended"
        );
        _;
    }

    function buyNFT(uint256 quantity, bytes32[] calldata merkleProof)
        external
        payable
    {
        require(quantity > 0, "Quantity cannot be 0");
        require(
            distributionPhase != DistributionPhase.closed,
            "Sale is closed"
        );
        require(distributionPhase != DistributionPhase.ended, "Sale ended");
        require(
            (_tokenIdCounter.current() + quantity) < MAX_SUPPLY,
            "Not enough tokens available"
        );
        require(msg.value >= (PRICE * quantity), "Sent amount is not enough");
        require(
            buyers[msg.sender] + quantity <= 6,
            "Already reached maximum buy limit"
        );

        if (distributionPhase == DistributionPhase.preSale) {
            require(
                buyers[msg.sender] == 0 && quantity == 1,
                "On pre sale you can only buy one token"
            );
            _requireWhitelisted(merkleProof);
        }

        for (uint256 i = 0; i < quantity; i++) {
            buyers[msg.sender] = buyers[msg.sender] + 1;
            safeMint(msg.sender);
        }
    }

    function activateNextDistributionPhase() external onlyOwner {
        if (distributionPhase == DistributionPhase.closed) {
            distributionPhase = DistributionPhase.preSale;
        } else if (distributionPhase == DistributionPhase.preSale) {
            distributionPhase = DistributionPhase.sale;
        } else if (distributionPhase == DistributionPhase.sale) {
            distributionPhase = DistributionPhase.ended;
        }
    }

    function reveal(string memory baseURIValue)
        external
        onlyOwner
        whenDistributionEnded
    {
        require(!isReveald, "NFTs already reveald");
        baseURI = baseURIValue;
        isReveald = true;
    }

    function _requireWhitelisted(bytes32[] calldata merkleProof) private view {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        bool isWhitelisted = MerkleProof.verify(
            merkleProof,
            whitelistMerkleTreeRoot,
            leaf
        );
        require(isWhitelisted, "Not whitelisted");
    }

    function safeMint(address to) private {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function withdraw(address to) external onlyOwner whenDistributionEnded {
        require(aeFeeClaimed, "AE fee must be claimed first");
        require(to != address(0), "Cannot withdraw to zero address");
        (bool success, ) = to.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function withdrawAEFee(address to)
        external
        onlyOwner
        whenDistributionEnded
    {
        require(!aeFeeClaimed, "Fee already claimed");
        require(to != address(0), "Cannot withdraw to zero address");
        aeFeeClaimed = true;
        uint256 currentBalance = address(this).balance;
        (bool success, ) = to.call{value: (currentBalance * 25) / 1000}("");
        require(success, "Transfer failed.");
    }

    function ownerMint(address to)
        external
        onlyOwner
    {   
        require(
            distributionPhase == DistributionPhase.closed,
            "Sale already open"
        );
        for (uint256 i = 0; i < 15; i++) {
            safeMint(to);
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        _requireMinted(tokenId);
        if (!isReveald) {
            return baseURI;
        }
        return
            bytes(baseURI).length != 0
                ? string(
                    abi.encodePacked(baseURI, "/", tokenId.toString(), ".json")
                )
                : "";
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function contractURI() public view returns (string memory) {
        return "ipfs://QmdfBA1fiHtszUGD3i8DneiwQqxDXTXsUhAYjbvTZxdnKM";
    }
}
