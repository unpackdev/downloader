// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

contract DeSdog is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public uriPrefix = "";
    string public uriExt = ".json";

    uint256 public constant cost = 0.015 ether;
    uint256 public dsMaxSupply = 10000;
    uint256 public dsFreeMaxSupply = 1000;
    uint256 public dsFreeCurrentMinted = 0;

    uint256 public maxMintPerAddr = 30;
    uint256 public freeMaxMintPerAddr = 30;

    mapping(address => uint256) public freeMinted;
    mapping(address => uint256) public minted;

    bool public mintLive = true;

    constructor(string memory _uriPrefix)
        ERC721A("DeSdog", "DSG")
    {
        setUriPrefix(_uriPrefix);
    }

    function setMintLive(bool _state) public onlyOwner {
        mintLive = _state;
    }

    function freeMint(uint256 _mintAmount) public payable {
        require(mintLive, "Mint is not activated.");
        require(
            _mintAmount > 0 && _mintAmount <= freeMaxMintPerAddr,
            "Invalid Mint Amount."
        );
        require(
            freeMinted[msg.sender] + _mintAmount <= freeMaxMintPerAddr,
            "Transaction limit reached."
        );
        require(
            dsFreeCurrentMinted + _mintAmount <= dsFreeMaxSupply,
            "Lack of free mint supply."
        );

        freeMinted[msg.sender] += _mintAmount;
        dsFreeCurrentMinted += _mintAmount;
        _safeMint(_msgSender(), _mintAmount);
    }

    function mint(uint256 _mintAmount) public payable {
        require(mintLive, "Mint is not activated.");
        require(
            _mintAmount > 0 && _mintAmount <= maxMintPerAddr,
            "Invalid Mint Amount."
        );
        require(
            minted[msg.sender] + _mintAmount <= maxMintPerAddr,
            "Mint amount exceeded!"
        );
        require(msg.value == cost * _mintAmount, "Wrong amount of ETH.");
        require(
            totalSupply() + _mintAmount <= dsMaxSupply,
            "No available supply to mint."
        );

        minted[msg.sender] += _mintAmount;
        _safeMint(_msgSender(), _mintAmount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 0;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokensOwned = new uint256[](ownerTokenCount);
        uint256 thisTokenId = _startTokenId();
        uint256 tokensOwnedIndex = 0;
        address latestOwnerAddress;

        while (
            tokensOwnedIndex < ownerTokenCount && thisTokenId <= dsMaxSupply
        ) {
            TokenOwnership memory ownership = _ownerships[thisTokenId];

            if (!ownership.burned && ownership.addr != address(0)) {
                latestOwnerAddress = ownership.addr;
            }

            if (latestOwnerAddress == _owner) {
                tokensOwned[tokensOwnedIndex] = thisTokenId;

                tokensOwnedIndex++;
            }
            thisTokenId++;
        }
        return tokensOwned;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function setUriPrefix(string memory _newUriPrefix) public onlyOwner {
        uriPrefix = _newUriPrefix;
    }

    function setUriExt(string memory _newUriExt) public onlyOwner {
        uriExt = _newUriExt;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Token unavailable.");

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(currentBaseURI, tokenId.toString(), uriExt)
                )
                : "";
    }

    function setFreeMaxMintPerAddr(uint256 _freeMaxMintPerAddr) public onlyOwner {
        freeMaxMintPerAddr = _freeMaxMintPerAddr;
    }

    function setMcgFreeMaxSupply(uint256 _dsFreeMaxSupply) public onlyOwner {
        dsFreeMaxSupply = _dsFreeMaxSupply;
    }

    function setMaxMintPerAddr(uint256 _maxMintPerAddr) public onlyOwner {
        maxMintPerAddr = _maxMintPerAddr;
    }

    function setMcgMaxSupply(uint256 _dsMaxSupply) public onlyOwner {
        dsMaxSupply = _dsMaxSupply;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "Withdraw not executed.");
    }
}
