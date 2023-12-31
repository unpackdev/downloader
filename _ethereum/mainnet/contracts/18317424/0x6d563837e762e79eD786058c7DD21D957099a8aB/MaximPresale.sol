// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./IERC721.sol";
import "./ERC721A.sol";

/**
* Maxim Coin Presale contract
* Sale cap per address is 0.01 to 0.05 eth
* Sale can be done multiple times as long as it does not exceed the cap per address
* Presale collection has a Total sales cap of 50 eth
*
* Only whitelisted addresses and Maximals NFT holders can participate in sale
* The list of presale participants should be accessible by Maxim Token claim contract
* 
**/

contract MaximPresaleContract is Ownable, ReentrancyGuard, Pausable {

    address public claimContractAddress; // Reference to your $MAXIM token contract
    address public nftContractAddress = 0xB8a52CBF0a322b5162173984b58510E5BF264D81; //NFT address
    address public tokenContractAddress = 0x64a7F7Ce1719fb64D8b885eDe9D24779e7456d3a;

    bytes32 private  merkleRoot; // The Merkle root for whitelist
    
    uint256 public minPurchase = 0.01 ether; // Minimum purchase amount
    uint256 public maxPurchase = 0.05 ether;
    uint256 public maxFundCap = 50 ether;
    
    uint256 public totalFundRaised;

    //Mapping to track participants and their purchases
    mapping(address => uint256) public purchases;
    address[] public presaleParticipants;

    //Events
    event Purchase(address indexed buyer, uint256 amount);
    event WithdrawalSuccessful(address indexed to, uint256 amount);

    //Errors
    error WithdrawalFailed();

    constructor() {
        _pause();
    }

    /*
    * ******** ******** ******** ******** ******** ******** ********
    * Public Setters functions
    * ******** ******** ******** ******** ******** ******** ********
    */

    /*
    * Sets minimum amount of presale purchase
    */

    function setMinPurchase(uint256 _minPurchase) external onlyOwner {
        minPurchase = _minPurchase;
    }

    /*
    * Sets maximum amount of presale purchase
    */

    function setMaxPurchase(uint256 _maxPurchase) external onlyOwner {
        maxPurchase = _maxPurchase;
    }

    /*
    * Sets maximum amount of total fund
    */
    function setMaxFundCap(uint256 _maxFundCap) external onlyOwner {
        maxFundCap = _maxFundCap;
    }
    

    /*
    * Sets Merkle tree root for whitelist presale
    */
    function setRoot(bytes32 _newRoot) external onlyOwner {
        merkleRoot = _newRoot;
    }

    /*
    * Sets NFT address for holders presale
    */

    function setNFTAddress(address _nftAddress) external onlyOwner {
        nftContractAddress = _nftAddress;
    }

    /*
    * Sets ERC20 Token address 
    */

    function setTokenAddress(address _tokenAddress) external onlyOwner {
        tokenContractAddress = _tokenAddress;
    }

    /*
    * Sets ERC20 Token CLAIM address
    */
    
    function setClaimAddress(address _claimAddress) external onlyOwner {
        claimContractAddress = _claimAddress;
    }

    /*
    * Gets list of purchases: address and cost. 
    * 
    */

    function getPurchases(address _address) external view returns (uint256) {
        return purchases[_address];
    }

    /*
    * Gets list of presale participants - addresses. 
    * 
    */

    function getPresaleParticipants() external view returns (address[] memory) {
        return presaleParticipants;
    }

    /*
    * Gets the total fund raised count 
    */
    function getTotalFundRaised() external view returns (uint256) {
        return totalFundRaised;
    }

    /*
    * Gets the NFT contract address
    */
    function getNFTAddress() public view returns (address) {
        return nftContractAddress;
    }

    /*
    * Gets presale info 
    */
    function getPresaleInfo() 
        external 
        view 
        returns (uint256, uint256, uint256, uint256, address, address, address) {
        return (
            maxFundCap, 
            minPurchase,
            maxPurchase,
            totalFundRaised,
            nftContractAddress,
            claimContractAddress,
            tokenContractAddress
        );
    }

    /*
    * Gets current address info
    */
    function getAccountInfo(address _address) public view returns (uint256, uint256) {
        return (
            purchases[_address],
            getNFTBalanceOfAddress(_address)
        );
    }

    /*
    * Checks if address owns an NFT 
    */
    function isAddressOwnNFT(uint256 _tokenId) public view returns (bool) {
        // Check if the address owns the NFT with the given token ID
        return IERC721(nftContractAddress).ownerOf(_tokenId) == msg.sender;
    }

    function getNFTBalanceOfAddress(address _address) public view returns (uint256) {
        ERC721A nftContract = ERC721A(nftContractAddress);
        return nftContract.balanceOf(_address);
    }

    /*
    * ******** ******** ******** ******** ******** ******** ********
    * Public and External functions
    * ******** ******** ******** ******** ******** ******** ********
    */
   
    /*
    * Function for purchasing tokens
    * params - _proof for whitelist interaction
    */
    function whitelistPurchase(bytes32[] calldata _proof) external payable nonReentrant whenNotPaused {
        require(isWhitelisted(msg.sender, _proof), "ERROR 421: Address is not whitelisted.");
        _purchase();
    }

    /*
    * Function for purchasing tokens
    * params - _tokenId for checking if address owns NFT
    */
    function nftHolderPurchase() external payable nonReentrant whenNotPaused {
        require(getNFTBalanceOfAddress(msg.sender) > 0, "ERROR 421: Address does not own NFT.");
        _purchase();
    }

    /*
    * Withdraw function
    */
    function withdraw() public onlyOwner {

        require(address(this).balance > 0, "ERROR: No balance to withdraw.");
        uint256 amount = address(this).balance;
        //sends fund to team wallet
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");

        if (!success) {
            revert WithdrawalFailed();
        } 

        emit WithdrawalSuccessful(msg.sender, amount);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
    

    //for whitelist check
    function isWhitelisted  (
        address _minterLeaf,
        bytes32[] calldata _merkleProof
    ) public view returns (bool) {
        bytes32 _leaf = keccak256(abi.encodePacked(_minterLeaf));
        return MerkleProof.verify(_merkleProof, merkleRoot, _leaf);
    }

    /*
    * ******** ******** ******** ******** ******** ******** ********
    * Internal functions
    * ******** ******** ******** ******** ******** ******** ********
    */

    function _purchase() internal {

        //checks if eth sent but the address is within the cap range
        require(msg.value >= minPurchase && msg.value <= maxPurchase, "ERROR 411: Amount is not within the allowed range");
        
        //checks if total eth sent by the address is within the cap range
        require((purchases[msg.sender] + msg.value) >= minPurchase && (purchases[msg.sender] + msg.value) <= maxPurchase, "ERROR 411: Amount is not within the allowed range." );
        
        //checks if the total eth collected + the current eth sent is withing the maxFundCap
        require((totalFundRaised + msg.value) <= maxFundCap, "ERROR 431: Maximum target cap exceeded.");
        
        //registers purchase and participant addresses
        purchases[msg.sender] += msg.value;
        presaleParticipants.push(msg.sender);

        //counts total fund
        totalFundRaised += msg.value;

        //Emit purchase event
        emit Purchase(msg.sender, msg.value);
    }
}

/*
* ***** ***** ***** ***** 
*/