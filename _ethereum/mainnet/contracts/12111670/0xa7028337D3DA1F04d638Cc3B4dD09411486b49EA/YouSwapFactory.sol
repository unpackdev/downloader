pragma solidity =0.5.16;

import "./IYouSwapFactory.sol";
import "./YouSwapPair.sol";
import "./MathV1.sol";

contract YouSwapFactory is IYouSwapFactory {
    using SafeMath  for uint;
    
    address public feeTo;
    address public feeToSetter;
    uint256 public feeToRate;
    bytes32 public initCodeHash;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
        initCodeHash = keccak256(abi.encodePacked(type(YouSwapPair).creationCode));
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'YouSwap: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'YouSwap: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'YouSwap: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(YouSwapPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IYouSwapPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'YouSwap: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'YouSwap: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }

    function setFeeToRate(uint256 _rate) external {
        require(msg.sender == feeToSetter, 'YouSwap: FORBIDDEN');
        require(_rate > 0, "YouSwap: FEE_TO_RATE_OVERFLOW");
        feeToRate = _rate.sub(1);
    }
}
