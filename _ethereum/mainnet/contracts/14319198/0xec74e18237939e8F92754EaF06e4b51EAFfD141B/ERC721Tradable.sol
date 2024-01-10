// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./SafeMath.sol";

import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC721Tradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
abstract contract ERC721Tradable is ERC721, ContextMixin, NativeMetaTransaction, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    /**
     * We rely on the OZ Counter util to keep track of the next available ID.
     * We track the nextTokenId instead of the currentTokenId to save users on gas costs.
     * Read more about it here: https://shiny.mirror.xyz/OUampBbIz9ebEicfGnQf5At_ReMHlZy0tB4glb9xQ0E
     */
    Counters.Counter private _nextTokenId;
    address proxyRegistryAddress;

    mapping(address => bool) public _allowList; // whitelist

    struct MintAddress {
        uint wlNumMinted;   // WL Mint Number
        uint psNumMinted;   // PS Mint Number
    }
    mapping(address => MintAddress) public _addressData;

    uint256 private constant TOTAL_SUPPLY = 2100;

    // whiteList parameter
    uint256 private _wlLimitNum = 2;
    uint256 private _wlPrice = 0.0002 ether;

    // public sale parameter
    uint256 private _psLimitNum = 4;
    uint256 private _psPrice = 0.0004 ether;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC721(_name, _symbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
        // nextTokenId is initialized to 1, since starting at 0 leads to higher gas cost for the first minter
        _nextTokenId.increment();
        _initializeEIP712(_name);
    }

    function setWhiteList(address[] memory addresses) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = true;
        }
    }

    function setWlPrice(uint256 _newPrice) external onlyOwner {
        _wlPrice = _newPrice;
    }

    function setWlMaxNum(uint256 _newNum) external onlyOwner {
        _wlLimitNum = _newNum;
    }

    function setPublicPrice(uint256 _newPrice) external onlyOwner {
        _psPrice = _newPrice;
    }

    function setPublicMaxNum(uint256 _newNum) external onlyOwner {
        _psLimitNum = _newNum;
    }

    function withdrawAll() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    //whiteList mint
    function wlMintTo(uint256 quantity) public payable {
        uint256 ts = totalSupply();

        // Address must be whitelisted.
        require(_allowList[msg.sender], "You are not whitelisted!");

        // cant exceed wallet mint limits
        require(_numberMinted(msg.sender, 1) + quantity <= _wlLimitNum, "can not mint this many");

        // cant exceed max supply
        require(ts + quantity <= TOTAL_SUPPLY, "reached max supply");

        // the fund must be sufficient
        require (_wlPrice * quantity <= msg.value, "Fund is not sufficient!");

        // record add number
        MintAddress memory addressData = _addressData[msg.sender];
        _addressData[msg.sender] = MintAddress(
            addressData.wlNumMinted + quantity,
            addressData.psNumMinted
        );
        for (uint256 i = 1; i <= quantity; i++) {
            //uint256 currentTokenId = _nextTokenId.current();
            _nextTokenId.increment();
            _safeMint(msg.sender, ts + i);
        }
        //_safeMint(msg.sender, currentTokenId);
    }

    //public sale mint
    function psMintTo(uint256 quantity) public payable {
        uint256 ts = totalSupply();

        // cant exceed wallet mint limits
        require(_numberMinted(msg.sender, 2) + quantity <= _psLimitNum, "can not mint this many");

        // cant exceed max supply
        require(ts + quantity <= TOTAL_SUPPLY, "reached max supply");

        // the fund must be sufficient
        require (_psPrice * quantity <= msg.value, "Fund is not sufficient!");

        // record add number
        MintAddress memory addressData = _addressData[msg.sender];
        _addressData[msg.sender] = MintAddress(
            addressData.wlNumMinted,
            addressData.psNumMinted + quantity
        );
        for (uint256 i = 1; i <= quantity; i++) {
            //uint256 currentTokenId = _nextTokenId.current();
            _nextTokenId.increment();
            _safeMint(msg.sender, ts + i);
        }
        //_safeMint(msg.sender, currentTokenId);
    }

    // validate address minted number
    function _numberMinted(address owner, uint from) private view returns (uint256) {
        require(
            owner != address(0),
            "ERC721A: number minted query for the zero address"
        );
        if (from == 1) {
            return uint256(_addressData[owner].wlNumMinted);
        } else {
            return uint256(_addressData[owner].psNumMinted);
        }
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */
    function mintTo(address _to, uint256 quantity) public onlyOwner {
        uint256 ts = totalSupply();
        for (uint256 i = 1; i <= quantity; i++) {
            _nextTokenId.increment();
            _safeMint(_to, ts + i);
        }
    }

    /**
        @dev Returns the total tokens minted so far.
        1 is always subtracted from the Counter since it tracks the next available tokenId.
     */
    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    function baseTokenURI() virtual public view returns (string memory);

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }
}
