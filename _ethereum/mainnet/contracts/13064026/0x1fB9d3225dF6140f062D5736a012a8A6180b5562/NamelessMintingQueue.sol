// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./NamelessTokenData.sol";
import "./NamelessToken.sol";

contract NamelessMintingQueue is AccessControl {
  constructor( ) {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  struct MintingInfo {
    address minter;
    address tokenContract;
    address recipient;
    uint[]  tokenIds;
    string name;
    string symbol;
  }

  mapping (address => MintingInfo ) public mintingInfoByData;

  function addMintingInfo(address minter, address recipient, address tokenDataContract, string calldata name, string calldata symbol, uint256[] calldata tokenIds) public onlyRole(DEFAULT_ADMIN_ROLE) {
    if (mintingInfoByData[tokenDataContract].minter == address(0)) {
      mintingInfoByData[tokenDataContract].minter = minter;
      mintingInfoByData[tokenDataContract].recipient = recipient;
      mintingInfoByData[tokenDataContract].name = name;
      mintingInfoByData[tokenDataContract].symbol = symbol;
    } else {
      require(
        mintingInfoByData[tokenDataContract].minter == address(0) && mintingInfoByData[tokenDataContract].recipient == address(0),
        'cannot update actors'
      );

      require(
        bytes(name).length == 0 && bytes(symbol).length == 0,
        'cannot update token params'
      );
    }

    for(uint idx; idx < tokenIds.length; idx++) {
      mintingInfoByData[tokenDataContract].tokenIds.push(tokenIds[idx]);
    }
  }

  function dropMintingInfo(address tokenDataContract) public onlyRole(DEFAULT_ADMIN_ROLE) {
    delete mintingInfoByData[tokenDataContract];
  }

  function processMintingQueue(address tokenDataContract, uint maxTokens) public {
    MintingInfo storage info = mintingInfoByData[tokenDataContract];
    require(info.minter != address(0), 'no such data contract');
    require(info.tokenContract == address(0) || info.tokenIds.length > 0, 'nothing to do');
    require(msg.sender == info.minter, 'not authorized');

    if (info.tokenContract == address(0)) {
      info.tokenContract = NamelessTokenData(tokenDataContract).createFrontend(info.name, info.symbol);
      require(info.tokenContract != address(0), 'failed to create frontend');

      NamelessToken token = NamelessToken(info.tokenContract);
      token.grantRole(token.MINTER_ROLE(), address(this));
      token.grantRole(token.DEFAULT_ADMIN_ROLE(), info.minter);
      token.grantRole(token.REDEEM_ROLE(), info.minter);
      token.transferLegacyOwnership(info.minter);
      token.renounceRole(token.DEFAULT_ADMIN_ROLE(), address(this));
    }

    uint numToMint = maxTokens < info.tokenIds.length ? maxTokens : info.tokenIds.length;
    for (uint idx = 0; idx < numToMint; idx++) {
      NamelessToken(info.tokenContract).mint(msg.sender,info.recipient, info.tokenIds[idx]);
    }

    if (numToMint == info.tokenIds.length) {
      delete info.tokenIds;
    } else {
      uint remaining = info.tokenIds.length - numToMint;
      for (uint idx = 0; idx < remaining; idx++) {
        info.tokenIds[idx] = info.tokenIds[numToMint + idx];
      }

      while (info.tokenIds.length > remaining) {
        info.tokenIds.pop();
      }
    }
  }
}
