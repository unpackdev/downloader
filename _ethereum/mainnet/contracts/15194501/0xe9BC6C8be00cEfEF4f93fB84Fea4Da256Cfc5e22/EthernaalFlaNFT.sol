// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

/**  
* @title An NFT Marketplace contract for Ethernaal Flash NFTs
* @author Gnana Lakshmi T C
* @notice This is the Ethernaal Marketplace contract for Minting NFTs and Direct Sale only.
* @dev Most function calls are currently implemented with access control
*/

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./SafeMath.sol";

/** 
* This is the Ethernaal Marketplace contract for Minting NFTs and Direct Sale only.
*/
contract EthernaalFlaNFT is ERC721URIStorage {

    using SafeMath for uint256;
    mapping(uint256 => uint256) private salePrice;
    mapping(address => bool) public creatorWhitelist;
    mapping(uint256 => address) private tokenOwner;
    mapping(uint256 => address) private tokenCreator;
    mapping(address => uint[]) private creatorTokens;
    //This is to determine the platform royalty for the first sale made by the creator
    mapping(uint => bool) private tokenFirstSale;

    event SalePriceSet(uint256 indexed _tokenId, uint256 indexed _price);
    event Sold(address indexed _buyer, address indexed _seller, uint256 _amount, uint256 indexed _tokenId);
    event WhitelistCreator(address indexed _creator);
    event DelistCreator(address indexed _creator);
    event OwnershipGranted(address indexed newOwner);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
    event Mint(address indexed creator,uint indexed tokenId, string indexed tokenURI);

    uint constant FLOAT_HANDLER_TEN_4 = 10000;

    address owner;
    address _grantedOwner;
    address admin;
    address blackUni_org;
    uint256 sellerFee;
    uint256 orgFee;
    uint256 creatorFee;
    uint256 blackUniFee;
    uint256 sellerFeeInitial;
    uint256 orgFeeInitial;
    uint256 blackUniFeeInital;
    address payable ethernaal_org;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct NFTData {
        uint tokenId;
        string title;
        string description;
        string artistName;
        address creator;
    }

    NFTData[] mintedNfts;

    /**
    * Modifier to allow only minters to mint
    */
    modifier onlyMinter() virtual {
        require(creatorWhitelist[msg.sender] == true);
        _;
    }

    /**
    * Modifier to allow only owners of a token to perform certain actions 
    */
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender);
        _;
    }

    /**
    * Modifier to allow only owner of the contract to perform certain actions 
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    /**
    * Modifier to allow only admin of the organization to perform certain actions 
    */
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    constructor(string memory _name,
        string memory _symbol,
        address payable org,
        address payable blackUnicornOrg,
        address payable _admin
        )
        ERC721(_name, _symbol)
    {
        owner = msg.sender;
        admin = _admin;
        ethernaal_org = org;
        blackUni_org = blackUnicornOrg;
        //Creator royalty Fee is fixed to be 1% of sales, org fee to be 1% and black unicorn to 0.5%
        //Multiply all the three % variables by 100, to kepe it uniform
        orgFee = 100;
        creatorFee = 100;
        blackUniFee = 50;
        sellerFee = 10000 - orgFee - creatorFee - blackUniFee;
        //Fees for first sale only
        orgFeeInitial = 200;
        blackUniFeeInital = 50;
        sellerFeeInitial = 10000-orgFeeInitial-blackUniFeeInital;
    }

    /**
    * @dev Owner can transfer the ownership of the contract to a new account (`_grantedOwner`).
    * Can only be called by the current owner.
    */
    function grantContractOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        emit OwnershipGranted(newOwner);
        _grantedOwner = newOwner;
    }

    /**
    * @dev Claims granted ownership of the contract for a new account (`_grantedOwner`).
    * Can only be called by the currently granted owner.
    */
    function claimContractOwnership() public virtual {
        require(_grantedOwner == msg.sender, "Ownable: caller is not the granted owner");
        emit OwnershipTransferred(owner, _grantedOwner);
        owner = _grantedOwner;
        _grantedOwner = address(0);
    }

    /**
    * @dev Organisation address can be updated to another address in case of attack or compromise(`newOrg`)
    * Can be done only by the contract owner.
    */
    function changeOrgAddress(address _newOrg) public onlyOwner {
        require(_newOrg != address(0), "New organization cannot be zero address");
        ethernaal_org = payable(_newOrg);
    }

    /**
    * @dev Black Unicorn organisation address can be updated to another address in case of attack or compromise(`newOrg`)
    * Can be done only by the contract owner.
    */
    function changeBlackUniAddress(address _blakcUniOrg) public onlyOwner {
        require(_blakcUniOrg != address(0), "New organization cannot be zero address");
        blackUni_org = payable(_blakcUniOrg);
    }

    /**
    * @dev This function is used to get the seller percentage. 
    * This refers to the amount of money that would be distributed to the seller 
    * after the reduction of royalty and platform fees.
    * The values are multiplied by 100, in order to work easily 
    * with floating point percentages.
    */
    function getSellerFee() public view returns (uint256) {
        //Returning % multiplied by 100 to keep it uniform across contract
        return sellerFee;
    }


    /** @dev Calculate the royalty distribution for organisation/platform and the
    * creator/artist.
    * Each of the organisation, creator royalty and the parent organsation fees
    * are set in this function.
    * The 'sellerFee' indicates the final amount to be sent to the seller.
    */
    function setRoyaltyPercentage(uint256 _orgFee, uint _creatorFee, uint _blackUnicornFee) public onlyOwner returns (bool) {
        //Sum of org fee and creator fee should be 100%
        require(10000 > _orgFee+_creatorFee+_blackUnicornFee, "Sum of creator fee and org fee should be 100%");
        orgFee = _orgFee;
        creatorFee = _creatorFee;
        blackUniFee = _blackUnicornFee;
        sellerFee = 10000 - orgFee - creatorFee - blackUniFee;
        return true; 
    }

    /** @dev Calculate the royalty distribution for organisation/platform and the
    * creator/artist(who would be the seller) on the first sale.
    * The first iteration of whitepaper has the following stats:
    * orgFee = 2%
    * blackUnicornFee = 0.5%
    * artist royalty/creator fee = 0%
    * The above numbers can be updated later by the DAO
    * @notice _creatorFeeInitial should be sellerFeeInitial - seller fees on first sale
    */
    function setRoyaltyPercentageFirstSale(uint256 _orgFeeInitial, uint _creatorFeeInitial, uint _blackUnicornFeeInitial) public onlyOwner returns (bool) {
        orgFeeInitial = _orgFeeInitial;
        sellerFeeInitial = _creatorFeeInitial;
        _blackUnicornFeeInitial = _blackUnicornFeeInitial;
        return true;
    }

    /** @dev Return all the royalties including first sale and subsequent sale values
    * orgFee - % of fees that would go to the org from the total royalty
    * blackUniFee - % of fees for Black Unicorn
    * creatorRoyalty - % of fees that would go to the artist/creator
    * orgInitialRoyalty - % of fees that would go to the organisation on first sale
    * sellerFeeInitial - % of fees for seller on the first sale
    * blackUniFeeInitial - % of fees that would go to Black Unicorn on first sale
    */
    function getRoyalties() public view returns (uint _orgFee, uint _blackUniFee, uint256 _creatorRoyalty, 
    uint256 _orgInitialRoyalty, uint256 _sellerFeeInitial, uint _blakcUniFeeInitial) {
        
        return (orgFee, creatorFee, blackUniFee, orgFeeInitial, sellerFeeInitial, blackUniFeeInital);
    }

    /**
    * This function is used to set the price of a token
    * @notice Only admin is allowed to set the price of a token
    */
    function setPrice(uint256 tokenId, uint256 price) public onlyAdmin {
        salePrice[tokenId] = price;
    }

    /**
    * This function is used to change the price of a token
    * @notice Only token owner is allowed to change the price of a token
    */
    function changePrice(uint256 _tokenId, uint256 price) public onlyOwnerOf(_tokenId) {
        require(price > 0, "changePrice: Price cannot be changed to less than 0");
        salePrice[_tokenId] = price;
    }

    /**
    * This function is used to check if it is the first sale of a token
    * on the Ethernaal marketplace.
     */
    function isTokenFirstSale(uint tokenId) external view returns(bool){
        return tokenFirstSale[tokenId];
    }

    /**
    * This function is used to mint an NFT for the Ethernaal marketplace.
    * @dev The basic information related to the NFT needs to be passeed to this function,
    * in order to store it on chain to avoid disputes in future.
    */
    function mintWithIndex(address _creator, string memory _tokenURI, string memory title,
    string memory description, string memory artistName) public virtual onlyMinter returns (uint256 _tokenId) {
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();
        tokenOwner[tokenId] = _creator;

       
        _mint(_creator, tokenId);
        _setTokenURI(tokenId, _tokenURI);

        tokenCreator[tokenId] = _creator;
        
        NFTData memory nftNew = NFTData(tokenId, title, description, artistName, _creator);
        mintedNfts.push(nftNew);
        
        creatorTokens[_creator].push(tokenId);
        emit Mint(_creator,tokenId, _tokenURI);
        return tokenId;
    }
    
    /**
    * This function is used to set an NFT on sale. 
    * @dev The sale price set in this function will be used to perform the sale transaction
    * once the buyer wants to buy an NFT.
    */
    function setSale(uint256 _tokenId, uint256 price) public virtual onlyOwnerOf(_tokenId) {
        address tOwner = ownerOf(_tokenId);
        require(tOwner != address(0), "setSale: nonexistent token");
        require(price != 0, "setSale: Price cannot be set to zero");
        salePrice[_tokenId] = price;
        emit SalePriceSet(_tokenId, price);
    }

    /**
    * This function is used to buy an NFT which is on sale.
    */
    function buyTokenOnSale(uint256 tokenId, address _nftAddress)
        public
        payable
    {
        ERC721 nftAddress = ERC721(_nftAddress);

        uint256 price = salePrice[tokenId];
        uint256 sellerFees = getSellerFee();
        uint256 creatorRoyalty = creatorFee;
        uint256 platformFees = orgFee;
        uint256 blackUnicornFee = blackUniFee;

        require(price != 0, "buyToken: price equals 0");
        require(
            msg.value == price,
            "buyToken: price doesn't equal salePrice[tokenId]"
        );
        address tOwner = nftAddress.ownerOf(tokenId);

        nftAddress.safeTransferFrom(tOwner, msg.sender, tokenId);
        salePrice[tokenId] = 0;

        if(tokenFirstSale[tokenId] == false) {
            /* Platform takes 2.5% on each artist's first sale
            *  All values are multiplied by 100 to deal with floating points
            */
            platformFees = orgFeeInitial;
            sellerFees = sellerFeeInitial;
            blackUnicornFee = blackUniFeeInital;
            //No creator royalty/royalties when artist is minting for the first time
            creatorRoyalty = 0;

            tokenFirstSale[tokenId] = true;
        }   
        
        //Dividing by 100*100 as all values are multiplied by 100
        uint256 toSeller = (msg.value * sellerFees) / FLOAT_HANDLER_TEN_4;
        
        //Dividing by 100*100 as all values are multiplied by 100
        uint256 toCreator = (msg.value*creatorRoyalty) / FLOAT_HANDLER_TEN_4;
        uint256 toPlatform = (msg.value*platformFees) / FLOAT_HANDLER_TEN_4;
        uint256 toBlackUnicorn = (msg.value*blackUnicornFee) / FLOAT_HANDLER_TEN_4;
        
        address tokenCreatorAddress = tokenCreator[tokenId];
        
        payable(tOwner).transfer(toSeller);
        if(toCreator != 0) {
            payable(tokenCreatorAddress).transfer(toCreator);
        }
        
        ethernaal_org.transfer(toPlatform);
        payable(blackUni_org).transfer(toBlackUnicorn);
        
        emit Sold(msg.sender, tOwner, msg.value,tokenId);
    }


    /**
    * This function is used to return all the tokens created by a specific creator
    */
    function tokenCreators(address _creator) external view onlyOwner returns(uint[] memory) {
            return creatorTokens[_creator];
    }

    /**
    * This function is used to whitelist a creator/ an artist on the platform
    */
    function whitelistCreator(address[] memory _creators) public onlyOwner {
        for(uint i = 0; i < _creators.length; i++){
            if(creatorWhitelist[_creators[i]]){
                //Do nothing if address is already whitelisted
            }
            else {
                creatorWhitelist[_creators[i]] = true;
                emit WhitelistCreator(_creators[i]);
            }
        }
        
    }

    /**
    * This function is used to unlist/delist a creator from the platform
    */
    function delistCreator(address[] memory _creators) public onlyOwner {
        for(uint i = 0; i < _creators.length; i++){
            if (creatorWhitelist[_creators[i]] == true){
                creatorWhitelist[_creators[i]] = false;
                emit DelistCreator(_creators[i]);
            }
        }
        
    }

    /**
    * This is a getter function to get the current price of an NFT.
    */
    function getSalePrice(uint256 tokenId) public view returns (uint256) {
        return salePrice[tokenId];
    }

    /**
    * This function returns if a creator is whitelisted on the platform or no
    */
    function isWhitelisted(address _creator) external view returns (bool) {
        return creatorWhitelist[_creator];
    }

    /**
    * This returns the total number of NFTs minted on the platform
    */
    function totalSupply() public view virtual returns (uint256) {
        return _tokenIds.current();
    }
}