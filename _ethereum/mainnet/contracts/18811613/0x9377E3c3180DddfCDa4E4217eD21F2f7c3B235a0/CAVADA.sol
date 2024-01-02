// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract CAVADA is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Burn(address indexed from, uint256 value);
    event Mint(address indexed to, uint256 value);

    constructor()  {
        name = "CAVADA";
        symbol = "CAVADA";
        decimals = 6;
        totalSupply = 3000000000 * (10 ** decimals);
        balanceOf[msg.sender] = totalSupply;
    }

    
    function transfer(address _to, uint256 _value) external override returns (bool) {
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(_value <= balanceOf[msg.sender], "ERC20: insufficient balance");

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external override returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external override returns (bool) {
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(_value <= balanceOf[_from], "ERC20: insufficient balance");
        require(_value <= allowance[_from][msg.sender], "ERC20: insufficient allowance");

        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);

        emit Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) external  {
        require(_value <= balanceOf[msg.sender], "ERC20: insufficient balance for burning");

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);

        emit Burn(msg.sender, _value);
    }

    function mint(address _to, uint256 _value) external onlyOwner {
        totalSupply = totalSupply.add(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);

        emit Mint(_to, _value);
    }

    function increaseAllowance(address _spender, uint256 _addedValue) external returns (bool) {
        allowance[msg.sender][_spender] = allowance[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }

    function decreaseAllowance(address _spender, uint256 _subtractedValue) external returns (bool) {
        uint256 currentAllowance = allowance[msg.sender][_spender];
        require(_subtractedValue <= currentAllowance, "ERC20: decreased allowance below zero");
        allowance[msg.sender][_spender] = currentAllowance.sub(_subtractedValue);
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }

    function _burnFrom(address _from, uint256 _value) external {
        require(_value <= balanceOf[_from], "ERC20: insufficient balance for burning");
        require(_value <= allowance[_from][msg.sender], "ERC20: insufficient allowance for burning");

        balanceOf[_from] = balanceOf[_from].sub(_value);
        totalSupply = totalSupply.sub(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);

        emit Burn(_from, _value);
    }
}