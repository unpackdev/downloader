// SPDX-License-Identifier: MIT
/*
 ________  ________  ___  ___  ___  ___  ________  ________     
|\   __  \|\   ____\|\  \|\  \|\  \|\  \|\   __  \|\   __  \    
\ \  \|\  \ \  \___|\ \  \\\  \ \  \\\  \ \  \|\  \ \  \|\  \   
 \ \   __  \ \_____  \ \   __  \ \  \\\  \ \   _  _\ \   __  \  
  \ \  \ \  \|____|\  \ \  \ \  \ \  \\\  \ \  \\  \\ \  \ \  \ 
   \ \__\ \__\____\_\  \ \__\ \__\ \_______\ \__\\ _\\ \__\ \__\
    \|__|\|__|\_________\|__|\|__|\|_______|\|__|\|__|\|__|\|__|
             \|_________|                                       
*/

pragma solidity 0.8.12;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

contract Ashura is ERC721A, Ownable {
    using Strings for uint256;

    //SALE STATE
    enum SaleStates {
        NOT_STARTED,
        WHITELIST_MINT,
        SALE,
        ENDED
    }

    SaleStates private _saleState = SaleStates.NOT_STARTED;

    //WL STORES
    // devil
    bytes32 public devilRoot =
        0xd9ea7822fc200f19049d2658e144a7cd1fe6b5a45c6d5682e7b9401d66d4d400;
    mapping(address => uint8) public devilStore;

    // demon
    bytes32 public demonRoot =
        0xec986214227fa93240237a38be684b36ac26ff49113befc8016eebd00e177dac;
    mapping(address => uint8) public demonStore;

    // PRICES
    //devil
    uint256 public constant DEVIL_PRICE_1 = 0 ether;
    uint256 public constant DEVIL_PRICE_REST = 0.03 ether;
    uint256 public constant DEVIL_MAX_MINT = 4;

    //demon
    uint256 public constant DEMON_PRICE = 0.03 ether;
    uint256 public constant DEMON_MAX_MINT = 4;

    //public
    uint256 public constant PUBLIC_PRICE = 0.05 ether;
    uint256 public constant PUBLIC_MAX_MINT = 5;

    // Admin Reserved
    uint256 public constant ADMIN_RESERVED = 10;
    uint256 private _adminMinted = ADMIN_RESERVED;

    //SUPPLY
    uint256 public constant MAX_SUPPLY = 4000;

    // ERC721 Metadata
    string private _baseURI_ = "ipfs://nice_try_nerd/"; //You aint getting it early bruv

    //HIDDEN
    string private _hiddenURI =
        "ipfs://QmSAswEyQUdMLkSkuXSXe3utP8AR8RKgkSSTSfkWAG94rS/"; //Replace this
    bool private _hidden = true;

    constructor(string memory name_, string memory symbol_)
        ERC721A(name_, symbol_)
    {
        //Create 1nft so the collection gets listed on opensea
        _safeMint(msg.sender, 1);
    }

    //---------------------------------------------------- MINT FUNCTIONS----------------------------------
    //EXTERNAL
    // Devil mint
    function DevilMint(bytes32[] calldata merkleProof_, uint8 amount_)
        external
        payable
    {
        require(
            _saleState == SaleStates.WHITELIST_MINT,
            "Devil mint not active"
        );
        require(amount_ > 0, "You must mint at least 1");
        require(
            devilStore[msg.sender] + amount_ <= DEVIL_MAX_MINT,
            "Amount is too large"
        );
        require(
            amount_ <= (MAX_SUPPLY - _adminMinted - totalSupply()),
            "Not enough supply"
        );
        require(
            MerkleProof.verify(
                merkleProof_,
                devilRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Devil role check failed"
        );

        //account for 0
        uint8 mintAmount = amount_;

        if (devilStore[msg.sender] == uint8(0)) {
            amount_ -= 1;
        }

        require(
            msg.value >= amount_ * DEVIL_PRICE_REST,
            "Insufficient eth to process the order"
        );

        //increment number minted
        devilStore[msg.sender] += mintAmount;

        _safeMint(msg.sender, mintAmount);
    }

    //Demon mint
    function DemonMint(bytes32[] calldata merkleProof_, uint8 amount_)
        external
        payable
    {
        require(
            _saleState == SaleStates.WHITELIST_MINT,
            "Demon mint not active"
        );
        require(amount_ > 0, "You must mint at least 1");
        require(
            demonStore[msg.sender] + amount_ <= DEMON_MAX_MINT,
            "Amount is too large"
        );
        require(
            amount_ <= (MAX_SUPPLY - _adminMinted - totalSupply()),
            "Not enough supply"
        );
        require(
            MerkleProof.verify(
                merkleProof_,
                demonRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Demon role check failed"
        );
        require(
            msg.value >= amount_ * DEMON_PRICE,
            "Insufficient eth to process the order"
        );

        //increment number minted
        demonStore[msg.sender] += amount_;

        _safeMint(msg.sender, amount_);
    }

    //Public Mint
    function AshuraPublicMint(uint8 quantity_) external payable {
        require(_saleState == SaleStates.SALE, "Sale not active");
        require(quantity_ > 0, "You must mint at least 1");
        require(
            quantity_ <= (MAX_SUPPLY - _adminMinted - totalSupply()),
            "Not enough supply"
        );
        require(
            quantity_ <= PUBLIC_MAX_MINT,
            "Cannot mint more than MAX_BATCH_MINT per transaction"
        );
        /*
        require(
            (balanceOf(msg.sender) + quantity_) <= MAX_BATCH_MINT,
            "Any one wallet cannot hold more than MAX_BATCH_MINT"
        );
        */
        require(
            msg.value >= PUBLIC_PRICE * quantity_,
            "Insufficient eth to process the order"
        );

        _safeMint(msg.sender, quantity_);
    }

    //ONLY OWNER
    // admin
    function adminMint(uint8 quantity_) public onlyOwner {
        require(_adminMinted >= quantity_, "You have already minted");
        require(
            quantity_ <= PUBLIC_MAX_MINT,
            "Cannot mint more than MAX_BATCH_MINT per transaction"
        );

        _adminMinted -= quantity_;

        _safeMint(msg.sender, quantity_);
    }

    // -------------------------------------------------------------- SALES STATE-----------------------------
    //VIEW INFORMATION
    function saleState() public view returns (string memory state) {
        if (_saleState == SaleStates.NOT_STARTED) return "NOT_STARTED";
        if (_saleState == SaleStates.WHITELIST_MINT) return "WHITELIST_MINT";
        if (_saleState == SaleStates.SALE) return "SALE";
        if (_saleState == SaleStates.ENDED) return "ENDED";
    }

    //OWNLY OWNER
    function startWhitelistMint() external onlyOwner {
        require(
            _saleState < SaleStates.WHITELIST_MINT,
            "Whitelist mint has already started"
        );
        _saleState = SaleStates.WHITELIST_MINT;
    }

    function startSaleMint() external onlyOwner {
        require(
            _saleState >= SaleStates.WHITELIST_MINT,
            "Must start the whitelist mint before the general public sale"
        );
        require(_saleState < SaleStates.SALE, "Sale mint has already started");
        _saleState = SaleStates.SALE;
    }

    function endMint() external onlyOwner {
        require(_saleState < SaleStates.ENDED, "Must be in sale state to end");
        require(
            uint256(0) == MAX_SUPPLY - totalSupply(),
            "Must be sold out to end"
        );
        _saleState = SaleStates.ENDED;
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

        if (_hidden) {
            return _hiddenURI;
        }
        return string(abi.encodePacked(_baseURI_, tokenId.toString(), ".json"));
    }

    //ONLY OWNER
    function setBaseURI(string memory _uri) public onlyOwner {
        require(
            bytes(_uri)[bytes(_uri).length - 1] == bytes1("/"),
            "Must set trailing slash"
        );
        _baseURI_ = _uri;
    }

    function setHiddenURI(string memory _uri) public onlyOwner {
        _hiddenURI = _uri;
    }

    //ONLY OWNER
    function reveal() public onlyOwner {
        _hidden = false;
    }

    function hide() public onlyOwner {
        _hidden = true;
    }

    //-----------------------------------------------WHITELIST-----------------------------------------
    function checkDemonMinted() public view returns (uint8 minted) {
        return demonStore[msg.sender];
    }

    function checkDevilMinted() public view returns (uint8 minted) {
        return devilStore[msg.sender];
    }

    //ONLY OWNER
    function setDevilRoot(bytes32 _merkleRoot) public onlyOwner {
        devilRoot = _merkleRoot;
    }

    function setDemonRoot(bytes32 _merkleRoot) public onlyOwner {
        demonRoot = _merkleRoot;
    }

    //----------------------------------------------------WITHDRAW
    //ONLY OWNER
    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}
