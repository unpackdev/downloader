pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

/**
 * @title OxyFarmsNFT
 * @dev The NFTrees token contract for the first OxyFarm of Oxychain
 * Taken from https://github.com/oxychain-earth/oxyfarms-contracts/blob/master/contracts/OxyFarmsNFT.sol
 *
 * @author The Storm Network & Dandelion Labs team
 */
contract OxyFarmsNFT is ERC721Enumerable, Ownable {
    using SafeMath for uint;
    
    string baseURI;                          // BASE URI FOR TOKEN METADATA URL CREATION
    string public contractURI;               // CONTRACT URI FOR PUBLIC MARKETPLACES
    
    uint public constant MAX_NFTREES = 4444; // MAX NFTREES EVER MINTED
    uint public constant MAX_SALE = 50;      // MAX NFTREES TO BE SOLD DURING PUBLIC SALE
    
    address saleAddress;                     // ADDRESS THAT WILL RECEIVE THE PROCEEDS OF THE SALE

    uint public maxPreSale;                  // MAX AMOUNT OF NFTREES MINTED DURING PRESALE
    uint public price;                       // PRICE PER NFT DURING SALE
    
    mapping(address => uint256) private whitelistedAllowance; // ALLOWANCE INDEX
    
    bool public hasPreSaleStarted = false;   // INDICATES IF PRE SALE IS STARTED
    bool public preSaleOver = false;         // INDICATES IF PRE SALE IS OVER
    bool public hasSaleStarted = false;      // INDICATES IF SALE HAS STARTED
    
    event NFTreeMinted(uint indexed tokenId, address indexed owner); //THROWN EVERY TIME AN NFTREE IS MINTED
    
    /**
     * @dev constructor instantiates ERC721 with URI params for the sale and sets up
     * the basic params of the sale, price per nft and max pre sale values.
     *
     * @param baseURI_ receives a string as the base for the token URI creation
     * @param contractURI_ receives a string as the contract URI for public marketplaces
     */
    constructor(string memory baseURI_, string memory contractURI_) ERC721("OxyFarms NFTrees", "OXF") {

        price = 0.05 ether;
        maxPreSale = 10;
        saleAddress = msg.sender;
        baseURI = baseURI_;
        contractURI = contractURI_;
    }
    
    /**
     * @dev mintTo is an internal function with the business logic for minting.
     * 
     * @param _to address which we are going to mint the NFTree to.
     */
    function mintTo(address _to) internal {
        uint mintIndex = totalSupply();
        _safeMint(_to, mintIndex);
        emit NFTreeMinted(mintIndex, _to);
    }
    
    /**
     * @dev mint is an external function that allows the minting process to happen during public sale.
     * 
     * @param _quantity number of NFTrees we want to mint.
     */
    function mint(uint _quantity) external payable  {
        require(hasSaleStarted, "OxyFarmsNFT::mint: Sale hasn't started.");
        require(_quantity > 0, "OxyFarmsNFT::mint: Quantity cannot be zero.");
        require(_quantity <= MAX_SALE, "OxyFarmsNFT::mint: Quantity cannot be bigger than MAX_BUYING.");
        require(totalSupply().add(_quantity) <= MAX_NFTREES, "OxyFarmsNFT::mint: Sold out.");
        require(msg.value >= price.mul(_quantity) || msg.sender == owner(), "OxyFarmsNFT::mint: Ether value sent is below the price.");
        
        for (uint i = 0; i < _quantity; i++) {
            mintTo(msg.sender);
        }
    }

    /**
     * @dev preMint is an external function that allows the minting process to happen during pre sale.
     * 
     * @param _quantity number of NFTrees we want to mint.
     */ 
    function preMint(uint _quantity) external payable  {
        require(hasPreSaleStarted, "OxyFarmsNFT::preMint: Presale hasn't started.");
        require(!preSaleOver, "OxyFarmsNFT::preMint: Presale is over, no more allowances.");
        require(_quantity > 0, "OxyFarmsNFT::preMint: Quantity cannot be zero.");
        require(_quantity <= maxPreSale, "OxyFarmsNFT::preMint: Quantity cannot be bigger than maxPreSale.");
        require(whitelistedAllowance[msg.sender].sub(_quantity) >= 0, "OxyFarmsNFT::preMint: The user is not allowed to do further presale buyings.");
        require(whitelistedAllowance[msg.sender] >= _quantity, "OxyFarmsNFT::preMint: This address is not allowed to buy that quantity.");
        require(totalSupply().add(_quantity) <= MAX_NFTREES, "OxyFarmsNFT::preMint: Sold out");
        require(msg.value >= price.mul(_quantity) || msg.sender == owner(), "OxyFarmsNFT::preMint: Ether value sent is below the price.");
        
        whitelistedAllowance[msg.sender] = whitelistedAllowance[msg.sender].sub(_quantity);
        
        for (uint i = 0; i < _quantity; i++) {
            mintTo(msg.sender);
        }
    }
    
    /**
     * @dev mintByOwner is a function to allow the preminting for team, partners, and community reserve.
     * Only the contract owner can access this function.
     * 
     * @param _to address we are going to mint the NFTrees to.
     * @param _quantity number of NFTrees we want to mint.
     */ 
    function mintByOwner(address _to, uint256 _quantity) public onlyOwner {
        require(_quantity > 0, "OxyFarmsNFT::mintByOwner: Quantity cannot be zero.");
        require(_quantity <= MAX_SALE, "OxyFarmsNFT::mintByOwner: Quantity cannot be bigger than MAX_SALE.");
        require(totalSupply().add(_quantity) <= MAX_NFTREES, "OxyFarmsNFT::mintByOwner: Sold out.");
        
        for (uint i = 0; i < _quantity; i++) {
            mintTo(_to);
        }
    }

    /**
     * @dev batchMintByOwner is a function to allow the preminting for team, partners, and community reserve in batch.
     * Only the contract owner can access this function.
     * 
     * @param _mintAddressList list of addresses we are going to mint the NFTrees to.
     * @param _quantityList list with the number of NFTrees we want to mint to each address.
     */ 
    function batchMintByOwner(address[] memory _mintAddressList, uint256[] memory _quantityList) external onlyOwner {
        require (_mintAddressList.length == _quantityList.length, "OxyFarmsNFT::batchMintByOwner: The length should be same");

        for (uint256 i = 0; i < _mintAddressList.length; i += 1) {
            mintByOwner(_mintAddressList[i], _quantityList[i]);
        }
    }

    function tokensOfOwner(address _owner) public view returns(uint[] memory ) {
        uint tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint[](0);
        } else {
            uint[] memory result = new uint[](tokenCount);
            uint index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }
    
    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }
    
    function setContractURI(string memory _URI) external onlyOwner {
        contractURI = _URI;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setPrice(uint _price) external onlyOwner {
        price = _price;
    }

    function setMaxPreSale(uint _quantity) external onlyOwner {
        maxPreSale = _quantity;
    }
    
    function startSale() external onlyOwner {
        require(!hasSaleStarted, "OxyFarmsNFT::startSale: Sale already active.");
        
        hasSaleStarted = true;
        hasPreSaleStarted = false;
        preSaleOver = true;
    }

    function pauseSale() external onlyOwner {
        require(hasSaleStarted, "OxyFarmsNFT::pauseSale: Sale is not active.");
        
        hasSaleStarted = false;
    }
    
    function startPreSale() external onlyOwner {
        require(!preSaleOver, "OxyFarmsNFT::startPreSale: Presale is over, cannot start again.");
        require(!hasPreSaleStarted, "OxyFarmsNFT::startPreSale: Presale already active.");
        
        hasPreSaleStarted = true;
    }

    function pausePreSale() external onlyOwner {
        require(hasPreSaleStarted, "OxyFarmsNFT::pausePreSale: Presale is not active.");
        
        hasPreSaleStarted = false;
    }

    function setSaleAddress(address _saleAddress) external onlyOwner {
        saleAddress = _saleAddress;
    }
    
    /**
     * @dev checkWhitelisting() allows us to check how many tokens the address
     * is still able to mint during the presale.
     * 
     * @param _addressToCheck address to be checked.
     *
     * @return allowed quantity
     */
    function checkWhitelisting(address _addressToCheck) public view returns (uint) {
        return whitelistedAllowance[_addressToCheck];
    }
    
    /**
     * @dev addAddressessToWhitelist() allows to add new addresses to the presale whitelist.
     * 
     * @param addressesToWhitelist receives a list of addresses to whitelist.
     */
    function addAddressessToWhitelist(address[] memory addressesToWhitelist) external onlyOwner {
        require(!preSaleOver, "OxyFarmsNFT::addAddressessToWhitelist: presale is over, no more allowances");
        
        for (uint i = 0; i < addressesToWhitelist.length; i++) {
            whitelistedAllowance[addressesToWhitelist[i]] = maxPreSale;
        }
    }
    
    /**
     * @dev withdrawAll() allows to withdraw all the funds of the contract during
     * or after the sale is ended, to the sale address (by default contract creator).
     */
    function withdrawAll() external onlyOwner {

        (bool withdrawSale, ) = saleAddress.call{value: address(this).balance}("");
        require(withdrawSale, "OxyFarmsNFT::withdrawAll: Withdrawing failed to the sale address.");
    }
}
