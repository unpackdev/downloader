pragma solidity 0.7.5;
// SPDX-License-Identifier: MIT

import "./IUniswapV2Factory.sol";
import "./ChilliSwapPair.sol";

contract ChilliSwapFactory is IUniswapV2Factory {
    address public override feeTo;
    address public override feeToSetter;

    uint public override protocolFeeDenominator = 3000; // uses ~10% of each swap fee
    uint public override totalFee = 996; // uses ~10% of each swap fee

    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(ChilliSwapPair).creationCode));

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external override view returns (uint256) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB)
        external
        override
        returns (address pair)
    {
        require(tokenA != tokenB, "ChilliSwap: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "ChilliSwap: ZERO_ADDRESS");
        require(
            getPair[token0][token1] == address(0),
            "ChilliSwap: PAIR_EXISTS"
        ); // single check is sufficient
        bytes memory bytecode = type(ChilliSwapPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IUniswapV2Pair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, "ChilliSwap: FORBIDDEN");
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, "ChilliSwap: FORBIDDEN");
        feeToSetter = _feeToSetter;
    }
    
    // set protocol fee denominator to change fee in _mintFee() function of V2 pair
    function setProtocolFee(uint _protocolFeeDenominator) external {
        require(msg.sender == feeToSetter, 'ChilliSwap: FORBIDDEN');
        require(_protocolFeeDenominator > 0, 'ChilliSwap: FORBIDDEN_FEE');
        protocolFeeDenominator = _protocolFeeDenominator;
    }

    // set total fee function to change fees in getAmountsOut function
    function changeTotalFee(uint _totalFee) external {
        require(msg.sender == feeToSetter, 'ChilliSwap: FORBIDDEN');
        require(_totalFee > 0, 'ChilliSwap: FORBIDDEN_FEE');
        totalFee = _totalFee;
    }
}
