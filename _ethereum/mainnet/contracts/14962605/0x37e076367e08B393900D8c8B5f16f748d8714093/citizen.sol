// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;


import "./Ownable.sol";
import "./MerkleProof.sol";
import "./PaymentSplitter.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract citizenERC721A is Ownable, ERC721A {
    using Strings for uint256;

    uint private constant MAX_SUPPLY = 200;

    uint public publicSalePrice = 0.1 ether;

    string public baseURI;

    mapping(address => uint) amountNFTperWalletPublicSale;

    uint private constant maxPerAddressDuringPublicMint = 2;

    bool public isPaused;

    //Constructor
    constructor(string memory _baseURI)
    ERC721A("perplexing citizen", "PC") {
        baseURI = _baseURI;
    }

    /**
    * @notice Override the first Token ID# for ERC721A
    */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
    * @notice This contract can't be called by other contracts
    */
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /**
    * @notice Mint function for the Public Sale
    *
    * @param _account Account which will receive the NFTs
    * @param _quantity Amount of NFTs the user wants to mint
    **/
    function publicMint(address _account, uint _quantity) external payable callerIsUser {
        require(!isPaused, "Contract is Paused");
        uint price = publicSalePrice;
        require(price != 0, "Price is 0");
        require(amountNFTperWalletPublicSale[msg.sender] + _quantity <= maxPerAddressDuringPublicMint, "You can only get 2 NFTs on the Whitelist Sale");
        require(msg.value >= price * _quantity, "Not enought funds");
        amountNFTperWalletPublicSale[msg.sender] += _quantity;
        _safeMint(_account, _quantity);
    }


    /**
    * @notice Get the token URI of an NFT by his ID
    *
    * @param _tokenId The ID of the NFT you want to have the URI of the metadatas
    *
    * @return the token URI of an NFT by his ID
    */
    function tokenURI(uint _tokenId) public view virtual override returns(string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    /**
    * @notice Allows to set the public sale price
    *
    * @param _publicSalePrice The new price of one NFT during the public sale
    */
    function setPublicSalePrice(uint _publicSalePrice) external onlyOwner {
        publicSalePrice = _publicSalePrice;
    }

    /**
    * @notice Pause or unpause the smart contract
    *
    * @param _isPaused true or false if we want to pause or unpause the contract
    */
    function setPaused(bool _isPaused) external onlyOwner {
        isPaused = _isPaused;
    }

    /**
    * @notice Change the base URI of the NFTs
    *
    * @param _baseURI the new base URI of the NFTs
    */
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

        /**
     * @notice withdraw function
     **/
    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
		require(success);
    }
}