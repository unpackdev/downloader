// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./VRFConsumerBase.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

/*
_______/\\\\\________/\\\\\\\\\\\\______/\\\\\\\\\\\\____        
 _____/\\\///\\\_____\/\\\////////\\\___\/\\\////////\\\__       
  ___/\\\/__\///\\\___\/\\\______\//\\\__\/\\\______\//\\\_      
   __/\\\______\//\\\__\/\\\_______\/\\\__\/\\\_______\/\\\_     
    _\/\\\_______\/\\\__\/\\\_______\/\\\__\/\\\_______\/\\\_    
     _\//\\\______/\\\___\/\\\_______\/\\\__\/\\\_______\/\\\_   
      __\///\\\__/\\\_____\/\\\_______/\\\___\/\\\_______/\\\__  
       ____\///\\\\\/______\/\\\\\\\\\\\\/____\/\\\\\\\\\\\\/___ 
        ______\/////________\////////////______\////////////_____

*/

contract BirdNFT is ERC721, VRFConsumerBase, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private supply;
    event RequestedRandomness(bytes32 requestId);

    uint256 public constant BIRDS_TOTAL_SUPPLY           = 10006;
    uint256 public constant BIRDS_COLLAB_MINT_LIMIT      = 5;
    uint256 public constant BIRDS_PRESALE_MINT_LIMIT     = 2;
    uint256 public constant BIRDS_SALE_MINT_LIMIT        = 10;
    uint256 public constant PUBLIC_PRICE                 = 0.088 ether;
    uint256 public collabMintCap                         = 4000;
    uint256 public presaleMintCap                        = 9000;
    bytes32 public keyHash;
    uint256 public fee;

    mapping(address => uint256) public collabListPurchases;
    mapping(address => uint256) public presalerListPurchases;

    string public baseURI;
    address public seedStach;

    uint256 public metadataIndexOffset;
    bytes32 internal _randomnessRequestId;

    bool public collabSaleLive;
    bool public presaleLive;
    bool public saleLive;

    bytes32 public collabSaleMerkleRoot;
    bytes32 public presaleMerkleRoot;

    constructor(
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _keyHash,
        uint256 _fee,
        string memory _baseURI,
        address _seedStach
    )
        VRFConsumerBase(_vrfCoordinator, _linkToken)  
        ERC721("OddBirds", "ODD") 
    {
        keyHash = _keyHash;
        fee = _fee;
        baseURI = _baseURI;
        seedStach = _seedStach;
    }

    /**
     * @dev validates merkleProof
     */
    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }

    modifier isCorrectPayment(uint256 price, uint256 numberOfTokens) {
        require(
            price * numberOfTokens == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    function reserveTokens(address[] calldata entries) external onlyOwner {
        uint256 tokenCount = supply.current();
        uint256 tokenQuantity = entries.length;
        require(tokenCount + tokenQuantity <= BIRDS_TOTAL_SUPPLY, "EXCEED_TOTAL_SUPPLY");
        for (uint256 i = 0; i < tokenQuantity; i++) {
            _safeMint(entries[i], tokenCount + i + 1);
        }
    }

    function collabBuy(
        uint256 tokenQuantity, 
        bytes32[] calldata merkleProof
    ) 
        external
        payable
        isValidMerkleProof(merkleProof, collabSaleMerkleRoot)
        isCorrectPayment(PUBLIC_PRICE, tokenQuantity)
        nonReentrant
    {
        require(!presaleLive && !saleLive && collabSaleLive, "NOT_COLLAB_STATE");
        uint256 tokenCount = supply.current();
        require(tokenCount + tokenQuantity <= collabMintCap, "EXCEED_COLLAB_SUPPLY");
        require(collabListPurchases[msg.sender] + tokenQuantity <= BIRDS_COLLAB_MINT_LIMIT, "EXCEED_USER_ALLOC");
        
        for (uint256 i = 1; i <= tokenQuantity; i++) {
            collabListPurchases[msg.sender]++;
            _safeMint(msg.sender, tokenCount + i);
        }
    }
    
    function presaleBuy(
        uint256 tokenQuantity,
        bytes32[] calldata merkleProof
    ) 
        external
        payable
        isValidMerkleProof(merkleProof, presaleMerkleRoot)
        isCorrectPayment(PUBLIC_PRICE, tokenQuantity)
        nonReentrant
    {
        require(!saleLive && !collabSaleLive && presaleLive, "NOT_PRESALE_STATE");
        uint256 tokenCount = supply.current();
        require(tokenCount + tokenQuantity <= presaleMintCap, "EXCEED_PRESALE_SUPPLY");
        require(presalerListPurchases[msg.sender] + tokenQuantity <= BIRDS_PRESALE_MINT_LIMIT, "EXCEED_USER_ALLOC");
        
        for (uint256 i = 1; i <= tokenQuantity; i++) {
            presalerListPurchases[msg.sender]++;
            _safeMint(msg.sender, tokenCount + i);
        }
    }

    function buy(
        uint256 tokenQuantity
    )
        external
        payable
        isCorrectPayment(PUBLIC_PRICE, tokenQuantity)
        nonReentrant
    {
        require(!presaleLive && !collabSaleLive && saleLive, "NOT_SALE_STATE");
        uint256 tokenCount = supply.current();
        require(tokenCount + tokenQuantity <= BIRDS_TOTAL_SUPPLY, "EXCEED_TOTAL_SUPPLY");
        require(tokenQuantity <= BIRDS_SALE_MINT_LIMIT, "EXCEED_BIRDS_SALE_MINT_LIMIT");        
        for(uint256 i = 1; i <= tokenQuantity; i++) {
            _safeMint(msg.sender, tokenCount + i);
        }
    }

    function setCollabSaleMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        collabSaleMerkleRoot = merkleRoot;
    }

    function setPresaleMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        presaleMerkleRoot = merkleRoot;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(seedStach).transfer(balance);
    }

    function toggleCollabStatus() external onlyOwner {
        collabSaleLive = !collabSaleLive;
    }
    
    function togglePresaleStatus() external onlyOwner {
        presaleLive = !presaleLive;
    }
    
    function toggleSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }
    
    function setBaseURI(string calldata URI) external onlyOwner {
        baseURI = URI;
    }

    function setCollabMintCap(uint256 mintCap) external onlyOwner {
        collabMintCap = mintCap;
    }

    function setPresaleMintCap(uint256 mintCap) external onlyOwner {
        presaleMintCap = mintCap;
    }

    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    function _beforeTokenTransfer (address from, address to, uint256 tokenId) internal override {
        if (from == address(0)){
            supply.increment();
        }
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    function setMetadataIndexOffset() external onlyOwner {
        require(_randomnessRequestId == "", "Already requested");
        require(LINK.balanceOf(address(this)) >= fee * 10**17, "Not enough LINK");
        _randomnessRequestId = requestRandomness(keyHash, fee * 10**17);
        emit RequestedRandomness(_randomnessRequestId);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        require(requestId == _randomnessRequestId, "Bad Request");
        metadataIndexOffset = randomness % BIRDS_TOTAL_SUPPLY;
        if (metadataIndexOffset == 0) {
            metadataIndexOffset = 1;
        }
    }
}
