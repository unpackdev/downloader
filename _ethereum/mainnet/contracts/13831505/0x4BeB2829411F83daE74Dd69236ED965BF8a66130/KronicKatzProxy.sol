// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

/****************************************
 * @author: squeebo_nft                 *
 * @team:   X-11                        *
 ****************************************/

import "./Delegated.sol";
import "./Address.sol";

interface IKronicKatz{
  function balanceOf( address ) external view returns( uint );
  function mintTo(uint[] calldata quantity, address[] calldata recipient) external payable;
  function totalSupply() external view returns( uint );
}

contract KronicKatzProxy is Delegated{
  using Address for address;

  string public name = "KronicKatz:Proxy";
  string public symbol = "KRONIC:P";

  address public CONTRACT  = 0x19534c6bC37fD44C93F3a6506E44F32a99670f43;
  uint public PRICE        = 0.025 ether;
  uint public ORDER_LIMIT  = 10;
  uint public WALLET_LIMIT = 10;

  bool public isActive = true;

  fallback() external payable {}

  receive() external payable {
    Address.sendValue(payable(CONTRACT), address(this).balance);
  }

  function balanceOf( address account ) external view returns( uint ){
    return IKronicKatz( CONTRACT ).balanceOf( account );
  }

  function totalSupply() external view returns( uint ){
    return IKronicKatz( CONTRACT ).totalSupply();
  }

  function mint( uint quantity ) external payable {
    require(isActive,                      "Sale is closed" );
    require(quantity <= ORDER_LIMIT,       "Order too big" );
    require(msg.value >= quantity * PRICE, "Not enough ETH sent" );

    IKronicKatz proxy = IKronicKatz( CONTRACT );
    require(proxy.balanceOf( msg.sender ) + quantity <= WALLET_LIMIT, "Don't be greedy" );

    uint[] memory quantitys = new uint[](1);
    quantitys[0] = quantity;

    address[] memory recipients = new address[](1);
    recipients[0] = msg.sender;

    IKronicKatz( CONTRACT ).mintTo{ value: msg.value }( quantitys, recipients );
  }

  function setOptions( bool isActive_, uint price, uint orderLimit, uint walletLimit, address contract_ ) external onlyDelegates{
    isActive = isActive_;
    PRICE = price;
    ORDER_LIMIT = orderLimit;
    WALLET_LIMIT = walletLimit;
    CONTRACT = contract_;
  }

  function withdraw() external {
    require(address(this).balance >= 0, "No funds available");
    Address.sendValue(payable(owner()), address(this).balance);
  }
}