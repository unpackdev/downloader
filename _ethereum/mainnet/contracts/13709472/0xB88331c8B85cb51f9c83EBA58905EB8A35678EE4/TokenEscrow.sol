// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";


contract TokenEscrow {
  using SafeMath for uint;
  IERC20 public token;

  constructor(address tokenAddr) {
    token = IERC20(tokenAddr);
  }

  event Deposited(address indexed user, uint256 weiAmount);
  event Withdrawn(address indexed user, uint256 weiAmount);

  mapping(address => uint256) private _deposits;

  /**
    * @dev Checks the funds deposited in the contract by _user.
    * @param _user The user to check funds of.
    */
  function depositsOf(address _user) public view returns (uint256) {
    return _deposits[_user];
  }

  /**
    * @dev Stores the sent _amount as funds to be withdrawn.
    * @param _amount The amount funds to deposit.
    */
  function deposit(uint256 _amount) public {
    address msgSender = msg.sender;
    token.transferFrom(msgSender, address(this), _amount);
    _deposits[msgSender] = _deposits[msgSender].add(_amount);
    emit Deposited(msgSender, _amount);
  }

  /**
    * @dev Withdraw the sent _amount from contract.
    *
    * @param _amount Amount of funds to withdraw from contract.
    */
  function withdraw(uint256 _amount) public {
    address msgSender = msg.sender;
    require(_deposits[msgSender] >= _amount, "Withdraw: user does not have enough funds");
    
    if(_amount > 0) {
      token.transfer(msgSender, _amount);
      _deposits[msgSender] = _deposits[msgSender].sub(_amount);
      emit Withdrawn(msg.sender, _amount);
    }

  }

  /**
    * @dev Withdraw all user funds from contract.
    *
    */
  function withdrawAll() public {
    address msgSender = msg.sender;
    uint256 amount = _deposits[msgSender];
    require(_deposits[msgSender] > 0, "Withdraw: user does not have funds");
    
    token.transfer(msgSender, amount);
    emit Withdrawn(msgSender, amount);
    _deposits[msgSender] = 0;
  }
}
