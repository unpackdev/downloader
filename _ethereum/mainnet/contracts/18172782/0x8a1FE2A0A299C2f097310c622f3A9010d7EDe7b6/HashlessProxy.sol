import "./IERC20.sol";
import "./SafeERC20.sol";

pragma solidity ^0.7.0;
pragma abicoder v2;

interface IHashlessInstance {
  function token() external view returns (address);

  function denomination() external view returns (uint256);

  function deposit(bytes32 commitment) external payable;

  function withdraw(
    bytes calldata _proof,
    bytes32 _root,
    bytes32 _nullifierHash,
    address payable _recipient,
    address payable _relayer,
    address payable _referral,
    uint256 _refund
  ) external payable;
}
contract HashlessProxy {
  using SafeERC20 for IERC20;

  uint256 public depositCounter;
  uint256 public withdrawCounter;

  event EncryptedNote(address indexed sender, bytes encryptedNote);
  event Deposit(address token, uint256 denomination, uint256 timestamp, uint256 count);
  event Withdraw(address token, uint256 denomination, uint256 timestamp, uint256 count);

  function deposit(
    IHashlessInstance _hashless,
    bytes32 _commitment,
    bytes calldata _encryptedNote
  ) external payable {
    address token = _hashless.token();
    uint256 denomination = _hashless.denomination();

    if (token != address(0)) {
      IERC20(token).transferFrom(msg.sender, address(this), denomination);
      IERC20(token).approve(address(_hashless), denomination);
    }
    _hashless.deposit{ value: msg.value }(_commitment);
    emit EncryptedNote(msg.sender, _encryptedNote);
    emit Deposit(token, denomination, block.timestamp, ++depositCounter);
  }

  function withdraw(
    IHashlessInstance _hashless,
    bytes calldata _proof,
    bytes32 _root,
    bytes32 _nullifierHash,
    address payable _recipient,
    address payable _relayer,
    address payable _referral,
    uint256 _refund
  ) external payable {
    _hashless.withdraw{ value: msg.value }(_proof, _root, _nullifierHash, _recipient, _relayer, _referral, _refund);
    emit Withdraw(_hashless.token(), _hashless.denomination(), block.timestamp, ++withdrawCounter);
  }

  function backupNotes(bytes[] calldata _encryptedNotes) external {
    for (uint256 i = 0; i < _encryptedNotes.length; i++) {
      emit EncryptedNote(msg.sender, _encryptedNotes[i]);
    }
  }
}
