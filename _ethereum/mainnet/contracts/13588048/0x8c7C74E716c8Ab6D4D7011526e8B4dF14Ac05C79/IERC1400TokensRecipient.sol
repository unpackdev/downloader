pragma solidity ^0.8.0;

/**
 * The contract is utilised and constructed from UniversalToken implementatation 
 * with modifications done to suit the TitanBank ecosystem
 * See https://github.com/ConsenSys/UniversalToken
 * @title IERC1400TokensRecipient
 * @dev ERC1400TokensRecipient interface
 */
interface IERC1400TokensRecipient {

  function canReceive(
    bytes calldata payload,
    bytes32 partition,
    address operator,
    address from,
    address to,
    uint value,
    bytes calldata data,
    bytes calldata operatorData
  ) external view returns(bool);

  function tokensReceived(
    bytes calldata payload,
    bytes32 partition,
    address operator,
    address from,
    address to,
    uint value,
    bytes calldata data,
    bytes calldata operatorData
  ) external;

}
