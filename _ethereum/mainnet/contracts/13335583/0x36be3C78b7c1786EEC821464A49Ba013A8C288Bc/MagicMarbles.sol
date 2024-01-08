// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Math.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./ERC721Pausable.sol";

contract MagicMarbles is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    uint256 public constant MAX_ELEMENTS_L1 = 4444;
    uint256 public constant MAX_ELEMENTS_L2 = 2222;
    uint256 public constant MAX_ELEMENTS_L3 = 1111;
    uint256 public constant MAX_ELEMENTS_L4 = 777;
    uint256 public constant MAX_ELEMENTS_L5 = 334;
    uint256 public constant MAX_ELEMENTS = MAX_ELEMENTS_L1 + MAX_ELEMENTS_L2 + MAX_ELEMENTS_L3 + MAX_ELEMENTS_L4 + MAX_ELEMENTS_L5;
    uint256 public constant MAX_PRESALE = 200;
    uint256 public constant PRICE = 888 * 10**14;
    uint256 public constant MAX_BY_MINT = 20;
    address public constant TRESURY_ADDRESS = 0xCC4d8114DF84AdE1FA63900aA524C4346c123857;
    uint256 public SMELT_FEE = 100 * 10**14;
    string public baseTokenURI;
    bool public isPresale = false;


    struct Ancestors {
        uint256 fireAncestor;
        uint256 waterAncestor;
    }

    uint256[] public levelsCount;

    mapping(address => bool) public PRESALE_LIST;
    mapping (uint256 => Ancestors) public ancestors;
    mapping (uint256 => uint256) public levels;
    mapping (uint256 => bytes32) public magicSalt;

    event CreateMarble(uint256 indexed id);

    constructor(string memory baseURI) ERC721("MagicMarbles", "MM") {
        levelsCount.push(0);
        levelsCount.push(0);
        levelsCount.push(0);
        levelsCount.push(0);
        levelsCount.push(0);
        levelsCount.push(0);
        setBaseURI(baseURI);
        pause(true);
        isPresale = true;
    }

    modifier saleIsOpen {
        require(totalMinted() <= MAX_ELEMENTS, "Sale end");
        if (_msgSender() != owner()) {
            require(!paused(), "Pausable: paused");
            require(!isPresale, "Cannot mint while presale is ongoing");
        }
        _;
    }
    modifier presaleIsOpen {
        if (_msgSender() != owner()) {
            require(!paused(), "Pausable: paused");
            require(isPresale, "Presale is not running");
        }
        _;
    }

    function _totalSupply() internal view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function getMaxPerLevel(uint256 level) private pure returns (uint256) {
        if (level == 1) { return MAX_ELEMENTS_L1; }
        if (level == 2) { return MAX_ELEMENTS_L2; }
        if (level == 3) { return MAX_ELEMENTS_L3; }
        if (level == 4) { return MAX_ELEMENTS_L4; }
        if (level == 5) { return MAX_ELEMENTS_L5; }
        return 0;
    }

    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }

    function totalMintedPerLevel(uint256 level) public view returns (uint256) {
        return levelsCount[level];
    }

    function totalMinted() public view returns (uint256) {
        return levelsCount[1] + levelsCount[2] + levelsCount[3] + levelsCount[4] + levelsCount[5];
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

    function setSmeltFee(uint256 fee) public onlyOwner {
        SMELT_FEE = fee;
    }

    function setPresale(bool presale) public onlyOwner {
        isPresale = presale;
    }

    function smelt(uint256 item1, uint256 item2) public payable {
        require(
            _exists(item1)
            && _exists(item2) 
            && ownerOf(item1) == msg.sender 
            && ownerOf(item2) == msg.sender,
            "You don't own these tokens"
        );
        require(msg.value >= SMELT_FEE, "Value below price");

        uint256 newLevel = Math.max(levels[item1], levels[item2]) + 1;
        if (newLevel > 5) { newLevel = 5; }

        uint256 total = totalMintedPerLevel(newLevel);
        require(total + 1 <= getMaxPerLevel(newLevel), "Max limit for this Level");

        _burnItem(item1);
        _burnItem(item2);
        uint256 newItem = _mintItem(msg.sender, newLevel);

        Ancestors memory ancest = Ancestors({fireAncestor: item1, waterAncestor: item2});
        ancestors[newItem] = ancest;
    }

    function mint(address _to, uint256 _count) public payable saleIsOpen {
        uint256 total = totalMintedPerLevel(1);
        require(total <= MAX_ELEMENTS);
        require(total + _count <= getMaxPerLevel(1), "Max limit for L1");
        require(_count <= MAX_BY_MINT, "Exceeds number");
        require(msg.value >= price(_count), "Value below price");

        for (uint256 i = 0; i < _count; i++) {
            _mintItem(_to, 1);
        }
    }

    function presaleMint(address _to, uint256 _count) public payable presaleIsOpen {
        uint256 total = totalMintedPerLevel(1);
        require(PRESALE_LIST[msg.sender], "Not qualified for presale");
        require(total <= MAX_PRESALE, "Max presale items limit");
        require(_count <= MAX_BY_MINT, "Exceeds number");
        require(msg.value >= price(_count), "Value below price");

        for (uint256 i = 0; i < _count; i++) {
            _mintItem(_to, 1);
        }
    }

    function _burnItem(uint256 id) private {
        _burn(id);
        uint level = levels[id];
        levelsCount[level] = levelsCount[level] - 1;
    }

    function _mintItem(address _to, uint256 level) private returns (uint256) {
        uint id = _totalSupply();
        _tokenIdTracker.increment();
        _safeMint(_to, id);
        bytes32 ms = keccak256(abi.encodePacked(msg.sender, block.difficulty, block.timestamp, id));
        magicSalt[id] = ms;
        levels[id] = level;
        levelsCount[level] = levelsCount[level] + 1;
        emit CreateMarble(id);
        return id;
    }

    function ownerGrant(address[] calldata recipients) public onlyOwner {
        for (uint256 i = 0; i < recipients.length; i++) {
            _mintItem(recipients[i], 1);
        }
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function pause(bool val) public onlyOwner {
        if (val == true) {
            _pause();
            return;
        }
        _unpause();
    }
    
    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(TRESURY_ADDRESS, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success);
    }

    function addToPresaleList(address[] calldata entries) external onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            PRESALE_LIST[entry] = true;
        }   
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}