pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

/*
    )              )           (                )   
 ( /(   (       ( /(   *   )   )\ )    (     ( /(   
 )\())  )\      )\())` )  /(  (()/(    )\    )\())  
((_)\((((_)(  |((_)\  ( )(_))  /(_))((((_)( ((_)\   
 _((_))\ _ )\ |_ ((_)(_(_())  (_))_  )\ _ )\  ((_)  
| || |(_)_\(_)| |/ / |_   _|   |   \ (_)_\(_)/ _ \  
| __ | / _ \    ' <    | |     | |) | / _ \ | (_) | 
|_||_|/_/ \_\  _|\_\   |_|     |___/ /_/ \_\ \___/  
                                                    
*/

import "./ERC721.sol";
import "./Counters.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract HaktDAO is ERC721, ERC721URIStorage, ERC721Enumerable, Ownable {
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIds;
  string private baseURI;

  uint256 public constant limit = 500;
  uint256 public currentPrice = 0.005 ether;

  event Mint(
      address indexed to,
      uint256 indexed tokenId
  );

  constructor() ERC721("HaktDAO", "BOB") {
    baseURI = "https://gateway.ipfs.io/ipns/k51qzi5uqu5di0xiaggf2azd5hqaslcfoxosvxe7aps37bnf81u6ql376igea6/json/";
  }

  /// @notice Internal Mint an item for a given address
  /// @param to recipient address
  function _mintItem(address to)
      private
      returns (uint256)
  {
    _tokenIds.increment();
    uint256 id = _tokenIds.current();
    _mint(to, id);
    _setTokenURI(id, string(abi.encodePacked(uint2str(id), ".json")));

    emit Mint(to, id);
    return id;
  }

  /// @notice Mint an item for a given address  
  /// @param to recipient address
  function requestMint(address to)
      public
      payable
      returns (uint256)
  {
    require( _tokenIds.current() < limit , "DONE MINTING");
    require( msg.value >= currentPrice, "NOT ENOUGH");

    currentPrice = (currentPrice * 1011) / 1000;

    (bool success,) = owner().call{value:msg.value}("");
    require( success, "could not send");
    return _mintItem(to);
  }

  /// @notice Mint an item for a given address as the DAO 
  /// @param to recipient address
  function mintAsDAO(address to)
      public
      onlyOwner
      returns (uint256)
  {
    return _mintItem(to);
  }

  /// @notice Change the BaseURI 
  /// @param newBaseURI string of the new base URI
  function setBaseURI(string memory newBaseURI)
      public
      onlyOwner
  {
    baseURI = newBaseURI;
  }

  /// @notice Change the Current Price 
  /// @param newCurrentPrice value of the new current price
  function setCurrentPrice(uint256 newCurrentPrice)
      onlyOwner
      public
  {
    currentPrice = newCurrentPrice;
  }

  /// @notice Override of the burn function
  /// @param tokenId value of the token id to be burned
  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  /// @notice Get the token URI for a given token Id
  /// @param tokenId value of the token id
  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }

  /// @notice Get the current base URI
  function _baseURI() internal override view virtual returns (string memory) {
    return baseURI;
  }
  
  /// @notice Override of the beforeTokenTransfer function
  /// @param from the from address
  /// @param to the to address
  /// @param tokenId value of the token id to be burned
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  /// @notice Override of the supportsInterface function
  /// @param interfaceId the id of the interface
  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
        return "0";
    }
    uint j = _i;
    uint len;
    while (j != 0) {
        len++;
        j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len;
    while (_i != 0) {
        k = k-1;
        uint8 temp = (48 + uint8(_i - _i / 10 * 10));
        bytes1 b1 = bytes1(temp);
        bstr[k] = b1;
        _i /= 10;
    }
    return string(bstr);
    }
}
