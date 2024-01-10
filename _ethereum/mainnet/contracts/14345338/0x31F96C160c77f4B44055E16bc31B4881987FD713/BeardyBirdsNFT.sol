// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/// Beardy Birds by Out of the Dark Cave
/// https://outofthedarkcave.art
/// https://beardy-birds.outofthedarkcave.art

import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";

/// @custom:security-contact outofthedarkcave@pm.me
contract BeardyBirdsNFT is
    ERC721A,
    ReentrancyGuard,
    Ownable
{
    string public baseURI = '';
    string public uriSuffix = '.json';

    uint256 public cost;
    uint256 public maxSupply;
    uint256 public maxMintAmountPerTx;

    bool public paused = true;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _cost,
        uint256 _maxSupply,
        uint256 _maxMintAmountPerTx
    ) ERC721A(_tokenName, _tokenSymbol) {
        cost = _cost;
        maxSupply = _maxSupply;
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setCost(uint256 _cost) external onlyOwner {
        cost = _cost;
    }

    function setUriSuffix(string memory _uriSuffix) external onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        external
        onlyOwner
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setPaused(bool _state) external onlyOwner {
        paused = _state;
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
        require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        if (msg.sender != owner()) {
            require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
        }
        _;
    }

    function mint(uint256 _mintAmount)
        external
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
        require(!paused, 'The contract is paused!');
        _safeMint(_msgSender(), _mintAmount);
    }

    function mintForAddress(uint256 _mintAmount, address _receiver)
        external
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

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
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

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            'ERC721URIStorage: URI query for nonexistent token'
        );

        string memory base = _baseURI();

        if (bytes(base).length == 0) {
            return '';
        }

        return string(abi.encodePacked(base, Strings.toString(tokenId), uriSuffix));
    }

    function withdraw() external nonReentrant onlyOwner {
        Address.sendValue(payable(owner()), address(this).balance);
    }
}
