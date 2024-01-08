// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import "./IERC20.sol";
import "./SafeMath.sol";

contract ReignToken is IERC20 {
    using SafeMath for uint256;

    string public constant name = "Sovreign Governance Token";
    string public constant symbol = "REIGN";
    uint8 public constant decimals = 18;

    uint256 public override totalSupply;

    address public owner;

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    event Mint(address indexed to, uint256 value);

    constructor(address _owner) {
        owner = _owner;
    }

    // after the initial mint the owner will be set to 0 address
    function setOwner(address _owner) public {
        require(msg.sender == owner, "Only Owner can do this");
        owner = _owner;
    }

    function mint(address to, uint256 value) external returns (bool) {
        require(msg.sender == owner, "Only Owner can do this");

        _mint(to, value);
        emit Mint(to, value);
        return true;
    }

    function approve(address spender, uint256 value)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    /**
        INTERNAL
     */

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }
}
