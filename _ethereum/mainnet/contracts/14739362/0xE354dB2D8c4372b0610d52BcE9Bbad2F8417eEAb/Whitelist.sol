// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./IERC721.sol";


contract Whitelist is Ownable {
  mapping(address => uint) private entries;
  mapping(address => bool) private graylist;
  address public operator;

  event SetContractEntries(address _contract, uint256 _newSupply);
  event WhitelistUsed(address _wallet, string _symbol, string _name);

  function setOperator(address _operator) public onlyOwner {
    operator = _operator;
  }

  function setEntries(address _contract, uint _entries) public onlyOwner {
    entries[_contract] = _entries;
    emit SetContractEntries(_contract, _entries);
  }

  function getEntries(address _contract) public view returns( uint ) {
    return( entries[_contract]);
  }

  function isWhitelisted(address _contract, address _user) public view returns (bool) {
    if (entries[_contract] == 0) {
      return(false);
    }
    if (graylist[_user]) {
      return(false);
    }
    IERC721 externalNft = IERC721(_contract);
    return ( (externalNft.balanceOf(_user) > 0)? true : false );
  }

  function update(address _contract, address _user) public {
    require(msg.sender == operator, "You are not the operator");
    require(!graylist[_user], "Address already used the whitelist");
    require(entries[_contract] > 0, "Contract provided has no entries left");
    entries[_contract] -= 1;
    graylist[_user] = true;
    // IERC721Metadata externalNft = IERC721Metadata(_contract);
    // emit WhitelistUsed(_user, externalNft.symbol(), externalNft.name());
  }

}