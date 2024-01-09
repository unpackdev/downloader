// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import "./ERC721Upgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./SafeMathUpgradeable.sol";
import "./SafeCastUpgradeable.sol";
import "./CountersUpgradeable.sol";

import "./ITodayToken.sol";
import "./ERC721Checkpointable.sol";
import "./OpenSea.sol";

/// @title Contract for Today NFT
/// @custom:security-contact dev@todaynft.xyz
contract TodayToken is
    Initializable,
    ERC721Upgradeable,
    ERC721BurnableUpgradeable,
    ERC721Checkpointable,
    OwnableUpgradeable,
    ITodayToken
{
    using SafeMathUpgradeable for uint256;
    using SafeCastUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    address public minter;
    address public proxyRegistry;

    uint16 public maxSupply;

    string private _baseTokenURI;
    string private _contractURI;

    CountersUpgradeable.Counter private _nextTokenId;

    mapping(string => uint256) private _dateToTokenId;
    mapping(uint256 => string) private _tokenIdToDate;

    modifier onlyMinter() {
        require(msg.sender == minter, "Sender is not minter");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _minter,
        address _proxyRegistry,
        uint16 _maxSupply
    ) public initializer {
        __ERC721_init("Today", "TODAY");
        __ERC721Burnable_init();
        __Ownable_init();

        minter = _minter;
        proxyRegistry = _proxyRegistry;
        maxSupply = _maxSupply;

        _nextTokenId.increment();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable)
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseTokenURI = (bytes(_baseTokenURI).length == 0)
            ? "https://meta.todaynft.xyz/token/"
            : _baseTokenURI;

        return string(abi.encodePacked(baseTokenURI, _tokenIdToDate[tokenId]));
    }

    function mint(string memory _tokenDate) external override onlyMinter returns (uint256) {
        require(maxSupply >= _nextTokenId.current(), "The max supply has been reached");
        require(_dateToTokenId[_tokenDate] == 0, "This date already exists");

        uint256 tokenId = _nextTokenId.current();
        _safeMint(minter, tokenId);

        _dateToTokenId[_tokenDate] = tokenId.toUint16();
        _tokenIdToDate[tokenId] = _tokenDate;

        emit TokenMinted(minter, tokenId);
        _nextTokenId.increment();

        return tokenId;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721Upgradeable, ITodayToken) {
        require(_exists(tokenId), "The tokenId is not exist.");
        super.transferFrom(from, to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721Checkpointable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function contractURI() public view returns (string memory) {
        if (bytes(_contractURI).length == 0) {
            return "https://meta.todaynft.xyz/contract/today";
        }
        return _contractURI;
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        // allows gas less trading on OpenSea
        return super.isApprovedForAll(owner, operator) || isOwnersOpenSeaProxy(owner, operator);
    }

    function isOwnersOpenSeaProxy(address owner, address operator) public view returns (bool) {
        if (proxyRegistry != address(0)) {
            if (block.chainid == 1 || block.chainid == 4) {
                return address(ProxyRegistry(proxyRegistry).proxies(owner)) == operator;
            } else if (block.chainid == 137 || block.chainid == 80001) {
                // on Polygon and Mumbai just try with OpenSea's proxy contract
                // https://docs.opensea.io/docs/polygon-basic-integration
                return proxyRegistry == operator;
            }
        }

        return false;
    }

    function setContractURI(string memory _uri) public onlyOwner {
        _contractURI = _uri;
    }

    function setBaseTokenURI(string memory _uri) public onlyOwner {
        _baseTokenURI = _uri;
    }

    function setMinter(address _minter) public onlyOwner {
        require(_minter != address(0), "Minter address cannot be 0");
        require(_minter != minter, "Minter address cannot be the same as the current minter");
        emit MinterUpdated(_minter);
        minter = _minter;
    }

    function _burn(uint256 tokenId) internal override(ERC721Upgradeable) {
        super._burn(tokenId);
    }

    function burn(uint256 tokenId)
        public
        override(ERC721BurnableUpgradeable, ITodayToken)
        onlyMinter
    {
        require(_exists(tokenId), "The tokenId is not exist.");
        _burn(tokenId);
        emit TokenBurned(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
