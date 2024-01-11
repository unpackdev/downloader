// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

contract Fxckwon is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public uriPrefix = "";
    string public uriExt = ".json";
    string public hiddenMetadataURI;

    uint256 public constant cost = 0.0059 ether;
    uint256 public fkMaxSupply = 1000;
    uint256 public fkFreeMaxSupply = 400;
    uint256 public fkFreeCurrentMinted = 0;

    uint256 public maxMintPerAddr = 5;
    uint256 public freeMaxMintPerAddr = 5;

    mapping(address => uint256) public freeMinted;
    mapping(address => uint256) public minted;

    bool public mintLive = true;
    bool public revealed = false;

    constructor(string memory _uriPrefix, string memory _hiddenMetadataURI)
        ERC721A("Fxckwon", "FK")
    {
        setUriPrefix(_uriPrefix);
        setHiddenMetaDataURI(_hiddenMetadataURI);
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
            fkFreeCurrentMinted + _mintAmount <= fkFreeMaxSupply,
            "Lack of free mint supply."
        );

        freeMinted[msg.sender] += _mintAmount;
        fkFreeCurrentMinted += _mintAmount;
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
            totalSupply() + _mintAmount <= fkMaxSupply,
            "No available supply to mint."
        );

        minted[msg.sender] += _mintAmount;
        _safeMint(_msgSender(), _mintAmount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
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
            tokensOwnedIndex < ownerTokenCount && thisTokenId <= fkMaxSupply
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

    function setHiddenMetaDataURI(string memory _hiddenMetadataURI)
        public
        onlyOwner
    {
        hiddenMetadataURI = _hiddenMetadataURI;
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

        if (revealed == false) {
            return
                string(
                    abi.encodePacked(
                        hiddenMetadataURI,
                        Strings.toString(tokenId),
                        uriExt
                    )
                );
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(currentBaseURI, tokenId.toString(), uriExt)
                )
                : "";
    }

    function setRevealedState(bool _status) public onlyOwner {
        revealed = _status;
    }

    function setFreeMaxMintPerTx(uint256 _freeMaxMintPerTx) public onlyOwner {
        freeMaxMintPerAddr = _freeMaxMintPerTx;
    }

    function setMcgFreeMaxSupply(uint256 _fkFreeMaxSupply) public onlyOwner {
        fkFreeMaxSupply = _fkFreeMaxSupply;
    }

    function setMaxMintPerTx(uint256 _maxMintPerTx) public onlyOwner {
        maxMintPerAddr = _maxMintPerTx;
    }

    function setMcgMaxSupply(uint256 _fkMaxSupply) public onlyOwner {
        fkMaxSupply = _fkMaxSupply;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "Withdraw not executed.");
    }
}
