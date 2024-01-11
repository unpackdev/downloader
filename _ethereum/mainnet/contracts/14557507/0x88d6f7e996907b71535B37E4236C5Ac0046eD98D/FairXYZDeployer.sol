// SPDX-License-Identifier: MIT
// @ Fair.xyz dev

pragma solidity ^0.8.7;

import "ERC721xyz.sol";
import "Pausable.sol";
import "ECDSA.sol";

contract FairXYZDeployer is ERC721xyz, Pausable{
    
    string private _name;
    string private _symbol;

    using ECDSA for bytes32;
    
    uint256 internal maxTokens;
    
    uint256 internal nftPrice;

    string private baseURI;
    bool public lockURI; 

    bool public isBase;
    bool public isInitialized;
    address public owner;
    bool public burnable;
    uint256 public maxMintsPerWallet;

    address public interfaceAddress;

    mapping(bytes32 => bool) private usedHashes;

    mapping(address => uint256) public mintsPerWallet;

    event OwnershipTransferred(address indexed prevOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "ERROR");
        _;
    }

    constructor() payable ERC721xyz(_name, _symbol){
        isBase = true;
        _name = "FairXYZ";
        _symbol = "FairXYZ";
        _pause();
    }

    // Collection Name
    function name() override public view returns (string memory) {
        return _name;
    }

    // Collection ticker
    function symbol() override public view returns (string memory) {
        return _symbol;
    }

    // Signer address for minting
    function viewSigner() public view returns(address){
        address returnSigner = IFairXYZWallets(interfaceAddress).viewSigner(); 
        return(returnSigner);
    }

    // Fair.xyz wallet address
    function viewWithdraw() public view returns(address){
        address returnWithdraw = IFairXYZWallets(interfaceAddress).viewWithdraw(); 
        return(returnWithdraw);
    }

    // Initialize Creator contract
    function initialize(address contractOwner, uint256 maxTokens_, uint256 nftPrice_, string memory name_, string memory symbol_,
                        bool burnable_, uint256 maxMintsPerWallet_, address interfaceAddress_) external {
        
        require( isBase == false , "This contract is not a base contract!");
        require( owner == address(0), "This is an owned contract" );
        require( isInitialized == false, "Contract already initialized");
        owner = contractOwner;
        maxTokens = maxTokens_;
        nftPrice = nftPrice_;
        _name = name_;
        _symbol = symbol_;
        burnable = burnable_; 
        maxMintsPerWallet = maxMintsPerWallet_;
        interfaceAddress = interfaceAddress_;
        isInitialized = true;
    }

    // Limit on NFT sale
    modifier saleIsOpen{
        require(viewMinted() < maxTokens, "Sale end");
        _;
    }

    // Lock metadata forever
    function lockURIforever() external onlyOwner {
        lockURI = true;
    }

    // Modify sale price
    function changeNFTprice(uint256 newPrice) public onlyOwner returns(uint256)
    {
        nftPrice = newPrice;
        return(nftPrice);
    }
    
    // View price
    function price() public view returns (uint256) {
        return nftPrice; 
    }
    
    // modify the base URI 
    function changeBaseURI(string memory newBaseURI)
        onlyOwner
        public
    {   
        require(!lockURI, "URI change has been locked");
        baseURI = newBaseURI;
    }
    
    // return Base URI
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // See remaining mints
    function remainingMints(address minterAddress) public view returns(uint256) {
        
        if (maxMintsPerWallet == 0 ) {
            revert("Collection with no mint limit");
        }
            
        uint256 mintsLeft = maxMintsPerWallet - mintsPerWallet[minterAddress];

        if (mintsLeft <= 0) {
            return 0;
        }
        return mintsLeft; 
    }
    
    // pause minting 
    function pause() public onlyOwner {
        _pause();
    }
    
    // unpause minting 
    function unpause() public onlyOwner {
        _unpause();
    }

    // Burn token
    function burn(uint256 tokenId) public returns(uint256)
    {
        require(burnable, "This contract does not allow burning");
        require(msg.sender == ownerOf(tokenId), "Burner is not the owner of token");
        _burn(tokenId);
        return tokenId;
    }

    // Airdrop a token
    function airdrop(address[] memory address_, uint256 tokenCount) onlyOwner public returns(uint256) 
    {
        require(viewMinted() + address_.length * tokenCount <= maxTokens, "This exceeds the maximum number of NFTs on sale!");
        for(uint256 i = 0; i < address_.length; ) {
            _mint(address_[i], tokenCount);
            unchecked{
                ++i;    
            }
        }
        return viewMinted();
    }

    function hashTransaction(address sender, uint256 qty, uint256 nonce, address address_) private pure returns(bytes32) {
          bytes32 hash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(sender, qty, nonce, address_)))
          );    
          return hash;
    }

    // Change the maximum number of mints per wallet
    function changeMaxMints(uint256 newMax) onlyOwner public returns(uint256)
    {
        maxMintsPerWallet = newMax;
        return(maxMintsPerWallet);
    }
    
    // View block number
    function viewBlockNumber() public view returns(uint256){
        return(block.number);
    }

    // Mint a token    
    function mint(bytes memory signature, uint256 nonce, uint256 numberOfTokens)
        payable
        public
        whenNotPaused
        saleIsOpen
        returns (uint256)
    {
        bytes32 messageHash = hashTransaction(msg.sender, numberOfTokens, nonce, address(this));
        address signAdd = IFairXYZWallets(interfaceAddress).viewSigner();
        require(messageHash.recover(signature) == signAdd, "Unrecognizable Hash");
        require(!usedHashes[messageHash], "Reused Hash");
        require(msg.value  >= nftPrice * numberOfTokens, "You have not sent the required amount of ETH");
        require(numberOfTokens <= 20, "Token minting limit per transaction exceeded");
        require(block.number <= nonce  + 20, "Time limit has passed");

        if(maxMintsPerWallet > 0)
            require(mintsPerWallet[msg.sender] + numberOfTokens <= maxMintsPerWallet, "Exceeds number of mints per wallet");

        // If trying to mint more tokens than available -> reimburse for excess mints and allow for lower mint count
        // to avoid a failed tx 
        if(viewMinted() + numberOfTokens > maxTokens)
        {
            payable(msg.sender).transfer( ( numberOfTokens - (maxTokens - viewMinted() ) ) * nftPrice );
            numberOfTokens = maxTokens - viewMinted();
        }

        _mint(msg.sender, numberOfTokens);

        usedHashes[messageHash] = true;

        if(maxMintsPerWallet > 0)
            mintsPerWallet[msg.sender] += numberOfTokens;
        
        return viewMinted();
    }
    
    // transfer ownership of the smart contract
    function transferOwnership(address newOwner) onlyOwner public returns(address)
    {
        require(newOwner != address(0), "Cannot set zero address as owner!");
        owner = newOwner;
        emit OwnershipTransferred(msg.sender, newOwner);
        return(owner);
    }

    // renounce ownership of the smart contract
    function renounceOwnership() onlyOwner public returns(address)
    {
        owner = address(0);
        emit OwnershipTransferred(msg.sender, address(0));
        return(owner);
    }

    // only owner - withdraw contract balance to wallet. 6% primary sale fee to Fair.xyz
    function withdraw()
        public
        payable
        onlyOwner
    {
        uint256 contractBalance = address(this).balance;
        payable(IFairXYZWallets(interfaceAddress).viewWithdraw()).transfer(contractBalance*3/50);
        payable(msg.sender).transfer(contractBalance*47/50);
    }


}