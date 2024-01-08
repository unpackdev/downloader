// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";

contract BionicaGirls is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    uint256 public constant MAX_ELEMENTS = 9999;
    uint256 public constant PRICE = 55 * 10**15; // .055 eth
    uint256 public constant MAX_BY_MINT = 25;
    uint256 public constant MAX_BY_MINT_WHITELIST = 10;
    uint256 public constant MAX_RESERVE_COUNT = 150;
    uint256 public constant LAUNCH_TIMESTAMP = 1637100000; // Thu Nov 16 2021 22:00:00 GMT+0000

    bool public isSaleOpen = false;
    bool public isPresaleOpen = false;
    bool public isClaimOpen = false;

    mapping(address => bool) private _whiteList;
    mapping(address => uint256) private _whiteListSpent;

    mapping(address => uint256) private _freeMintClaimed;

    uint256 private _reservedCount = 0;
    uint256 private _reserveAtATime = 50;

    address public constant t1 = 0xeF180bc72D49f1599389DC767c203f6E49E6Bd3F;
    address public constant t2 = 0xC861f8A8669A8fd9852c211F6eFf551541ab2aa2;
    address public constant t3 = 0x076F26b99B75761323266C3a70cC98592cC7e64d;
    address public constant t4 = 0x8d6272e73eb0A8363405aCA8cB519F3B7DCd8aB6;
    address public constant t5 = 0x13Ccc96C26d0Ab532a681EB48344EB795919F6E0;

    string public baseTokenURI;

    event CreateBionicaGirl(uint256 indexed id);

    constructor(string memory baseURI) ERC721("Bionica Girls", "BGC") {
        setBaseURI(baseURI);
    }

    modifier saleIsOpen {
        if (_msgSender() != owner()) {
            require(isSaleOpen, "Sale is not open");
        }
        _;
    }

    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }

    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }

    function reserveTokens() public onlyOwner {
        require(_reservedCount + _reserveAtATime <= MAX_RESERVE_COUNT, "Max reserve exceeded");
        uint256 i;
        for (i = 0; i < _reserveAtATime; i++) {
            _reservedCount++;
            _mintAnElement(msg.sender);
        }
    }

    function mint(address _to, uint256 _count) public payable saleIsOpen {
        uint256 total = _totalSupply();
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(total <= MAX_ELEMENTS, "All Bionica Girls are sold out");
        require(_count <= MAX_BY_MINT, "Exceeds number");
        require(msg.value >= price(_count), "Value below price");

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to);
        }
    }

    function presaleMint(uint256 _count) public payable {
        require(isPresaleOpen, "Presale is not open");
        require(_whiteList[msg.sender], "You are not in whitelist");
        require(_count <= MAX_BY_MINT_WHITELIST, "Incorrect amount to claim");
        require(_whiteListSpent[msg.sender] + _count <= MAX_BY_MINT_WHITELIST, "Purchase exceeds max allowed");
        uint256 total = _totalSupply();
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(total <= MAX_ELEMENTS, "All Bionica Girls are sold out");
        require(msg.value >= price(_count), "Value below price");

        for (uint256 i = 0; i < _count; i++) {
            _whiteListSpent[msg.sender] += 1;
            _mintAnElement(msg.sender);
        }
    }

    function claim() public {
        uint256 _count = 1;
        require(isClaimOpen, "Claiming is not open");
        require(balanceOf(msg.sender) > 0, "You must have at least 1 BGC");
        require(_whiteList[msg.sender], "You are not in white list");
        require(_freeMintClaimed[msg.sender] < 1, "Claiming exceeds max allowed");
        uint256 total = _totalSupply();
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(total <= MAX_ELEMENTS, "All Bionica Girls are sold out");

        for (uint256 i = 0; i < _count; i++) {
            _freeMintClaimed[msg.sender] += 1;
            _mintAnElement(msg.sender);
        }
    }

    function _mintAnElement(address _to) private {
        uint id = _totalSupply();
        _tokenIdTracker.increment();
        _safeMint(_to, id);
        emit CreateBionicaGirl(id);
    }

    function price(uint256 _count) public pure returns (uint256) {
        return PRICE.mul(_count);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function setSaleOpen(bool _isSaleOpen) external onlyOwner {
        isSaleOpen = _isSaleOpen;
    }

    function setPresaleOpen(bool _isPresaleOpen) external onlyOwner {
        isPresaleOpen = _isPresaleOpen;
    }

    function setClaimOpen(bool _isClaimOpen) external onlyOwner {
        isClaimOpen = _isClaimOpen;
    }

    function addToWhiteList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Null address found");

            _whiteList[addresses[i]] = true;
            _whiteListSpent[addresses[i]] > 0 ? _whiteListSpent[addresses[i]] : 0;
        }
    }

    function addressInWhitelist(address addr) external view returns (bool) {
        return _whiteList[addr];
    }

    function removeFromWhiteList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Null address found");

            _whiteList[addresses[i]] = false;
        }
    }

    function setReserveAtATime(uint256 _count) public onlyOwner {
        _reserveAtATime = _count;
    }

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);

        uint256 withdrawal1 = balance.mul(50).div(100);
        uint256 withdrawal2 = balance.mul(14).div(100);
        uint256 withdrawal3 = balance.mul(12).div(100);

        _withdraw(t1, withdrawal1);
        _withdraw(t2, withdrawal2);
        _withdraw(t3, withdrawal2);
        _withdraw(t4, withdrawal3);

        _withdraw(t5, address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        payable(_address).transfer(_amount);
    }
}