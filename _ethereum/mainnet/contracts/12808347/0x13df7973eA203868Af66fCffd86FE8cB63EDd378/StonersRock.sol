// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/\@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@..@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@....(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@......(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,.......@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&.........@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@........../@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@\....(@@@@@@@@@@@@@@@@...........@@@@@@@@@@@@@@@@)..../@@@@@@@@@@@@
// @@@@@@@@@@@@@@@..........@@@@@@@@@%...........@@@@@@@@@@,........,@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@.............@@@@@&...........@@@@@@.............@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@...............@@@...........@@@..............#@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@&...............@...........@...............@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@#.......................................@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@...................................@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@.............................@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@&%%%.....................&%&&@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@(...........................................%@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@\................................................./@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@#,.......&#,...............&#,........,#@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.....&@/.@@......@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@..,@@@@@/.@@@@@%..,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/.@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//
// Stoners Rock
// Smoke weed every day.
//
// 10,420 on-chain Rock NFTs
// https://stonersrock.com
//
// Twitter: https://twitter.com/mystoners
//
// Produced by:     @sircryptos
// Art by:          @linedetail
// Code by:         @altcryp
//
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

contract StonersRock is ERC721Burnable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _reserveIds;

    // Team
    address public constant sara        = 0x00796e910Bd0228ddF4cd79e3f353871a61C351C;     // @sarasioux
    address public constant shaun       = 0x7fc55376D5A29e0Ee86C18C81bb2fC8F9f490E50;     // @sircryptos
    address public constant mark        = 0xB58Fb5372e9Aa0C86c3B281179c05Af3bB7a181b;     // @linedetail
    address public constant community   = 0xd83Dd8A288270512b8A46F581A8254CD971dCb09;     // stonersrock.eth

    // Rocks
    string public imageTx = '';
    string public metadataTx = '';
    string public baseUri;

    // Sales
    uint256 public saleStartBlock = 120250457;
    uint256 public constant rockPrice = 42069000000000000; //0.042069 ETH
    uint public constant maxRockPurchase = 20;
    uint public constant maxRockSupply = 10420;
    uint public constant maxReserveSupply = 420;

    // Internals
    event RockMinted(address minter, address receiver, uint256 tokenId);

    // Constructor
    constructor() ERC721("Stoners Rock", "ROCK") {
        _tokenIds._value = maxReserveSupply;
    }

    /*
    *   Getters.
    */
    function getCurrentRockId() public view returns(uint256 currentRockId) {
        currentRockId = _tokenIds.current();
        return currentRockId;
    }

    function getCurrentReserveId() public view returns(uint256 currentRockId) {
        currentRockId = _reserveIds.current();
        return currentRockId;
    }

    function exists(uint256 tokenId) public view returns(bool) {
        return _exists(tokenId);
    }

    function saleStarted() public view returns (bool) {
        return block.number >= saleStartBlock;
    }

    /*
    *   Mint reserved rocks for giveaways and the teams.
    */
    function reserveRocks(uint256 numberOfTokens) public onlyOwner {
        reserveRocks(numberOfTokens, msg.sender);
    }

    function reserveRocks(uint256 numberOfTokens, address receiver) public onlyOwner {
        uint256 reserved = _reserveIds.current();
        require(numberOfTokens <= maxRockPurchase, "Maximum 20!");
        require(reserved.add(numberOfTokens) <= maxReserveSupply, "Exceeding max supply!");
        for (uint i = 0; i < numberOfTokens; i++) {
            _reserveIds.increment();
            uint256 tokenId = _reserveIds.current();
            _safeMint(receiver, tokenId);
            emit RockMinted(msg.sender, receiver, tokenId);
        }
    }

    /**
    *   Public function for minting a rock and enforcing requirements.
    */
    function mintRock(uint numberOfTokens) public payable {
        mintRock(numberOfTokens, msg.sender);
    }

    function mintRock(uint numberOfTokens, address receiver) public payable {
        uint256 totalIssued = _tokenIds.current();
        require(saleStarted(), "Wait for the sale to start!");
        require(numberOfTokens <= maxRockPurchase, "Maximum 20!");
        require(totalIssued.add(numberOfTokens) <= maxRockSupply, "Exceeding max supply!");
        require(rockPrice.mul(numberOfTokens) <= msg.value, "Dont fuck around.");

        for(uint i = 0; i < numberOfTokens; i++) {
            _tokenIds.increment();
            uint256 tokenId = _tokenIds.current();
            _safeMint(receiver, tokenId);
            emit RockMinted(msg.sender, receiver, tokenId);
        }
    }

    /**
    *   External function for getting all rocks by a specific owner.
    */
    function getRocksByOwner(address _owner) view public returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalTokens = _tokenIds.current();
            uint256 resultIndex = 0;
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
        baseUri = _baseUri;
    }

    function setSaleStartBlock(uint256 _saleStartBlock) public onlyOwner {
        require(!saleStarted(), 'Start block cannot be changed once sale has started.');
        saleStartBlock = _saleStartBlock;
    }

    function setProvenance(string memory _imageTx, string memory _metadataTx) public onlyOwner {
        imageTx = _imageTx;
        metadataTx = _metadataTx;
    }

    /*
    *   Money management.
    */
    function withdraw() public payable onlyOwner {
        uint256 _each = address(this).balance / 4;
        require(payable(sara).send(_each));
        require(payable(shaun).send(_each));
        require(payable(mark).send(_each));
        require(payable(community).send(_each));
    }

    function forwardERC20s(IERC20 _token, uint256 _amount) public onlyOwner {
        _token.transfer(msg.sender, _amount);
    }

    /*
    *   On chain storage.
    */
    function uploadRockImages(bytes calldata s) external onlyOwner {}
    function uploadRockAttributes(bytes calldata s) external onlyOwner {}

    /*
    *   Overrides
    */
    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    receive () external payable virtual {}
}
