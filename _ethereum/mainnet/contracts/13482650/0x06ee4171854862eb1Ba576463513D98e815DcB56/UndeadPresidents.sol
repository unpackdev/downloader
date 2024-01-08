// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";

// Credit goes to CryptoChicks project https://etherscan.io/address/0x1981CC36b59cffdd24B01CC5d698daa75e367e04#code

contract UndeadPresidents is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    uint256 public constant MAX_ELEMENTS = 2850; // Total purchasable tokens
    uint256 public constant PRICE = 80 * 10**15; // .08 eth
    uint256 public constant MAX_BY_MINT = 10; // Maximum purchasable tokens per transaction after presale
    uint256 public constant MAX_BY_MINT_WHITELIST = 10; // Maximum purchasable tokens per account during presale
    uint256 public constant MAX_RESERVE_COUNT = 150; // Total reserved tokens
    
    uint256 public constant LAUNCH_TIMESTAMP = 1635379200; // Monday October 28 2021 00:00:00 GMT+0000

    bool public isSaleOpen = false;
    bool public isPresaleOpen = false;

    mapping(address => bool) private _whiteList;
    mapping(address => uint256) private _whiteListClaimed;
    uint256 private _reservedCount = 0;

    address public constant t1 = 0x71959E2C8337493368c000ef0F1c98c8bB79A7af; // 40%
    address public constant t2 = 0xAe285D3FA6aCE812E3A54f7713E6008F157DfC66; // 40%
    address public constant t3 = 0x2fc75c3bA5B199323C3f919c594D2C061cc689DD; // 10%
    address public constant t4 = 0xb4ce79c7592f53505d551cB57439Fc16a9e0eF5C; // 10%

    string public baseTokenURI;

    event CreateUndeadPresident(uint256 indexed id);

    constructor(string memory baseURI) ERC721("Undead President", "UNP") {
        setBaseURI(baseURI);
    }

    modifier saleIsOpen() {
        if (_msgSender() != owner()) {
            require(isSaleOpen, "Sale is not open");
        }
        _;
    }

    function _totalSupply() internal view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }

    function reserveTokens(address _to, uint256 _count) public onlyOwner {
        require(
            _reservedCount + _count <= MAX_RESERVE_COUNT,
            "Max reserve exceeded"
        );
        uint256 i;
        for (i = 0; i < _count; i++) {
            _reservedCount++;
            _mintAnElement(_to);
        }
    }

    function mint(address _to, uint256 _count) public payable saleIsOpen {
        uint256 total = _totalSupply();
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(total <= MAX_ELEMENTS, "All UndeadPresidents are sold out");
        require(_count <= MAX_BY_MINT, "Exceeds number");
        require(msg.value >= price(_count), "Value below price");

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to);
        }
    }

    function presaleMint(uint256 _count) public payable {
        require(isPresaleOpen, "Presale is not open");
        require(_whiteList[msg.sender], "You are not in the presale whitelist");
        require(_count <= MAX_BY_MINT_WHITELIST, "Incorrect amount to claim");
        require(
            _whiteListClaimed[msg.sender] + _count <= MAX_BY_MINT_WHITELIST,
            "Purchase exceeds max allowed during presale"
        );
        uint256 total = _totalSupply();
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(total <= MAX_ELEMENTS, "All UndeadPresidents are sold out");
        require(msg.value >= price(_count), "Value below price");

        for (uint256 i = 0; i < _count; i++) {
            _whiteListClaimed[msg.sender] += 1;
            _mintAnElement(msg.sender);
        }
    }

    function _mintAnElement(address _to) private {
        uint256 id = _totalSupply();
        _tokenIdTracker.increment();
        _safeMint(_to, id);
        emit CreateUndeadPresident(id);
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

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
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

    function addToWhiteList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Null address found");

            _whiteList[addresses[i]] = true;
            _whiteListClaimed[addresses[i]] > 0
                ? _whiteListClaimed[addresses[i]]
                : 0;
        }
    }

    function addressInWhitelist(address addr) external view returns (bool) {
        return _whiteList[addr];
    }

    function removeFromWhiteList(address[] calldata addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Null address found");

            _whiteList[addresses[i]] = false;
        }
    }

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        uint256 withdrawal = balance.mul(40).div(100);
        _withdraw(t1, withdrawal);
        _withdraw(t2, withdrawal);

        uint256 withdrawalSecondary = balance.mul(10).div(100);
        _withdraw(t3, withdrawalSecondary);
        _withdraw(t4, withdrawalSecondary);
    }

    function _withdraw(address _address, uint256 _amount) private {
        payable(_address).transfer(_amount);
    }
}
