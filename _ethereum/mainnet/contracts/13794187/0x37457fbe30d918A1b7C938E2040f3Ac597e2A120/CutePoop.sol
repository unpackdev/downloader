// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./IERC721.sol";

contract CutePoop is ERC721, ERC721Burnable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Sales
    bool public saleStart;
    uint256 public price = .04 ether;
    uint256 public constant maxSupply = 9800;
    uint256 private constant maxReserved = 111;
    uint256 private reserveMinted;
    uint256 public constant maxMint = 10;

    // Settings
    string public baseUri = "https://api.cutepoop.art/json/";
    bool public sealContract;

    // Accesslist
    uint256 public maxAccessMint = 3000;
    bool public accesslistSale;
    mapping (uint256 => address) public Collections;
    uint256 public collectionCount;

    // Team
    address sara        = 0x00796e910Bd0228ddF4cd79e3f353871a61C351C;
    address ardie       = 0x2Da0831D81c0626B028516CAAD41b6FDc26F272B;
    address eugene      = 0x714E6A851aBA9F597dB2096C19C6b25cbf235d3C;
    address cutepoopDAO = 0xEDC1f417a409f375F7273DE1D72437EbB59eF2aF;
    address cutepoop    = 0x095deeA5d8CFFA7E48E6048eF3039dc857eE6Cba;


    constructor() ERC721("Cute Poop", "POOP") { }

    /**
    *   Public function for minting.
    */
    function mint(uint256 amount) public payable {
        uint256 totalIssued = _tokenIds.current();
        require(saleStart && totalIssued.add(amount) <= maxSupply+reserveMinted && amount <= maxMint && msg.value == amount*price);

        if(accesslistSale) {
            // Check if we're on any of the approved collections
            bool found;
            for(uint256 i=1; i<=collectionCount; i++) {
                if(IERC721(Collections[collectionCount]).balanceOf(msg.sender) > 0) {
                    found = true;
                    break;
                }
            }
            require(found);
        }

        for(uint256 i=0; i<amount; i++) {
            _tokenIds.increment();
            _safeMint(msg.sender, _tokenIds.current());
        }
    }

    function mintReserved(uint256 amount, address receiver) public onlyOwner {
        uint256 totalIssued = _tokenIds.current();
        require(totalIssued.add(amount) <= (maxSupply + maxReserved));
        require(reserveMinted.add(amount) <= maxReserved);
        for(uint256 i=0; i<amount; i++) {
            _tokenIds.increment();
            _safeMint(receiver, _tokenIds.current());
        }
    }

    /*
    *   Getters.
    */
    function totalSupply() public view returns(uint256) {
        return _tokenIds.current();
    }

    function exists(uint256 tokenId) public view returns(bool) {
        return _exists(tokenId);
    }

    function getByOwner(address _owner) view public returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalTokens = _tokenIds.current();
            uint256 resultIndex;
            for (uint256 t = 1; t <= totalTokens; t++) {
                if (_exists(t) && ownerOf(t) == _owner) {
                    result[resultIndex] = t;
                    resultIndex++;
                }
            }
            return result;
        }
    }

    /*
    *   Owner setters.
    */

    function setBaseUri(string memory _baseUri) public onlyOwner {
        require(!sealContract, "Contract must not be sealed.");
        baseUri = _baseUri;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setAccesslist(bool _accesslistSale) public onlyOwner {
        accesslistSale = _accesslistSale;
    }

    function setSaleStart(bool _saleStart) public onlyOwner {
        saleStart = _saleStart;
    }

    function setSealContract() public onlyOwner {
        sealContract = true;
    }

    function addCollection(address _collection) public onlyOwner {
        collectionCount++;
        Collections[collectionCount] = _collection;
    }

    /*
    *   Money management.
    */
    function withdraw() public payable onlyOwner {
        uint256 each = address(this).balance / 10;
        require(payable(sara).send(each));
        require(payable(ardie).send(each));
        require(payable(eugene).send(each));
        require(payable(cutepoopDAO).send(each));
        require(payable(cutepoop).send(address(this).balance));
    }

    function forwardERC20s(IERC20 _token, uint256 _amount) public onlyOwner {
        _token.transfer(msg.sender, _amount);
    }

    /*
    *   Overrides
    */
    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    receive () external payable virtual {}
}
