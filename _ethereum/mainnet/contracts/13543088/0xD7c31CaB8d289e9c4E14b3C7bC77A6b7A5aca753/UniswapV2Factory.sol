// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./IUniswapV2Factory.sol";
import "./UniswapV2Pair.sol";

// import "./Ownable.sol";

contract UniswapV2Factory is IUniswapV2Factory {
    // address public override feeTo;
    address owner;

    address treasury;

    mapping(address => mapping(address => address)) public override getPair;
    // address[] public allPairs; // storage of all pairs
    uint public override allPairs;

    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(UniswapV2Pair).creationCode));
    
    uint releaseTime;
    uint lockTime = 2 days;

    constructor(address _owner, address _treasury) {
        owner = _owner;
        treasury = _treasury;
        releaseTime = block.timestamp;
    }

    function allPairsLength() external override view returns (uint) {
        // return pair length
        // return allPairs.length;
        return allPairs;
    }

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, 'PolkaBridge AMM V1: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'PolkaBridge AMM V1: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'PolkaBridge AMM V1: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IUniswapV2Pair(pair).initialize(token0, token1, owner, treasury);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        // allPairs.push(pair);
        allPairs++;
        // emit PairCreated(token0, token1, pair, allPairs.length);
        emit PairCreated(token0, token1, pair, allPairs);
    }

    function setTreasuryAddress(address _treasury) external override {
        require(msg.sender == owner, 'Only owner can set treasury');
        {
            require(block.timestamp - releaseTime >= lockTime, "current time is before release time");
            treasury = _treasury;
            emit TreasurySet(_treasury);
        }
    }

}
