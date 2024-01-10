// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";



/**
 * @dev The OpenSea interface system that allows for approval fee skipping.
 */
contract OwnableDelegateProxy {}
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract GentlemenClub is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;

    using Counters for Counters.Counter;
    Counters.Counter private supply;

    string public uriPrefix = '';
    string public uriSuffix = '.json';
    string public hiddenMetadataUri;
    string public provenanceHash = '';

    uint256 public cost = 0.04 ether;
    uint256 public maxSupply = 10000;
    uint256 public maxMintAmountPerTx = 10;
    uint256 public maxAllowlistMintAmount = 3;

    bytes32 public allowlistMerkleRoot;

    bool public isPaused = true;
    bool public isRevealed = false;
    bool public isAllowlistEnabled = true;

    address public proxyRegistryAddr;

    mapping(address => bool) public projectProxy;
    mapping(address => uint256) public addressMintedBalance;
    mapping(address => bool) public addressToRegistryDisabled;

    constructor(address _proxyRegistryAddr) ERC721('Gentlemen Club', 'GNTLMN') {
        proxyRegistryAddr = _proxyRegistryAddr;
        setHiddenMetadataUri('ipfs://QmZ4MJFUbnzCXrGJCtamnqSDhiCvwDuzA7D8wfPbmTJev8/hidden.json');
    }

    modifier mintCompliance(uint256 _mintAmount) {
        if (_msgSender() != owner()) {
            require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount');
        }
        require(_msgSender() == tx.origin, 'Contracts not allowed');
        require(supply.current() + _mintAmount <= maxSupply, 'Max supply exceeded');
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= cost * _mintAmount, 'Insufficient funds');
        _;
    }

    modifier mintPauseCompliance() {
        require(!isPaused, 'The contract is paused');
        _;
    }

    modifier mintPublic() {
        require(!isAllowlistEnabled, 'Allowlist minting in progress');
        _;
    }

    modifier allowlistMintCompliance(uint256 _mintAmount, bytes32[] calldata _merkleProof) {
        require(isAllowlistEnabled && isAllowlisted(_merkleProof));

        uint256 ownerMintedCount = addressMintedBalance[_msgSender()];

        require(
            ownerMintedCount + _mintAmount <= maxAllowlistMintAmount,
            'max NFT per address exceeded'
        );
        _;
    }

    // ============ PUBLIC FUNCTIONS ============

    function totalSupply() external view returns (uint256) {
        return supply.current();
    }

    function mint(uint256 _mintAmount)
        external
        payable
        mintPauseCompliance
        mintPublic
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
        nonReentrant
    {
        _mintLoop(_msgSender(), _mintAmount);
    }

    function allowlistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        external
        payable
        mintPauseCompliance
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
        allowlistMintCompliance(_mintAmount, _merkleProof)
        nonReentrant
    {
        _mintLoop(_msgSender(), _mintAmount);
    }

    function flipProjectProxyState(address _proxyAddress) public onlyOwner {
        projectProxy[_proxyAddress] = !projectProxy[_proxyAddress];
    }

    function isAllowlisted(bytes32[] calldata _merkleProof) public view returns (bool) {
        require(
            MerkleProof.verify(
                _merkleProof,
                allowlistMerkleRoot,
                keccak256(abi.encodePacked(_msgSender()))
            ),
            'Address is not allowlisted'
        );

        return true;
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1; // loop through all tokens from 1 to (maxSupply - 1)
        uint256 ownedTokenIndex = 0; // index for returned array

        // Early return if all tokens owned by this address have been found
        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

        if (isRevealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
                : '';
    }

    /**
     * @notice Allow a user to disable the pre-approval if they believe OS to not be secure.
     */
    function toggleRegistryAccess() public virtual {
        addressToRegistryDisabled[_msgSender()] = !addressToRegistryDisabled[_msgSender()];
    }

    // ============ OWNER-ONLY ADMIN FUNCTIONS ============

    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        mintCompliance(_mintAmount)
        onlyOwner
        nonReentrant
    {
        _mintLoop(_receiver, _mintAmount);
    }

    function setIsRevealed(bool _state) external onlyOwner {
        isRevealed = _state;
    }

    function setMaxAllowlistMintAmount(uint256 _limit) external onlyOwner {
        maxAllowlistMintAmount = _limit;
    }

    function setAllowlistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        allowlistMerkleRoot = _merkleRoot;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setCost(uint256 _cost) external onlyOwner {
        cost = _cost;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) external onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setUriPrefix(string memory _uriPrefix) external onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) external onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setProvenanceHash(string memory _provenanceHash) external onlyOwner {
        provenanceHash = _provenanceHash;
    }

    function setIsPaused(bool _state) external onlyOwner {
        isPaused = _state;
    }

    function setIsAllowlistEnabled(bool _state) external onlyOwner {
        isAllowlistEnabled = _state;
    }

    function setProxyRegistryAddr(address _proxyRegistryAddr) external onlyOwner {
        proxyRegistryAddr = _proxyRegistryAddr;
    }

    /**
     * @notice Allow user's OpenSea proxy accounts to enable gas-less listings
     * @notice Eenable extendibility for the project
     * @param _owner      The active owner of the token
     * @param _operator    The origin of the action being called
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddr);

        if (
            (address(proxyRegistry.proxies(_owner)) == _operator &&
                !addressToRegistryDisabled[_owner]) || projectProxy[_operator]
        ) {
            return true;
        }

        return super.isApprovedForAll(_owner, _operator);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}('');
        require(success, 'Failed to withdraw');
    }

    // ============ INTERNAL FUNCTIONS ============

    function _mintLoop(address _receiver, uint256 _mintAmount) internal {
        for (uint256 i = 0; i < _mintAmount; i++) {
            addressMintedBalance[_msgSender()]++;
            supply.increment();
            _safeMint(_receiver, supply.current());
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}
