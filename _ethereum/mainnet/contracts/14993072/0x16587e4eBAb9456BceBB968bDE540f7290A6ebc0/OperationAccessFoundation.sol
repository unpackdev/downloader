// SPDX-License-Identifier: MIT

/*
@@@@@@@@@@@@@@@@@@@@@@@@                                 @@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@                                 @@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@                                 @@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@                                                                   @@@@@@
@@@@@@@                                                                   @@@@@@
@@@@@@@     @@@@@@@@@@@@@@                              @@@@@@@@@@@@@     @@@@@@
@@@@@@@     @@@@@@@@@@@@@@@@                         @@@@@@@@@@@@@@@@     @@@@@@
@@@@@@@     @@@@@@@@@@@@@@@@@@@                    @@@@@@@@@@@@@@@@@@     @@@@@@
@@@@@@@     @@@@@@@@@@@@@@@@@@@@@               @@@@@@@@@@@@@@@@@@@@@     @@@@@@
@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@#          @@@@@@@@@@@@@@@@@@@@@@@     @@@@@@
             *@@@@@@@@@@@@@@@@@@@@@@@@     /@@@@@@@@@@@@@@@@@@@@@@@@            
                @@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@               
                   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&                 
                     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                    
                        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(                      
                          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@                         
                            @@@@@@@@@@@@@@@@@@@@@@@@@                           
                          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@,                        
                       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                      
                     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(                   
                  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                 
                @@@@@@@@@@@@@@@@@@@@@@@@ %@@@@@@@@@@@@@@@@@@@@@@@#              
             @@@@@@@@@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@@@@@@            
@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@           @@@@@@@@@@@@@@@@@@@@@@@     @@@@@@
@@@@@@@     @@@@@@@@@@@@@@@@@@@@@                @@@@@@@@@@@@@@@@@@@@     @@@@@@
@@@@@@@     @@@@@@@@@@@@@@@@@@                     @@@@@@@@@@@@@@@@@@     @@@@@@
@@@@@@@     @@@@@@@@@@@@@@@@                         @@@@@@@@@@@@@@@@     @@@@@@
@@@@@@@     @@@@@@@@@@@@@,                              @@@@@@@@@@@@@     @@@@@@
@@@@@@@                                                                   @@@@@@
@@@@@@@                                                                   @@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@                                 @@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@                                 @@@@@@@@@@@@@@@@@@@@@@@
*/

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";

contract OperationAccessFoundation is ERC721A, Ownable {
    uint256 public maxSupply = 11; 
    uint256 public price = 1 ether;
    uint256 public maxQtyPerWalletAddressPreSale = 100;
    uint256 public maxQtyPerWalletAddressPublicSale = 100; //max total for public mint
    uint256 public maxQtyPerTransaction; //max per tx public mint   

    bool public _isActive = false;
    bool public _presaleActive = false;

    mapping(address => bool) public allowList;
    mapping(address => uint8) public _preSaleListCounter;
    mapping(address => uint256) public _publicCounter;    

    // merkle root
    bytes32 public preSaleRoot;

    // metadata URI
    string private _baseTokenURI;

    constructor(       
        uint256 _amountForTeam,
        uint256 _maxQtyPerTransaction
    )
        ERC721A("Operation Access Foundation", "OAF", _amountForTeam, _maxQtyPerTransaction)        
    {
        maxQtyPerTransaction = _maxQtyPerTransaction;        
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    //set variables
    function setPublicActive(bool isActive) external onlyOwner {
        _isActive = isActive;
    }

    function setPresaleActive(bool isActive) external onlyOwner {
        _presaleActive = isActive;
    }

    function setMaxSupply(uint256 _newmaxSupply) public onlyOwner {
        maxSupply = _newmaxSupply;
    }

    function setNewPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setMaxQtyPerWalletAddressPreSale(uint256 _maxQtyPerWalletAddressPreSale) external onlyOwner {
        maxQtyPerWalletAddressPreSale = _maxQtyPerWalletAddressPreSale;
    }

    function setMaxQtyPerWalletAddressPublicSale(uint256 maxMints_) public onlyOwner {
        maxQtyPerWalletAddressPublicSale = maxMints_;
    }

    function setPreSaleRoot(bytes32 _root) external onlyOwner {
        preSaleRoot = _root;
    }        

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    //withdraw to owner wallet
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // Presale
    function mintPreSaleTokens(uint8 quantity, bytes32[] calldata _merkleProof)
        external
        payable
        callerIsUser        
    {
        require(_presaleActive, "Whitelist mint is not active yet");
        require(_preSaleListCounter[msg.sender] + quantity <= maxQtyPerWalletAddressPreSale, "Exceeded max available to purchase at a time");
        require(quantity > 0, "Must mint more than 0 tokens");
        require(totalSupply() + quantity <= maxSupply, "No more NFTs left");
        require(price * quantity >= msg.value, "Incorrect funds");
        // check proof & mint
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, preSaleRoot, leaf) || allowList[msg.sender], "Invalid MerkleProof");

        _safeMint(msg.sender, quantity);
        _preSaleListCounter[msg.sender] = _preSaleListCounter[msg.sender] + quantity;
    }        

    // public mint
    function publicSaleMint(uint256 quantity)
        external
        payable        
        callerIsUser
    {
        require(quantity > 0, "Must mint more than 0 tokens at a time");
        require(_isActive, "Public mint has not begun yet");
        require(price * quantity >= msg.value, "Incorrect funds");
        require(quantity <= maxQtyPerTransaction, "Exceeds max per transaction");
        require(_publicCounter[msg.sender] + quantity <= maxQtyPerWalletAddressPublicSale, "Exceeds max per address");
        require(totalSupply() + quantity <= maxSupply, "No more NFTs left");

        _safeMint(msg.sender, quantity);
        _publicCounter[msg.sender] = _publicCounter[msg.sender] + quantity;
    }

    // owner mint
    function ownerMint(uint256 quantity) external payable callerIsUser onlyOwner
    {        
        require(totalSupply() + quantity <= maxSupply, "No more NFTs left");

        _safeMint(msg.sender, quantity);
        _publicCounter[msg.sender] = _publicCounter[msg.sender] + quantity;
    }
}