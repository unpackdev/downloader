// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

// Contracts
import "./ERC721.sol";
import "./Ownable.sol";

// Utils
import "./Address.sol";
import "./Counters.sol";
import "./Strings.sol";

/** 
 * @title ERC721Extended
 * @dev Extends ERC721 implementations
*/


contract ERC721Extended is 
    ERC721, 
    Ownable
{
    // use some good trusty modules
    using Address for address;
    using Counters for Counters.Counter;
    using Strings for uint256;

    /* Artwork properties */
    uint256 public price;       // Artwork price
    uint256 public available;   // How many artworks are available
    uint256 public giveawayReserve = 0; // reserve certain amount for giveaways
    uint256 public maxMultiple; // How many artworks can be bought in one purchaseMultiple call
    string  public baseURI;     // base token metadata URI
    

    // track if sales are enabled
    bool public saleEnabled;

    // whitelist and giveaway contract addresses
    address public whitelistContractAddress;
    address public giveawayContractAddress;

    address payable internal treasury;

    Counters.Counter internal _tokenIdTracker;

    // event StartSales();

    constructor (
        uint256 _price, 
        string memory name, 
        string memory symbol, 
        string memory baseTokenURI,
        uint256 _maxMultiple, 
        uint256 _available, 
        bool _saleEnabled
    )
    ERC721(name, symbol) {
   
        price = _price;
        available = _available;
        baseURI = baseTokenURI;
        maxMultiple = _maxMultiple;

        // set if sale is enabled or disabled
        saleEnabled = _saleEnabled;

        // assign owner as default treasury address
        treasury = payable(owner());
    } 

    function totalSupply() public view returns (uint256) {
        return _tokenIdTracker.current();
    }  
  
    /**
        * @dev Burns `tokenId`. See {ERC721-_burn}.
        * @dev Implementation from ERC721Burnable
        *
        * Requirements:
        *
        * - The caller must own `tokenId` or be an approved operator.
    */
    function burn(uint256 tokenId) public virtual {
        bool approved = _isApprovedOrOwner(_msgSender(), tokenId);        
        require(approved, "Caller is not owner nor approved");

        _burn(tokenId);
    }

    /**
        * @dev Toggles if the sale is active
     */
    function toggleSaleEnabled() public onlyOwner {
        saleEnabled = !saleEnabled;
    }
    
  /**
        * @notice Set treasury address
        * @param a treasury address
    */
    function setTreasury(address payable a) public onlyOwner {
        treasury = a;
    }

    /**
    * @notice Set purchase price for proxy transactions
    * @param p price for proxy transactions
    */
    function setPrice(uint256 p) public onlyOwner {
        price = p;
    }

    /**
     * @dev Set the new whitelist contract address
     */
    function setWhitelistContractAddress(address contractAddress) public onlyOwner {
      whitelistContractAddress = contractAddress;
    }

    /**
     * @dev Set the new giveaway contract address
     */
    function setGiveawayContractAddress(address contractAddress) public onlyOwner {
      giveawayContractAddress = contractAddress;
    }

    /**
     * @dev Set giveaway reserve
     */
    function setGiveawayReserve(uint256 newReserve) public onlyOwner {
        giveawayReserve = newReserve;
    }

    /** 
    * @notice Get token metadata base uri
    * @param newURI new base URI
    */
    function setBaseURI(string memory newURI) public onlyOwner {
        baseURI = newURI;
    }

    /**
    * @notice Purchases an artwork.
    *   - Returns the artworkID of purchased work.
    *   - Reverts if insuffiscient funds, no artworks left or sales are paused.
    */
    function _purchase(address recipient) internal returns (uint256) {
        
        // get next artwork
        uint256 artworkID = _tokenIdTracker.current();

        // mint new artwork!
        _mint(recipient, artworkID);

        // increment pieces sold count
        _tokenIdTracker.increment();

        return artworkID;
    }

    /**
     * @dev Allow whitelist contract to be authorized to mint
     */
    function saleAuthorized() internal virtual returns (bool) {
      return saleEnabled || _msgSender() == whitelistContractAddress;
    }


    function canPurchase(uint256 count, address /*recipient*/) internal virtual {
        // ensure sales period is active 
        require(saleAuthorized(), "ERC721Extended: Sales not authorized");

        // make sure we're not sold out and have enough giveaway reserve left
        require(_tokenIdTracker.current() < available - giveawayReserve, "No more pieces available.");

        // ensure not too many requested for mint
        require(count <= maxMultiple, "ERC721Extended: greedy mint!");
        
        //validate price
        // NOTE: solidity compiter ^0.8 has overflow checks, so none needed here
        require(msg.value >= (price * count), "ERC721Extended: Not enough payment!");
    }

    function _purchaseMultiple(uint256 count, address recipient) internal virtual returns (uint256 id, uint256 purchased) {

        // validation checks for purchase
        canPurchase(count, recipient);

        uint256 firstArtworkID;
        uint256 artworkID;

        // attempt to purchase `count` tokens
        for (uint256 index = 0; index < count; index++) {

            artworkID = _purchase(recipient);
          
            if(index == 0)
                firstArtworkID = artworkID;
        }

        return (firstArtworkID, count);
    }

    /**
    * @notice Purchases an artwork.
    *   - Returns the tuple(artworkID, count)
    *     - artworkID -  of the first purchased work.
    *     - count - the number of artworks purchased.
    *   - Reverts if insuffiscient funds, no artworks left or sales are paused.
    */
    function purchaseMultiple(uint256 count) public payable returns (uint256 id, uint256 purchased) {
       return _purchaseMultiple(count, _msgSender());
    }

    /**
    * @notice Purchases an artwork.
    *   - Returns the artworkID of purchased work.
    *   - Reverts if insuffiscient funds, no artworks left or sales are paused.
    */
    function purchaseMultipleFor(uint256 count, address to) public payable returns (uint256 id, uint256 purchased)  {
        return _purchaseMultiple(count, to);
    }

    /**
     * @dev Allow owner to mint in order to be used for giveaways
     */
    function giveawayMint(uint256 count, address to) public {
        address sender = _msgSender();
        require(sender == owner() || sender == giveawayContractAddress, "ERC721Extended: Not authorized!");

        require((_tokenIdTracker.current() + count <= available) && (count <= giveawayReserve), "ERC721Extended: Not enough tokens");
        giveawayReserve -= count;

        // attempt to purchase `count` tokens
        for (uint256 index = 0; index < count; index++) {
            _purchase(to);
        }
    }

    /**
    * @notice Withdraw funds to treasury
    *   - Errors if transaction failed
    */
    function withdraw() public {
        // solhint-disable-next-line indent, bracket-align
        (bool success, ) = treasury.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    /**
        * @notice Returns the Uniform Resource Identifier (URI) for `tokenId` token.
        * @dev Complies with ERC721Metadata extension 
        */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        // apply random start index to token URI
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

}