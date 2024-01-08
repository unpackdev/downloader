// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

import "./IyusdiNftV3.sol";
import "./Console.sol";

contract IyusdiNftOpenSea is IyusdiNftV3 {

  string public name;
  string public symbol;
  string public contractURI;
  
  constructor (address _operator, address _curator, string memory _uri, string memory _name, string memory _symbol, string memory _contractURI, address _proxyRegistryAddress) 
    IyusdiNftV3(_operator, _curator, _uri, _proxyRegistryAddress) {
    name = _name;
    symbol = _symbol;
    contractURI = _contractURI;
  }

  function owner() external view returns(address) {
    return curator;
  }

  function creators(uint256 id) external view returns(address) {
    return _getOgOwner(id);
  }

  function totalSupply(uint256 id) external view returns(uint256) {
    return 1;
  }

  function tokenSupply(uint256 id) external view returns(uint256) {
    return 1;
  }

  function tokenMaxSupply(uint256 id) external view returns(uint256) {
    return 1;
  }


}