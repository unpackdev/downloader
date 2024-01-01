// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/*
For the army...
*/

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract nnjaERC721A is Ownable, ERC721A {

    using Strings for uint;

    enum Step {
        Before,
        PublicSale,
        SoldOut,
        Reveal
    }

    Step public sellingStep;

    uint private constant MAX_SUPPLY = 4000;
    uint private constant MAX_GIFT = 20;
    uint private constant MAX_PUBLIC = 3980;
    uint private constant MAX_SUPPLY_MINUS_GIFT = MAX_SUPPLY - MAX_GIFT;

    string public baseURI;

    mapping(address => uint) amountNFTperWalletPublicSale;

    uint private constant maxPerAddressDuringPublicMint = 2;

    bool public isPaused;

    //Constructor

    constructor(string memory _baseURI)
    ERC721A("nnja", "nnja") {
        baseURI = _baseURI;
    }

    /**
    * @notice this contract cant be call by other contracts
    */

    modifier callerIsUser(){
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /**
    * @notice Mint function for Public Sale
    *
    * @param _account Account which will receive the NFT
    * @param _quantity Amount of NFT user want to mint
     */
    
    function publicMint(address _account, uint _quantity) external callerIsUser {
        require(!isPaused, "contract is paused");
        require(sellingStep == Step.PublicSale, "Public sale is not activated");
        require(amountNFTperWalletPublicSale[msg.sender] + _quantity <= maxPerAddressDuringPublicMint, "You can only get 3 NFTs on this sale");
        require(totalSupply() + _quantity <= MAX_SUPPLY_MINUS_GIFT, "Max supply exceeded");
        amountNFTperWalletPublicSale[msg.sender] += _quantity;
        _safeMint(_account, _quantity);
    }

    /**
    * @notice Allow the owner to gift NFTs
    *
    * @param _to the address of the receiver
    * @param _quantity Amount of NFT the owner want to offer
     */

    function gift(address _to, uint _quantity) external onlyOwner {
        require(sellingStep > Step.PublicSale, "Gift is after Public Sale");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Reach max Supply");
        _safeMint(_to, _quantity);
    }

    /**
    * @notice get token URI of an NFT based on his ID
    *
    * @param _tokenId The ID of the NFT you want to have the URI of the metadatas
    *
    * @return the token URI of an NFT  based on his ID
    */

    function tokenURI(uint _tokenId) public view virtual override returns(string memory){
        require(_exists(_tokenId), "URI query for nonexistent token");

        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    /**
    * @notice change the step of the sale
    *
    * @param _step the new step of the sale
     */

    function setStep(uint _step) external onlyOwner {
        sellingStep = Step(_step);
    }

    /**
    * @notice pause of unpause smart contract 
    *
    * @param _isPaused true or false if we want to pause or unpause the contract 
     */

    function setPaused(bool _isPaused) external onlyOwner {
        isPaused = _isPaused;
    }

    /**
    * @notice change the baseURI of the NTFs 
    *
    * @param _baseURI the new baseURI of the NFTs 
     */

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }


}
