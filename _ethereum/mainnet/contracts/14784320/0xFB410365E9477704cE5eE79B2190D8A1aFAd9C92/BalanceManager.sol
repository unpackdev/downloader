// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ECDSAUpgradeable.sol";

contract BalanceManager is Initializable, OwnableUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using ECDSAUpgradeable for bytes32;

  event NFTLDeposited(address indexed by, uint256 amount);
  event MaintainerUpdated(address indexed by, address indexed oldMaintainer, address indexed newMaintainer);
  event NFTLWithdrawn(address indexed by, address indexed beneficiary, uint256 amount);
  event NFTLWithdrawnByDAO(address indexed by, address indexed beneficiary, uint256 amount);

  /// @dev NFTL token address
  address public nftl;

  /// @dev User -> Total deposit amount
  mapping(address => uint256) private userDeposits;

  /// @dev User -> Total withdrawal amount
  mapping(address => uint256) private userWithdrawals;

  /// @dev User -> Nonce
  mapping(address => uint256) public nonce;

  /// @dev Signature -> Bool
  mapping(bytes => bool) public signatures;

  /// @dev Maintainer address
  address public maintainer;

  function initialize(address _nftl, address _maintainer) public initializer {
    __Ownable_init();

    nftl = _nftl;
    maintainer = _maintainer;
  }

  /**
   * @notice Deposit NFTL tokens into the contract
   * @param _amount Deposit amount
   */
  function deposit(uint256 _amount) external {
    IERC20Upgradeable(nftl).safeTransferFrom(msg.sender, address(this), _amount);
    userDeposits[msg.sender] += _amount;

    emit NFTLDeposited(msg.sender, _amount);
  }

  /**
   * @notice Withdraw NFTL tokens from the contract to the user
   * @param _amount NFTL token amount to withdraw
   * @param _nonce Nonce
   * @param _expireAt Expiration time
   * @param _signature Signature
   */
  function withdraw(
    uint256 _amount,
    uint256 _nonce,
    uint256 _expireAt,
    bytes memory _signature
  ) external {
    // check if the nonce is matched
    require(nonce[msg.sender] == _nonce, "mismatched nonce");
    nonce[msg.sender] += 1;

    // check if the request is not expired
    require(block.timestamp <= _expireAt, "expired withdrawal request");

    // check if the signature was already used
    require(!signatures[_signature], "used signature");
    signatures[_signature] = true;

    // check the signer
    bytes32 data = keccak256(abi.encodePacked(msg.sender, _amount, _nonce, _expireAt));
    require(data.toEthSignedMessageHash().recover(_signature) == maintainer, "wrong signer");

    // update the withdrawal amount
    userWithdrawals[msg.sender] += _amount;

    // transfer tokens to the user
    IERC20Upgradeable(nftl).safeTransfer(msg.sender, _amount);

    emit NFTLWithdrawn(msg.sender, msg.sender, _amount);
  }

  /**
   * @notice Update maintianer address
   * @dev Only owner
   * @param _maintainer New maintainer address
   */
  function updateMaintainer(address _maintainer) external onlyOwner {
    emit MaintainerUpdated(msg.sender, maintainer, _maintainer);

    maintainer = _maintainer;
  }

  /**
   * @notice Allow DAO to withdraw NFTL token from the contract
   * @dev Only owner
   * @param _beneficiary Beneficiary address
   * @param _amount NFTL token amount to withdraw
   */
  function withdrawByDAO(address _beneficiary, uint256 _amount) external onlyOwner {
    IERC20Upgradeable(nftl).safeTransfer(_beneficiary, _amount);

    emit NFTLWithdrawnByDAO(msg.sender, _beneficiary, _amount);
  }
}
