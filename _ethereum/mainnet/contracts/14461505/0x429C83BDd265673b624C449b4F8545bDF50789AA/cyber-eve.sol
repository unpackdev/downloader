//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract CyberEve is ERC721Enumerable, Ownable {
    using ECDSA for bytes32;
    
    // Max Supply
    uint256 constant MAX_SUPPLY = 4096;

    // Max Supply for presale
    uint256 constant MAX_SUPPLY_PRESALE = 3000;

    // Max allocaiton per wallet
    uint256 constant WALLET_MAX = 10;

    // Max presale allocation per wallet 
    uint constant PRESALE_MAX = 2;

    // The base link that leads to the image / video of the token
    string public baseTokenURI = "https://mint.cybereve.io/nft/";

    // Signer address
    address private signerAddress = 0xE904d85B6B92f0556c0Ac05bAf094Dcd51a889CA;

    // Pass signer address
    address private passSignerAddress = 0xFE42841957CD2A0a474246799dd84ab5101E7B76;

    // Starting and stopping sale
    bool public saleActive = false;
    
    // Starting and stopping presale
    bool public presaleActive = false;

    // Price of each token
    uint256 public price = 0.07 ether;

    // Price of each token
    uint256 public presalePrice = 0.05 ether;

    // NFTs per wallet record
    mapping(address => uint256) public walletMinted;
    mapping(address => bool) public freeMinted;
    mapping(address => uint256) public presaleMinted;

    // Used hashes
    mapping(bytes32 => bool) private usedHash;

    constructor () ERC721 ("Cyber-Eve", "CYBER-EVE") {}

    // Mint an NFT
    function mint(uint256 _amount) public payable {
        require(saleActive, "sale_is_closed");
        
        require(walletMinted[msg.sender] + _amount <= WALLET_MAX , "exceeded_max_per_wallet");
        require(totalSupply() + _amount <= MAX_SUPPLY, "out_of_stock");
        require(msg.value >= price * _amount, "insufficient_eth");

        for(uint256 i; i < _amount; i++){
            walletMinted[msg.sender]++;
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    // Presale mint
    function mintPresale(bytes32 _hash, bytes memory _signature, string memory _nonce, uint256 _amount) public payable {
        require(!saleActive && presaleActive, "presale_is_closed");

        require(addressSignerValid(_hash, _signature, signerAddress), "unverified_mint");
        require(!usedHash[_hash], "hash_already_used");
        require(hashTransaction(msg.sender, _nonce, _amount) == _hash, "hash_mismatched");

        require(totalSupply() + _amount <= MAX_SUPPLY_PRESALE, "presale_out_of_stock");
        require(presaleMinted[msg.sender] + _amount <= PRESALE_MAX, "exceeded_max_per_wallet");

        require(msg.value >= presalePrice * _amount, "insufficient_eth");

        for (uint256 i = 0; i < _amount; i++) {
            walletMinted[msg.sender]++;
            presaleMinted[msg.sender]++;
            _safeMint(msg.sender, totalSupply() + 1);
        }

        usedHash[_hash] = true;
    }

    // Free mint
    function mintFree(bytes32 _hash, bytes memory _signature, string memory _nonce) public {
        require(saleActive || presaleActive, "presale_is_closed");

        require(addressSignerValid(_hash, _signature, passSignerAddress), "unverified_mint");
        require(!usedHash[_hash], "hash_already_used");
        require(hashTransaction(msg.sender, _nonce, 1) == _hash, "hash_mismatched");

        require(totalSupply() + 1 <= MAX_SUPPLY, "out_of_stock");
        require(!freeMinted[msg.sender], "eve_pass_already_claimed");

        walletMinted[msg.sender]++;
        freeMinted[msg.sender] = true;
        _safeMint(msg.sender, totalSupply() + 1);

        usedHash[_hash] = true;
    }

    // airdrop tokens to address for free
    function airdrop(address _to, uint256 _amount) public onlyOwner {
        require(totalSupply() + _amount <= MAX_SUPPLY, "out_of_stock");

        for (uint256 i = 0; i < _amount; i++) {
            _safeMint(_to, totalSupply() + 1);
        }
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

    // State Management //

    // Start and stop sale
    function setSaleActive(bool _state) external onlyOwner {
        saleActive = _state;
    }

    // Start and stop presale
    function setPresaleActive(bool _state) external onlyOwner {
        presaleActive = _state;
    }

    // Set new baseURI
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    // Set a different price in case ETH changes drastically
    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    // Set a different price in case ETH changes drastically
    function setPresalePrice(uint256 _newPrice) public onlyOwner {
        presalePrice = _newPrice;
    }

    // Set signer address
    function setSignerAddress(address _address) public onlyOwner {
        signerAddress = _address;
    }

    // Set pass signer address
    function setPassSignerAddress(address _address) public onlyOwner {
        passSignerAddress = _address;
    }

    // Withdraw funds from contracts for the team
    function withdrawTeam() external payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // Create a keccak256 hash from the sender, amount and nonce
    function hashTransaction(address sender, string memory nonce, uint256 amount) private pure returns(bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(sender, nonce, amount)))
        );

        return hash;
    }

    // Validate that the address that signed the hashed message with the signature is correct
    function addressSignerValid(bytes32 hash, bytes memory signature, address _signer) private pure returns(bool) {
        return _signer == hash.recover(signature);
    }

    // Override so the openzeppelin tokenURI() method will use this method to create the full tokenURI instead
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
}
