// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// @author Ben BK https://twitter.com/BenBKTech

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Address.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract ArtERC721A is Ownable, ERC721A {
    //To concatenate the URL of an NFT
    using Strings for uint;
 
    //Amount of NFTs per Wallet for presale and whitelist sale Mint
    uint private constant MAX_PER_ADDRESS_GOLDLIST = 2;
    uint private constant MAX_PER_ADDRESS_WHITELIST = 2;
    uint private constant MAX_PER_ADDRESS_PUBLIC = 300;

    //The amount for the gold list sale
    uint private constant MAX_GOLDLIST = 500;
    //The amount released on whitelist sale
    uint private constant MAX_WHITELIST = 2000;
    //The total number of NFTs //10000
    uint private constant MAX_SUPPLY = 10000;

    //Amount of tokens reserved for gift
    uint private giftReserved = 90;

    //Is the mint enabled ?
    bool public mintEnabled = true;

    //The price for the goldlist sale, whitelist sale & public sale
    uint public goldSalePrice = 0.26 ether;
    uint public whiteSalePrice = 0.28 ether;
    uint public publicSalePrice = 0.3 ether;

    //When the sale starts
    uint public saleStartTime;

    //The Merkle Roots
    bytes32 public goldlistRoot;
    bytes32 public whitelistRoot;

    //base URI of the NFTs
    string public baseURI;

    //Address recipient of the payments
    address payable public recipient;

    //Number of NFTs/Wallet gold list & whitelist & public sale
    mapping(address => uint) public mintedGoldlist;
    mapping(address => uint) public mintedWhitelist;
    mapping(address => uint) public mintedPublicSale;

    //Let's save the forests!
    constructor(
        address payable _recipient,
        uint _saleStartTime,
        bytes32 _goldlistRoot,
        bytes32 _whitelistRoot, 
        string memory _baseURI) 
    ERC721A("Anim4rt", "A4RT") {
        recipient = _recipient;
        saleStartTime = _saleStartTime;
        goldlistRoot = _goldlistRoot;
        whitelistRoot = _whitelistRoot;
        baseURI = _baseURI;
    }

    /**
    * @notice Mint functions cannot be called by other contracts
    **/
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /**
    * @notice Mint functions cannot run if contract is paused
    **/
    modifier mintIsEnabled() {
        require(mintEnabled, "Mint is not enabled");
        _;
    }

    /**
    * @notice Mint function for the Goldlist Sale
    *
    * @param _account Account which will receive the NFT
    * @param _quantity Amount of NFTs the user wants to mint
    * @param _proof The Merkle Proof (goldlist)
    **/
    function goldlistMint(address _account, uint _quantity, bytes32[] calldata _proof) external payable mintIsEnabled callerIsUser {
        require(_verify(goldlistRoot, leaf(msg.sender), _proof), "Not goldlisted");
        require(currentTime() >= saleStartTime, "Goldlist sale has not started yet");
        require(currentTime() < saleStartTime + 24 hours, "Goldlist sale is finished");

        uint256 price = goldSalePrice;
        require(price > 0, "Goldlist sale not ready");
        require(msg.value >= price * _quantity, "Not enought funds");

        uint256 accountMinted = mintedGoldlist[msg.sender];
        require(accountMinted == 0, "Goldlist mint already spent");
        require(accountMinted + _quantity <= MAX_PER_ADDRESS_GOLDLIST, 
        "Max mints per wallet of Goldlist sale reached");
        require(totalSupply() + _quantity <= MAX_GOLDLIST, "Max supply exceeded");
        
        mintedGoldlist[msg.sender] = accountMinted + _quantity;
        _safeMint(_account, _quantity);
        Address.sendValue(recipient, msg.value);
    }

    /**
    * @notice Mint function for the Whitelist Sale
    *
    * @param _account Account which will receive the NFT
    * @param _quantity Amount of NFTs the user wants to mint
    * @param _proof The Merkle Proof (whitelist)
    **/
    function whitelistMint(address _account, uint _quantity, bytes32[] calldata _proof) external payable mintIsEnabled callerIsUser {
        require(_verify(whitelistRoot, leaf(msg.sender), _proof), "Not whitelisted");
        require(currentTime() >= saleStartTime + 96 hours, "Whitelist sale has not started yet");
        require(currentTime() < saleStartTime + 120 hours, "Whitelist sale is finished");
        
        uint256 price = whiteSalePrice;
        require(price > 0, "Whitelist sale not ready");
        require(msg.value >= price * _quantity, "Not enough funds");

        uint256 accountMinted = mintedWhitelist[msg.sender];
        require(accountMinted + _quantity <= MAX_PER_ADDRESS_WHITELIST, 
        "Max mints per wallet of Whitelist sale reached");
        require(totalSupply() + _quantity <= MAX_WHITELIST, "Max supply exceeded");

        mintedWhitelist[msg.sender] = accountMinted + _quantity;
        _safeMint(_account, _quantity);
        Address.sendValue(recipient, msg.value);
    }

    /**
    * @notice Mint function for the Public Sale
    *
    * @param _account Account which will receive the NFT
    * @param _quantity Amount of NFTs the user wants to mint
    **/
    function publicSaleMint(address _account, uint _quantity) external payable mintIsEnabled callerIsUser {
        require(currentTime() >= saleStartTime + 168 hours, "Public sale has not started yet");
        
        uint256 price = publicSalePrice;
        require(price > 0, "Public sale not ready");
        require(msg.value >= publicSalePrice * _quantity, "Not enought funds");

        uint256 accountMinted = mintedWhitelist[msg.sender];
        require(accountMinted + _quantity <= MAX_PER_ADDRESS_PUBLIC, 
        "Max mints per wallet of Public sale reached");
        require(totalSupply() + giftReserved + _quantity <= MAX_SUPPLY, "Max supply exceeded");

        mintedPublicSale[msg.sender] = accountMinted + _quantity;
        _safeMint(_account, _quantity);
        Address.sendValue(recipient, msg.value);
    }

    /**
    * @notice Allows the owner to gift NFTs
    *
    * @param _to The address of the receiver
    * @param _quantity Amount of NFTs the owner wants to gift
    **/
    function gift(address _to, uint _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Reached max supply");
        if(_quantity < giftReserved) {
            giftReserved -= _quantity;
        } else {
            giftReserved = 0;
        }
        _safeMint(_to, _quantity);
    }

    /**
    * @notice Allows to set the goldlist sale price
    */
    function setGoldSalePrice(uint price) external onlyOwner {
        goldSalePrice = price;
    }

    /**
    * @notice Allows to set the whitelist sale price
    */
    function setWhiteSalePrice(uint price) external onlyOwner {
        whiteSalePrice = price;
    }

    /**
    * @notice Allows to set the public sale price
    */
    function setPublicSalePrice(uint price) external onlyOwner {
        publicSalePrice = price;
    }
    
    /**
    * @notice Change the starting time (timestamp) of the Presale (dutch auction)
    *
    * @param _saleStartTime The starting timestamp of the Presale (dutch auction)
    **/
    function setSaleStartTime(uint _saleStartTime) external onlyOwner {
        saleStartTime = _saleStartTime;
    }

    /**
    * @notice Get the current timestamp
    *
    * @return the current timestamp
    **/
    function currentTime() internal view returns(uint) {
        return block.timestamp;
    }

    /**
    * @notice Get the token URI of an NFT by his ID
    *
    * @param _tokenId The ID of the NFT you want to have the URI
    **/
    function tokenURI(uint _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    /**
    * @notice Pause or unpause the smart contract
    *
    * @param status true or false if we want to able or disable the mint
    **/
    function enableMint(bool status) external onlyOwner {
        mintEnabled = status;
    }

    /**
    * @notice Change the base URI of the NFTs
    *
    * @param _baseURI The new base URI of the NFTs
    **/
    function setBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }
 
    /**
    * @notice Change the Merkle Root of the goldlist
    *
    * @param _root The new Merkle Root
    **/
    function setGoldlistRoot(bytes32 _root) external onlyOwner {
        goldlistRoot = _root;
    }

    /**
    * @notice Change the Merkle Root of the whitelist
    *
    * @param _root The new Merkle Root
    **/
    function setWhitelistRoot(bytes32 _root) external onlyOwner {
        whitelistRoot = _root;
    }

    /**
    * @notice Hash an address
    *
    * @param _account The address to be hashed
    * 
    * @return bytes32 The hashed address
    **/
    function leaf(address _account) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    /** 
    * @notice Returns true if a leaf can be proved to be a part of a Merkle tree defined by root (Goldlist)
    *
    * @param root The merkle root
    * @param _leaf The leaf
    * @param _proof The Merkle Proof
    *
    * @return True if a leaf can be provded to be a part of a Merkle tree defined by root
    **/
    function _verify(bytes32 root, bytes32 _leaf, bytes32[] memory _proof) internal pure returns(bool) {
        return MerkleProof.verify(_proof, root, _leaf);
    }

    /**
    * Not allowing receiving ether outside minting functions
    */
    receive() external payable {
        revert('Only if you mint');
    }
}
