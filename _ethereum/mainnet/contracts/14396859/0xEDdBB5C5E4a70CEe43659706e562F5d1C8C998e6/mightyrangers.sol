// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
/***
 *    ______  ________          ______  _____          ________                                                
 *    ___   |/  /___(_)_______ ____  /_ __  /______  _____  __ \______ ________ _______ ______ ________________
 *    __  /|_/ / __  / __  __ `/__  __ \_  __/__  / / /__  /_/ /_  __ `/__  __ \__  __ `/_  _ \__  ___/__  ___/
 *    _  /  / /  _  /  _  /_/ / _  / / // /_  _  /_/ / _  _, _/ / /_/ / _  / / /_  /_/ / /  __/_  /    _(__  ) 
 *    /_/  /_/   /_/   _\__, /  /_/ /_/ \__/  _\__, /  /_/ |_|  \__,_/  /_/ /_/ _\__, /  \___/ /_/     /____/  
 *                     /____/                 /____/                            /____/                         
 */
import "./ERC721Enumerable.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";

contract MightyRangers is ERC721Enumerable, Ownable 
{
    using Strings for string;

    //TOKEN SUPPLY
    uint public MAX_TOKENS = 3333;
    uint public RESERVED = 100;
    uint public MAX_WL_TOKENS = 2000;

    //COLLECTION
    uint256 public PRICE = 0.04 ether; //40000000000000000
    string private _baseTokenURI;
    bool public saleIsActive = false;
    uint public perTransactionLimit = 5;
    uint public perAddressLimit = 10;

    //WHITELIST
    bool public isWhitelistActive = false;
    uint public whitelistSupply;
    bytes32 public mRoot;
    uint public whitelistMintLimit = 5;
    mapping(address => uint) public whitelistNumClaimed;

    constructor() ERC721("MightyRangers", "MGTY") {}

    function mintToken(uint256 amount) external payable
    {
        require(msg.sender == tx.origin, "Minting from Contract not Allowed");
        require(saleIsActive, "Sale is not active to mint");
        require(amount > 0 && amount <= perTransactionLimit, "Max 1-5 NFTs per transaction");
        require(balanceOf(msg.sender) + amount <= perAddressLimit, "Max NFT per address exceeded");
        require(totalSupply() + amount + RESERVED <= MAX_TOKENS, "Purchase would exceed max supply");
        require(msg.value >= PRICE * amount, "Not enough ETH for transaction");

        for (uint i = 0; i < amount; i++) 
        {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    } 

    function mintWhitelistTokens(bytes32[] calldata _proof, uint256 amount, uint256 _max) external payable{
        require(msg.sender == tx.origin, "Minting from Contract not Allowed");
        require(isWhitelistActive, "Whitelist Mint Not Active");
        require(whitelistSupply + amount <= MAX_WL_TOKENS, "Mint Amount Exceeds Total Allowed Mints");
        require(whitelistNumClaimed[msg.sender] + amount <= _max, "Mint Amont Exceeds Total Allowed WL Mints");
        require(whitelistNumClaimed[msg.sender] + amount <= whitelistMintLimit, "Mint Amont Exceeds Total Allowed WL Mints"); 
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_proof,mRoot,leaf), "Invalid proof/root/leaf");
        require(msg.value >= PRICE * amount,  "Incorrect Payment");
        
        whitelistNumClaimed[msg.sender] += amount;
        for (uint i = 0; i < amount; i++) 
        {
            _safeMint(msg.sender, totalSupply() + 1);
            whitelistSupply++;
        }
    }

    function mintReservedTokens(address to, uint256 amount) external onlyOwner 
    {
        require(amount <= RESERVED, "This amount is more than max available");
        for (uint i = 0; i < amount; i++) 
        {
            _safeMint(to, totalSupply() + 1);
            RESERVED--;
        }
    }

    ////
    //Collection management part
    ////
    
    function flipSaleState() external onlyOwner 
    {
        saleIsActive = !saleIsActive;
    }
    
    function flipWhitelistState() external onlyOwner 
    {
        isWhitelistActive = !isWhitelistActive;
    }

    function changePrice(uint256 newPRICE) external onlyOwner 
    {
        PRICE = newPRICE; //50000000000000000 = 0.05 ether
    }

    function changeMaxToken(uint256 newMaxToken) external onlyOwner 
    {
        require(newMaxToken >= totalSupply() + RESERVED, "Current Token Index Over newMaxToken");
        MAX_TOKENS = newMaxToken; 
    }

    function changeMaxReservedToken(uint256 newResToken) external onlyOwner 
    {
        require(newResToken + MAX_WL_TOKENS <= MAX_TOKENS, "Too Much Reserved Tokens!");
        require(totalSupply() + newResToken <= MAX_TOKENS, "Too Much Reserved Tokens!");
        RESERVED = newResToken; 
    }

    function changeMaxWLToken(uint256 newWLToken) external onlyOwner 
    {   require(!saleIsActive, "Sale must be inactive for open mint");
        require(newWLToken + RESERVED <= MAX_TOKENS, "newWLToken value over Collection limit");
        require(newWLToken >= whitelistSupply, "Current Token Index Over whitelistSupply");
        MAX_WL_TOKENS = newWLToken; 
    }

    function changePerTransactionLimit(uint256 newTransactionLimit) external onlyOwner {
        require(newTransactionLimit >= 1, "Transaction Limit below 1");
        perTransactionLimit = newTransactionLimit;
    }
    
    function changePerAddressLimit(uint256 newAddressLimit) external onlyOwner {
        require(newAddressLimit >= 1, "Address Limit below 1");
        perAddressLimit = newAddressLimit;
    }

    function changeWhitelistMintLimit(uint256 newWLLimit) external onlyOwner {
        require(newWLLimit >= 1, "Whitelist Limit below 1");
        whitelistMintLimit = newWLLimit;
    }
    
    function plantNewRoot(bytes32 _root) external onlyOwner {
        require(!isWhitelistActive, "Whitelist Minting Not Disabled");
        mRoot = _root;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    ////
    //URI management part
    ////
    
    function _setBaseURI(string memory baseURI) internal virtual {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
    
    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }
  
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require( _exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        string memory _tokenURI = super.tokenURI(tokenId);
        return bytes(_tokenURI).length > 0 ? string(abi.encodePacked(_tokenURI, ".json")) : "";
    }

    ////
    //Withdraw part
    ////

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = owner().call{value: balance}("");
        require(success, "Withdraw failed");
    }
}