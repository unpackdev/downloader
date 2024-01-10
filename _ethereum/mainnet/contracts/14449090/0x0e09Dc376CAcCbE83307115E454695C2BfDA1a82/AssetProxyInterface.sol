pragma solidity 0.5.8;

import "./ERC20Interface.sol";

contract AssetProxyInterface is ERC20Interface {
  function _forwardApprove(
    address _spender,
    uint256 _value,
    address _sender
  ) public returns (bool);

  function _forwardTransferFromWithReference(
    address _from,
    address _to,
    uint256 _value,
    string memory _reference,
    address _sender
  ) public returns (bool);

  function _forwardTransferFromToICAPWithReference(
    address _from,
    bytes32 _icap,
    uint256 _value,
    string memory _reference,
    address _sender
  ) public returns (bool);

  function recoverTokens(
    ERC20Interface _asset,
    address _receiver,
    uint256 _value
  ) public returns (bool);

  function etoken2() external view returns (address); // To be replaced by the implicit getter;

  // To be replaced by the implicit getter;
  function etoken2Symbol() external view returns (bytes32);
}
