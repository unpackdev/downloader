// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPoolFactory.sol";
import "./ERC20Pair.sol";

contract PoolFactory is IPoolFactory {
    address public override feeTo;
    address public override owner;
    address public override feeToSetter;
    address public override ownerSetter;

    mapping(address => mapping(address => mapping(uint32 => address)))
        public
        override getPair;
    mapping(address => bool) public protocolTokens;
    address[] public override allPairs;
    bytes32 public constant INIT_CODE_HASH =
        keccak256(abi.encodePacked(type(ERC20Pair).creationCode));

    constructor(address _feeToSetter, address _owner) {
        feeToSetter = _feeToSetter;
        feeTo = _feeToSetter;
        owner = _owner;
        ownerSetter = _owner;
    }

    function allPairsLength() external view override returns (uint256) {
        return allPairs.length;
    }

    function createPair(
        address tokenA,
        address tokenB,
        uint32 fee
    ) external override returns (address pair) {
        require(tokenA != tokenB, "PoolFactory: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "PoolFactory: ZERO_ADDRESS");
        // it's not allowed to create pool with more that 10% fee since fee deNumerator = 10 ** 5
        uint32 protocolFee = getProtocolFee(token0, token1);
        require(fee >= protocolFee, "PoolFactory: INVALID_FEE");
        uint32 lpFee = fee - protocolFee;
        require(lpFee <= 10**4, "PoolFactory: TOO_MUCH_FEE");
        require(
            getPair[token0][token1][fee] == address(0),
            "PoolFactory: PAIR_EXISTS"
        );
        // single check is sufficient
        bytes memory bytecode = type(ERC20Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1, fee));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        ERC20Pair(pair).initialize(token0, token1, fee, protocolFee);
        getPair[token0][token1][fee] = pair;
        getPair[token1][token0][fee] = pair;
        // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, fee);
    }

    // protocol fee will be always 0.05% for all pools and 0.03% for protocol tokens
    // wheres   fee deNumerator = 10 ** 5; protocol fee = 30/10**5 || 50/10**5
    function getProtocolFee(address token0, address token1)
        public
        view
        returns (uint32)
    {
        if (protocolTokens[token0] || protocolTokens[token1]) {
            return 30;
        }
        return 50;
    }

    function setFeeProtocolToken(address token, bool active) external {
        require(msg.sender == owner, "PoolFactory: FORBIDDEN");
        protocolTokens[token] = active;
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, "PoolFactory: FORBIDDEN");
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, "PoolFactory: FORBIDDEN");
        feeToSetter = _feeToSetter;
    }
}
