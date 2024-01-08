// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract CryptoVikings is ERC721Enumerable, Ownable {  
    using ECDSA for bytes32;
    
    // Starting and stopping sale
    bool public saleActive = false;

    // Price of each token
    uint256 public price = 0.018 ether;

    // Maximum limit of tokens that can ever exist
    uint256 constant MAX_SUPPLY = 1708;
    uint256 constant FREE = 708;

    // The base link that leads to the image / video of the token
    string public baseTokenURI = "https://cryptovikings.xyz/nft/";

    // Team addresses for withdrawals
    address public teamAddress = 0x49dd764b0b4500ECa638321035D8770b18490fcA;
    address private signerAddress = 0x25240c690abaeC8bDa140b4399cA9874054F7cD9;

    // List of addresses that have a number of reserved tokens for presale
    uint256 public freeGiven;
    mapping(address => uint256) public freePerWallet;
    mapping(bytes32 => bool) private usedHash;

    constructor () ERC721 ("Crypto Vikings", "CVI") {}

    // Override so the openzeppelin tokenURI() method will use this method to create the full tokenURI instead
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // See which address owns which tokens
    function tokensOfOwner(address addr) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(addr);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(addr, i);
        }
        return tokensId;
    }

    // Create a keccak256 hash from the sender, amout and nonce
    function hashTransaction(address sender, uint256 amount, string memory nonce) private pure returns(bytes32) {
          bytes32 hash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(sender, amount, nonce)))
          );
          
          return hash;
    }
    
    // Validate that the address that signed the hashed message with the signature is correct
    function addressSignerValid(bytes32 hash, bytes memory signature) private view returns(bool) {
        return signerAddress == hash.recover(signature);
    }

    // Free mint
    function giveMeThatFreeViking(bytes32 hash, bytes memory signature, string memory nonce, uint256 amount) public {
        require(saleActive, "sale_is_closed");

        require(addressSignerValid(hash, signature), "unverified_mint");
        require(!usedHash[hash], "hash_already_used");
        require(hashTransaction(msg.sender, amount, nonce) == hash, "hash_mismatched");

        require(amount <= 3, "free_allocated_exceeded" );
        require(totalSupply() + amount <= MAX_SUPPLY, "out_of_stock");
        require(freePerWallet[msg.sender] + amount <= 3, "max_free_per_wallet");
        require(freeGiven + amount <= FREE, "no_free_left");
       
        for(uint256 i; i < amount; i++){
            _safeMint(msg.sender,  totalSupply() + 1 );
            freePerWallet[msg.sender] = freePerWallet[msg.sender] + 1;
            freeGiven = freeGiven + 1;
        }   

        usedHash[hash] = true;
    }

    // Standard mint function
    function mint(uint256 amount) public payable {
        require(saleActive, "sale_is_closed");
        
        require(amount <= 20, "exceeded_max_mint_amount");
        require(totalSupply() + amount <= MAX_SUPPLY, "out_of_stock");
        require(msg.value == price * amount, "insufficient_eth");

        for(uint256 i; i < amount; i++){
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    // Start and stop sale
    function flipSaleState() public onlyOwner {
        saleActive = !saleActive;
    }

    // Set new baseURI
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    // Set a different price in case ETH changes drastically
    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    // Set team addresses
    function setAddresses(address _address) public onlyOwner {
        teamAddress = _address;
    }

    // Set signer addresses
    function setSignerAddresses(address newSignerAddress) external onlyOwner {
        signerAddress = newSignerAddress;
    }

    // Withdraw funds from contract for the team
    function withdrawTeam() external payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}