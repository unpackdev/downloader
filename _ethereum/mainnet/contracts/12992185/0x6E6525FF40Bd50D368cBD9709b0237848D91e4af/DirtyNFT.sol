//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./IERC20.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

// Allows another user(s) to change contract variables
contract Authorizable is Ownable {

    mapping(address => bool) public authorized;

    modifier onlyAuthorized() {
        require(authorized[_msgSender()] || owner() == address(_msgSender()));
        _;
    }

    function addAuthorized(address _toAdd) onlyOwner public {
        require(_toAdd != address(0));
        authorized[_toAdd] = true;
    }

    function removeAuthorized(address _toRemove) onlyOwner public {
        require(_toRemove != address(0));
        require(_toRemove != address(_msgSender()));
        authorized[_toRemove] = false;
    }

}

// Allows authorized users to add creators/infuencer addresses to the whitelist
contract Whitelisted is Ownable, Authorizable {

    mapping(address => bool) public whitelisted;

    modifier onlyWhitelisted() {
        require(whitelisted[_msgSender()] || authorized[_msgSender()]);
        _;
    }

    function addWhitelisted(address _toAdd) onlyAuthorized public {
        require(_toAdd != address(0));
        whitelisted[_toAdd] = true;
    }

    function removeWhitelisted(address _toRemove) onlyAuthorized public {
        require(_toRemove != address(0));
        require(_toRemove != address(_msgSender()));
        whitelisted[_toRemove] = false;
    }

}

