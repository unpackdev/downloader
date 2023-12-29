pragma solidity 0.6.6;

import "./ISojoswapFactory.sol";
import "./SojoswapPair.sol";

contract SojoswapFactory is ISojoswapFactory {
    address override public feeTo;
    address override public feeToSetter;

    mapping(address => mapping(address => address)) override public getPair;
    address[] override public allPairs;

    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() override external view returns (uint256) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB)
        override
        external
        returns (address pair)
    {
        require(tokenA != tokenB, "Sojoswap: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "Sojoswap: ZERO_ADDRESS");
        require(
            getPair[token0][token1] == address(0),
            "Sojoswap: PAIR_EXISTS"
        ); // single check is sufficient
        bytes memory bytecode = type(SojoswapPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        ISojoswapPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) override external {
        require(msg.sender == feeToSetter, "Sojoswap: FORBIDDEN");
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) override external {
        require(msg.sender == feeToSetter, "Sojoswap: FORBIDDEN");
        feeToSetter = _feeToSetter;
    }
}
