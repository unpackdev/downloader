// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IRenaswapV1Wrapper.sol";
import "./RenaswapV1Pair.sol";

/**
 * RenaswapV1Factory allows for the creation of RenaswapV1Pair contracts
 * Behaves the same as UniswapV2Factory
 */
contract RenaswapV1Factory is IUniswapV2Factory {

    /// @dev Sends fees to this address
    address public override feeTo;
    /// @dev Address able to change the feeTo value (owner)
    address public override feeToSetter;
    /// @dev Maps pair addresses by tokenA and tokenB keys
    mapping(address => mapping(address => address)) public override getPair;
    /// @dev List of all created pairs addresses
    address[] public override allPairs;
    /// @dev Wrapper address used with the pairs
    IRenaswapV1Wrapper public wrapper;

    /**
     * @param _feeToSetter Owner address
     * @param _wrapper Wrapper address
     */
    constructor(address _feeToSetter, IRenaswapV1Wrapper _wrapper) {
        wrapper = _wrapper;
        feeToSetter = _feeToSetter;
    }

    /**
     * @dev creates a new pair for tokenA and B
     * @param tokenA ERC20 tokenA address
     * @param tokenB ERC20 tokenB address, which is to be wrapped
     * @return pair new pair address
     */
    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tx.origin == feeToSetter, 'RenaswapV1: FORBIDDEN');
        require(tokenA != tokenB, 'RenaswapV1: IDENTICAL_ADDRESSES');
        require(tokenA != address(0) && tokenB != address(0), 'RenaswapV1: ZERO_ADDRESS');
        require(getPair[tokenA][tokenB] == address(0), 'RenaswapV1: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(RenaswapV1Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(tokenA, tokenB));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IUniswapV2Pair(pair).initialize(tokenA, address(wrapper));
        getPair[tokenA][tokenB] = pair;
        allPairs.push(pair);
        /// @dev Adds tokenB as wrapped token linked to the pair
        wrapper.addWrappedToken(tokenB, pair);
        emit PairCreated(tokenA, tokenB, pair, allPairs.length);
    }
    
    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view override returns (uint) {
        return allPairs.length;
    }
}