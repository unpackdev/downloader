// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), 'Ownable: caller is not the owner');
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

interface IERC20 {
  function transfer(address recipient, uint256 amount) external returns (bool);

  function approve(address spender, uint256 amount) external returns (bool);
}

interface IAaveEcosystemReserve {
  function approve(
    IERC20 token,
    address recipient,
    uint256 amount
  ) external;

  function transfer(
    IERC20 token,
    address recipient,
    uint256 amount
  ) external;
}

/*
 * @title ControllerAaveEcosystemReserve
 * @dev Proxy smart contract to control the AaveEcosystemReserve, in order for the Aave Governance to call its
 * user-face functions (as the governance timelock is also the proxy admin of the AaveEcosystemReserve)
 * @author Aave
 */
contract ControllerAaveEcosystemReserve is Ownable {
  IAaveEcosystemReserve public constant AAVE_RESERVE_ECOSYSTEM = IAaveEcosystemReserve(
    0x25F2226B597E8F9514B3F68F00f494cF4f286491
  );

  constructor(address aaveGovShortTimelock) {
    transferOwnership(aaveGovShortTimelock);
  }

  function approve(
    IERC20 token,
    address recipient,
    uint256 amount
  ) external onlyOwner {
    AAVE_RESERVE_ECOSYSTEM.approve(token, recipient, amount);
  }

  function transfer(
    IERC20 token,
    address recipient,
    uint256 amount
  ) external onlyOwner {
    AAVE_RESERVE_ECOSYSTEM.transfer(token, recipient, amount);
  }
}