contract DirtyNFT is Ownable, Authorizable, Whitelisted, ERC721Enumerable, ReentrancyGuard  {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    Counters.Counter private _tokenIds;
    Counters.Counter private _NFTIds; //so we can track which NFT's have been added to the system

    struct CreatorInfo {
        address creatorAddress; //wallet address of the NFT creator/infuencer
        string collectionName; // Name of nft creator/influencer/artist
        string nftName; // Name of the actual NFT artwork
        string uri; //address of NFT metadata
        uint256 price; //id of the NFT
        uint256 creatorSplit; //percent to split proceeds with creator/pool;
        uint256 mintLimit; //total amount of this NFT to mint
        bool redeemable; //can be purchased with DIRTYCASH 
        bool purchasable; //can be purchased with Dirty tokens
        bool exists;
    }

    mapping(uint256 => CreatorInfo) public creatorInfo; // Info of each NFT artist/infuencer wallet.
    mapping(string => uint) private mintedCountURI;  // Get total # minted by URI.
    mapping(string => bool) private uriExists;  // Get total # minted by URI.
    mapping(uint256 => uint) private mintedCountID; // Get total # minted by ID.
    mapping(uint256 => bool) private mintInitial; // Whether the creator minted the NFT they added to the system.
    address public farmingContract; // Address of the associated farming contract.
    uint private minted;

    constructor() public ERC721("DirtyNFT", "XXXNFT") {}


    function mint(address recipient, uint256 id) public nonReentrant returns (uint256) {

        require(address(farmingContract) != address(0), "Farming contract address is invalid");
        require(msg.sender == address(farmingContract), "Minting not allowed outside of the farming contract");

        CreatorInfo storage creator = creatorInfo[id];

        require(mintedCountbyURI(creator.uri) < creator.mintLimit, "This NFT has reached its mint limit");

        _tokenIds.increment();
        
        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, creator.uri);

        minted = mintedCountURI[creator.uri];
        mintedCountURI[creator.uri] = minted + 1;

        minted = mintedCountID[id];
        mintedCountID[id] = minted + 1;

        return newItemId;

    }

    //returns the total number of minted NFT
    function totalMinted() public view returns (uint256) {
        return _tokenIds.current();
    }

    //returns the balance of the erc20 token required for validation
    function checkBalance(address _token, address _holder) public view returns (uint256) {
        IERC20 token = IERC20(_token);
        return token.balanceOf(_holder);
    }
    //returns the number of mints for each specific NFT based on URI
    function mintedCountbyURI(string memory tokenURI) public view returns (uint256) {
        return mintedCountURI[tokenURI];
    }

    function mintedCountbyID(uint256 _id) public view returns (uint256) {
        return mintedCountID[_id];
    }

    function setFarmingContract(address _address) public onlyAuthorized {
        farmingContract = _address;
    }

    function getFarmingContract() external view returns (address) {
        return farmingContract;
    }


    //here is where we populate the NFT infuencer/artist info so they can receive proceeds from purchases with $dirty token
    //and split that with the staking pool based on a split % for each NFT (can be all the same by invoking ALL or can be 
    //different base on each NFT [the _mintInital bool can mint the first NFT for the creator's private collection])
    function setCreatorInfo(address _creator, string memory _collectionName, string memory _nftName, string memory _URI, uint256 _price, uint256 _splitPercent, uint256 _mintLimit, bool _redeemable, bool _purchasable, bool _mintInitial) public onlyWhitelisted returns (uint256) {

        require(_creator == address(_msgSender()) || authorized[_msgSender()], "Sender is not creator or authorized"); 
        require(bytes(_collectionName).length > 0, "Creator name string must not be empty");
        require(bytes(_nftName).length > 0, "NFT name string must not be empty");
        require(bytes(_URI).length > 0, "URI string must not be empty");
        require(_price > 0, "Price must be greater than zero");
        require(_mintLimit > 0, "Mint limit must be greater than zero");
        require(_splitPercent >= 0 && _splitPercent <= 100, "Split is not between 0 and 100");
        require(!uriExists[_URI], "An NFT with this URI already exists");

        _NFTIds.increment();

        uint256 _nftid = _NFTIds.current();

        CreatorInfo storage creator = creatorInfo[_nftid];

            creator.creatorAddress = _creator;
            creator.collectionName = _collectionName;
            creator.nftName = _nftName;
            creator.uri = _URI;
            creator.price = _price;
            creator.creatorSplit = _splitPercent;
            creator.mintLimit = _mintLimit;
            creator.redeemable = _redeemable;
            creator.purchasable = _purchasable;
            creator.exists = true;

            uriExists[_URI] = true;

        // Mints the initial NFT for the creator, won't show up on counters and is more so artists can keep
        // one for their own private collection

        if (_mintInitial) { 

        _tokenIds.increment();
        
        uint256 newItemId = _tokenIds.current();
        _mint(_creator, newItemId);
        _setTokenURI(newItemId, creator.uri);

        mintInitial[_nftid] = true;

        }

        return  _nftid; 

    }

    // Get the current NFT counter
    function getCurrentNFTID() public view returns (uint256) {
        return _NFTIds.current();
    }

    // If the creator didn't mint their initial NFT, this will allow it
    function remintInitial(uint256 _nftid) external onlyWhitelisted {

       CreatorInfo storage creator = creatorInfo[_nftid];

       require(creator.creatorAddress == address(_msgSender()) || authorized[_msgSender()], "Sender is not creator or authorized"); 
       require(creator.creatorAddress != address(0), "Creator is the zero address");
       require(!mintInitial[_nftid], "This NFT was already minted when added to the system");

       _tokenIds.increment();
        
        uint256 newItemId = _tokenIds.current();
        _mint(creator.creatorAddress, newItemId);
        _setTokenURI(newItemId, creator.uri);

        mintInitial[_nftid] = true;

    }

    // Get all NFT IDs added by a certain address (seems to only work if more than one address exist in CreatorInfo)
    function getAllNFTbyAddress(address _address) public view returns (uint256[] memory, string[] memory) {
        uint256 totalNFT = _NFTIds.current();
        uint256[] memory ids = new uint256[](totalNFT);
        string[] memory name = new string[](totalNFT);
        uint256 count = 0;

        for (uint256 x = 1; x <= totalNFT; ++x) {

            CreatorInfo storage creator = creatorInfo[x];

            if (creator.creatorAddress == address(_address)) {
                count = count.add(1);
                ids[count] = x;
                name[count] = creator.nftName;
            }

        }

        return (ids,name);
    }

    
    // Set creator address to new, or set to 0 address to clear out the NFT completely
    function setCreatorAddress(uint256 _nftid, address _address) public onlyAuthorized {

        CreatorInfo storage creator = creatorInfo[_nftid];

        require(creator.creatorAddress == address(_msgSender()) || authorized[_msgSender()], "Sender is not creator or authorized");  

        if (_address == address(0)) {

            _NFTIds.decrement();

            uriExists[creator.uri] = false;

            creator.creatorAddress = _address;
            creator.collectionName = "";
            creator.nftName = "";
            creator.uri = "";
            creator.price = 0;
            creator.creatorSplit = 0;
            creator.mintLimit = 0;
            creator.redeemable = false;
            creator.purchasable = false;
            creator.exists = false;

        } else {

            creator.creatorAddress = _address;
        }
    }

    // Get NFT creator/influence/artist info
    function getCreatorInfo(uint256 _nftid) external view returns (address,string memory,string memory,string memory,uint256,uint256,uint256,bool,bool,bool) {
        CreatorInfo storage creator = creatorInfo[_nftid];
        return (creator.creatorAddress,creator.collectionName,creator.nftName,creator.uri,creator.price,creator.creatorSplit,creator.mintLimit,creator.redeemable,creator.purchasable,creator.exists);
    }

    // Get NFT influencer/artist/creator address
    function getCreatorAddress(uint256 _nftid) external view returns (address) {
        CreatorInfo storage creator = creatorInfo[_nftid];
        return creator.creatorAddress;
    }

    // Get NFT URI string
    function getCreatorURI(uint256 _nftid) external view returns (string memory) {
        CreatorInfo storage creator = creatorInfo[_nftid];
        return creator.uri;
    }

    // Set NFT creator name
    function setNFTcollectionName(uint256 _nftid, string memory _name) public onlyAuthorized {

        CreatorInfo storage creator = creatorInfo[_nftid];

        require(creator.creatorAddress == address(_msgSender()) || authorized[_msgSender()], "Sender is not creator or authorized");   
        require(bytes(_name).length > 0, "Creator name string must not be empty");    

        creator.collectionName = _name;
    }

    // Set NFT name
    function setNFTname(uint256 _nftid, string memory _name) public onlyAuthorized {

        CreatorInfo storage creator = creatorInfo[_nftid];

        require(creator.creatorAddress == address(_msgSender()) || authorized[_msgSender()], "Sender is not creator or authorized");   
        require(bytes(_name).length > 0, "NFT name string must not be empty");     

        creator.nftName = _name;
    }

    // Set NFT URI string
    function setNFTUri(uint256 _nftid, string memory _uri) public onlyAuthorized {

        CreatorInfo storage creator = creatorInfo[_nftid];

        require(creator.creatorAddress == address(_msgSender()) || authorized[_msgSender()], "Sender is not creator or authorized");  
        require(bytes(_uri).length > 0, "URI string must not be empty");     
        require(!uriExists[_uri], "An NFT with this URI already exists"); 

        uriExists[creator.uri] = false;

        creator.uri = _uri;

        uriExists[_uri] = true;
    }

     // Set cost of NFT
    function setNFTCost(uint256 _nftid, uint256 _cost) public onlyAuthorized {

        CreatorInfo storage creator = creatorInfo[_nftid];

        require(creator.creatorAddress == address(_msgSender()) || authorized[_msgSender()], "Sender is not creator or authorized");  
        require(_cost > 0, "Price must be greater than zero");

        creator.price = _cost;
    }

    // Get cost of NFT
    function getCreatorPrice(uint256 _nftid) external view returns (uint256) {
        CreatorInfo storage creator = creatorInfo[_nftid];
        return creator.price;
    }

    // Set profit sharing of NFT
    function setNFTSplit(uint256 _nftid, uint256 _split) public onlyAuthorized {

        CreatorInfo storage creator = creatorInfo[_nftid];

        require(creator.creatorAddress == address(_msgSender()) || authorized[_msgSender()], "Sender is not creator or authorized");  
        require(_split >= 0 && _split <= 100, "Split is not between 0 and 100");

        creator.creatorSplit = _split;
    }

    function getCreatorSplit(uint256 _nftid) external view returns (uint256) {
        CreatorInfo storage creator = creatorInfo[_nftid];
        return creator.creatorSplit;
    }

    // Set NFT mint limit
    function setNFTmintLimit(uint256 _nftid, uint256 _limit) public onlyAuthorized {

        CreatorInfo storage creator = creatorInfo[_nftid];

        require(creator.creatorAddress == address(_msgSender()) || authorized[_msgSender()], "Sender is not creator or authorized"); 
        require(_limit > 0, "Mint limit must be greater than zero");

        creator.mintLimit = _limit;
    }

    function getCreatorMintLimit(uint256 _nftid) external view returns (uint256) {
        CreatorInfo storage creator = creatorInfo[_nftid];
        return creator.mintLimit;
    }

    // Set NFT redeemable with DirtyCash
    function setNFTredeemable(uint256 _nftid, bool _redeemable) public onlyAuthorized {

        CreatorInfo storage creator = creatorInfo[_nftid];

        require(creator.creatorAddress == address(_msgSender()) || authorized[_msgSender()], "Sender is not creator or authorized"); 

        creator.redeemable = _redeemable;
    }

    function getCreatorRedeemable(uint256 _nftid) external view returns (bool) {
        CreatorInfo storage creator = creatorInfo[_nftid];
        return creator.redeemable;
    }

    // Set NFT purchasable with Dirty tokens
    function setNFTpurchasable(uint256 _nftid, bool _purchasable) public onlyAuthorized {

        CreatorInfo storage creator = creatorInfo[_nftid];

        require(creator.creatorAddress == address(_msgSender()) || authorized[_msgSender()], "Sender is not creator or authorized"); 

        creator.redeemable = _purchasable;
    }

    function getCreatorPurchasable(uint256 _nftid) external view returns (bool) {
        CreatorInfo storage creator = creatorInfo[_nftid];
        return creator.purchasable;
    }

    function getCreatorExists(uint256 _nftid) external view returns (bool) {
        CreatorInfo storage creator = creatorInfo[_nftid];
        return creator.exists;
    }

    // This will allow to rescue ETH sent by mistake directly to the contract
    function rescueETHFromContract() external onlyOwner {
        address payable _owner = payable(_msgSender());
        _owner.transfer(address(this).balance);
    }

    // Function to allow admin to claim *other* ERC20 tokens sent to this contract (by mistake)
    function transferERC20Tokens(address _tokenAddr, address _to, uint _amount) public onlyOwner {
       
        IERC20(_tokenAddr).transfer(_to, _amount);
    }

    function getIDbyURI(string memory _uri) public view returns (uint256) {
        uint256 totalNFT = _NFTIds.current();
        uint256 nftID = 0;

        for (uint256 x = 1; x <= totalNFT; ++x) {

            CreatorInfo storage creator = creatorInfo[x];

            if (keccak256(bytes(creator.uri)) == keccak256(bytes(_uri))) {   
                nftID = x;
            }

        }

        return nftID;
    }
    
}

