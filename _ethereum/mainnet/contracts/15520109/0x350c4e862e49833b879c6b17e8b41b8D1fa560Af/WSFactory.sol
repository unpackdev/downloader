// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;

import "./IWSFactory.sol";
import "./IWSController.sol";
import "./WSProxyPair.sol";
import "./IWSPair.sol";
import "./IWSImplementation.sol";

contract WSFactory is IWSFactory, IWSImplementation {
    bool private initialized;
    address public override feeTo;
    address public override feeToSetter;
    address public controller;
    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(WSProxyPair).creationCode));

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function initialize(address _feeToSetter, address _controller) public returns(bool) {
        require(initialized == false, "WSFactory: Factory was already initialized.");
        require(_controller != address(0), "WSFactory: controller should not bo zero address.");
        require(_feeToSetter != address(0), "WSFactory: _feeToSetter should not be zero address.");
        feeToSetter = _feeToSetter;
        controller = _controller;
        initialized = true;
        return true;
    }

    function allPairsLength() external override view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, 'WSwap: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'WSwap: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'WSwap: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(WSProxyPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        // Factory as current proxypair admin initializes proxy with logic and right admin
        IWSProxy(pair).initialize(IWSController(controller).getLogicForPair(), IWSController(controller).getCurrentAdmin(), "");
        // Factory initialized created pair with tokens variables
        require(IWSPair(pair).initialize(address(this), token0, token1) == true, "WSFactory: Pair initialize not succeed.");
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, 'WSwap: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, 'WSwap: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }

    function getImplementationType() external pure override returns(uint256) {
        /// 1 is a factory type
        return 1;
    }
}
