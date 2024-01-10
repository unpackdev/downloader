// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

/****************************************
 * @author: squeebo_nft                 *
 * @team:   X-11                        *
 ****************************************/

import "./Delegated.sol";
import "./PaymentSplitterMod.sol";
import "./Address.sol";

interface IFierceModels{
  function balanceOf( address ) external view returns( uint );
  function mintTo(uint[] calldata quantity, address[] calldata recipient) external payable;
  function totalSupply() external view returns( uint );
}

contract FierceModelsProxy is Delegated, PaymentSplitterMod{
  /* using Address for address; */

  address public CONTRACT  = 0xfd1f39C04Fc0ca7E54955687B55d858813160Ef2;
  uint public MAX_TOKENS_PER_TRANSACTION = 20;
  uint public PRICE = 0.07 ether;

  string public name = "Fierce Models: Proxy";
  string public symbol = "FM:P";

  bool public paused = false;

  // Withdrawal addresses
  address dev = 0xB7edf3Cbb58ecb74BdE6298294c7AAb339F3cE4a;
  address art = 0xF7aDD17E99F097f9D0A6150D093EC049B2698c60;
  address fierce = 0x9aF1757A18E3b3ea25c46331509279e4B6c5e0A6;
  address f1 = 0x7ca64429125EC529f13E07cEa1a7Ce55B54875F0;
  address f2 = 0x16624b589419012a2817C47432762369c859B6e4;

  address[] addressList = [dev, art, fierce, f1, f2];
  uint[] shareList = [100, 40, 151, 425, 284];

  constructor()
    PaymentSplitterMod( addressList, shareList ){
  }

  fallback() external payable {}

  function balanceOf( address account ) external view returns( uint ){
    return IFierceModels( CONTRACT ).balanceOf( account );
  }

  function totalSupply() external view returns( uint ){
    return IFierceModels( CONTRACT ).totalSupply();
  }

  function mint( uint _count ) external payable {
    require( _count <= MAX_TOKENS_PER_TRANSACTION, "Count exceeded max tokens per transaction." );
    require( !paused,                              "Sale is currently paused." );
    require( msg.value >= PRICE * _count,          "Ether sent is not correct." );

    uint[] memory quantitys = new uint[](1);
    quantitys[0] = _count;

    address[] memory recipients = new address[](1);
    recipients[0] = msg.sender;

    IFierceModels( CONTRACT ).mintTo( quantitys, recipients );
  }

  function setOptions( address contract_, bool paused_, uint price_, uint maxPerTx_ ) external onlyDelegates{
    CONTRACT = contract_;
    paused = paused_;
    PRICE = price_;
    MAX_TOKENS_PER_TRANSACTION = maxPerTx_;
  }

  function addPayee(address account, uint256 shares_) external onlyOwner {
    _addPayee( account, shares_ );
  }

  function resetCounters() external onlyOwner {
    _resetCounters();
  }

  function setPayee( uint index, address account, uint newShares ) external onlyOwner {
    _setPayee(index, account, newShares);
  }
}