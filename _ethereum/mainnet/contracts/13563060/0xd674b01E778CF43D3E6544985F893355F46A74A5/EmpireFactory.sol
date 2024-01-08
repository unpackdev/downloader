// SPDX-License-Identifier: Unlicense

pragma solidity =0.6.8;

import "./IEmpireFactory.sol";

import "./EmpirePair.sol";

contract EmpireFactory is IEmpireFactory {
    address public override feeTo;
    address public override feeToSetter;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view override returns (uint256) {
        return allPairs.length;
    }

    function createPair(
        address tokenA,
        address tokenB,
        PairType pairType,
        uint256 unlockTime
    ) public override returns (address pair) {
        require(tokenA != tokenB, "Empire: IDENTICAL_ADDRESSES");
        (address token0, address token1) =
            tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "Empire: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "Empire: PAIR_EXISTS"); // single check is sufficient
        bytes memory bytecode = type(EmpirePair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        if (pairType != PairType.Common) {
            require(msg.sender == token0 || msg.sender == token1, "EmpireFactory::createPair: Insufficient Privileges");
            if (pairType == PairType.SweepableToken0 || pairType == PairType.SweepableToken1) unlockTime = ~uint256(0);
        }

        IEmpirePair(pair).initialize(token0, token1, pairType, unlockTime);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function createPair(address tokenA, address tokenB)
        external
        override
        returns (address pair)
    {
        return createPair(tokenA, tokenB, PairType.Common, 0);
    }

    function createEmpirePair(address tokenA, address tokenB, PairType pairType, uint256 unlockTime)
        external
        override
        returns (address pair)
    {
        return createPair(tokenA, tokenB, pairType, unlockTime);
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, "Empire: FORBIDDEN");
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, "Empire: FORBIDDEN");
        feeToSetter = _feeToSetter;
    }
}
