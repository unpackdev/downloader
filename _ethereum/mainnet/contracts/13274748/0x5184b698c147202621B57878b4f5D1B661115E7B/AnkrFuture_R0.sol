// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC165Upgradeable.sol";

import "./IAnkrFuture.sol";
import "./IOwnable.sol";
import "./IPausable.sol";

contract AnkrFuture_R0 is OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable, ERC721EnumerableUpgradeable, IAnkrFuture {

    address private _operator;
    address private _pool;

    mapping(uint256 => uint256) private _futureMaturity;
    mapping(uint256 => uint256) private _futureAmount;
    uint256 private _idCounter;
    string private _baseUri;

    uint256 private _defaultMaturity;
    uint8 private _decimals;

    event FutureClaimed(uint256 tokenId, uint256 amount);

    // token will be like DOT or KSM
    function initialize(address operator, address pool, string memory token, uint256 defaultMaturity, uint8 initDecimals, string memory baseUri) public override initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        __AnkrFuture_init(operator, pool, token, defaultMaturity, initDecimals, baseUri);
    }

    function __AnkrFuture_init(address operator, address pool, string memory token, uint256 defaultMaturity, uint8 initDecimals, string memory baseUri) internal {
        string memory name = string(abi.encodePacked("Ankr ", token, " Future"));
        string memory symbol = string(abi.encodePacked("a", token, "f"));
        __ERC721_init(name, symbol);
        _baseUri = baseUri;
        _operator = operator;
        _pool = pool;
        _idCounter = 0;
        _decimals = initDecimals;
        _defaultMaturity = defaultMaturity;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function getMaturity(uint256 tokenId) public view override returns (uint256) {
        return _futureMaturity[tokenId];
    }

    function getAmount(uint256 tokenId) public view override returns (uint256) {
        return _futureAmount[tokenId];
    }

    function mint(address to, uint256 maturityBlock, uint256 futureValue) public override onlyPoolOrOperator {
        uint256 mintedTokenId = _idCounter;
        _idCounter += 1;
        _futureAmount[mintedTokenId] = futureValue;
        _futureMaturity[mintedTokenId] = maturityBlock;
        _safeMint(to, mintedTokenId);
    }

    function burn(uint256 tokenId) public override onlyPoolOrOperator {
        require(_futureMaturity[tokenId] <= block.number, "Can't burn future before maturity");
        _burn(tokenId);
    }

    function getDefaultMaturityBlocks() public view override returns (uint256) {
        return _defaultMaturity;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function setDefaultMaturityBlocks(uint256 blocks) public onlyPoolOrOperator {
        _defaultMaturity = blocks;
    }

    modifier onlyPoolOrOperator() {
        require(msg.sender == _pool || msg.sender == _operator, "onlyPoolOrOperator: not allowed");
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId)
        || interfaceId == type(IOwnable).interfaceId
        || interfaceId == type(IPausable).interfaceId
        || interfaceId == type(IERC721EnumerableUpgradeable).interfaceId
        || interfaceId == type(IERC721Upgradeable).interfaceId
        || interfaceId == type(IAnkrFuture).interfaceId;
    }
}
