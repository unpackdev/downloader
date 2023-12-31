pragma solidity ^0.8.14;

import "./DarwinSwapPair.sol";
import "./DarwinLiquidityBundles.sol";
import "./LiquidityInjector.sol";

import "./IDarwinSwapRouter.sol";
import "./IDarwinSwapFactory.sol";
import "./IMasterChef.sol";

contract DarwinSwapFactory is IDarwinSwapFactory {
    address public dev;
    address public router;
    address public lister;
    address public feeTo;
    IDarwinLiquidityBundles public liquidityBundles;
    IDarwinMasterChef public masterChef;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    bytes32 public constant INIT_CODE_HASH =
        keccak256(abi.encodePacked(type(DarwinSwapPair).creationCode));

    event LiquidityInjectorCreated(address indexed pair, address injector);

    constructor(address _lister, IDarwinMasterChef _masterChef) {
        dev = msg.sender;
        lister = _lister;
        masterChef = _masterChef;
        // Create LiquidityBundles contract
        bytes memory bytecode = type(DarwinLiquidityBundles).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(address(this)));
        address _liquidityBundles;
        assembly {
            _liquidityBundles := create2(
                0,
                add(bytecode, 32),
                mload(bytecode),
                salt
            )
        }
        liquidityBundles = IDarwinLiquidityBundles(_liquidityBundles);
    }

    modifier onlyDev() {
        require(msg.sender == dev, "DarwinSwap: CALLER_NOT_DEV");
        _;
    }

    modifier onlyLister() {
        require(msg.sender == lister, "DarwinSwap: CALLER_NOT_LISTER_CONTRACT");
        _;
    }

    function createPair(
        address tokenA,
        address tokenB
    ) external onlyLister returns (address pair) {
        require(tokenA != tokenB, "DarwinSwap: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "DarwinSwap: ZERO_ADDRESS");
        require(
            getPair[token0][token1] == address(0),
            "DarwinSwap: PAIR_EXISTS"
        ); // single check is sufficient
        bytes memory bytecode = type(DarwinSwapPair).creationCode;
        bytes memory bytecode2 = type(LiquidityInjector).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        address _liquidityInjector;
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
            _liquidityInjector := create2(
                0,
                add(bytecode2, 32),
                mload(bytecode2),
                salt
            )
        }

        emit LiquidityInjectorCreated(pair, _liquidityInjector);

        ILiquidityInjector(_liquidityInjector).initialize(pair, token0, token1);
        IDarwinSwapPair(pair).initialize(token0, token1, _liquidityInjector);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external onlyDev {
        feeTo = _feeTo;
    }

    function setDev(address _dev) external onlyDev {
        dev = _dev;
    }

    function setLister(address _lister) external onlyDev {
        lister = _lister;
    }

    function setRouter(address _router) external onlyDev {
        require(router == address(0), "DarwinSwapFactory: INVALID");
        router = _router;
        liquidityBundles.initialize(
            _router,
            masterChef,
            IDarwinSwapRouter(_router).WETH()
        );
    }
}
