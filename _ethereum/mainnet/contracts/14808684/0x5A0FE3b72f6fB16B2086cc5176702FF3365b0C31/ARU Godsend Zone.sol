// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract ARUGodsendZone is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public stage;
    mapping(uint256 => mapping(address => uint256)) public whitelistClaimed;

    string public uriPrefix = "";
    string public uriSuffix = ".json";

    uint256 public maxSupply;

    bool public paused = true;
    uint256 public whitelistMintStart = 1654048800;
    uint256 public whitelistMintEnd = 1655258400;

    mapping(address => bool) controllers;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _maxSupply,
        uint256 _stage
    ) ERC721A(_tokenName, _tokenSymbol) {
        addController(msg.sender);
        maxSupply = _maxSupply;
        setStage(_stage);
    }

    modifier onlyController() {
        require(controllers[msg.sender], "Only controllers can operate this function");
        _;
    }

    function whitelistMint()
        public
    {
        // Verify whitelist requirements
        require(!paused, "The contract is paused!");
        require((block.timestamp >= whitelistMintStart)&&(block.timestamp <= whitelistMintEnd), "mint time has not been reached");
        
        uint256 _mintAmount = whitelistClaimed[stage][_msgSender()];
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );

        require(_mintAmount > 0 , "not eligible for whitelist mint");
        
        whitelistClaimed[stage][_msgSender()] = 0;
        _safeMint(_msgSender(), _mintAmount);
    }

    function Airdrop(uint256 _mintAmount, address _receiver)
        public
        onlyController
    {
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );

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

    function setStage(uint256 _stage)
        public
        onlyController
    {
        stage = _stage;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyController {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyController {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyController {
        paused = _state;
    }

    function setWhitelistMintStart(uint256 timestamp) public onlyController {
        whitelistMintStart = timestamp;
    }

    function setWhitelistMintEnd(uint256 timestamp) public onlyController {
        whitelistMintEnd = timestamp;
    }

    function setWhitelist(address[] memory addresses, uint256[] memory numSlots)
        external
        onlyController
    {
        require(
            addresses.length == numSlots.length,
            "addresses does not match numSlots length"
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            whitelistClaimed[stage][addresses[i]] = numSlots[i];
        }
    }

    function addController(address controller) public onlyOwner {
        controllers[controller] = true;
    }

    function removeController(address controller) public onlyOwner {
        controllers[controller] = false;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyController {
        maxSupply = _maxSupply;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}
