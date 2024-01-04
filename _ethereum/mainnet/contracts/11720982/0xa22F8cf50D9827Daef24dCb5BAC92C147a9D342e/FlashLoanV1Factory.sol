pragma solidity =0.5.16;


interface IFlashLoanV1Factory {
    event PoolCreated(address indexed token, address pool, uint);

    function feeInBips() external view returns (uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPool(address token) external view returns (address pool);
    function allPools(uint) external view returns (address pool);
    function allPoolsLength() external view returns (uint);

    function createPool(address token) external returns (address pool);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IFlashLoanV1Pool {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount);
    event Burn(address indexed sender, uint amount, address indexed to);
    event FlashLoan(
        address indexed target,
        address indexed initiator,
        address indexed asset,
        uint amount,
        uint premium
    );
    event Sync(uint reserve);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token() external view returns (address);
    function reserve() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount);
    function flashLoan(address target, uint amount, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address) external;
}

interface IFlashLoanV1ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)
library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

contract FlashLoanV1ERC20 is IFlashLoanV1ERC20 {
    using SafeMath for uint;

    string public constant name = 'Deer FlashLoan V1';
    string public constant symbol = 'DEER-V1';
    uint8 public constant decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() public {
        uint chainId;
        assembly {
            chainId := chainid
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'FlashLoanV1: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'FlashLoanV1: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IFlashLoanReceiver {
  function executeOperation(
    address asset,
    uint amount,
    uint premium,
    address initiator,
    bytes calldata params
  ) external returns (bool);
}

contract FlashLoanV1Pool is IFlashLoanV1Pool, FlashLoanV1ERC20 {
    using SafeMath  for uint;

    uint public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public factory;
    address public token;

    uint public reserve; // uses single storage slot, accessible via getReserves

    uint public kLast; // reserve, as of immediately after the most recent liquidity event

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'FlashLoanV1: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function _safeTransfer(address _token, address to, uint value) private {
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'FlashLoanV1: TRANSFER_FAILED');
    }

    event Mint(address indexed sender, uint amount);
    event Burn(address indexed sender, uint amount, address indexed to);
    event FlashLoan(
        address indexed target,
        address indexed initiator,
        address indexed asset,
        uint amount,
        uint premium
    );
    event Sync(uint reserve);

    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token) external {
        require(msg.sender == factory, 'FlashLoanV1: FORBIDDEN'); // sufficient check
        token = _token;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance) private {
        require(balance <= uint112(-1), 'FlashLoanV1: OVERFLOW');
        reserve = balance;
        emit Sync(reserve);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth
    function _mintFee(uint k) private returns (bool feeOn) {
        address feeTo = IFlashLoanV1Factory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                if (k > _kLast) {
                    uint numerator = totalSupply.mul(k.sub(_kLast));
                    uint denominator = k.mul(5).add(_kLast);
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock returns (uint liquidity) {
        uint _reserve = reserve; // gas savings
        uint balance = IERC20(token).balanceOf(address(this));
        uint amount = balance.sub(_reserve);

        bool feeOn = _mintFee(_reserve);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = amount.sub(MINIMUM_LIQUIDITY);
           _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = amount.mul(_totalSupply) / reserve;
        }
        require(liquidity > 0, 'FlashLoanV1: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balance);
        if (feeOn) kLast = reserve; // reserve is up-to-date
        emit Mint(msg.sender, amount);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock returns (uint amount) {
        uint _reserve = reserve; // gas savings
        address _token = token; // gas savings
        uint balance = IERC20(_token).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount = liquidity.mul(balance) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount > 0, 'FlashLoanV1: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        _safeTransfer(_token, to, amount);
        balance = IERC20(_token).balanceOf(address(this));

        _update(balance);
        if (feeOn) kLast = reserve; // reserve is up-to-date
        emit Burn(msg.sender, amount, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function flashLoan(address target, uint amount, bytes calldata data) external lock {
        address _token = token; // gas savings
        require(amount > 0, 'FlashLoanV1: INSUFFICIENT_LIQUIDITY_TO_BORROW');

        uint balanceBefore = IERC20(_token).balanceOf(address(this));
        require(balanceBefore >= amount, 'FlashLoanV1: INSUFFICIENT_LIQUIDITY_TO_BORROW');

        uint feeInBips = IFlashLoanV1Factory(factory).feeInBips();
        uint amountFee = amount.mul(feeInBips) / 10000;
        require(amountFee > 0, 'FlashLoanV1: AMOUNT_TOO_SMALL');

        _safeTransfer(_token, target, amount);

        IFlashLoanReceiver receiver = IFlashLoanReceiver(target);
        receiver.executeOperation(_token, amount, amountFee, msg.sender, data);

        uint balanceAfter = IERC20(_token).balanceOf(address(this));
        require(balanceAfter == balanceBefore.add(amountFee), 'FlashLoanV1: AMOUNT_INCONSISTENT');

        _update(balanceAfter);
        emit FlashLoan(target, msg.sender, _token, amount, amountFee);
    }

    // force balances to match reserves
    function skim(address to) external lock {
        address _token = token; // gas savings
        _safeTransfer(_token, to, IERC20(_token).balanceOf(address(this)).sub(reserve));
    }

    // force reserves to match balances
    function sync() external lock {
        _update(IERC20(token).balanceOf(address(this)));
    }
}

contract FlashLoanV1Factory is IFlashLoanV1Factory {
    uint public feeInBips = 5;
    address public feeTo;
    address public feeToSetter;

    mapping(address => address) public getPool;
    address[] public allPools;

    event PoolCreated(address indexed token, address pool, uint);

    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
    }

    function allPoolsLength() external view returns (uint) {
        return allPools.length;
    }

    function createPool(address token) external returns (address pool) {
        require(token != address(0), 'FlashLoanV1: ZERO_ADDRESS');
        require(getPool[token] == address(0), 'FlashLoanV1: POOL_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(FlashLoanV1Pool).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token));
        assembly {
            pool := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IFlashLoanV1Pool(pool).initialize(token);
        getPool[token] = pool;
        allPools.push(pool);
        emit PoolCreated(token, pool, allPools.length);
    }

    function setFeeInBips(uint _feeInBips) external {
        require(msg.sender == feeToSetter, 'FlashLoanV1: FORBIDDEN');
        require(_feeInBips > 0 && _feeInBips < 100, 'FlashLoanV1: INVALID_VALUE');
        feeInBips = _feeInBips;
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'FlashLoanV1: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'FlashLoanV1: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}