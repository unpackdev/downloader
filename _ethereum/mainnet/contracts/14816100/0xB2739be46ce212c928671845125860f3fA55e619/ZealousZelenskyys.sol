// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";


contract ZealousZelenskyys is ERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    uint256 public constant MAX_ELEMENTS = 8888;
    uint256 public constant PRICE = 0.4 * 1e18;

    mapping(address => bool) public admins;

    address public constant founder = 0x50BAC532a3BC6AF87238aE5F653ED769750B45F8;
    address public constant ukrainianGov = 0x165CD37b4C644C2921454429E7F9358d18A45e14;

    uint256 public startTime;

    string public baseTokenURI;
    uint256[] public remainingIds;
    // We start off with 4 to save gas
    // must be multiple of 2 to work
    uint256 public remainingIdsLength = 4;
    // Similar to remainingIdsLength, but only increases
    uint256 public tokenIdsAvailable = remainingIdsLength;

    // Timers for how long an nftId has been roosted
    mapping(uint256 => uint256) public foreverRoostingTimer;
    mapping(uint256 => uint256) public startOfCurrentRoosting;

    // Whitelist for people to get one free mint (promo)
    mapping(address => bool) public freeMintWhitelist;

    event CreateZelenskyy(uint256 indexed id);
    constructor(uint256  _startTime) ERC721("ZealousZelenskyys", "ZealousZelenskyys") {
        startTime = _startTime;

        admins[founder] = true;
        admins[0xc7e9Ea73c8Db71C373D35EF4c1FCB9bB50C6ADb0] = true;

        for (uint i = 0;i<remainingIdsLength;i++) {
            remainingIds.push(i);
        }
    }

    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }
    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }
    function mint(address _to, uint256 _count) public payable nonReentrant {
        require(startTime < block.timestamp, "Minting not started yet!");

        uint256 total = _totalSupply();
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(total <= MAX_ELEMENTS, "Sale end");
        if (!freeMintWhitelist[msg.sender]) {
            require(msg.value >= price(_count) ||
                    admins[msg.sender], "Value below price");
        } else {
            require(msg.value >= price(_count - 1) ||
                    admins[msg.sender], "Value below price");
            freeMintWhitelist[msg.sender] = false;
        }

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to);
        }
    }
    /// randomise a number
    function expand(uint256 inputVal) public pure returns (uint256 expandedValues) {
        return uint256(keccak256(abi.encode(inputVal)));
    }
    function _mintAnElement(address _to) private {
        require(remainingIdsLength > 0, "no more ids left to mint!");
        uint256 oldTotalSupply = _totalSupply();
        uint256 index = expand(oldTotalSupply * 8) % remainingIdsLength;
        uint256 id = remainingIds[index];

        delete remainingIds[index];
        remainingIds[index] = remainingIds[remainingIdsLength - 1];

        if (tokenIdsAvailable < MAX_ELEMENTS - 1) {
            remainingIds[remainingIdsLength - 1] = tokenIdsAvailable;
            tokenIdsAvailable++;

            if (tokenIdsAvailable < MAX_ELEMENTS) {
                remainingIds.push(tokenIdsAvailable);
                remainingIdsLength++;
                tokenIdsAvailable++;
            }
        } else {
            remainingIdsLength--;
        }

        emit CreateZelenskyy(id);

        _tokenIdTracker.increment();
        _mint(_to, id);
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
    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        uint256 seventyPc = balance * 7000 / 10000;
        _withdraw(ukrainianGov, seventyPc);
        _withdraw(founder, balance - seventyPc);
    }
    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }
    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
    /// @dev overrides transfer function to enable roosting!
    function _transfer(address from, address to, uint256 tokenId) internal override {
        require(startOfCurrentRoosting[tokenId] == 0, "Transfer Error: nft is currently roosting!");
        super._transfer( from, to, tokenId );
    }
    function isNftIdRoosting(uint256 nftId) external view returns (bool) {
        return startOfCurrentRoosting[nftId] > 0;
    }
    function roostNftId(uint256 nftId) external {
        require(ownerOf(nftId) == msg.sender, "owner of NFT isn't sender!");
        require(nftId < MAX_ELEMENTS, "invalid NFTId!");
        require(startOfCurrentRoosting[nftId] == 0, "nft is aready roosting!");

        startOfCurrentRoosting[nftId] = block.timestamp;
    }
    function unroostNftId(uint256 nftId) external {
        require(ownerOf(nftId) == msg.sender, "owner of NFT isn't sender!");
        require(nftId < MAX_ELEMENTS, "invalid NFTId!");
        require(startOfCurrentRoosting[nftId] > 0, "nft isnt currently roosting!");

        foreverRoostingTimer[nftId]+= block.timestamp - startOfCurrentRoosting[nftId];
        startOfCurrentRoosting[nftId] = 0;
    }
    function addToWhiteList(address[] calldata participants) external onlyOwner {
        for (uint i = 0;i<participants.length;i++) {
            freeMintWhitelist[participants[i]] = true;
        }
    }
    function setStartTime(uint256 _newStartTime) public onlyOwner {
        startTime = _newStartTime;
    }
    function setAdmins(address _newAdmin, bool status) public onlyOwner {
        admins[_newAdmin] = status;
    }
}