// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

/****************************************
 * @author: squeebo_nft                 *
 * @team:   X-11                        *
 ****************************************/

import "./Delegated.sol";
import "./Address.sol";

interface ISupLadies{
  function mintVouchersTo(uint[] calldata quantity, address[] calldata recipient) external payable;
}

contract SupLadiesVoucher is Delegated{
  using Address for address;

  uint public PRICE = 0.1957 ether;
  address public SUP_LADIES = 0x54b5FfAA0d5EA71543703740724189C6C8Ee66c2;

  string public name = "SupLadiesVoucher";
  string public symbol = "SL:V";

  fallback() external payable {}

  receive() external payable {
    Address.sendValue(payable(SUP_LADIES), address(this).balance);
  }

  function withdraw() external {
    require(address(this).balance >= 0, "No funds available");
    Address.sendValue(payable(owner()), address(this).balance);
  }

  function mintVouchers( uint quantity ) external payable {
    require(msg.value >= quantity * PRICE, "Not enough ETH sent" );

    uint[] memory quantitys = new uint[](1);
    quantitys[0] = quantity;

    address[] memory recipients = new address[](1);
    recipients[0] = msg.sender;

    ISupLadies( SUP_LADIES ).mintVouchersTo{ value: msg.value }( quantitys, recipients );
  }

  function setPrice( uint price ) external onlyDelegates{
    PRICE = price;
  }
}