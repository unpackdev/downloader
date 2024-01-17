// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9 <0.9.0;

import "./ERC721F.sol";
import "./AllowList.sol";
import "./ERC721Payable.sol";
import "./MerkleProof.sol";

/**
 * @title RDRPunks contract
 * @dev Extends ERC721F Non-Fungible Token Standard basic implementation.
 * Optimized to no longer use ERC721Enumarable , but still provide a totalSupply() implementation.
 * @author @FrankNFT.eth
 * 
 */

contract Genkei is ERC721F, ERC721Payable, AllowList{
    
    uint256 public tokenPrice = 0.032 ether; 
    uint256 public tokenPreSalePrice = 0.022 ether; 
    uint256 public constant MAX_TOKENS = 4747;
    uint256 public constant MAX_PUBLIC = 4700;
    
    uint public constant MAX_PURCHASE = 4; // set 1 to high to avoid some gas
    uint public constant MAX_PURCHASE_PUBLIC = 6; // set 1 to high to avoid some gas
    uint public constant MAX_RESERVE = 201; // set 1 to high to avoid some gas
    
    bool public saleIsActive;
    bool public preSaleIsActive;
    bool public unionIsActive;

    bytes32 public root;

    address private constant FRANK = 0xF40Fd88ac59A206D009A07F8c09828a01e2ACC0d;
    address private constant WALLET1 = 0x5292102537aA1A276869B30Ca41c9997fEA89299;
    address private constant WALLET2 = 0x5674b4F3F41C72ac724DCb84189FAd3E753C3efA;

    mapping(address => uint256) private balances;
    mapping(address => uint256) private balancesPreSale;
    mapping(address => bool) private unionMinted;

    event PriceChange(address _by, uint256 price);
    
    constructor() ERC721F("Genkei", "Gen") {
        setBaseTokenURI("ipfs://QmRSQo4QtifxFJctFaCN94NUsKRfHLYp3XEKWy5sSDWwZW/"); 
        _mint(FRANK, 0);
    }

    /**
     * Mint Tokens to a wallet.
     */
    function mint(address to,uint numberOfTokens) public onlyOwner {    
        uint supply = totalSupply();
        require(supply + numberOfTokens <= MAX_TOKENS, "Reserve would exceed max supply of Tokens");
        require(numberOfTokens < MAX_RESERVE, "Can only mint 200 tokens at a time");
        for (uint i = 0; i < numberOfTokens;) {
            _safeMint(to, supply + i);
            unchecked{ i++;}           
        }
    }
     /**
     * Mint Tokens to the owners reserve.
     * 
     */   
    function reserveTokens() external onlyOwner {    
        mint(owner(),MAX_RESERVE-1);
    }

    /**
     * @notice Assigns `_root` to `root`, this changes the whitelisted accounts that have access to mintPreSale
     * @param _root Calculated roothash of merkle tree
     * @dev A new roothash can be calculated using the `scripts\merkle_tree.js` file
     */
    function setRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    /**
     * Changes the state of preSaleIsactive from true to false and false to true
     */
    function flipPreSaleState() external onlyOwner {
        preSaleIsActive = !preSaleIsActive;
        if (preSaleIsActive) {
            unionIsActive = false;
            saleIsActive = false;           
        }
    }

    /**
     * Changes the state of saleIsActive from true to false and false to true
     * @dev If saleIsActive becomes `true` sets preSaleIsActive to `false`
     */
    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
        if (saleIsActive) {
            preSaleIsActive = false;
            unionIsActive = false;
        }
    }

    /**
     * Changes the state of UnionIsActive from true to false and false to true
     * @dev If saleIsActive becomes `true` sets preSaleIsActive to `false`
     */
    function flipUnionSaleState() external onlyOwner {
        unionIsActive = !unionIsActive;
        if (unionIsActive) {
            preSaleIsActive = false;
            saleIsActive = false;           
        }
    }

    /**     
    * Set price 
    */
    function setPrice(uint256 price) external onlyOwner {
        tokenPrice = price;
        emit PriceChange(msg.sender, tokenPrice);
    }

    /**
     * Mint your tokens here.
     */
    function mint(uint256 numberOfTokens) external payable{
        require(saleIsActive,"Sale NOT active yet");
        require(numberOfTokens*tokenPrice <= msg.value, "Ether value sent is not correct"); 
        require(numberOfTokens != 0, "numberOfNfts cannot be 0");
        require (balances[msg.sender]+numberOfTokens < MAX_PURCHASE_PUBLIC ,"You already made 5 tokens.");
        uint256 supply = totalSupply();
        require(supply + numberOfTokens <= MAX_PUBLIC, "Purchase would exceed max supply of Tokens");
        balances[msg.sender] = balances[msg.sender]+numberOfTokens; 
        for(uint256 i; i < numberOfTokens;){
            _safeMint( msg.sender, supply + i );
            unchecked{ i++;}
        }
    }

        /**
     * @notice Mints a certain number of tokens
     * @param numberOfTokens Total tokens to be minted, must be larger than 0 and at most 30
     * @param merkleProof Proof that an address is part of the whitelisted pre-sale addresses
     * @dev Uses MerkleProof to determine whether an address is allowed to mint during the pre-sale, non-mint name is due to hardhat being unable to handle function overloading
     */
    function mintPreSale(uint256 numberOfTokens, bytes32[] calldata merkleProof)
        external
        payable
    {
        require(preSaleIsActive, "PreSale is not active yet");
        require(numberOfTokens*tokenPreSalePrice <= msg.value, "Ether value sent is not correct"); 
        uint256 supply = _totalMinted();
        require(
            supply + numberOfTokens <= MAX_PUBLIC,
            "Purchase would exceed max supply of Tokens"
        );
        require(checkValidity(merkleProof), "Invalid Merkle Proof");
        require(numberOfTokens != 0, "numberOfNfts cannot be 0");
        require (balancesPreSale[msg.sender]+numberOfTokens < MAX_PURCHASE ,"You already made 3 tokens.");
        balancesPreSale[msg.sender] = balancesPreSale[msg.sender]+numberOfTokens;
        for (uint256 i; i < numberOfTokens; ) {
            _safeMint(msg.sender, supply + i);
            unchecked {
                i++;
            }
        }
    }

    /**
     * Mint your tokens here.
     */
    function freeMint() external onlyAllowList{ 
        require(unionIsActive,"Union Sale NOT active yet");
        require(! unionMinted[msg.sender],"You already minted");
        uint256 supply = totalSupply();
        require(supply + 1 <= MAX_TOKENS, "Purchase would exceed max supply of Tokens");
        unionMinted[msg.sender]=true;
        _safeMint( msg.sender, supply);

    }

    function checkValidity(bytes32[] calldata merkleProof)
        internal
        view
        returns (bool)
    {
        bytes32 leafToCheck = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(merkleProof, root, leafToCheck);
    }
    
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        uint256 payout = balance/20;
        _withdraw(FRANK, payout);  
        _withdraw(WALLET1, payout);  
        _withdraw(WALLET2, payout);  
        _withdraw(owner(), address(this).balance);
    }

    /**
    * exists function for the Royalty splitter
    */
    function exists(uint256 tokenId) public view returns (bool){
        return _exists(tokenId);
    }
}
