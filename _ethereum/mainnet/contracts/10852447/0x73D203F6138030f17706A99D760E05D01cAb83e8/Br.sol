pragma solidity ^0.5.0;

import "./TradeableERC721Token.sol";
import "./Strings.sol";

contract Br is TradeableERC721Token {

    mapping(uint256 => string) internal _tokenHash;

    address internal creator;
    string private baseURI = 'ipfs://ipfs/';

    event TokenMinted (uint256 _tokenId, string _hash);
    event TokenBurnt (uint256 _tokenId);
  
    constructor (address _proxyRegistryAddress) TradeableERC721Token('BlockRacers', 'BLRA', _proxyRegistryAddress) public {
      creator = msg.sender;
    }

    function mint(
        address _to,
        string memory _hash
    ) public onlyOwner {

        uint256 _tokenId = _getNextTokenId();
        super.mintTo(_to);
        _setTokenHash(_tokenId, _hash);

        emit TokenMinted(_tokenId, _hash);
    }

    function _setTokenHash(uint256 _tokenId, string memory _hash) internal {
      require(_exists(_tokenId), "ERC721Metadata: hash set of nonexistent token");
      _tokenHash[_tokenId] = _hash;
    }

    function setBaseURI (string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function baseTokenURI () public view returns (string memory) {
      return baseURI;
    }

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
      require(_exists(_tokenId), "Can't get tokenURI of non-existent token");
      return Strings.strConcat(
        baseURI,
        _tokenHash[_tokenId]
      );
    }

    function currentTokenIndex () public view returns (uint256) {
        return _currentTokenId;
    }

    function getTokenHash(uint256 _tokenId) public view returns (string memory) {
      require(_exists(_tokenId), "Can't get hash of non-existent token");
      return _tokenHash[_tokenId];
    }

    function burn(uint256 _tokenId) public onlyOwner {
      super._burn(ownerOf(_tokenId), _tokenId);
      delete _tokenHash[_tokenId];
      emit TokenBurnt(_tokenId);
    }
}

