// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import "./Ownable.sol";
import "./Counters.sol";
import "./ERC721.sol";
import "./ERC2981.sol";
import "./ContextMixin.sol";
import "./IERC721Wrapper.sol";
import "./IERC721OwnableWrapper.sol";
import "./ERC721URIStorage.sol";

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract ERC721Wrapper is Ownable, ContextMixin, ERC721URIStorage, IERC721Wrapper, IERC721OwnableWrapper, ERC2981 {
    using Counters for Counters.Counter;

    // Token parameters
    uint256 public maxSupply;
    Counters.Counter internal mintedCounter;
    Counters.Counter internal burnedCounter;

    // Approved
    address public proxyRegistryAddress;

    // Uri
    string public baseUri;

    // Reserved URIs
    string[] public reservedURIs;
    uint256 public reservedURICounter;

    // Modifiers
    modifier onlyWhenMintable(uint256 amount) {
        require(canMint(amount), 'ERC721: cannot mint that amount of tokens');
        _;
    }

    constructor(string memory name_, string memory symbol_, uint256 maxSupply_, address proxyRegistryAddress_) ERC721(name_, symbol_)
    {
        maxSupply = maxSupply_; // 0 = Inf
        // nextTokenId is initialized to 1, since starting at 0 leads to higher gas cost for the first minter
        mintedCounter.increment();
        burnedCounter.increment();
        proxyRegistryAddress = proxyRegistryAddress_;
    }

    // Core functions
    function mintTo(address to) public override {
        mintTo(to, 1); // onlyOwner check is performed in this call instead
    }

    function mintTo(address to, uint256 amount) public override onlyOwner onlyWhenMintable(amount) {
        for (uint i=1; i<=amount; i++) _safeMint(to, mintedCounter.current());
    }

    function canMint(uint256 amount) public virtual view override returns (bool) {
        return (mintedCounter.current() + amount - 1 <= maxSupply || maxSupply == 0);
    }

    function burn(uint256 tokenId) public override {
        require(_msgSender() == ownerOf(tokenId), 'ERC721: to burn token you need to be its owner!');
        _burn(tokenId);
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        mintedCounter.increment();
        super._mint(to, tokenId);
        if (reservedURIs.length > 0 && reservedURICounter < reservedURIs.length) {
            super._setTokenURI(tokenId, reservedURIs[reservedURICounter]);
            reservedURICounter++;
        }
    }

    function _burn(uint256 tokenId) internal virtual override {
        burnedCounter.increment();
        super._burn(tokenId);
    }

    // Uri functions
    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner {
        super._setTokenURI(tokenId, _tokenURI);
        emit TokenUriSet(tokenId, _tokenURI);
    }

    function delReservedTokenURIs() public onlyOwner {
        require(reservedURICounter == 0, 'ERC721: no longer can delete reserved token URIs, minting already started!');
        delete reservedURIs;
        emit ReservedUrisChanged();
    }

    function addReservedTokenURIs(string[] memory _tokenURIs) public onlyOwner {
        for (uint i=0; i<_tokenURIs.length; i++) reservedURIs.push(_tokenURIs[i]);
        emit ReservedUrisChanged();
    }

    function setBaseURI(string memory _uri) public override onlyOwner {
        baseUri = _uri;
        emit BaseUriSet(_uri);
    }

    // Additional functions
    function totalSupply() external view returns (uint256) {
        return mintedCounter.current() - burnedCounter.current();
    }

    function totalMinted() external view returns (uint256) {
        return mintedCounter.current() - 1;
    }

    function totalBurned() external view returns (uint256) {
        return burnedCounter.current() - 1;
    }

    // Royalty
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external override onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external override onlyOwner {
        _deleteDefaultRoyalty();
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external override onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function resetTokenRoyalty(uint256 tokenId) external override onlyOwner {
        _resetTokenRoyalty(tokenId);
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address _owner, address _operator) public override view returns (bool isOperator) {
        // Whitelist OpenSea proxy contract for easy trading.
        if (proxyRegistryAddress != address(0)) {
            ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
            if (address(proxyRegistry.proxies(_owner)) == _operator) {
                return true;
            }
        }
        
        // Whitelist owner for easier integration
        if (owner() == _operator) {
            return true;
        }

        // otherwise, use the default ERC721.isApprovedForAll()
        return super.isApprovedForAll(_owner, _operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender() internal override view returns (address sender) {
        return ContextMixin.msgSender();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return interfaceId == type(IERC721Wrapper).interfaceId || super.supportsInterface(interfaceId);
    }
}