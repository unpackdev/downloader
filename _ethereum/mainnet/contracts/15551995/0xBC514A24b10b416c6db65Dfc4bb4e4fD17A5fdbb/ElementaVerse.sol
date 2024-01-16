// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract ElementaVerse is
    ERC721,
    ReentrancyGuard,
    Pausable,
    AccessControl,
    Ownable
{
    using Counters for Counters.Counter;
    using Strings for uint256;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public MAX_NFT;

    Counters.Counter private _tokenIdCounter;
    
    address public proxyRegistryAddress;

    string public baseURI;
    string public unrevealURI;

    constructor(
        string memory name,
        string memory symbol,
        uint256 _MAX_NFT
    ) ERC721(name, symbol) {
        MAX_NFT = _MAX_NFT;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mintTo(address to) public onlyRole(MINTER_ROLE) {
        require(
            _tokenIdCounter.current() + 1 <= MAX_NFT,
            "NFT: Max supply exceeded"
        );

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function setBaseURI(string calldata _tokenBaseURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        baseURI = _tokenBaseURI;
    }

    function setProxyAddress(address _proxyAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        proxyRegistryAddress = _proxyAddress;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();

        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
                : unrevealURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {

        if (operator == address(proxyRegistryAddress)) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setUnrevealURI(string calldata _unrevealURI ) public onlyRole(DEFAULT_ADMIN_ROLE){
        unrevealURI = _unrevealURI;
    }
}
