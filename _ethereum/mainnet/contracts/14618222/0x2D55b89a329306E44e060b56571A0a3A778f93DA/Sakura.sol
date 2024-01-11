// SPDX-License-Identifier: MIT
                                                 
pragma solidity 0.8.12;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

contract Sakura is ERC721A, Ownable {
    using Strings for uint256;

    // Sale state variables
    enum SaleStates {
        NOT_STARTED,
        WHITELIST_MINT,
        SALE
    }

    SaleStates private _saleState = SaleStates.NOT_STARTED;

    // Whitelist
    bytes32 public merkleRoot = 0x12a7f6f1726fff267056218fc294302cb4736e6c5af8e2eae05c187ea8747417;
    mapping(address => bool) public whitelistStore;

    // Prices
    uint256 public constant WHITELIST_PRICE = 0.04 ether; 
    uint256 public constant SALE_PRICE = 0.04 ether; 
    uint256 public constant MAX_SUPPLY = 1111; 
    uint256 public constant MAX_BATCH_MINT = 20; 
    uint256 public constant WHITELIST_MMA= 3;


    // Admin Reserved
    uint256 public constant ADMIN_RESERVED = 10;
    uint256 private _adminMinted = ADMIN_RESERVED;
    

    // ERC721 Metadata
    string private _baseURI_;

    constructor(
        string memory name_, 
        string memory symbol_, 
        string memory _initBaseURI
    ) ERC721A(name_, symbol_){
        //Set base uri
        _baseURI_ = _initBaseURI;
   
        //Create 1 nft so that the collection gets listed on opensea
        _safeMint(msg.sender, 1);
        
    } 

    //---------------------------------------------------- MINT FUNCTIONS----------------------------------
    //EXTERNAL
    // Whitelist Mint
    function SakuraMintWhitelist(
        bytes32[] calldata merkleProof_
    ) external payable {
        require(_saleState == SaleStates.WHITELIST_MINT, "Whitelist mint not active");
        require(!whitelistStore[msg.sender], "Whitelist used");
        require(
            1 <= (MAX_SUPPLY - _adminMinted - totalSupply()),
            "Not enough supply"
        );
        require(msg.value >= WHITELIST_PRICE, "Insufficient eth to process the order");
        require(
            MerkleProof.verify(
                merkleProof_,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Whitelist check failed"
        );

        whitelistStore[msg.sender] = true;

        _safeMint(msg.sender, WHITELIST_MMA); 
    }

    // Sale Mint
    function SakuraPublicMint(
        uint8 quantity_
    ) external payable {
        require(_saleState == SaleStates.SALE, "Sale not active");
        require(quantity_ > 0, "You must mint at least 1");
        require(
            quantity_ <= (MAX_SUPPLY - _adminMinted - totalSupply()),
            "Not enough supply"
        );
        require(
            quantity_ <= MAX_BATCH_MINT,
            "Cannot mint more than MAX_BATCH_MINT per transaction"
        );
        require(
            msg.value >= SALE_PRICE * quantity_,
            "Insufficient eth to process the order"
        );

        _safeMint(msg.sender, quantity_);
    }

    //ONLY OWNER
    // admin
    function adminMint() public onlyOwner {
        require(_adminMinted <= ADMIN_RESERVED, "You have already minted");
        require(
             ADMIN_RESERVED <= MAX_BATCH_MINT,
            "Cannot mint more than MAX_BATCH_MINT per transaction"
        );

        _adminMinted -= ADMIN_RESERVED;

        _safeMint(msg.sender, ADMIN_RESERVED);
    }


   

    // -------------------------------------------------------------- SALES STATE-----------------------------
    //VIEW INFORMATION
    function saleState() public view returns (string memory state) {
        if (_saleState == SaleStates.NOT_STARTED) return "Paused";
        if (_saleState == SaleStates.WHITELIST_MINT) return "Whitelist";
        if (_saleState == SaleStates.SALE) return "Public";
    }


    //OWNLY OWNER
    function startWhitelistMint() external onlyOwner {
        require(_saleState < SaleStates.WHITELIST_MINT, "Whitelist mint has already started");
        _saleState = SaleStates.WHITELIST_MINT;
    }

    function startSaleMint() external onlyOwner {
        require(_saleState >= SaleStates.WHITELIST_MINT, "Must start the whitelist mint before the general public sale");
        require(_saleState < SaleStates.SALE, "Sale mint has already started");
        _saleState = SaleStates.SALE;
    }

    

    

  
    //------------------------------------------------------------TOKEN INFORMATION
    //VIEW
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");

        return
            string(
                abi.encodePacked(
                    _baseURI_,
                    tokenId.toString(),
                    ".json"
                )
            );
    }

    //ONLY OWNER
    function setBaseURI(string memory _uri) public onlyOwner {
        require(
            bytes(_uri)[bytes(_uri).length - 1] == bytes1("/"),
            "Must set trailing slash"
        );
        _baseURI_ = _uri;
    }

    //-----------------------------------------------WHITELIST-----------------------------------------
    function checkWhitelistClaimed() public view returns( bool isClaimed) {
        if (whitelistStore[msg.sender]){
            return true;
        }else{
            return false;
        }
    }
    
    //ONLY OWNER
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    
    //----------------------------------------------------WITHDRAW
    //ONLY OWNER
    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}

