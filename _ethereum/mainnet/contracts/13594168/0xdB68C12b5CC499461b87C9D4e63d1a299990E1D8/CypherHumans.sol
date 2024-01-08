// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

interface IProxyRegistry {
    function proxies(address) external view returns (address);
}

contract CypherHumans is ERC721Enumerable, Ownable {
    using ECDSA for bytes32;

    bool public openToAll;

    address private signer;

    uint256 public constant TOTAL_SUPPLY = 8888;
    uint256 public RESERVED_TOKENS = 888;
    uint256 public constant PRICE_PER_TOKEN = 0.088 ether;
    uint256 public constant MAX_PUBLIC_MINT = 8;
    uint256 public currentTokenId;
    uint256 public startingIndex;

    string public PROVENANCE;

    string private _baseURIextended;

    string public contractURI = "ipfs://bafkreif2r53gl2u6kzseje3atnzmntwq7u7nzbms3n2gigxuzxcceebqoq";

    string private constant _defaultURI = "ipfs://bafkreifwut2gsujjbel6hmnlelj62sxttfujx4qg4qpg35p7nfec2ybave";

    // OpenSea's Proxy Registry
    IProxyRegistry public immutable proxyRegistry;

    event SetProvenance(string provenance);
    event SaleOpened();
    event SaleClosed();

    modifier onSaleOpen() {
        require(openToAll, "Sale is not open");
        _;
    }

    /**
     * @dev Set the _startTokenId to the first one after the whitelist
     */
    constructor(
        address _signer,
        uint256 _startTokenId,
        IProxyRegistry _proxyRegistry
    ) ERC721("CypherHumans", "CH") {
        signer = _signer;
        currentTokenId = _startTokenId;
        proxyRegistry = _proxyRegistry;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
        emit SetProvenance(provenance);
    }

    function mintSignature(
        bytes memory _signature,
        uint256 startTokenId,
        uint256 numberOfTokens,
        bool free
    ) public payable {
        require(startTokenId + numberOfTokens <= TOTAL_SUPPLY, "Invalid tokenId");
        if (free) RESERVED_TOKENS -= numberOfTokens;
        else require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

        bool allowed = allowedAddress(msg.sender, startTokenId, numberOfTokens, free, _signature);
        require(allowed, "Invalid signature");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(owner(), msg.sender, startTokenId + i);
        }
    }

    function mint(uint256 amount) public payable onSaleOpen {
        require(PRICE_PER_TOKEN * amount <= msg.value, "Ether value sent is not correct");
        require(totalSupply() + amount + RESERVED_TOKENS <= TOTAL_SUPPLY, "Cannot mint more than TOTAL_SUPPLY!");
        require(currentTokenId + amount + RESERVED_TOKENS < TOTAL_SUPPLY, "Reserved tokenId");
        require(balanceOf(msg.sender) + amount <= MAX_PUBLIC_MINT, "Exceeded max token per wallet");

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(owner(), msg.sender, currentTokenId + i);
        }
        currentTokenId += amount;
    }

    function mintSpecific(uint256[] memory _tokenIds) public payable onSaleOpen {
        require(PRICE_PER_TOKEN * _tokenIds.length <= msg.value, "Ether value sent is not correct");
        require(
            totalSupply() + _tokenIds.length + RESERVED_TOKENS <= TOTAL_SUPPLY,
            "Cannot mint more than TOTAL_SUPPLY!"
        );
        require(balanceOf(msg.sender) + _tokenIds.length <= MAX_PUBLIC_MINT, "Exceeded max token per wallet");

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(_tokenIds[i] < currentTokenId, "Cannot mint above currentTokenId!");
            _safeMint(owner(), msg.sender, _tokenIds[i]);
        }
    }

    function reserve(uint256[] memory tokenIds, address to) public onlyOwner {
        RESERVED_TOKENS -= tokenIds.length;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenIds[i] < TOTAL_SUPPLY, "Invalid tokenId");
            _safeMint(owner(), to, tokenIds[i]);
        }
    }

    function setSigner(address _signer) public onlyOwner {
        require(_signer != address(0), "Signer address cannot be zero");
        signer = _signer;
    }

    function allowedAddress(
        address wallet,
        uint256 startTokenId,
        uint256 numberOfTokens,
        bool freeMint,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 hash = getMessage(wallet, startTokenId, numberOfTokens, freeMint);
        bytes32 messageDigest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        address _signer = ECDSA.recover(messageDigest, signature);
        return _signer == signer;
    }

    function getMessage(
        address wallet,
        uint256 startTokenId,
        uint256 numberOfTokens,
        bool free
    ) public view returns (bytes32) {
        return keccak256(abi.encode(address(this), wallet, startTokenId, numberOfTokens, free));
    }

    function setContractURI(string memory uri) external onlyOwner {
        contractURI = uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return bytes(_baseURIextended).length > 0 ? super.tokenURI(tokenId) : _defaultURI;
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function unmintedTokens() public view returns (uint256[] memory) {
        uint256 tokenCount = TOTAL_SUPPLY - totalSupply();

        uint256 currentIndex = 0;
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < TOTAL_SUPPLY; i++) {
            if (!_exists(i)) {
                tokensId[currentIndex] = i;
                currentIndex++;
            }
        }
        return tokensId;
    }

    function setSaleOpen(bool state) public onlyOwner {
        openToAll = state;
        if (state) {
            emit SaleOpened();
        } else {
            emit SaleClosed();
        }
    }

    /**
     * Set the starting index for the collection
     */
    function setStartingIndex(uint256 index) public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");

        startingIndex = index % TOTAL_SUPPLY;
    }

    function withdraw(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0), "Withdrawal to null address");
        (bool success, ) = to.call{ value: amount }("");
        require(success, "Transfer failed.");
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        if (proxyRegistry.proxies(owner) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }
}
