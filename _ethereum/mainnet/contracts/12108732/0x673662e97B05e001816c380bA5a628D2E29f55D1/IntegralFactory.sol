// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

import 'IIntegralFactory.sol';
import 'IntegralPair.sol';

contract IntegralFactory is IIntegralFactory {
    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;
    address public override owner;

    constructor() {
        owner = msg.sender;
    }

    function allPairsLength() external view override returns (uint256) {
        return allPairs.length;
    }

    function createPair(
        address tokenA,
        address tokenB,
        address oracle,
        address trader
    ) external override returns (address pair) {
        require(msg.sender == owner, 'IF_FORBIDDEN');
        require(tokenA != tokenB, 'IF_IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'IF_ADDRESS_ZERO');
        require(getPair[token0][token1] == address(0), 'IF_PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(IntegralPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IIntegralPair(pair).initialize(token0, token1, oracle, trader);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setOwner(address _owner) external override {
        require(msg.sender == owner, 'IF_FORBIDDEN');
        owner = _owner;
        emit OwnerSet(owner);
    }

    function setMintFee(
        address tokenA,
        address tokenB,
        uint256 fee
    ) external override {
        require(msg.sender == owner, 'IF_FORBIDDEN');
        _getPair(tokenA, tokenB).setMintFee(fee);
    }

    function setBurnFee(
        address tokenA,
        address tokenB,
        uint256 fee
    ) external override {
        require(msg.sender == owner, 'IF_FORBIDDEN');
        _getPair(tokenA, tokenB).setBurnFee(fee);
    }

    function setSwapFee(
        address tokenA,
        address tokenB,
        uint256 fee
    ) external override {
        require(msg.sender == owner, 'IF_FORBIDDEN');
        _getPair(tokenA, tokenB).setSwapFee(fee);
    }

    function setOracle(
        address tokenA,
        address tokenB,
        address oracle
    ) external override {
        require(msg.sender == owner, 'IF_FORBIDDEN');
        _getPair(tokenA, tokenB).setOracle(oracle);
    }

    function setTrader(
        address tokenA,
        address tokenB,
        address trader
    ) external override {
        require(msg.sender == owner, 'IF_FORBIDDEN');
        _getPair(tokenA, tokenB).setTrader(trader);
    }

    function setToken0AbsoluteLimit(
        address tokenA,
        address tokenB,
        uint256 token0AbsoluteLimit
    ) external {
        require(msg.sender == owner, 'IF_FORBIDDEN');
        _getPair(tokenA, tokenB).setToken0AbsoluteLimit(token0AbsoluteLimit);
    }

    function setToken1AbsoluteLimit(
        address tokenA,
        address tokenB,
        uint256 token1AbsoluteLimit
    ) external {
        require(msg.sender == owner, 'IF_FORBIDDEN');
        _getPair(tokenA, tokenB).setToken1AbsoluteLimit(token1AbsoluteLimit);
    }

    function setToken0RelativeLimit(
        address tokenA,
        address tokenB,
        uint256 token0RelativeLimit
    ) external {
        require(msg.sender == owner, 'IF_FORBIDDEN');
        _getPair(tokenA, tokenB).setToken0RelativeLimit(token0RelativeLimit);
    }

    function setToken1RelativeLimit(
        address tokenA,
        address tokenB,
        uint256 token1RelativeLimit
    ) external {
        require(msg.sender == owner, 'IF_FORBIDDEN');
        _getPair(tokenA, tokenB).setToken1RelativeLimit(token1RelativeLimit);
    }

    function setPriceDeviationLimit(
        address tokenA,
        address tokenB,
        uint256 priceLimit
    ) external {
        require(msg.sender == owner, 'IF_FORBIDDEN');
        _getPair(tokenA, tokenB).setPriceDeviationLimit(priceLimit);
    }

    function collect(
        address tokenA,
        address tokenB,
        address to
    ) external override {
        require(msg.sender == owner, 'IF_FORBIDDEN');
        _getPair(tokenA, tokenB).collect(to);
    }

    function withdraw(
        address tokenA,
        address tokenB,
        uint256 amount,
        address to
    ) external override {
        require(msg.sender == owner, 'IF_FORBIDDEN');
        IIntegralPair pair = _getPair(tokenA, tokenB);
        pair.transfer(address(pair), amount);
        pair.burn(to);
    }

    function _getPair(address tokenA, address tokenB) internal view returns (IIntegralPair pair) {
        pair = IIntegralPair(getPair[tokenA][tokenB]);
        require(address(pair) != address(0), 'IF_PAIR_DOES_NOT_EXIST');
    }
}
