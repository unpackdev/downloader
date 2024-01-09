pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

/**
 * @title CubesNFT
 * @dev The Cubes NFT token contract for Latent Life project.
 * Taken from https://github.com/dandelionlabs-io/cubes-contracts/blob/master/contracts/LatentLifeNFT.sol
 *
 * @author Dandelion Labs | https://github.com/dandelionlabs-io
 */
contract LatentLifeNFT is ERC721Enumerable, Ownable {
    using SafeMath for uint;
    
    string baseURI;                          // BASE URI FOR TOKEN METADATA URL CREATION
    string public contractURI;               // CONTRACT URI FOR PUBLIC MARKETPLACES
    
    uint public constant MAX_CUBES = 33;     // MAX CUBES EVER MINTED
    
    address saleAddress;                     // ADDRESS THAT WILL RECEIVE THE PROCEEDS OF THE SALE

    uint public price;                       // PRICE PER NFT DURING SALE
    uint public claimPrice;                  // PRICE PER NFT CLAIMED
    
    mapping(address => bool) private whitelist;       // WHITELIST INDEX
    mapping(uint256 => address) private claimedCubes; // claim cube index 
    
    bool public hasPreSaleStarted = false;   // INDICATES IF PRE SALE IS STARTED
    bool public preSaleOver = false;         // INDICATES IF PRE SALE IS OVER
    bool public hasSaleStarted = false;      // INDICATES IF SALE HAS STARTED
    
    event CubeMinted(uint indexed tokenId, address indexed owner);  //THROWN EVERY TIME AN CUBE IS MINTED
    event CubeClaimed(uint indexed tokenId, address indexed owner); //THROWN EVERY TIME AN CUBE IS CLAIMED
    
    /**
     * @dev constructor instantiates ERC721 with URI params for the sale and sets up
     * the basic params of the sale and price per nft.
     *
     * @param baseURI_       receives a string as the base for the token URI creation
     * @param contractURI_   receives a string as the contract URI for public marketplaces
     */
    constructor(string memory baseURI_, string memory contractURI_) ERC721("Latent Life Cubes", "LL-CUBE") {

        price = 0.45 ether;
        claimPrice = 0.3 ether;
        saleAddress = msg.sender;
        baseURI = baseURI_;
        contractURI = contractURI_;
    }
    
    /**
     * @dev mintTo is an internal function with the business logic for minting.
     * 
     * @param _to address which we are going to mint the Cube to.
     */
    function mintTo(address _to) internal {
        uint mintIndex = totalSupply();
        _safeMint(_to, mintIndex);
        emit CubeMinted(mintIndex, _to);
    }
    
    /**
     * @dev mint is an external function that allows the minting process to happen during public sale.
     * 
     * @param _quantity number of Cube we want to mint.
     */
    function mint(uint _quantity) external payable  {
        require(hasSaleStarted, "LatentLifeNFT::mint: Sale hasn't started.");
        require(_quantity > 0, "LatentLifeNFT::mint: Quantity cannot be zero.");
        require(totalSupply().add(_quantity) <= MAX_CUBES, "LatentLifeNFT::mint: Sold out.");
        require(msg.value >= price.mul(_quantity) || msg.sender == owner(), "LatentLifeNFT::mint: Ether value sent is below the price.");
        
        for (uint i = 0; i < _quantity; i++) {
            mintTo(msg.sender);
        }
    }

    /**
     * @dev preMint is an external function that allows the minting process to happen during pre sale.
     * 
     * @param _quantity number of CUBES we want to mint.
     */ 
    function preMint(uint _quantity) external payable  {
        require(hasPreSaleStarted, "LatentLifeNFT::preMint: Presale hasn't started.");
        require(!preSaleOver, "LatentLifeNFT::preMint: Presale is over, no more allowances.");
        require(_quantity > 0, "LatentLifeNFT::preMint: Quantity cannot be zero.");
        require(whitelist[msg.sender], "LatentLifeNFT::preMint: User must be in the whitelist.");
        require(totalSupply() < MAX_CUBES, "LatentLifeNFT::preMint: Sold out");
        require(totalSupply().add(_quantity) <= MAX_CUBES, "LatentLifeNFT::preMint: Cannot mint so many cubes, check how many are left.");
        require(msg.value >= price.mul(_quantity) || msg.sender == owner(), "LatentLifeNFT::preMint: Ether value sent is below the price.");
                
        for (uint i = 0; i < _quantity; i++) {
            mintTo(msg.sender);
        }
    }
    
    /**
     * @dev mintByOwner is a function to allow the contract owner to mint to a specific address.
     * Only the contract owner can access this function.
     * 
     * @param _to address we are going to mint the Cubes to.
     * @param _quantity number of CUBES we want to mint.
     */ 
    function mintByOwner(address _to, uint256 _quantity) public onlyOwner {
        require(_quantity > 0, "LatentLifeNFT::mintByOwner: Quantity cannot be zero.");
        require(totalSupply() < MAX_CUBES, "LatentLifeNFT::preMint: Sold out");
        require(totalSupply().add(_quantity) <= MAX_CUBES, "LatentLifeNFT::preMint: Cannot mint so many cubes, check how many are left.");
        
        for (uint i = 0; i < _quantity; i++) {
            mintTo(_to);
        }
    }

    /**
     * @dev claimCube is an external function that allows user to claim a token.
     * 
     * @param _cubeId id of the cube to claim
     */ 
    function claimCube(uint _cubeId) external payable  {
        require(_exists(_cubeId), "LatentLifeNFT::claimCube: Cube has not been minted yet.");
        require(claimedCubes[_cubeId] == address(0), "LatentLifeNFT::claimCube: Cube has already been claimed,");
        require(ownerOf(_cubeId) == msg.sender, "LatentLifeNFT::claimCube: Sender must be the owner of the Cube NFT");
        require(msg.value >= claimPrice, "LatentLifeNFT::claimCube: Ether value sent is below the price.");
        require(totalSupply() == MAX_CUBES, "LatentLifeNFT::claimCube: Contract must be sold out");

        claimedCubes[_cubeId] = msg.sender;
        emit CubeClaimed(_cubeId, msg.sender);
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

    function setClaimPrice(uint _claimPrice) external onlyOwner {
        claimPrice = _claimPrice;
    }
    
    function startSale() external onlyOwner {
        require(!hasSaleStarted, "LatentLifeNFT::startSale: Sale already active.");
        
        hasSaleStarted = true;
        hasPreSaleStarted = false;
        preSaleOver = true;
    }

    function pauseSale() external onlyOwner {
        require(hasSaleStarted, "LatentLifeNFT::pauseSale: Sale is not active.");
        
        hasSaleStarted = false;
    }
    
    function startPreSale() external onlyOwner {
        require(!preSaleOver, "LatentLifeNFT::startPreSale: Presale is over, cannot start again.");
        require(!hasPreSaleStarted, "LatentLifeNFT::startPreSale: Presale already active.");
        
        hasPreSaleStarted = true;
    }

    function pausePreSale() external onlyOwner {
        require(hasPreSaleStarted, "LatentLifeNFT::pausePreSale: Presale is not active.");
        
        hasPreSaleStarted = false;
    }

    function setSaleAddress(address _saleAddress) external onlyOwner {
        saleAddress = _saleAddress;
    }
    
    /**
     * @dev checkWhitelisting() allows us to check if the address is whitelisted or not.
     * 
     * @param _addressToCheck address to be checked.
     *
     * @return true or false if is checklisted.
     */
    function checkWhitelisting(address _addressToCheck) public view returns (bool) {
        return whitelist[_addressToCheck];
    }

    /**
     * @dev checkClaimedCubes() allows us to check if the cube has been claimed and by whom.
     * 
     * @param _tokenId to be checked.
     *
     * @return address of who claimed it.
     */
    function checkClaimedCubes(uint256 _tokenId) public view returns (address) {
        return claimedCubes[_tokenId];
    }
    
    /**
     * @dev addAddressessToWhitelist() allows to add new addresses to the presale whitelist.
     * 
     * @param addressesToWhitelist receives a list of addresses to whitelist.
     */
    function addAddressessToWhitelist(address[] memory addressesToWhitelist) external onlyOwner {
        require(!preSaleOver, "LatentLifeNFT::addAddressessToWhitelist: presale is over, no more allowances");
        
        for (uint i = 0; i < addressesToWhitelist.length; i++) {
            whitelist[addressesToWhitelist[i]] = true;
        }
    }
    
    /**
     * @dev withdrawAll() allows to withdraw all the funds of the contract during
     * or after the sale is ended, to the sale address (by default contract creator).
     */
    function withdrawAll() external onlyOwner {

        (bool withdrawSale, ) = saleAddress.call{value: address(this).balance}("");
        require(withdrawSale, "LatentLifeNFT::withdrawAll: Withdrawing failed to the sale address.");
    }
}
