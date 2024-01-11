pragma solidity ^0.8.9;
// SPDX-License-Identifier: MIT

import "./IShunaInuPair.sol";
import "./ShunaInuPair.sol";

contract ShunaInuFactory {
    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    constructor(
        address _feeToSetter,
        address _feeTo
    ) {
        feeToSetter = _feeToSetter;
        feeTo = _feeTo;
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair)
    {
        require(tokenA != tokenB, "ShunaInu: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "ShunaInu: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "ShunaInu: PAIR_EXISTS"); // single check is sufficient
        bytes memory bytecode = type(ShunaInuPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IShunaInuPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function getInitHash() public pure returns (bytes32) {
        bytes memory bytecode = type(ShunaInuPair).creationCode;
        return keccak256(abi.encodePacked(bytecode));
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, "ShunaInu: FORBIDDEN");
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, "ShunaInu: FORBIDDEN");
        feeToSetter = _feeToSetter;
    }
}
