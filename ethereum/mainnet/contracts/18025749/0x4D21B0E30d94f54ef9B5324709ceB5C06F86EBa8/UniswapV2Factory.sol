pragma solidity =0.5.16;

import "./IUniswapV2Factory.sol";
import "./UniswapV2Pair.sol";
import "./Roles.sol";

contract UniswapV2Factory is IUniswapV2Factory {
    using Roles for Roles.Role;

    Roles.Role private _admin;

    address public feeTo;
    address public feeToSetter;
    bytes32 public constant INIT_CODE_HASH = keccak256(abi.encodePacked(type(UniswapV2Pair).creationCode));

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;
    uint256 public swapLimitBP;

    uint256 public swapFeeBP;
    uint256 public addLiquidityFeeBP;
    uint256 public removeLiquidityFeeBP;

    address public feeReceiver;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter, address _feeReceiver) public {
        feeToSetter = _feeToSetter;
        feeReceiver = _feeReceiver;
        swapLimitBP = 500;
        swapFeeBP = 500;
        addLiquidityFeeBP = 500;
        removeLiquidityFeeBP = 500;
        _admin.add(msg.sender);
    }

    function addAdmin(address account) external {
        require(_admin.has(msg.sender), 'UniswapV2: FORBIDDEN');
        _admin.add(account);
    }

    function removeAdmin(address account) external {
        require(_admin.has(msg.sender), 'UniswapV2: FORBIDDEN');
        _admin.remove(account);
    }

    function lock(address pool) external {
        require(_admin.has(msg.sender), 'UniswapV2: FORBIDDEN');
        UniswapV2Pair(pool).setLock(true);
    }

    function unlock(address pool) external {
        require(_admin.has(msg.sender), 'UniswapV2: FORBIDDEN');
        UniswapV2Pair(pool).setLock(false);
    }

    function setFeeReceiver(address _feeReceiver) external {
        require(_admin.has(msg.sender), 'UniswapV2: FORBIDDEN');
        feeReceiver = _feeReceiver;
    }

    function setSwapLimitBP(uint256 value) external {
        require(_admin.has(msg.sender), 'UniswapV2: FORBIDDEN');
        swapLimitBP = value;
    }

    function setSwapFeeBP(uint256 value) external {
        require(_admin.has(msg.sender), 'UniswapV2: FORBIDDEN');
        swapFeeBP = value;
    }

    function setAddLiquidityFeeBP(uint256 value) external {
        require(_admin.has(msg.sender), 'UniswapV2: FORBIDDEN');
        addLiquidityFeeBP = value;
    }

    function setRemoveLiquidityFeeBP(uint256 value) external {
        require(_admin.has(msg.sender), 'UniswapV2: FORBIDDEN');
        removeLiquidityFeeBP = value;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IUniswapV2Pair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(_admin.has(msg.sender), 'UniswapV2: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(_admin.has(msg.sender), 'UniswapV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}
