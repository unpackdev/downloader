// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;

import "./LowGasSafeMath.sol";
import "./IHotPotV3FundERC20.sol";


abstract contract HotPotV3FundERC20 is IHotPotV3FundERC20{
    using LowGasSafeMath for uint;

    string public override constant name = 'Hotpot V3';
    string public override constant symbol = 'HPT-V3';
    uint8 public override constant decimals = 18;
    uint public override totalSupply;

    mapping(address => uint) public override balanceOf;
    mapping(address => mapping(address => uint)) public override allowance;

    constructor() {
    }

    function _mint(address to, uint value) internal {
        require(to != address(0), "ERC20: mint to the zero address");

        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        require(from != address(0), "ERC20: burn from the zero address");

        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function approve(address spender, uint value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function _transfer(address from, address to, uint value) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function transfer(address to, uint value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from, 
        address to, 
        uint value
    ) external override returns (bool) {
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }
}
