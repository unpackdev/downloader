// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import "./IERC20.sol";
import "./SafeMath.sol";

contract SovToken is IERC20 {
    using SafeMath for uint256;

    string public constant name = "Store-Of-Value Token";
    string public constant symbol = "SOV";
    uint8 public constant decimals = 18;
    uint256 public override totalSupply;

    address public reignDAO;

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;
    mapping(address => bool) public isMinter;

    event Mint(address indexed to, uint256 value);
    event SetMinter(address indexed account, bool value);
    event Burn(address indexed from, uint256 value);

    // initialize with DAO ad one Minter (can be zero address if not minter is needed)
    constructor(address _reignDAO, address _minter) {
        reignDAO = _reignDAO;
        isMinter[_minter] = true;
    }

    function setReignDAO(address _reignDAO) public {
        require(msg.sender == reignDAO, "Only reignDAO can do this");
        reignDAO = _reignDAO;
    }

    function setMinter(address _minter, bool value) public {
        require(msg.sender == reignDAO, "Only reignDAO can do this");
        isMinter[_minter] = value;

        emit SetMinter(_minter, value);
    }

    function mint(address to, uint256 value) external returns (bool) {
        require(isMinter[msg.sender] == true, "Only Minter can do this");

        _mint(to, value);
        emit Mint(to, value);
        return true;
    }

    function burn(address from, uint256 value) external returns (bool) {
        require(isMinter[msg.sender] == true, "Only Minter can do this");

        _burn(from, value);
        emit Burn(from, value);
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

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

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
