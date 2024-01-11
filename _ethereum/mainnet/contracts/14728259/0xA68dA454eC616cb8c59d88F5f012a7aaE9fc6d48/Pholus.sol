// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

//@author Gaetan Dumont
//@title Pholus NFT collection

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./PaymentSplitter.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract Pholus is Ownable, ERC721A {

    using Strings for uint;

    // IPFS URI for the NFTs
    string public baseURI;
    string public hiddenURI;

    // Max suply and ammount of mint availaible per step/wallet
    uint private constant MAX_SUPPLY = 252;
    uint private MAX_VIP_MINT = 2;
    uint private MAX_WL_MINT = 2;
    uint private MAX_MINT = 1;

    // All the prices for each step
    uint public vipPrice = 0.01 ether;
    uint public wlPrice = 0.17 ether;
    uint public publicPrice = 0.2 ether;

    // Array of VIPs
    mapping(address => bool) public VIPlist;
    // Uniq id to check while minting if a user is on the whitelist
    bytes32 public wlMerkleRoot;

    // Timestamp for the start of the VIP sale step
    uint public saleStartTime = 1652119200;

    // Counter of mints per wallet
    mapping(address => uint) public amountNFTsperWallet;
    mapping(address => uint) public amountNFTsPublicperWallet;
    // Map of all the token minted to know when to reveal them
    mapping(uint => uint) public dateNFTMinted;
    
    // Just in case you have to pause the smartcontract it can be done
    bool public paused = false;

    // While deploying the smartcontract while ask for the uniq ids of the vip list and whitelist + the URI of the reveal and unrevealed NFT
    constructor(address[] memory _VIPlist, bytes32 _wlMerkleRoot, string memory _baseURI, string memory _hiddenURI) ERC721A("Pholus", "PHO") {
        for (uint i=0; i < _VIPlist.length; i++) {
            VIPlist[_VIPlist[i]] = true;
        }
        wlMerkleRoot = _wlMerkleRoot;
        baseURI = _baseURI;
        hiddenURI = _hiddenURI;
        // A quick mint of NFT for the owner
        _safeMint(msg.sender, 10);
        for(uint i = 1 ; i <= 10 ; i++) {
            dateNFTMinted[i] = currentTime();
        }
    }

    // Here we pause/unpause the smartcontract
    function setPaused() external onlyOwner {
        paused = !paused;
    }

    // For internal use only
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // Function used to check if the mint user is a person or a smartcontract
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // Here we ask on which step we are for the website to know what to do
    function getStep() public view returns (string memory) {
        uint currentTimestamp = currentTime();
        if (currentTimestamp < saleStartTime) {
            return "waiting";
        }
        else if (currentTimestamp >= saleStartTime && currentTimestamp < saleStartTime + 24 hours) {
            return "vip";
        }
        else if (currentTimestamp >= saleStartTime + 24 hours && currentTimestamp < saleStartTime + 48 hours) {
            return "whitelist";
        }
        else {
            return "public";
        }
    }

    // VIP minting function
    function vipSaleMint(address _account) external payable callerIsUser {
        uint price = vipPrice;
        uint quantity = 1;
        require(price != 0, "Price is 0");
        require(!paused, "The smartcontract is paused");
        require(currentTime() > saleStartTime, "VIP sale has not started yet");
        require(currentTime() < saleStartTime + 24 hours, "VIP sale is finished");
        require(isVIP(msg.sender), "Not a VIP");
        require(amountNFTsperWallet[msg.sender] + quantity <= MAX_VIP_MINT, "You can't get more NFT");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Max supply exceeded");
        require(msg.value >= price * quantity, "Not enought funds");
        amountNFTsperWallet[msg.sender] += quantity;
        uint index = _currentIndex;
        _safeMint(_account, quantity);
        dateNFTMinted[index] = currentTime();
    }

    // Whitelist minting function
    function WhitelistSaleMint(address _account, bytes32[] calldata _proof) external payable callerIsUser {
        uint price = wlPrice;
        uint quantity = 1;
        require(price != 0, "Price is 0");
        require(!paused, "The smartcontract is paused");
        require(currentTime() >= saleStartTime + 24 hours, "Whitelist sale has not started yet");
        require(currentTime() < saleStartTime + 48 hours, "Whitelist sale is finished");
        require(isWhiteListed(msg.sender, _proof), "Not a VIP");
        require(amountNFTsperWallet[msg.sender] + quantity <= MAX_WL_MINT, "You can't get more NFT");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Max supply exceeded");
        require(msg.value >= price * quantity, "Not enought funds");
        amountNFTsperWallet[msg.sender] += quantity;
        uint index = _currentIndex;
        _safeMint(_account, quantity);
        dateNFTMinted[index] = currentTime();
    }

    // Public minting function
    function publicSaleMint(address _account) external payable callerIsUser {
        uint price = publicPrice;
        uint quantity = 1;
        require(price != 0, "Price is 0");
        require(!paused, "The smartcontract is paused");
        require(currentTime() >= saleStartTime + 48 hours, "Public sale has not started yet");
        require(amountNFTsPublicperWallet[msg.sender] + quantity <= MAX_MINT, "You can't get more NFT");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Max supply exceeded");
        require(msg.value >= price * quantity, "Not enought funds");
        amountNFTsPublicperWallet[msg.sender] += quantity;
        amountNFTsperWallet[msg.sender] += quantity;
        uint index = _currentIndex;
        _safeMint(_account, quantity);
        dateNFTMinted[index] = currentTime();
    }

    // Update the VIP mint start time 
    function setSaleStartTime(uint _saleStartTime) external onlyOwner {
        saleStartTime = _saleStartTime;
    }

    // Update the URI of the NFTs on IPFS
    function setBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    // Update the URI of the unrevealed NFT on IPFS
    function setHiddenBaseUri(string memory _hiddenURI) external onlyOwner {
        hiddenURI = _hiddenURI;
    }

    // Internal function to get the time
    function currentTime() public view returns(uint) {
        return block.timestamp;
    }

    // Here we ask the token path in order to get it metadatas and we check of it's revealed or not
    function tokenURI(uint _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        // add if on mint date > 5 days to show the reveal
        if ( (dateNFTMinted[_tokenId] + 5 days) > currentTime() ) {
            return string(abi.encodePacked(hiddenURI, "hidden.json"));
        }
        else {
            return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
        }
    }

    // VIP functions
    function isVIP(address _account) internal view returns(bool) {
        return VIPlist[_account];
    }
    function addToVIP(address _account) external onlyOwner {
        VIPlist[_account] = true;
    }
    function removeFromVIP(address _account) external onlyOwner {
        VIPlist[_account] = false;
    }
    // Whitelist functions
    function setWlMerkleRoot(bytes32 _wlMerkleRoot) external onlyOwner {
        wlMerkleRoot = _wlMerkleRoot;
    }
    function leaf(address _account) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(_account));
    }
    function isWhiteListed(address _account, bytes32[] calldata _proof) internal view returns(bool) {
        return _verifyWl(leaf(_account), _proof);
    }
    function _verifyWl(bytes32 _leaf, bytes32[] memory _proof) internal view returns(bool) {
        return MerkleProof.verify(_proof, wlMerkleRoot, _leaf);
    }

    // Here the owner of the smartcontract whil get back the ETH users paid to mint
    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

}