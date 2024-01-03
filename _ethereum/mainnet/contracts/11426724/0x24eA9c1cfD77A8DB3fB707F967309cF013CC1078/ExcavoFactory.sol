pragma solidity >=0.6.6;

import "./IExcavoFactory.sol";
import "./IEXCV.sol";
import "./ICAVO.sol";
import "./ExcavoPair.sol";

contract ExcavoFactory is IExcavoFactory {
    address public immutable override EXCVToken;
    address public immutable override CAVOToken;
    address public immutable override WETHToken;
    address public immutable override feeToSetter;

    address public override router;
    // TODO: Remove
    bytes32 public immutable getCreationCode;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    constructor(address _CAVO, address _EXCV, address _WETH) public {
        feeToSetter = msg.sender;
        CAVOToken = _CAVO;
        EXCVToken = _EXCV;
        WETHToken = _WETH;
        getCreationCode = keccak256(type(ExcavoPair).creationCode);
    }

    function allPairsLength() external view override returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, 'Excavo: FORBIDDEN');
        require(router != address(0), 'Excavo: ROUTER_NOT_SET');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'Excavo: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'Excavo: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(ExcavoPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        IExcavoPair(pair).initialize(token0, token1, router);
       
        if ((token0 == CAVOToken || token1 == CAVOToken) && (token0 == WETHToken || token1 == WETHToken)) {
            // enable CAVO farming for CAVO/ETH pair only
            IExcavoPair(pair).setCAVO(CAVOToken, ICAVO(CAVOToken).xCAVOToken());
        } else if ((token0 == EXCVToken || token1 == EXCVToken) && (token0 == WETHToken || token1 == WETHToken)) {
            // enable xCAVO contract permissions for EXCV/ETH pair only
            IExcavoPair(pair).setCAVO(address(0), ICAVO(CAVOToken).xCAVOToken());
        }
        
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function initialize(address _router) external override {
        require(msg.sender == feeToSetter && router == address(0), 'Excavo: FORBIDDEN');
        router = _router;
    }
}