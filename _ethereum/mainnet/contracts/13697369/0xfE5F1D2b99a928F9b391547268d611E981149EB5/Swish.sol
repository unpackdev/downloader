// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

contract Swish is ERC721, ERC721Burnable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _reserveIds;

    // Sales
    bool public saleStart;
    uint256 public price = .04 * 1e18;
    uint256 public constant maxSupply = 9658;
    uint256 public constant maxReserve = 100;
    uint256 public constant maxMint = 10;

    // Settings
    string public baseUri = "https://api.swishdreamsnft.com/json/";
    bool public sealContract;

    // Accesslist
    uint256 public accesslisted;
    mapping (address => bool) public Accesslist;
    bool public accesslistSale;
    bool public openForAccesslist;
    uint256 public maxAccesslist = 1100;

    // Wallets
    address private taylor = 0x0C94f0E39b9Be4595eFfe148faBF350ca23Cc04D;
    address private greg = 0x07e9eD7f69230A07f6995Ad3480F52958609eC22;
    address private sara = 0x00796e910Bd0228ddF4cd79e3f353871a61C351C;
    address private community = 0x4FEc3578988c112bAe15E5f05e38ae7833c84c6f;
    uint256 public walletLimit = 4;
    mapping (address => uint256) public Wallets;

    constructor() ERC721("Swish Dreams", "SWISH") {
        for(uint256 i=maxSupply; i<maxSupply+maxReserve; i++) {
            _reserveIds.increment();
            _safeMint(community, _reserveIds.current() + maxSupply);
        }
    }

    /**
    *   Public functions for minting.
    */
    function mint(uint256 amount) public payable {
        uint256 totalIssued = _tokenIds.current();
        require(msg.value == amount*price && saleStart && totalIssued.add(amount) <= maxSupply && amount <= maxMint);
        if(accesslistSale) {
            require(Accesslist[msg.sender]);
            require(Wallets[msg.sender]+amount <= walletLimit);
            Wallets[msg.sender] += amount;
        }

        for(uint256 i=0; i<amount; i++) {
            _tokenIds.increment();
            _safeMint(msg.sender, _tokenIds.current());
        }
    }

    function addSelfToAccesslist() public {
        require(openForAccesslist && accesslisted.add(1) <= maxAccesslist && !Accesslist[msg.sender]);
        Accesslist[msg.sender] = true;
        accesslisted++;
    }

    function addToAccesslist(address[] memory accesslist) public onlyOwner {
        for(uint256 i=0; i<accesslist.length; i++) {
            if(!Accesslist[accesslist[i]]) {
                Accesslist[accesslist[i]] = true;
                accesslisted++;
            }
        }
    }

    /*
    *   Getters.
    */
    function getCurrentId() public view returns(uint256) {
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

    function setWalletLimit(uint256 _limit) public onlyOwner {
        walletLimit = _limit;
    }

    function setSaleStart(bool _saleStart) public onlyOwner {
        saleStart = _saleStart;
    }

    function setAccessListSale(bool _accesslistSale, bool _openForAccessList, uint256 _maxAccesslist) public onlyOwner {
        accesslistSale = _accesslistSale;
        openForAccesslist = _openForAccessList;
        maxAccesslist = _maxAccesslist;
    }

    function setSealContract() public onlyOwner {
        sealContract = true;
    }

    /*
    *   Money management.
    */
    function withdraw() public payable onlyOwner {

        // Splits
        uint256 saraPay = (address(this).balance / 100) * 15;
        uint256 teamPay = (address(this).balance / 1000) * 415;
        uint256 communityPay = (address(this).balance / 100) * 2;

        // Payouts
        require(payable(sara).send(saraPay));
        require(payable(taylor).send(teamPay));
        require(payable(greg).send(teamPay));
        require(payable(community).send(communityPay));
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
