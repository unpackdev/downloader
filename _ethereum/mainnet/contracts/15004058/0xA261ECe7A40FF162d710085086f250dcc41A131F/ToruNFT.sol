// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";

contract ToruNFT is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    string private baseURI;
    string public baseExtension = ".json";
    uint256 public immutable maxSupply = 200;
    bool public isAllowListActive = false;

    // keep track of how many each address has claimed
    mapping (uint256 => string) private _tokenURIs;
    mapping(address => uint256) private _allowList;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        _tokenIdCounter.increment();
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint(uint256 _mintAmount) public nonReentrant {
        uint256 totalSupply = _tokenIdCounter.current();
        string memory currentBaseURI = _baseURI();

        require(isAllowListActive, "Allow list is not active");
        require(_mintAmount > 0, "Cannot mint 0");
        require(totalSupply + _mintAmount <= maxSupply, "Cannot mint more than max supply");
        require(_allowList[msg.sender] != 0, "Address is not on whitelist");
        require(_mintAmount <= _allowList[msg.sender], "Cannot mint more than one NFT per address");


        _allowList[msg.sender] -= _mintAmount;

        _safeMint(_msgSender(), totalSupply);
        _setTokenURI(totalSupply, string(
                abi.encodePacked(
                    currentBaseURI,
                    Strings.toString(totalSupply),
                    baseExtension
                )
        ));

        _tokenIdCounter.increment();
    }

    function adminMint(uint256 _mintAmount) public nonReentrant onlyOwner {
        uint256 totalSupply = _tokenIdCounter.current();
        string memory currentBaseURI = _baseURI();

        require(isAllowListActive, "Allow list is not active");
        require(_mintAmount > 0, "Cannot mint 0");
        require(totalSupply + _mintAmount <= maxSupply, "Cannot mint more than max supply");

        for (uint i = 0; i < _mintAmount; i++) {
            uint mintIndex = _tokenIdCounter.current();
            _safeMint(_msgSender(), mintIndex);
            _setTokenURI(mintIndex, string(
                    abi.encodePacked(
                        currentBaseURI,
                        Strings.toString(mintIndex),
                        baseExtension
                    )
            ));

            _tokenIdCounter.increment();
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override (ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        Strings.toString(tokenId),
                        baseExtension
                    )
                )
                : "";
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setAllowList(address[] calldata addresses, uint256 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = numAllowedToMint;
        }
    }

    function setAllowListActive()
        public
        onlyOwner
        returns (bool)
    {
        isAllowListActive = !isAllowListActive;
        return true;
    }

    function inAllowList(address _address) public view returns (uint256) {
        return _allowList[_address];
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function getTokenIds(address _owner) public view returns (uint[] memory) {
        uint[] memory _tokensOfOwner = new uint[](ERC721.balanceOf(_owner));
        uint i;

        for (i = 0; i < ERC721.balanceOf(_owner); i++) {
            _tokensOfOwner[i] = ERC721Enumerable.tokenOfOwnerByIndex(_owner, i);
        }
        return (_tokensOfOwner);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}