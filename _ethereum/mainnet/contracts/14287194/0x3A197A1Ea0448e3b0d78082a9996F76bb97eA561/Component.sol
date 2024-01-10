// SPDX-License-Identifier: MIT

/**
 * @title Complete the Punks: Component
 * @dev Base component contract for Bodies + Legs
 * @author earlybail.eth | Cranky Brain Labs
 * @notice #GetBodied #LegsFuknGooo
 */

// Directives.
pragma solidity 0.8.9;

// Third-party deps.
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./ERC721.sol";

// Contract.
contract Component is ERC721, ReentrancyGuard, Ownable {
    // Strings.
    using Strings for uint256;

    // Counters.
    using Counters for Counters.Counter;

    // Supply counter.
    Counters.Counter private _supply;

    // Parent Project contract address.
    address public projectAddress;

    // OpenSea Proxy contract address.
    address public openSeaProxyContractAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    // Base URI.
    string public baseURI;

    // Base extension.
    string public baseExtension = "";

    // Provenance hash.
    string public provenanceHash;

    // Mint ID tracking.
    mapping(uint256 => uint256) private _tokenIdCache;
    uint256 public remainingTokenCount = 10000;

    // Token start ID.
    uint256 public tokenStartId = 0;

    // Constructor.
    constructor (
        string memory _name,
        string memory _symbol,
        uint256 _tokenStartId
    ) ERC721(_name, _symbol) {
        // Set token start ID.
        tokenStartId = _tokenStartId;
    }

    // Only allow the project contract as caller.
    modifier onlyProject () {
        require(_msgSender() == projectAddress, "Only the parent Project contract can call this method");
        _;
    }

    // Get base URI.
    function _baseURI () internal view virtual override returns (string memory) {
        return baseURI;
    }

    // Set project address.
    function setProjectAddress (address _newAddr) external onlyOwner {
        projectAddress = _newAddr;
    }

    // Set base URI.
    function setBaseURI (string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    // Set base extension.
    function setBaseExtension (string memory _newBaseExtension) external onlyOwner {
        baseExtension = _newBaseExtension;
    }

    // Set the token start ID.
    function setTokenStartId (uint256 _newId) external onlyOwner {
        tokenStartId = _newId;
    }

    // Set provenance hash.
    function setProvenanceHash (string memory _newHash) external onlyOwner {
        provenanceHash = _newHash;
    }

    // Set OpenSea proxy address.
    // Rinkeby: 0x1E525EEAF261cA41b809884CBDE9DD9E1619573A
    // Mainnet: 0xa5409ec958C83C3f309868babACA7c86DCB077c1
    // Disable: 0x0000000000000000000000000000000000000000
    function setOpenSeaProxyAddress (address _newAddress) external onlyOwner {
        openSeaProxyContractAddress = _newAddress;
    }

    // Token URI.
    function tokenURI (uint256 _tokenId) public view virtual override returns (string memory) {
        // Ensure existence.
        require(_exists(_tokenId), "Query for non-existent token");

        // Cache.
        string memory currentBaseURI = _baseURI();

        // Concatenate.
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), baseExtension))
            : "";
    }

    // Get the current total supply.
    function totalSupply () public view returns (uint256) {
        return _supply.current();
    }

    // Mint.
    function mint (address _to, uint256 _numToMint) public nonReentrant onlyProject {
        _mintLoop(_to, _numToMint);
    }

    // Actually mint.
    function _mintLoop (address _to, uint256 _numToMint) private {
        for (uint256 i = 0; i < _numToMint; i++) {
            // Draw ID.
            uint256 tokenId = drawTokenId();

            // Safe mint.
            _safeMint(_to, tokenId);

            // Increment supply counter.
            _supply.increment();
        }
    }

    // Draw token ID.
    function drawTokenId () private returns (uint256) {
        // Generate an index.
        uint256 num = uint256(
            keccak256(
                abi.encode(
                    _msgSender(),
                    name(),
                    symbol(),
                    blockhash(block.number - 1),
                    block.number,
                    block.timestamp,
                    block.difficulty,
                    tx.gasprice,
                    remainingTokenCount,
                    projectAddress
                )
            )
        );

        // Mod.
        uint256 index = num % remainingTokenCount;

        // If we haven't already drawn this index, use it directly as tokenId.
        // Otherwise, pull the tokenId we cached at this index last time.
        uint256 tokenId = _tokenIdCache[index] == 0
            ? index
            : _tokenIdCache[index];

        // Cache this index with the tail of remainingTokenCount.
        _tokenIdCache[index] = _tokenIdCache[remainingTokenCount - 1] == 0
            ? remainingTokenCount - 1
            : _tokenIdCache[remainingTokenCount - 1];

        // Decrement remaining tokens.
        remainingTokenCount = remainingTokenCount - 1;

        // Return with optional start offset.
        return tokenId + tokenStartId;
    }

    // Public exists.
    function exists (uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    // Override operator approval.
    function isApprovedForAll (address _owner, address _operator) public override view returns (bool) {
        // Skip if disabled.
        if (openSeaProxyContractAddress != address(0)) {
            // Instantiate proxy registry.
            ProxyRegistry proxyRegistry = ProxyRegistry(openSeaProxyContractAddress);

            // Check proxy.
            if (address(proxyRegistry.proxies(_owner)) == _operator) {
                return true;
            }
        }

        // Defer.
        return super.isApprovedForAll(_owner, _operator);
    }
}

// Proxy.
contract OwnableDelegateProxy {}

// Proxy registry.
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
