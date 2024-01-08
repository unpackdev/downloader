// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "./ERC721.sol";
import "./Strings.sol";
import "./IERC20.sol";
import "./Delegable.sol";
/**
 * @title CryptoDogs
 */

contract CoinDogs is ERC721, Delegable
{
    using Strings for string;
    mapping(uint256 => string) private _uris;
    mapping(uint256 => address) private _creators;
    mapping(uint256 => uint256) private prices;
    string private _defaultUri;
    constructor( string memory defaultUri_) ERC721("TokenDogs","DOGS") {
        
        _defaultUri = defaultUri_;
    }
    function setDefaultUri(string memory _uri)public onlyOwnerOrApproved{
        _defaultUri = _uri;
    }
    function mint(
        address _to,
        uint256 _id,
        string memory _uri
    ) public onlyOwnerOrApproved {
    _mint(_to, _id);
    _uris[_id] = _uri;
    _creators[_id] = _to;
  }
  function getCreator(uint256 _id)external view returns(address){
      return _creators[_id];
  }



    function tokenURI(uint256 id) public view override returns (string memory){
        if (_exists(id))
            return _uris[id];
        else
            return _defaultUri;
    }

}