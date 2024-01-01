// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Strings.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

contract CrazyBlackrock is Ownable, ERC721A, ReentrancyGuard {

    using Address for address;
    using SafeMath for uint256;

    mapping(address => uint256) public mintMap;
    uint256 public maxSupply = 5000;
    uint256 public maxMint = 10;
    uint256 public maxFreeMint = 5;
    uint256 public price = 2380000000000000; //0.00238
    string public _baseTokenURI;
    address payable public immutable shareholderAddress;

    constructor(
        address initialOwner,
        string memory name,
        string memory symbol,
        address payable _shareholderAddress,
        string memory _baseURI
    )Ownable(initialOwner)ERC721A(name, symbol){
        shareholderAddress = _shareholderAddress;
        _baseTokenURI = _baseURI;
    }

    function mint(uint256 _amount) external payable nonReentrant returns (bool) {
        require(totalSupply() <= maxSupply, "MeanLess: exceeds the total amount.");
        require((mintMap[msg.sender] + _amount) <= maxMint, "MeanLess: You have already minted.");
        uint256 _price = 0;
        if ((mintMap[msg.sender] + _amount) > maxFreeMint) {
            if (mintMap[msg.sender] >= maxFreeMint) {
                _price = _amount * price;
            } else {
                _price = (mintMap[msg.sender] + _amount - maxFreeMint) * price;
            }
        }
        require(
            msg.value >= _price,
            "Insufficient funds."
        );
        mintMap[msg.sender] = mintMap[msg.sender] + _amount;
        _safeMint(msg.sender, _amount);
        return true;
    }


    function setPrice(uint96 _maxMint, uint96 _maxFreeMint, uint256 _price) public onlyOwner {
        maxMint = _maxMint;
        maxFreeMint = _maxFreeMint;
        price = _price;
    }

    function setSupply(uint96 _maxSupply) public onlyOwner {
        require(_maxSupply >= maxSupply, "MeanLess: exceeds the total amount.");
        maxSupply = _maxSupply;
    }


    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(shareholderAddress, balance);
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721A)
    returns (string memory)
    {
        require(
            _exists(tokenId),
            "MeanLess: URI query for nonexistent token"
        );
        return string(
            abi.encodePacked(
                _baseTokenURI,
                Strings.toString(tokenId),
                ".json"
            ));
    }
}