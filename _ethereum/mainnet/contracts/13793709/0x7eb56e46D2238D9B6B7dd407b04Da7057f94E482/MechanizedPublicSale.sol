// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";
import "./Strings.sol";

interface Mechanized {
    function doMint(uint256, address) external;
}

contract MechanizedPublicSale is Ownable{
    using SafeMath for uint256;
    using Strings for uint256;
    using ECDSA for bytes32; 

    Mechanized public nft;

    // Flags
    bool public saleIsActive = false; // flag to indicate if minting is possible
    bool public isContractOpen = true;

     // Token data
    uint256 public MAX_SUPPLY = 685;    // the maximum amount of tokens that can be minted
    uint256 public MINT_PRICE = 0.08 ether; //mint price: 0.08 ETH
    uint256 public MAX_MINT_PER_USER = 2; // maximum amount of tokens one address can mint  

    uint256 public publicSaleMinted = 0;

    // mappings
    mapping(address => uint256) public _mintsPerAddress;

    // events
    event ReceivedEther(uint256 amount, address _from);

    // modifiers
    modifier modifiable {
        require(isContractOpen, "NOT MODIFIABLE");
        _;
    }

    constructor(
        address _mechanized
    ) {
         nft = Mechanized(_mechanized);
    }    

    /** === ONLY OWNER === */    

   /**
     * @dev function to change the max amount of 
     * tokens that can be minted
     *
     * @param _maxSupply the new max tokens that can be minted
     */
    function setMaxSupply(uint256 _maxSupply) external onlyOwner modifiable {
        MAX_SUPPLY = _maxSupply;
    }

    /**
     * @dev function to change the max amount of 
     * tokens that an address can mint
     *
     * @param _maxPurchase the new max tokens that an address can mint
     */
    function setMaxMintPerUser(uint256 _maxPurchase) external onlyOwner modifiable {
        MAX_MINT_PER_USER = _maxPurchase;
    }

    /**
     * @dev function to change the mint price of a token
     *
     * @param _mintPrice the new mint price of a single token
     */
    function setMintPrice(uint256 _mintPrice) external onlyOwner modifiable {
        MINT_PRICE = _mintPrice;
    }

    /**
     * @dev Allows the owner to withdraw ether
     */
    function withdrawEth() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "ETH Transfer failed");
    }

    /**
     * @dev Pause sale if active, make active if paused
    */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function disableModifications() external onlyOwner {
        isContractOpen = false;
    }

    /** === MINT METHODS === */

    /**
    * @dev Mints a token to an address with a tokenURI.
     * @param numberOfTokens the amount of tokens to mint
    */
    function mint(uint256 numberOfTokens) public payable {
        require(saleIsActive, "SALE NOT ACTIVE");
        require(_mintsPerAddress[msg.sender].add(numberOfTokens) <= MAX_MINT_PER_USER, "MINTER EXCEEDS MAX TOKENS");
        require(publicSaleMinted.add(numberOfTokens) <= MAX_SUPPLY, "MAX TOKENS ALREADY MINTED");
        require(MINT_PRICE.mul(numberOfTokens) == msg.value, "ETHER SENT NOT CORRECT"); 

        publicSaleMinted = publicSaleMinted.add(numberOfTokens);
        _mintsPerAddress[msg.sender] = _mintsPerAddress[msg.sender].add(numberOfTokens);
        nft.doMint(numberOfTokens, msg.sender);
    }

    /** === MISC === */
    
    /**
     * @dev Fallback function for receiving Ether
     */
    receive() external payable {
        emit ReceivedEther(msg.value, msg.sender);
    }        
}