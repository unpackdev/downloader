pragma solidity ^0.8.0; 

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./IERC721.sol";


contract Cyberdoge is ERC721Enumerable, Ownable {
    using Strings for uint256;
    event Mint (address indexed sender, uint256 startsWith, uint256 times);

    //mappings 
    mapping (address=>bool) public whitelist;

    //uints 
    uint256 public total;
    uint256 public totalCount = 5555;
    uint256 public maxBatch = 5; 
    uint256 public price = 50000000000000000;
    uint256 public maxWhitelistMint = 2; 
    uint256 public maxWallet = 5;

    //addressses
    address public contractAddress;

    //strings 
    string public baseURI;

    //bool 
    bool private started; 
    bool private startWhitelist;

    constructor(string memory _name, string memory _symbol, string memory baseUri_) ERC721(_name, _symbol) {
        baseURI = baseUri_;
        contractAddress = address(this);
    }
    function setBaseUri(string memory _newUri) public onlyOwner {
        baseURI = _newUri;
    }
    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token.");
        
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : '.json';
    }
    function setWhitelist(address[] calldata _user) public onlyOwner {
        for (uint256 i=0; i<_user.length; i++) {
            whitelist[_user[i]] = true;
        }
    }
    function setStart(bool _start) public onlyOwner {
        started = _start;
    }
    function setStartWhitelist(bool _start) public onlyOwner {
        startWhitelist = _start;
    }
    function mintWhitelist(uint256 times) public payable {
        require(whitelist[msg.sender] == true, "must be whitelisted");
        require(IERC721(contractAddress).balanceOf(msg.sender) <= maxWhitelistMint, "max whitelist mints reached");
        require(msg.value == times * price, "value error");
        require(total + times <= totalCount, "max supply reached!");
        require(startWhitelist, "whitelist mint not started!");
        payable(owner()).transfer(msg.value);
        emit Mint(_msgSender(), total+1, times);
        for(uint256 i=0; i<times; i++) {
            _mint(_msgSender(), 1 + total++);
        }
    }
    function devMint(uint256 _times) public onlyOwner {
        emit Mint(_msgSender(), total+1, _times);
        for(uint256 i=0; i<_times; i++) {
            _mint(_msgSender(), 1 + total++);
        }
    }
    function mint(uint256 times) public payable {
        require(started, "not started!");
        require(times > 0 && times <= maxBatch, "too many");
        require(total + times <= totalCount, "max supply reached");
        require(msg.value == times * price, "value error");
        payable(owner()).transfer(msg.value);
        emit Mint(_msgSender(), total+1, times);
        for(uint256 i=0; i<times; i++) {
            _mint(_msgSender(), 1 + total++);
        }
    }
}