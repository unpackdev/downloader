// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract SkullsInLove is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    bytes32 public merkleRoot;
    bytes32 public merkleRootHof;
    mapping(address => bool) public allowlistMinted;
    mapping(address => bool) public hofMinted;

    string public uriPrefix = '';
    string public uriSuffix = '.json';
    string public hiddenMetadataUri;

    uint256 public maxSupply;
    uint256 public mintPrice;
    uint256 public maxMintAmountPerTx;
    uint256 public maxMintAmountForHof;

    bool public isAllowlistOpen;
    bool public isSaleOpen;
    bool public revealed;

    constructor(
        string memory _nftName,
        string memory _nftSymbol,
        string memory _hiddenMetadataUri,
        uint256 _maxSupply,
        uint256 _forDev,
        uint256 _mintPrice,
        uint256 _maxMintAmountPerTx,
        uint256 _maxMintAmountForHof
    ) ERC721A(_nftName, _nftSymbol) {
        maxSupply = _maxSupply;
        mintPrice = _mintPrice;
        maxMintAmountPerTx = _maxMintAmountPerTx;
        maxMintAmountForHof = _maxMintAmountForHof;
        setHiddenMetadataUri(_hiddenMetadataUri);

        _safeMint(owner(), _forDev);
    }

    modifier mintCompliance(uint256 _mintAmount, uint256 _maxMintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= _maxMintAmount,
            'Invalid mint amount!'
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            'Max supply exceeded!'
        );
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= mintPrice * _mintAmount, 'Insufficient funds!');
        _;
    }

    function mintHOF(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        external
        payable
        mintCompliance(_mintAmount, maxMintAmountForHof)
        mintPriceCompliance(_mintAmount)
    {
        require(isAllowlistOpen, 'AL sale is closed!');
        require(!hofMinted[_msgSender()], 'Address already minted!');
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, merkleRootHof, leaf),
            'Invalid proof!'
        );

        hofMinted[_msgSender()] = true;

        _safeMint(_msgSender(), _mintAmount);
    }

    function mintAL(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        external
        payable
        mintCompliance(_mintAmount, maxMintAmountPerTx)
        mintPriceCompliance(_mintAmount)
    {
        require(isAllowlistOpen, 'AL sale is closed!');
        require(!allowlistMinted[_msgSender()], 'Address already minted!');
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            'Invalid proof!'
        );

        allowlistMinted[_msgSender()] = true;

        _safeMint(_msgSender(), _mintAmount);
    }

    function mint(uint256 _mintAmount)
        external
        payable
        mintCompliance(_mintAmount, maxMintAmountPerTx)
        mintPriceCompliance(_mintAmount)
    {
        require(isSaleOpen, 'Sale is closed!');

        _safeMint(_msgSender(), _mintAmount);
    }

    function mintForAddress(uint256 _mintAmount, address _receiver)
        external
        mintCompliance(_mintAmount, maxMintAmountPerTx)
        onlyOwner
    {
        _safeMint(_receiver, _mintAmount);
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = _startTokenId();
        uint256 ownedTokenIndex = 0;
        address latestOwnerAddress;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply
        ) {
            TokenOwnership memory ownership = _ownerships[currentTokenId];

            if (!ownership.burned && ownership.addr != address(0)) {
                latestOwnerAddress = ownership.addr;
            }

            if (latestOwnerAddress == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setMerkleRootHof(bytes32 _merkleRootHof) external onlyOwner {
        merkleRootHof = _merkleRootHof;
    }

    function setUriPrefix(string memory _uriPrefix) external onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) external onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        external
        onlyOwner
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setIsAllowlistOpen(bool _state) external onlyOwner {
        isAllowlistOpen = _state;
    }

    function setIsSaleOpen(bool _state) external onlyOwner {
        isSaleOpen = _state;
    }

    function setRevealed(bool _state) external onlyOwner {
        revealed = _state;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ''
        );
        require(success, 'Failed to withdraw');
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            'ERC721Metadata: URI query for nonexistent token'
        );

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();

        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : '';
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}
