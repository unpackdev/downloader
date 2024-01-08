// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";
import "./IERC721.sol";
import "./IERC20.sol";

contract DoodleApeClub is ERC721Enumerable, Ownable {
    using Strings for uint256;
    event Mint(address indexed sender, uint256 startWith, uint256 times);

    //supply counters 
    uint256 public totalCount = 8888;
    uint256 public MAX_BAYC_CLAIM = 420;
    uint256 public BAYC_CLAIMS = 0; 
    uint256 public MAX_DOODLE_CLAIM = 420;
    uint256 public DOODLE_CLAIMS = 0;
    uint256 public MAX_GM_CLAIM = 420;  
    uint256 public GM_CLAIMS = 0;
    uint256 public REQUIRED_GM_BALANCE = 15000000 ether;
    uint256 public CLAIM_MAX_WALLET = 1;
    uint256 public CURRENT_SUPPLY = 0;
    
    //addresses
    IERC721 public baycAddress;
    IERC721 public doodleAddress;
    IERC20 public gmAddress;
    address public _contractAddress;


    uint256 public maxBatch = 10;
    uint256 public price = 40000000000000000;

    //string
    string public baseURI;

    //bool
    bool private started;
    bool private _presaleStarted;

    //constructor args 
    constructor(string memory name_, string memory symbol_, string memory baseURI_) ERC721(name_, symbol_) {
        _contractAddress = address(this);
        baseURI = baseURI_;
    }
    
    function setContracts(address _baycAddress, address _doodleAddress, address _gmAddress) public onlyOwner {
        baycAddress = IERC721(_baycAddress);
        doodleAddress = IERC721(_doodleAddress);
        gmAddress = IERC20(_gmAddress);
    }

    //basic functions. 
    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }
    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }
    
    function totalSupply() public view virtual override returns (uint256) {
        return CURRENT_SUPPLY;
    }

    //erc721 
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token.");
        
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : '.json';
    }
    function setStart(bool _start) public onlyOwner {
        started = _start;
    }
    function setPresale(bool _start) public onlyOwner {
        _presaleStarted = _start;
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

    function baycClaim(uint256 tokenId) public {
        require(_presaleStarted, "presale not started");
        require(baycAddress.ownerOf(tokenId) == msg.sender, "Not the owner of this bayc");
        require(BAYC_CLAIMS + 1 <= MAX_BAYC_CLAIM, "All bayc reservations claimed");
        require(CURRENT_SUPPLY + 1 <= totalCount, "Total supply reached");
        require(IERC721(_contractAddress).balanceOf(msg.sender) < CLAIM_MAX_WALLET, "Max claims reached");
        BAYC_CLAIMS++;
        emit Mint(_msgSender(), CURRENT_SUPPLY + 1, 1);
        _mint(_msgSender(), 1 + CURRENT_SUPPLY++);
    }

    function doodleClaim(uint256 tokenId) public {
        require(_presaleStarted, "presale not started");
        require(doodleAddress.ownerOf(tokenId) == msg.sender, "Not the owner of this doodle");
        require(DOODLE_CLAIMS + 1 <= MAX_DOODLE_CLAIM, "All Doodle reservations claimed");
        require(CURRENT_SUPPLY + 1 <= totalCount, "Total supply reached");
        require(IERC721(_contractAddress).balanceOf(msg.sender) < CLAIM_MAX_WALLET, "Max claims reached");
        DOODLE_CLAIMS++;
        emit Mint(_msgSender(), CURRENT_SUPPLY + 1, 1);
        _mint(_msgSender(), 1 + CURRENT_SUPPLY++);
    }

    function gmClaim() public {
        require(_presaleStarted, "presale not started");
        require(gmAddress.balanceOf(msg.sender) >= REQUIRED_GM_BALANCE, "must have more gm to claim");
        require(GM_CLAIMS + 1 <= MAX_GM_CLAIM, "All Gm reservations claimed");
        require(CURRENT_SUPPLY + 1 <= totalCount, "Total supply reached");
        require(IERC721(_contractAddress).balanceOf(msg.sender) < CLAIM_MAX_WALLET, "Max claims reached");
        GM_CLAIMS++;
        emit Mint(_msgSender(), CURRENT_SUPPLY + 1, 1);
        _mint(_msgSender(), 1 + CURRENT_SUPPLY++);
    }

    function mint(uint256 _times) payable public {
        require(started, "Sale not started");
        require(_times > 0 && _times <= maxBatch, "Max batch");
        require(CURRENT_SUPPLY + _times <= totalCount, "Total supply reached");
        require(msg.value == _times * price, "value error, please check price.");
        payable(owner()).transfer(msg.value);
        emit Mint(_msgSender(), CURRENT_SUPPLY + 1, _times);
        for(uint256 i=0; i< _times; i++){
            _mint(_msgSender(), 1 + CURRENT_SUPPLY++);
        }
    }  
}