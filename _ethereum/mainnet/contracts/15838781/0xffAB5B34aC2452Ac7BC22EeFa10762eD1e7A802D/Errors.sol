// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

/**
 * @title Errors library
 * @author Jungle
 * @notice Defines the error messages emitted by the different contracts of the Aave protocol
 */
library Errors {
  string public constant DOMAIN_HASH_DID_NOT_MATCH = "1"; // Encoded domain hash and EIP_712 domain hash didn't match
  string public constant NAME_HASH_DID_NOT_MATCH  = "2"; // Encoded name hash and name hash didn't match
  string public constant VERSION_HASH_DID_NOT_MATCH  = "3"; // Encoded version hash and version hash didn't  match
  string public constant ORDER_HASH_DID_NOT_MATCH  = "4"; // Encoded order hash and order hash didn't  match
  string public constant TRANSFER_NOT_SUCCESSFUL  = "5"; // Token transfer is not successful
  string public constant INVALID_ORDER  = "6"; // Order is invalid
  string public constant CALLER_IS_NOT_MAKER  = "7"; // Order.maker is not the msg.sender
  string public constant ORDER_ALREADY_APPROVED  = "8"; // Order is already approved
  string public constant INVALID_PRICE  = "9"; // Buy price is not greater than or equal to sell price
  string public constant VALUE_IS_NOT_ZERO  = "10"; // msg.value is not equal to zero
  string public constant INVALID_BUY_TAKER_PROTOCOL_FEE  = "11"; // takerProtocolFee in buy order is not greater than or equal to takerProtocolFee in sell order
  string public constant INVALID_BUY_TAKER_RELAYER_FEE  = "12"; // takerRelayerFee in buy order is not greater than or equal to takerRelayerFee in sell order
  string public constant INVALID_SELL_TAKER_RELAYER_FEE  = "13"; // takerRelayerFee in sell order is not greater than or equal to takerRelayerFee in buy order
  string public constant INVALID_SELL_TAKER_PROTOCOL_FEE  = "14"; // takerProtocolFee in sell order is not greater than or equal to takerProtocolFee in buy order
  string public constant INVALID_SELL_PAYMENT_TOKEN  = "15"; // Payment Token in sell order is Zero address
  string public constant NOT_ENOUGH_VALUE  = "16"; // msg.value is not greater than or equal to required amount
  string public constant INVALID_ORDER_PARAMETERS_BUY_ORDER  = "17"; // Invalid order parameters in buy order
  string public constant INVALID_ORDER_PARAMETERS_SELL_ORDER  = "18"; // Invalid order parameters in sell order
  string public constant ORDERS_NOT_MATCHABLE  = "19"; // Buy order and sell order doesn't match
  string public constant TARGET_NOT_CONTRACT  = "20"; // Is not a contract
  string public constant DATA_NOT_MATCHED  = "21"; // Buy data and sell data are not matched 
  string public constant PROXY_NOT_REGISTERED = "22"; // Address of Delegate proxy is Zero address
  string public constant INVALID_IMPLEMENTATION = "23"; // Implementation address in delegate proxy and implementation address in proxy registry contract are not same 
  string public constant PROXY_CALL_FAILED = "24"; // call to proxy function in authenticated proxy failed
  string public constant BUY_STATIC_CALL_FAILED = "25"; // Static call to static target address in buy order failed
  string public constant SELL_STATIC_CALL_FAILED = "26"; // Static call to static target address in sell order failed
  string public constant CASHBACK_FAILED = "27"; // Failed to get cashback
  string public constant FEE_FAILED = "28"; // Failed to send fee
  string public constant ROYALTY_DATA_LENGTH_NOT_EQUAL = "29"; //Royalty data length must be equal
  string public constant INVALID_CASHBACK_AMOUNT = "30"; // cashbask amount invalid
  string public constant ROYALTY_TRANSFER_FAILED = "31"; //Royalty transfer failed
  string public constant ETHER_TRANSFER_NOT_SUCCESSFUL  = "32"; // Ether transfer is not successful
  }