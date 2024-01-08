/*
  __  __  ____  _   _  _____ _______ ______ _____
 |  \/  |/ __ \| \ | |/ ____|__   __|  ____|  __ \
 | \  / | |  | |  \| | (___    | |  | |__  | |__) |
 | |\/| | |  | | . ` |\___ \   | |  |  __| |  _  /
 | |  | | |__| | |\  |____) |  | |  | |____| | \ \
 |_|  |_|\____/|_| \_|_____/   |_|  |______|_|  \_\

     __  __          _____  _  ________ _______
    |  \/  |   /\   |  __ \| |/ /  ____|__   __|
    | \  / |  /  \  | |__) | ' /| |__     | |
    | |\/| | / /\ \ |  _  /|  < |  __|    | |
    | |  | |/ ____ \| | \ \| . \| |____   | |
    |_|  |_/_/    \_\_|  \_\_|\_\______|  |_|


               Contract written by:
     ____       _          _     _           _
    / __ \  ___| |__  _ __(_)___| |__   ___ | |
   / / _` |/ __| '_ \| '__| / __| '_ \ / _ \| |
  | | (_| | (__| | | | |  | \__ \ | | | (_) | |
   \ \__,_|\___|_| |_|_|  |_|___/_| |_|\___/|_|
    \____/

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./IERC721Transfer.sol";
import "./ReentrancyGuard.sol";

contract MonsterMarket is ReentrancyGuard {
  IERC721Transfer public monsterBlocks = IERC721Transfer(0xa56a4f2b9807311AC401c6afBa695D3B0C31079d);

  /* Balance Functions */

  mapping (address => uint256) private _balances;

  function balanceOf(address _owner) public view virtual returns (uint256) {
    require(_owner != address(0), "Balance query for the zero address");
    return _balances[_owner];
  }

  function transferBalance(address _to) public nonReentrant {
    require(msg.sender != _to, "No transfer required");

    uint256 balanceToTransfer = _balances[msg.sender];
    require(balanceToTransfer > 0, "No balance to transfer");

    _balances[msg.sender] = 0;
    _balances[_to] = balanceToTransfer;
  }

  /* Deposit and Redemption Functions */

  uint256 public maxTransactionSize = 10;

  function depositOne(uint256 _tokenId) public {
    monsterBlocks.transferFrom(msg.sender, address(this), _tokenId);
    _balances[msg.sender] += 1;
  }

  function depositMany(uint256[] memory _tokenIds) public {
    require(_tokenIds.length <= maxTransactionSize);
    _deposit(_tokenIds);
  }

  function redeemOne(uint256 _tokenId) public nonReentrant {
    require(_balances[msg.sender] > 0);
    _balances[msg.sender] -= 1;
    monsterBlocks.transferFrom(address(this), msg.sender, _tokenId);
  }

  function redeemMany(uint256[] memory _tokenIds) public nonReentrant {
    require(_tokenIds.length <= maxTransactionSize);
    _redeem(_tokenIds);
  }

  function depositAndRedeemOne(uint256 _depositTokenId, uint256 _redeemTokenId) public nonReentrant {
    monsterBlocks.transferFrom(msg.sender, address(this), _depositTokenId);
    monsterBlocks.transferFrom(address(this), msg.sender, _redeemTokenId);
  }

  function depositAndRedeemMany(uint256[] memory _depositTokenIds, uint256[] memory _redeemTokenIds) public nonReentrant {
    require(_depositTokenIds.length <= maxTransactionSize);
    require(_depositTokenIds.length == _redeemTokenIds.length);

    __deposit(_depositTokenIds);
    __redeem(_redeemTokenIds);
  }

  /* Internal Helper Functions */

  function _deposit(uint256[] memory _tokenIds) internal {
    __deposit(_tokenIds);

    _balances[msg.sender] += _tokenIds.length;
  }

  function _redeem(uint256[] memory _tokenIds) internal {
    require(_balances[msg.sender] >= _tokenIds.length);

    _balances[msg.sender] -= _tokenIds.length;

    __redeem(_tokenIds);
  }

  function __deposit(uint256[] memory _tokenIds) internal {
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      monsterBlocks.transferFrom(msg.sender, address(this), _tokenIds[i]);
    }
  }

  function __redeem(uint256[] memory _tokenIds) internal {
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      monsterBlocks.transferFrom(address(this), msg.sender, _tokenIds[i]);
    }
  }
}
