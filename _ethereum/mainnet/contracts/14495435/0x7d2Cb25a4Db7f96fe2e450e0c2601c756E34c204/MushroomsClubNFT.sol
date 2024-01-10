// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract MushroomsClubNFT is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    bytes32 public whitelistMerkleRoot;
    bytes32 public ogMerkleRoot;
    mapping(address => uint256) public totalPublicMint;
    mapping(address => uint256) public totalWhitelistMint;
    mapping(address => uint256) public totalOgMint;

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;

    uint256 public cost;
    uint256 public maxSupply;
    uint256 public maxPublicMint = 2;
    uint256 public maxWhitelistMint = 2;
    uint256 public maxOgMint = 3;

    bool public paused = true;
    bool public whitelistMintEnabled = false;
    bool public revealed = false;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _cost,
        uint256 _maxSupply,
        string memory _hiddenMetadataUri
    ) ERC721A(_tokenName, _tokenSymbol) {
        setCost(_cost);
        setOgMerkleRoot(
            0xd350ed36a111093848248050cdbeffed0dd1e623499c850404bb2c7685422397
        );
        setWhitelistMerkleRoot(
            0xa51ee589c272faba6ec02676501108090ac69d383818d142fc6d7e9bf3253b01
        );
        maxSupply = _maxSupply;
        setHiddenMetadataUri(_hiddenMetadataUri);
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0, "Invalid mint amount!");
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        _;
    }

    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
        // Verify whitelist requirements
        require(whitelistMintEnabled, "The whitelist sale is not enabled!");
        require(
            (totalWhitelistMint[_msgSender()] + _mintAmount) <=
                maxWhitelistMint,
            "Cannot mint beyond whitelist max mint!"
        );
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf),
            "Invalid proof! You are not in whitelist!"
        );

        totalWhitelistMint[_msgSender()] += _mintAmount;
        _safeMint(_msgSender(), _mintAmount);
    }

    function oglistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
        // Verify whitelist requirements
        require(whitelistMintEnabled, "The whitelist sale is not enabled!");
        require(
            (totalOgMint[_msgSender()] + _mintAmount) <= maxOgMint,
            "Cannot mint beyond OG max mint!"
        );
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, ogMerkleRoot, leaf),
            "Invalid proof! You are not in whitelist!"
        );

        totalOgMint[_msgSender()] += _mintAmount;
        _safeMint(_msgSender(), _mintAmount);
    }

    function mint(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
        require(!paused, "The contract is paused!");
        require(
            (totalPublicMint[_msgSender()] + _mintAmount) <= maxPublicMint,
            "Cannot mint beyond public max mint!"
        );

        totalPublicMint[_msgSender()] += _mintAmount;
        _safeMint(_msgSender(), _mintAmount);
    }

    function teamMint(uint256 _mintAmount, address _receiver)
        public
        mintCompliance(_mintAmount)
        onlyOwner
    {
        _safeMint(_receiver, _mintAmount);
    }

    function walletOfOwner(address _owner)
        public
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

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
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
            "ERC721Metadata: URI query for nonexistent token"
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
                : "";
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxPublicMint(uint256 _amountMint) public onlyOwner {
        maxPublicMint = _amountMint;
    }

    function setMaxWhitelistMint(uint256 _amountMint) public onlyOwner {
        maxWhitelistMint = _amountMint;
    }

    function setMaxOgMint(uint256 _amountMint) public onlyOwner {
        maxOgMint = _amountMint;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setWhitelistMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        whitelistMerkleRoot = _merkleRoot;
    }

    function setOgMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        ogMerkleRoot = _merkleRoot;
    }

    function setWhitelistMintEnabled(bool _state) public onlyOwner {
        whitelistMintEnabled = _state;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(0x467352d897aBAa6E9bd80Ec7759A7ADfe5c3314D).call{
            value: address(this).balance
        }("");
        require(os);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}
