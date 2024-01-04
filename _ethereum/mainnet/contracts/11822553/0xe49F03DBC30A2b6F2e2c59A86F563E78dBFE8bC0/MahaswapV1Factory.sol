// SPDX-License-Identifier: MIT

pragma solidity =0.5.16;

import "./Ownable.sol";
import "./MahaswapV1Pair.sol";
import "./IUniswapV2Factory.sol";

contract MahaswapV1Factory is IMahaswapV1Factory, Ownable {
    address public feeTo;
    address public feeToSetter;
    bool public allowPairCreation = true;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(allowPairCreation, 'MahaswapV1Factory: pair creation disabled');
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient

        bytes memory bytecode = type(MahaswapV1Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        IMahaswapV1Pair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }

    function setIncentiveControllerForPair(address pair, address controller) public onlyOwner {
        IMahaswapV1Pair(pair).setIncentiveController(controller);
    }

    function setPairCreation(bool flag) public onlyOwner {
        allowPairCreation = flag;
    }

    function setSwapingPausedForPair(address pair, bool isSet) public onlyOwner {
        IMahaswapV1Pair(pair).setSwapingPaused(isSet);
    }
}
