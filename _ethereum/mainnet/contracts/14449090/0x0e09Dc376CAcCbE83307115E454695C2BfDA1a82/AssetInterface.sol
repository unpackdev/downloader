pragma solidity 0.5.8;

contract AssetInterface {
  function _performTransferWithReference(
    address _to,
    uint256 _value,
    string memory _reference,
    address _sender
  ) public returns (bool);

  function _performTransferToICAPWithReference(
    bytes32 _icap,
    uint256 _value,
    string memory _reference,
    address _sender
  ) public returns (bool);

  function _performApprove(
    address _spender,
    uint256 _value,
    address _sender
  ) public returns (bool);

  function _performTransferFromWithReference(
    address _from,
    address _to,
    uint256 _value,
    string memory _reference,
    address _sender
  ) public returns (bool);

  function _performTransferFromToICAPWithReference(
    address _from,
    bytes32 _icap,
    uint256 _value,
    string memory _reference,
    address _sender
  ) public returns (bool);

  function _performGeneric(bytes memory, address) public payable {
    revert();
  }
}
