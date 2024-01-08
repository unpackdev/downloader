// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./Address.sol";

contract GeneRoom is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    using Address for address;
  
    uint256 public constant MAX_PER_MINT = 10;
    uint256 public constant MAX_PER_ADDRESS = 20;
    uint256 public constant MAX_ELEMENTS = 8999;
    uint256 public constant OWNER_MAX_ELEMENTS = 299;
    uint64 public ownerNextTokenId = 1;
    uint64 public nextTokenId = 300;
    uint64 public publicTime;
    uint256[] public priceCurve = [800, 2300, 3300, 4300, 5300, 6300, 8999];
    uint256 public currentPriceBucket = 0;

    mapping (address => uint64) public records;

    address private treasureAddress;
    string private baseURI;

    event Minted(address minter, uint256 quantity);
    
    constructor(address _treasureAddress, string memory _baseUri, uint64 _publicTime) ERC721("Gene-Room", "GR") {
        treasureAddress = _treasureAddress;
        baseURI = _baseUri;
        publicTime  = _publicTime;
    }
  
    function mint(uint64 quantity) external payable {
        // Gas optimization
        uint256 startTokenId = nextTokenId;
        require(!msg.sender.isContract(), 'contract not allowed');
        require(block.timestamp > publicTime, "Sale not started");
        require(quantity > 0 && quantity <= MAX_PER_MINT, "invalid quantity");
        require(records[msg.sender] + quantity <= MAX_PER_ADDRESS, "exceed per address limit");

        uint256 endTokenId = nextTokenId + quantity - 1;
        require(endTokenId <= MAX_ELEMENTS, "sold out");

        uint256 invoice = 0;
        uint256 boundry = priceCurve[currentPriceBucket];
        if (startTokenId <= boundry && endTokenId <= boundry) {
            invoice = quantity * 1e16 * currentPriceBucket;
        } else if (startTokenId <= boundry) {
            invoice = (boundry - startTokenId + 1) * 1e16 * currentPriceBucket + 
                (endTokenId - boundry) * 1e16 * (currentPriceBucket + 1);
        } else {
            currentPriceBucket++;
            invoice = quantity * 1e16 * currentPriceBucket;
        }
        require(msg.value >= invoice, "ether value sent is below the price");
        // Never leave money in the contract.
        payable(treasureAddress).transfer(msg.value);

        for (uint256 ind = 0; ind < quantity; ind++) {
            _safeMint(msg.sender, startTokenId + ind);
        }
        records[msg.sender] += quantity;
        nextTokenId += quantity;
        emit Minted(msg.sender, quantity);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory base) external onlyOwner {
        baseURI = base;
    }

    function setPublicTime(uint64 _publicTime) external onlyOwner { 
        publicTime = _publicTime;
    }

    function ownerMint(uint64 quantity) external onlyOwner{
        require(quantity + ownerNextTokenId - 1 <= OWNER_MAX_ELEMENTS , "invalid quantity");
        uint256 _nextTokenId = ownerNextTokenId;
        for (uint256 ind = 0; ind < quantity; ind++) {
            _safeMint(msg.sender, _nextTokenId + ind);
        }
        ownerNextTokenId += quantity;
    }

    function ownerMintToAddresses(address[] memory _addresses) external onlyOwner{
        require(_addresses.length + ownerNextTokenId - 1 <= OWNER_MAX_ELEMENTS , "invalid quantity");

        uint256 _nextTokenId = ownerNextTokenId;
        for (uint256 i; i < _addresses.length; i++) {
            _safeMint(_addresses[i], _nextTokenId+i);
        }
        ownerNextTokenId += uint64(_addresses.length);
    }
    


}