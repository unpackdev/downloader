// SPDX-License-Identifier: MIT


pragma solidity ^0.8.4;

import "./IERC721ABurnable.sol";
import "./ERC721AQueryable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract B4LL3RBox is ERC721AQueryable, IERC721ABurnable, Ownable, Pausable, ReentrancyGuard {

    event PermanentURI(string _value, uint256 indexed _id);

    string private _baseTokenURI;
    bool public _baseURILocked;

    address private _authorizedContract;
    address private _admin;

    uint256 public _maxMintPerPublicWallet = 250;
    uint256 public _maxMintPerWhiteListWallet = 1;
    uint256 public _maxSupply = 250;
    uint256 public constant PRICE = 0.025 ether;
    bool private _maxSupplyLocked;

    // merkle root
    bytes32 public ballerMintRoot;

    bool public _ballerPublicMintActive = false;
    bool public _ballerWhiteListMintActive = false;

    //mappings for counters
    mapping(address => uint8) public _ballerMintCounter;   

    constructor(
        string memory baseTokenURI,
        address admin)
    ERC721A("Packs", "Packs") {
        _admin = admin;
        _baseTokenURI = baseTokenURI;
        _safeMint(msg.sender, 1);
        _pause();
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Caller is another contract");
        _;
    }

    
    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner() || msg.sender == _admin, "Not owner or admin");
        _;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwnerOrAdmin {
        require(!_baseURILocked, "Base URI is locked");
        _baseTokenURI = newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBallerMintRoot(bytes32 _root) external onlyOwnerOrAdmin {
        ballerMintRoot = _root;
    }  

    function setBallerPublicMintActive(bool isActive) external onlyOwnerOrAdmin {
        _ballerPublicMintActive = isActive;
    }  

    function setBallerWhitelistMintActive(bool isActive) external onlyOwnerOrAdmin {
        _ballerWhiteListMintActive = isActive;
    }  
    


    function mint(uint256 quantity)
        external
        payable
        nonReentrant
        callerIsUser
        whenNotPaused
    {
        uint256 price = PRICE * quantity;
        require(_ballerPublicMintActive, "Public mint is not yet active");
        require(msg.value >= price, "Not enough ETH");
        require(_numberMinted(msg.sender) + quantity <= _maxMintPerPublicWallet, "Quantity exceeds wallet limit");
        require(totalSupply() + quantity <= _maxSupply, "Quantity exceeds supply");

        _safeMint(msg.sender, quantity);

               // refund excess ETH
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    // Presale
    function allowListMint(uint8 quantity, bytes32[] calldata _merkleProof)
        external
        payable
        callerIsUser     
        nonReentrant   
    {       
        uint256 price = PRICE * quantity;
        require(_ballerWhiteListMintActive, "Whitelist mint is not yet active");
        require(_numberMinted(msg.sender) + quantity <= _maxMintPerWhiteListWallet, "Quantity exceeds wallet limit");
        require(quantity > 0, "Must mint more than 0 tokens");
        require(totalSupply() + quantity <= _maxSupply, "Quantity exceeds supply");                
        require(msg.value >= price, "Not enough ETH");
        // check proof & mint
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, ballerMintRoot, leaf), "Invalid MerkleProof"); 

        _safeMint(msg.sender, quantity);

         if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
               
        _ballerMintCounter[msg.sender] = _ballerMintCounter[msg.sender] + quantity;        
    }    
 

    function ownerMint(address to, uint256 quantity) external onlyOwnerOrAdmin {
        require(totalSupply() + quantity <= _maxSupply, "Quantity exceeds supply");
        _safeMint(to, quantity);
    }

    // Pauses the mint process
    function pause() external onlyOwnerOrAdmin {
        _pause();
    }

    // Unpauses the mint process
    function unpause() external onlyOwnerOrAdmin {
        _unpause();
    }

    function setMaxMintPerPublicWallet(uint256 quantity) external onlyOwnerOrAdmin {
        _maxMintPerPublicWallet = quantity;
    }

    function setMaxMintPerWhiteListWallet(uint256 quantity) external onlyOwnerOrAdmin {
        _maxMintPerWhiteListWallet = quantity;
    }

    function setMaxSupply(uint256 supply) external onlyOwnerOrAdmin {
        require(!_maxSupplyLocked, "Max supply is locked");
        _maxSupply = supply;
    }

    // Locks maximum supply forever
    function lockMaxSupply() external onlyOwnerOrAdmin {
        _maxSupplyLocked = true;
    }

    // Locks base token URI forever and emits PermanentURI for marketplaces (e.g. OpenSea)
    function lockBaseURI() external onlyOwnerOrAdmin {
        _baseURILocked = true;
        for (uint256 i = 0; i < totalSupply(); i++) {
            emit PermanentURI(tokenURI(i), i);
        }
    }

    // Only the owner of the token and its approved operators, and the authorized contract
    // can call this function.
    function burn(uint256 tokenId) public virtual override {
        // Avoid unnecessary approvals for the authorized contract
        bool approvalCheck = msg.sender != _authorizedContract;
        _burn(tokenId, approvalCheck);
    }

    function setAdmin(address admin) external onlyOwner {
        _admin = admin;
    }
    
    function setAuthorizedContract(address authorizedContract) external onlyOwnerOrAdmin {
        _authorizedContract = authorizedContract;
    }

    function withdrawMoney(address to) external onlyOwnerOrAdmin {
        (bool success, ) = to.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    // OpenSea metadata initialization
    function contractURI() public pure returns (string memory) {
        return "https://exhale.mypinata.cloud/ipfs/QmUraxUXqhFTpoweuS5xMHypP2VqjcLaERXTh6pbksK6rT";
    }
}