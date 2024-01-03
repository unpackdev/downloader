// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";
import "./SafeMath.sol";

contract X2Fee is IERC20 {
    using SafeMath for uint256;

    string public constant name = 'X2 Fee Token';
    string public constant symbol = 'X2FEE';
    uint8 public constant decimals = 18;

    uint256 public override totalSupply;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowances;

    constructor(uint256 maxSupply) public {
        _mint(msg.sender, maxSupply);
    }

    function burn(uint256 _amount) public {
        _burn(msg.sender, _amount);
    }

    function balanceOf(address _account) public view override returns (uint256) {
        return balances[_account];
    }

    function transfer(address _recipient, uint256 _amount) public override returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public view override returns (uint256) {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) public override returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool) {
        uint256 nextAllowance = allowances[_sender][msg.sender].sub(_amount, "X2Fee: transfer amount exceeds allowance");
        _approve(_sender, msg.sender, nextAllowance);
        _transfer(_sender, _recipient, _amount);
        return true;
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) private {
        require(_sender != address(0), "X2Fee: transfer from the zero address");
        require(_recipient != address(0), "X2Fee: transfer to the zero address");

        balances[_sender] = balances[_sender].sub(_amount, "X2Fee: transfer amount exceeds balance");
        balances[_recipient] = balances[_recipient].add(_amount);
        emit Transfer(_sender, _recipient, _amount);
    }

    function _mint(address account, uint256 _amount) private {
        require(account != address(0), "X2Fee: mint to the zero address");

        balances[account] = balances[account].add(_amount);
        totalSupply = totalSupply.add(_amount);
        emit Transfer(address(0), account, _amount);
    }

    function _burn(address _account, uint256 _amount) private {
        require(_account != address(0), "X2Fee: burn from the zero address");

        balances[_account] = balances[_account].sub(_amount, "X2Fee: burn amount exceeds balance");
        totalSupply = totalSupply.sub(_amount);
        emit Transfer(_account, address(0), _amount);
    }

    function _approve(address _owner, address _spender, uint256 _amount) private {
        require(_owner != address(0), "X2Fee: approve from the zero address");
        require(_spender != address(0), "X2Fee: approve to the zero address");

        allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }
}
