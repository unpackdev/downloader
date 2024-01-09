// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";
import "./IERC721.sol";
import "./IERC20.sol";
import "./IStaking.sol";

contract FudFarmGenesis is ERC721Enumerable, Ownable {
    using Strings for uint256;
    event Mint(address indexed sender, uint256 startWith, uint256 times);

    mapping (address => bool) public presaleWhitelist;
    

    //supply counters 
    uint256 public total;
    uint256 public presaleTotal = 50;
    uint256 public totalCrop = 500;
    uint256 public totalEth = 277;
    uint256 public presaleMaxWallet = 3;
    uint256 public publicMaxWallet = 7;
    uint256 public totalMax = 777;
    //token Index tracker 

   uint256 public price = 40000000000000000;
   uint256 public cropPrice = 400000000000000000000;

    //string
    string public baseURI;

    //bool
    bool private started;
    bool private presaleStarted; 
    bool private publicStarted;

    //addresses
    IERC721 public fudFarmAddress;
    IERC20 public cropAddress;
    address public contractAddress;
    address public stakeAddress;

    //constructor args 
    constructor(string memory name_, string memory symbol_, string memory baseURI_, address _fudFarmAddress, address _cropAddress, address _stakeAddress) ERC721(name_, symbol_) {
        baseURI = baseURI_;
        fudFarmAddress = IERC721(_fudFarmAddress);
        cropAddress = IERC20(_cropAddress);
        stakeAddress = _stakeAddress;
        contractAddress = address(this);
    }

    //basic functions. 
    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }
    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }
    function addToWhitelist(address[] calldata _addresses) public onlyOwner {
        for (uint256 i=0; i<_addresses.length; i++) {
            presaleWhitelist[_addresses[i]] = true;
        }
    }
    //ERC271 
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "tokenId does not exist.");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : ".json";
    }

    function setPresaleStart(bool _start) public onlyOwner {
        presaleStarted = _start;
    }
    function setStart(bool _start) public onlyOwner {
        started = _start;
    }
    function setPublicStart(bool _start) public onlyOwner {
        publicStarted = _start;
    }

    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 count = balanceOf(owner);
        uint256[] memory ids = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            ids[i] = tokenOfOwnerByIndex(owner, i);
        }
        return ids;
    }

    function presaleMint(uint256 _times, uint256 _cropAmount) public {
        require(presaleStarted, "presale has not started.");
        require(total + _times <= totalCrop, "Exceed crop allocation");
        require(_cropAmount >= _times * cropPrice, "value error, please check price");
        require(presaleWhitelist[msg.sender], "must be on presale whitelist"); 
        require(_times <= presaleMaxWallet, "cannot mint more than 3");
        require(IERC721(contractAddress).balanceOf(msg.sender) <= presaleMaxWallet, "cannot have more than 3");
        cropAddress.transferFrom(msg.sender, address(this), _cropAmount);
        emit Mint(_msgSender(), total+1, _times);
        for(uint256 i=0; i < _times; i++) {
            _mint(_msgSender(), 1 + total++);
        }
    }

    function publicMint(uint256 _times, uint256 _cropAmount) public {
        require(started, "presale has not started.");
        require(total + _times <= totalCrop, "Exceed crop allocation");
        require(_cropAmount >= _times * cropPrice, "value error, please check price");
        uint256 depositBalance = IStaking(stakeAddress).depositsOf(msg.sender).length;
        require(fudFarmAddress.balanceOf(msg.sender) > 0 || depositBalance > 0, "must hold at least 1 fudFarm");
        require(_times <= publicMaxWallet, "cannot mint more than 3");
        require(IERC721(contractAddress).balanceOf(msg.sender) <= publicMaxWallet, "cannot have more than 3");
        cropAddress.transferFrom(msg.sender, address(this), _cropAmount);
        emit Mint(_msgSender(), total+1, _times);
        for(uint256 i=0; i < _times; i++) {
            _mint(_msgSender(), 1 + total++);
        }
    }

    function devMint(uint256 _times) public onlyOwner {
        require(total +_times <= totalCrop, "exceed max supply.");
        emit Mint(_msgSender(), total+1, _times);
        for(uint256 i=0; i<_times; i++) {
            _mint(_msgSender(), 1 + total++);
        }
    }

    function mint(uint256 _times) payable public {
        require(publicStarted, "Land sale ain't started, partner.");
        require(_times > 0 && _times <= publicMaxWallet, "Too many lands");
        require(IERC721(contractAddress).balanceOf(msg.sender) <= publicMaxWallet, "cannot have more than 7");
        require(total + _times <= totalMax, "ALL BOUGHT OUT");
        require(msg.value == _times * price, "value error, please check price.");
        payable(owner()).transfer(msg.value);
        emit Mint(_msgSender(), total+1, _times);
        for(uint256 i=0; i< _times; i++){
            _mint(_msgSender(), 1 + total++);
        }
    }  

    function withdrawCrop() public onlyOwner {
        uint256 cropBalance = cropAddress.balanceOf(address(this));
        cropAddress.transfer(_msgSender(), cropBalance);
    }
}