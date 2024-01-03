pragma solidity >=0.6.6;

import "./IExcavoERC20.sol";
import "./SafeMath.sol";
import "./PairLibrary.sol";

abstract contract BaseExcavoPair is IExcavoERC20 {
    using SafeMath for uint;
    using PairLibrary for PairLibrary.Data;

    string public constant override name = 'Excavo';
    string public constant override symbol = 'EXCAVO';
    uint8 public constant override decimals = 18;
    
    PairLibrary.Data internal data;
    mapping(address => mapping(address => uint)) public override allowance;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() public {}

    function totalSupply() external view override returns (uint) {
        return data.totalSupply;
    }

    function balanceOf(address account) external view override returns (uint) {
        return data.balanceOf[account];
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) internal virtual;

    function approve(address spender, uint value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external override returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }
}
