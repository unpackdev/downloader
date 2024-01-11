// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// @author Sp4rKz https://twitter.com/Sp4rKz_eth

import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract ElvesofEOCERC721A is Ownable, ERC721A, PaymentSplitter {

    using Strings for uint;

    enum Step {
        Before,
        PublicFreeSale,
        PublicSale,
        SoldOut,
        Reveal
    }

    Step public sellingStep;

    uint private constant MAX_SUPPLY = 5000;
    uint private constant MAX_GIFT = 100;
    uint private constant MAX_FREE_SALE = 1500;
    uint private constant MAX_PUBLIC = 3400;
    uint private constant MAX_SUPPLY_MINUS_GIFT = MAX_SUPPLY - MAX_GIFT;

    uint public publicSalePrice = 0.02 ether;

    uint public saleStartTime = 1654977600;
    
    string public baseURI;

    mapping(address => uint) amountNFTperWalletFreeMint;
    mapping(address => uint) amountNFTperWalletPublicSale;

    uint private maxPerAddressDuringFreeMint = 5;
    uint private maxPerAddressDuringPublicMint = 5;

    bool public isPaused;

    uint private teamLength;

    address[] private _team = [
        0x04c1fBda2D05DF46984d1071fB396466E761FF0c,
        0x9794Ec77f5d44B3109795aF9aE7465185e3E9571,
        0x60629dfe81cD812dF789c0e207F0dB6F3BE5613e,
        0x96942BABcE8fa02F9F7e304Dc3c0AB874C0DE781
    ];

    uint[] private _teamShares = [
        215,
        270,
        270,
        245
    ];

    //constructor
    constructor(string memory _baseURI)
    ERC721A("Elves of EOC", "EEOC")
    PaymentSplitter(_team, _teamShares) {
        baseURI = _baseURI;
        teamLength = _team.length;
    }
    
    /** 
    * @notice This contract can't be called by another contract
    */
    modifier callerIsUser() {
        require(tx.origin ==msg.sender, "The caller is another contract");
        _;
    }

    /** 
    * @notice Mint Function for the Public Free Sale
    *
    * @param _account Account which will receive the NFTs
    * @param _quantity Amount of NFTs the user wants to mint 
    */
    function freeMint(address _account, uint _quantity) external payable callerIsUser {
        require(!isPaused, "Contract is Paused");
        require(currentTime() >= saleStartTime , "Free Mint has not started yet");
        require(sellingStep == Step.PublicFreeSale, "Free Mint has not started yet");
        require(amountNFTperWalletFreeMint[msg.sender] + _quantity <= maxPerAddressDuringFreeMint, "You can only get 5 NFTs during the Free Mint");
        require(totalSupply() + _quantity <= MAX_FREE_SALE, "Max supply exceeded");
        amountNFTperWalletFreeMint[msg.sender] += _quantity;
        _safeMint(_account, _quantity);
    }

    /** 
    * @notice Mint Function for the public sale
    *
    * @param _account Account which will receive the NFTs
    * @param _quantity Amount of NFTs the user wants to mint 
    *
    */
    function publicMint(address _account, uint _quantity) external payable callerIsUser {
        require(!isPaused, "Contract is Paused");
        require(currentTime() >= saleStartTime , "Public sale has not started yet");
        uint price = publicSalePrice;
        require(price != 0, "Price is 0");
        require(sellingStep == Step.PublicSale, "Public sale has not started yet");
        require(amountNFTperWalletPublicSale[msg.sender] + _quantity <= maxPerAddressDuringPublicMint, "You can only get 5 NFTs during the public sale");
        require(totalSupply() + _quantity <= MAX_SUPPLY_MINUS_GIFT, "Max supply exceeded");
        require(msg.value >= price * _quantity, "not enough funds");
        amountNFTperWalletPublicSale[msg.sender] += _quantity;
        _safeMint(_account, _quantity);
    }


    /** 
    * @notice Allows the owner to gifts NFTs
    *
    * @param _to The address of the receiver
    * @param _quantity Amount of NFTs the owner wants to gift
    *
    */
    function gift(address _to, uint _quantity) external onlyOwner {
        require(sellingStep > Step.PublicSale, "Gift is after the public sale");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Reached max supply");
        _safeMint(_to, _quantity);
    }


    /** 
    * @notice Get the token URI of a NFT by his ID
    *
    * @param _tokenId The ID of the NFT you want to have the URI of the metadatas
    *
    * @return the token URI of an NFT by his ID
    */
    function tokenURI(uint _tokenId) public view virtual override returns(string memory){
        require(_exists(_tokenId), "URI query for nonexistent token");

        return string(abi.encodePacked(baseURI, _tokenId.toString(),".json"));
    }

    /** 
    * @notice Allows to set the public sale price
    * @param _publicSalePrice The new price of one NFT during the public sale
    */
    function SetPublicSalePrice( uint _publicSalePrice) external onlyOwner {
        publicSalePrice = _publicSalePrice;
    }

   /** 
    * @notice Change the starting time (TimeStamp) of the sale
    * @param _saleStartTime The new starting TimeStamp of the sale.
    */
    function SetSaleStartTime( uint _saleStartTime) external onlyOwner {
        saleStartTime = _saleStartTime;
    }

    /**
    * @notice Get the current timestamp
    * @return the current timestamp
    */
    function currentTime() internal view returns(uint) {
        return block.timestamp;
    }

    /**
    * @notice Change the step of the sale
    * @param _step The new Step of the sale
    */
    function setStep(uint _step) external onlyOwner {
        sellingStep = Step(_step);
    }

    /**
    * @notice Pause or unpause the smart contract
    * @param _isPaused True or False if you want to Pause or unpause the contract
    */
    function setPaused(bool _isPaused) external onlyOwner {
        isPaused = _isPaused;
    }

    /**
    * @notice Change the max supply that you can mint
    * @param _MaxMint The new maximum of supply you can mint
    */
    function setMaxMint(uint _MaxMint) external onlyOwner {
        maxPerAddressDuringPublicMint = _MaxMint;
    }

    /**
    * @notice Change the base URI of the NFTs
    * @param _BaseURI is the new base URI of the NFTs
    */
    function setBaseURI(string memory _BaseURI) external onlyOwner {
        baseURI = _BaseURI;
    }

    /**
    * @notice Release the gains on every account
    */

    function releaseAll() external {
        for(uint i = 0 ; i < teamLength ; i++) {
            release(payable(payee(i)));
        }
    }

    //not allowing receiving ethers outside minting functions
    receive() override external payable {
        revert("only if you mint");
    }

}