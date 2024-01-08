// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./PaymentSplitter.sol";
import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";

// For Opensea
contract OwnableDelegateProxy {

}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract PixelMisfits is
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    Ownable,
    ContextMixin,
    NativeMetaTransaction,
    PaymentSplitter
{
    using Counters for Counters.Counter;
    using Strings for uint256;
    using SafeMath for uint256;
    using SafeMath for uint16;
    using Strings for string;

    Counters.Counter private _tokenIdCounter;

    struct BulkMint {
        address to;
        uint16[] ids;
    }

    // Opensea
    address proxyRegistryAddress;

    bool public open = false;

    string private ipfsUri = "ipfs://";
    string private ipfsUriSuffix = ".json";
    string private baseURI = "https://api.pixelmisfits.com/v1/";
    string private _contractURI;

    uint32[] private _allTokenIds;
    uint16 public constant MAX_SALE_SUPPLY = 4000;
    uint16 public MAX_MINT_QUANTITY = 10;
    uint256 public UNIT_PRICE = 0.04 ether;

    string public folder = "";

    string public provenance = "";
    string public provenanceURI = "";

    bool public locked = false;

    mapping(address => bool) private _approved;

    modifier notLocked() {
        require(!locked, "Contract has been locked");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress,
        address[] memory payees,
        uint256[] memory shares_
    ) ERC721(_name, _symbol) PaymentSplitter(payees, shares_) {
        proxyRegistryAddress = _proxyRegistryAddress;
        _initializeEIP712(_name);
    }

    fallback() external payable {
        emit PaymentReceived(msg.sender, msg.value);
    }

    // Public methods
    function mint(uint256 quantity) public payable {
        require(open, "Not open to mint yet");
        require(quantity > 0, "Quantity to mint must be at least 1");

        uint256 totalSupplied = totalSupply();

        require(
            totalSupplied < MAX_SALE_SUPPLY,
            "Maximum sale supply amount has been reached"
        );

        // Limit buys
        if (quantity > MAX_MINT_QUANTITY) {
            quantity = MAX_MINT_QUANTITY;
        }

        // Limit buys that exceed MAX_SALE_SUPPLY
        if (quantity.add(totalSupplied) > MAX_SALE_SUPPLY) {
            quantity = MAX_SALE_SUPPLY.sub(totalSupplied);
        }

        uint256 price = getPrice(quantity);

        // Ensure enough ETH
        require(
            msg.value >= price,
            string(
                abi.encodePacked(
                    "Not enough ETH sent, got: ",
                    msg.value.toString(),
                    ", need: ",
                    price.toString()
                )
            )
        );

        for (uint256 i = 0; i < quantity; i++) {
            _safeMintInternal(msg.sender);
        }

        emit PaymentReceived(msg.sender, msg.value);

        // Return any remaining ether after the buy
        uint256 remaining = msg.value.sub(price);

        if (remaining > 0) {
            (bool success, ) = msg.sender.call{value: remaining}("");
            require(success);
            emit PaymentReleased(msg.sender, remaining);
        }
    }

    function getPrice(uint256 quantity) public view returns (uint256) {
        require(quantity <= MAX_SALE_SUPPLY);
        return quantity.mul(UNIT_PRICE);
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

        // Construct IPFS URI or fallback
        if (bytes(folder).length > 0) {
            return
                string(
                    abi.encodePacked(
                        ipfsUri,
                        folder,
                        "/",
                        tokenId.toString(),
                        ipfsUriSuffix
                    )
                );
        }

        // Fallback to centralised URI
        return string(abi.encodePacked(_baseURI(), tokenId.toString()));
    }

    modifier onlyApproved() {
        require(
            owner() == _msgSender() || _approved[_msgSender()],
            "Caller is not the owner or approved"
        );
        _;
    }

    function addApproved(address _approvedAddress) public onlyOwner {
        _approved[_approvedAddress] = true;
    }

    function approvedMint(address _to) public onlyApproved {
        _safeMintInternal(_to);
    }

    function ownerMint(BulkMint[] memory _bulkMint) public onlyOwner {
        require(_bulkMint.length > 0, "Nothing to mint");

        for (uint16 i = 0; i < _bulkMint.length; i++) {
            for (uint16 j = 0; j < _bulkMint[i].ids.length; j++) {
                _safeMintInternal(_bulkMint[i].to, _bulkMint[i].ids[j]);
            }
        }
    }

    function openSale() external onlyOwner {
        open = true;
    }

    function setMaxMintQuanity(uint16 _quantity) external onlyOwner notLocked {
        MAX_MINT_QUANTITY = _quantity;
    }

    function setUnitPrice(uint256 _price) external onlyOwner notLocked {
        UNIT_PRICE = _price;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner notLocked {
        baseURI = baseURI_;
    }

    function setIpfsURI(string memory _ipfsUri) external onlyOwner notLocked {
        ipfsUri = _ipfsUri;
    }

    function setIpfsURISuffix(string memory _suffix)
        external
        onlyOwner
        notLocked
    {
        ipfsUriSuffix = _suffix;
    }

    function setFolder(string memory _folder) external onlyOwner notLocked {
        folder = _folder;
    }

    function lock() external onlyOwner {
        locked = true;
    }

    function emergencyWithdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success);
    }

    function allTokenIds() public view onlyOwner returns (uint32[] memory) {
        return _allTokenIds;
    }

    // Opensea
    function setContractURI(string memory __contractURI) public onlyOwner {
        _contractURI = __contractURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // Opensea
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    // Opensea
    function contractURI() public view virtual returns (string memory) {
        return _contractURI;
    }

    function setProvenanceURI(string memory _provenanceURI)
        external
        onlyOwner
        notLocked
    {
        provenanceURI = _provenanceURI;
    }

    function setProvenance(string memory _provenance)
        external
        onlyOwner
        notLocked
    {
        provenance = _provenance;
    }

    function totalSupply() public view override returns (uint256) {
        uint256 totalSupplied = super.totalSupply();

        if (totalSupplied > 0) {
            return totalSupplied.sub(1);
        }

        return totalSupplied;
    }

    function _safeMintInternal(address to) private {
        uint256 newTokenId = _tokenIdCounter.current();

        while (_exists(newTokenId)) {
            _tokenIdCounter.increment();
            newTokenId = _tokenIdCounter.current();
        }

        _safeMint(to, newTokenId);
        _allTokenIds.push(uint32(newTokenId));
        _tokenIdCounter.increment();
    }

    function _safeMintInternal(address to, uint256 tokenId) private {
        _safeMint(to, tokenId);
        _allTokenIds.push(uint32(tokenId));
    }
}
