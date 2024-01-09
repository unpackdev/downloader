// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./MerkleProof.sol";

contract Playground is ERC721Enumerable, Ownable {
    // Qty
    uint256 public constant SUPPLY = 5555;
    
    // Price
    uint256 public PRESALE_PRICE;
    uint256 public PUBLIC_PRICE;
    uint256 public MAX_PER_MINT;

    // Auction
    uint256 public AUCTION_START_PRICE;
    uint256 public AUCTION_DEDUCTION_RATE;
    uint256 public AUCTION_START_TIME;
    uint256 public AUCTION_PERIOD;

    // Status
    bool public presaleActive = false;
    bool public auctionActive = false;
    bool public publicActive = false;

    string public baseTokenURI;
    string public baseContractURI;

    mapping(address => uint256) public wlPurchaseCount;
    mapping(uint256 => bytes32) public merkleRoot;

    constructor(string memory baseURI) ERC721("The Playground", "PLAYGROUND") {
        baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns(string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function presaleMint(uint256 _qty, uint256 _cid, bytes32[] calldata _merkleProof) external payable {
        require(presaleActive, "Presale is closed");

        // Verify proof
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot[_cid], leaf), "Invalid Proof");

        require(_qty > 0, "Qty must be more than 0");
        require(wlPurchaseCount[msg.sender] + _qty <= MAX_PER_MINT, "Exceeded max amount to mint");

        require(totalSupply() + _qty <= SUPPLY, "All NFT are sold out");
        require(msg.value >= PRESALE_PRICE * _qty, "Invalid price value");

        wlPurchaseCount[msg.sender] += _qty;

        for(uint256 i = 0; i < _qty; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function publicMint(uint256 _qty) external payable {
        require(publicActive, "Public sale is closed");
        require(totalSupply() + _qty <= SUPPLY, "All NFT are sold out");
        require(_qty > 0 && _qty <= MAX_PER_MINT, "Exceeded max amount to mint");
        require(msg.value >= PUBLIC_PRICE * _qty, "Invalid value");

        for(uint256 i = 0; i < _qty; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function auctionMint(uint256 _qty) external payable {
        require(auctionActive, "Auction is closed");
        require(totalSupply() + _qty <= SUPPLY, "All NFT are sold out");
        require(_qty > 0 && _qty <= MAX_PER_MINT, "Exceeded max amount to mint");

        uint256 timeElapsed = (block.timestamp - AUCTION_START_TIME) / 60 / 60;
        uint256 currentPrice;
        
        if(timeElapsed < AUCTION_PERIOD) {
            uint256 deduction = AUCTION_DEDUCTION_RATE * timeElapsed;
            currentPrice = AUCTION_START_PRICE - deduction;
        } else {
            currentPrice = PUBLIC_PRICE;
        }
        
        require(msg.value >= currentPrice * _qty, "Invalid value");   

        for(uint256 i = 0; i < _qty; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function gift(address[] calldata receivers) external onlyOwner {
        require(totalSupply() + receivers.length <= SUPPLY, "No more supply");

        for(uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], totalSupply() + 1);
        }
    }

    function togglePresaleActive() external onlyOwner {
        presaleActive = !presaleActive;
    }

    function togglePublicActive() external onlyOwner {
        presaleActive = false;
        publicActive = !publicActive;
    }

    function toggleAuctionActive() external onlyOwner {
        presaleActive = false;
        publicActive  = false;
        auctionActive = !auctionActive;
        AUCTION_START_TIME = block.timestamp;
    }

    function setVariables(uint256 _presale, uint256 _public, uint256 _max) external onlyOwner {
        PRESALE_PRICE = _presale;
        PUBLIC_PRICE = _public;
        MAX_PER_MINT = _max;
    }

    function setAuctionVariable(uint256 _start, uint256 _deduction, uint256 _period) external onlyOwner {
        AUCTION_START_PRICE = _start;
        AUCTION_DEDUCTION_RATE = _deduction;
        AUCTION_PERIOD = _period;
    }

    function setMerkleRoot(uint256 _id, bytes32 _merkleRoot) external onlyOwner {
        merkleRoot[_id] = _merkleRoot;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setContractURI(string calldata _contractURI) external onlyOwner {
        baseContractURI = _contractURI;
    }

    function contractURI() public view returns (string memory) {
        return baseContractURI;
    }
}