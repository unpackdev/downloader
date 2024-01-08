// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";
import "./ReentrancyGuard.sol";

contract LazyMe is ERC721Tradable, ReentrancyGuard {
    using Strings for uint256;

    uint256 private _currentTokenId = 0;

    mapping(uint256 => mapping(uint256 => address)) private _ownersMapWithBox;
    mapping(uint256 => uint256) private _jsonMap;
    mapping(uint256 => uint256) private _boxMap;
    mapping(uint256 => uint256) private _boxTotalsupply;
    mapping(uint256 => uint256) private _burnTotalsupply;
    mapping(uint256 => string) private _tokenURI;

    string public baseURI;
    string public storeDataURI;
    address public factoryNftAddress;

    constructor(
        address _proxyRegistryAddress,
        string memory _baseURI,
        string memory _storeDataURI
    ) ERC721Tradable("LazyMe NFT", "LAZY", _proxyRegistryAddress) {
        baseURI = _baseURI;
        storeDataURI = _storeDataURI;
    }

    function contractURI() public view returns (string memory) {
        return storeDataURI;
    }

    function baseTokenURI() public view override returns (string memory) {
        return baseURI;
    }

    function setFactoryAddress(address _factoryNftAddress) public onlyOwner {
        factoryNftAddress = _factoryNftAddress;
    }

    function getFactoryAddress() public view onlyOwner returns (address) {
        return factoryNftAddress;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        string memory rarityString = _tokenURI[_tokenId];
        uint256 tokenNum = _jsonMap[_tokenId];
        return
            string(
                abi.encodePacked(
                    baseTokenURI(),
                    rarityString,
                    "/",
                    Strings.toString(tokenNum),
                    ".json"
                )
            );
    }

    function mintTo(
        address _to,
        uint256 _boxnum,
        uint256 _tokenId,
        uint256 _classId
    ) public override {
        require(_to != address(0), "ERC721: mint to the zero address");
        require(
            _msgSender() == factoryNftAddress || _msgSender() == owner(),
            "ERC721: need factory to mint item"
        );
        require(!_exists(_currentTokenId), "ERC721: token already minted");

        _jsonMap[_currentTokenId] = _tokenId;
        _boxMap[_currentTokenId] = _boxnum;
        _tokenURI[_currentTokenId] = string(
            abi.encodePacked(
                Strings.toString(_boxnum),
                "/",
                Strings.toString(_classId)
            )
        );
        _ownersMapWithBox[_boxnum][_currentTokenId] = _to;
        _mint(_to, _currentTokenId);
        _boxTotalsupply[_boxnum] += 1;
        _incrementTokenId();
    }

    function _incrementTokenId() private {
        _currentTokenId++;
    }

    function checkOwnerOf(uint256 _boxnum, uint256 _boxTokenId)
        public
        view
        returns (address)
    {
        address owner = _ownersMapWithBox[_boxnum][_boxTokenId];
        return owner;
    }

    function checkTotalSupply(uint256 _boxnum) public view returns (uint256) {
        return _boxTotalsupply[_boxnum];
    }

    function checkBurnSupply(uint256 _boxnum) public view returns (uint256) {
        return _burnTotalsupply[_boxnum];
    }

    function getAllOwner(uint256 _boxnum)
        public
        view
        onlyOwner
        returns (address[] memory)
    {
        address[] memory result = new address[](_boxTotalsupply[_boxnum]);
        for (uint256 i = 0; i < _boxTotalsupply[_boxnum]; i++) {
            result[i] = _ownersMapWithBox[_boxnum][i];
        }
        return result;
    }

    function _transfer(address from, address to, uint256 tokenId) internal override nonReentrant() {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        uint256 _boxnum = _boxMap[tokenId];
        _ownersMapWithBox[_boxnum][tokenId] = to;

        super._transfer(from, to, tokenId);
    }

    function _burnCreature(uint256 tokenId) public onlyOwner {
        _burn(tokenId);
    }

    function _burn(uint256 tokenId) internal override nonReentrant() {
        delete (_jsonMap[tokenId]);
        delete (_tokenURI[tokenId]);
        uint256 _boxnum = _boxMap[tokenId];
        _ownersMapWithBox[_boxnum][tokenId] = address(0);
        _burnTotalsupply[_boxnum] += 1;
        delete (_boxMap[tokenId]);
        super._burn(tokenId);
    }
}
