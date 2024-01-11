// SPDX-License-Identifier: MIT


/**

*/

pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";

contract CuBeanzLegend is ERC1155, Ownable {
    
  string public name;
  string public symbol;

  mapping(uint => string) public tokenURI;

  constructor() ERC1155("") {
    name = "CuBeanz Koden Legend";
    symbol = "CBKL";
    setURI(0,"ipfs://QmPZep8d6sNHgyP54M2yhJLMqAjSc48oyQW7QkabJLSrXf");
  }


  function airdrop(address[] calldata accounts) public onlyOwner {
    for(uint i; i<accounts.length;i++){
    _mint(accounts[i], 0, 1, "");
        }
     }

  function setURI(uint _id, string memory _uri) public onlyOwner {
    tokenURI[_id] = _uri;
    emit URI(_uri, _id);
  }

  function uri(uint _id) public override view returns (string memory) {
    return tokenURI[_id];
  }

}