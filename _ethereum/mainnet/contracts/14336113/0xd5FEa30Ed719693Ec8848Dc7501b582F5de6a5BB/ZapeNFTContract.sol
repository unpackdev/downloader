pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

contract ZombieZape is ERC721A, Ownable, ReentrancyGuard {
    using Address for address;
    using SafeMath for uint256;
    using Strings for uint256;

    string public baseURI;
    uint256 public mintPrice = 0.06 ether;
    uint256 public maxSupply = 3333;
    bool public publicSaleLive;
    uint256 public maxMint = 10;
    uint256 public maxDev = 11;
    uint256 public devMinted;
    mapping(address => uint256) addressMinted;
    mapping(address => bool) OGAddresses;

    constructor() ERC721A("Zombie Apes", "Zape") {}

    function mint(uint256 amount) external payable nonReentrant {
        address _sender = msg.sender;
        require(publicSaleLive, "Public mint is not live");
        require(amount > 0, "Amount to mint is 0");
        require(totalSupply()+ amount <= maxSupply, "Sold out!");
        addressMinted[_sender] += amount;
        require(addressMinted[_sender] <= maxMint, "Max Mint per wallet is 10");
        if (!OGAddresses[_sender]) require(msg.value == mintPrice.mul(amount), "Must provide exact required ETH");
        _safeMint(_sender, amount);
    }

    function changeMaxMint(uint56 _new) external onlyOwner {
        maxMint = _new;
    }
 
    function setPublicSale(bool _status) external onlyOwner {
        publicSaleLive = _status;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setbaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to send ether");
    }

    function devMint(uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= maxSupply, "Sold out!");
        devMinted += amount;
        require(devMinted < maxDev, "Max Minted");
        _safeMint(msg.sender, amount);
    }

    function addOG(address [] calldata _users) public onlyOwner{
        uint256 length = _users.length;
        for (uint256 i; i < length; i++ ){
            OGAddresses[_users[i]] = true;
        }
    }

    function isOG(address _user) public view returns (bool _isOG) {
        _isOG = OGAddresses[_user];
    }

    function walletOfOwner(address address_) public virtual view returns (uint256[] memory) {
        uint256 _balance = balanceOf(address_);
        uint256[] memory _tokens = new uint256[] (_balance);
        uint256 _index;
        uint256 _loopThrough = totalSupply();
        for (uint256 i = 0; i < _loopThrough; i++) {
            bool _exists = _exists(i);
            if (_exists) {
                if (ownerOf(i) == address_) { _tokens[_index] = i; _index++; }
            }
            else if (!_exists && _tokens[_balance - 1] == 0) { _loopThrough++; }
        }
        return _tokens;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }
}