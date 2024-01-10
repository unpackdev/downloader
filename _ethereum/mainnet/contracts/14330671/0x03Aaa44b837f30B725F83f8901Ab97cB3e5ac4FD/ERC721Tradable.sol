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
    Counters.Counter internal _nextTokenId;
    bool isMintingActive;
    bool isAllowListActive;
    mapping(address => uint8) private _allowList;
    uint mintPrice = 68000000000000000;
    uint MAX_SUPPLY = 8888;
    address proxyRegistryAddress;

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

    function setAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = numAllowedToMint;
        }
    }

    function getIsAllowListActive() external view returns(bool){
        return isAllowListActive;
    }

    function getIsMintingActive() external view returns(bool) {
        return isMintingActive;
    }

    function setAllowListActive(bool isActive) external onlyOwner {
        isAllowListActive = isActive;
    }

    function setIsMintingActive(bool _isActive) external onlyOwner {
        isMintingActive = _isActive;
    }

    function getIsInAllowList(address _to) external view returns(bool){
        return _allowList[_to] > 0;
    }

    function getMaxNumAllowedToMint(address _addr) external view returns(uint) {
        return _allowList[_addr];
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */
    function mintTo(address _to) external payable {
        require(msg.value == mintPrice, "Not enough ETH sent; check price!");
        require(isMintingActive == true, "Minting not active yet");
        require(_nextTokenId.current() <= MAX_SUPPLY);

        uint256 currentTokenId = _nextTokenId.current();
        _nextTokenId.increment();
        _safeMint(_to, currentTokenId);
    }

    function mintAllowList(uint8 numberOfTokens) external payable {
        require(isAllowListActive, "Allow list is not active");
        require(numberOfTokens <= _allowList[msg.sender], "Exceeded max available to purchase");
        require(_nextTokenId.current() <= MAX_SUPPLY);
        require(msg.value == mintPrice*numberOfTokens, "Not enough ETH sent; check price!");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 currentTokenId = _nextTokenId.current();
            _nextTokenId.increment();
            _safeMint(msg.sender, currentTokenId);
            _allowList[msg.sender]--;
        }
    }

    function mintFromSale(uint8 numberOfTokens) external payable {
        require(isMintingActive == true, "Minting not active yet");
        require(msg.value == mintPrice*numberOfTokens, "Not enough ETH sent; check price!");
        require(_nextTokenId.current() <= MAX_SUPPLY);

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 currentTokenId = _nextTokenId.current();
            _nextTokenId.increment();
            _safeMint(msg.sender, currentTokenId);
        }
    }

    /**
        @dev Returns the total tokens minted so far.
        1 is always subtracted from the Counter since it tracks the next available tokenId.
     */
    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    function withdraw(uint amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    function baseTokenURI() virtual public pure returns (string memory);

    function tokenURI(uint256 _tokenId) override public pure returns (string memory) {
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
