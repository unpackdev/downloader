// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "./Configable.sol";
import "./Initializable.sol";
import "./IERC20.sol";
import "./ISwitchAcross.sol";


struct Order {
    uint sn;
    address user;
    uint chainId; 
    address tokenIn;
    address tokenOut;
    uint amountIn;
    uint amountOut;
    uint mode; // 1: auto process, 2: user process
    uint nonce;
    uint slide;
    uint fee;
}

interface _IAcross {
    function inOrders(address _user, uint _nonce) external view returns (Order memory);
    function outOrders(address _user, uint _nonce) external view returns (Order memory);
    function getInOrder(uint _sn) external view returns (Order memory);
    function getOutOrder(uint _sn) external view returns (Order memory);
}

interface ISwapPair {
    function totalSupply() external view returns(uint);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface ISwapFactory {
    function getPair(address _token0, address _token1) external view returns (address);
}

contract SwitchQuery is Configable, Initializable{

    struct Token {
        uint8 decimals;
        uint totalSupply;
        uint balance;
        uint allowance;
        string name;
        string symbol;
    }

    function initialize() public initializer {
        owner = msg.sender;
    }
    
    function queryTokenInfo(address _token, address _user, address _spender) public view returns(Token memory data){
        data.decimals = IERC20(_token).decimals();
        data.totalSupply = IERC20(_token).totalSupply();
        data.balance = IERC20(_token).balanceOf(_user);
        data.allowance = IERC20(_token).allowance(_user, _spender);
        data.name = IERC20(_token).name();
        data.symbol = IERC20(_token).symbol();
        return data;
    }
    
    function queryTokenList(address _user, address _spender, address[] memory _tokens) public view returns (Token[] memory data) {
        uint count = _tokens.length;
        data = new Token[](count);
        for(uint i = 0;i < count;i++) {
            data[i] = queryTokenInfo(_tokens[i], _user, _spender);
        }
        return data;
    }

    function getSwapPairReserve(address _pair) public view returns (address token0, address token1, uint decimals0, uint decimals1, uint reserve0, uint reserve1, uint totalSupply) {
        totalSupply = ISwapPair(_pair).totalSupply();
        token0 = ISwapPair(_pair).token0();
        token1 = ISwapPair(_pair).token1();
        decimals0 = IERC20(token0).decimals();
        decimals1 = IERC20(token1).decimals();
        (reserve0, reserve1, ) = ISwapPair(_pair).getReserves();
        return (token0, token1, decimals0, decimals1, reserve0, reserve1, totalSupply);
    }

    function getSwapPairReserveByTokens(address _factory, address _token0, address _token1) public view returns (address token0, address token1, uint decimals0, uint decimals1, uint reserve0, uint reserve1, uint totalSupply) {
        address pair = ISwapFactory(_factory).getPair(_token0, _token1);
        return getSwapPairReserve(pair);
    }

    // _tokenB is base token
    function getLpValueByFactory(address _factory, address _tokenA, address _tokenB, uint _amount) public view returns (uint, uint) {
        address pair = ISwapFactory(_factory).getPair(_tokenA, _tokenB);
        (, address token1, uint decimals0, uint decimals1, uint reserve0, uint reserve1, uint totalSupply) = getSwapPairReserve(pair);
        if(_amount == 0 || totalSupply == 0) {
            return (0, 0);
        }
        uint decimals = decimals0;
        uint total = reserve0 * 2;
        if(_tokenB == token1) {
            total = reserve1 * 2;
            decimals = decimals1;
        }
        return (_amount*total/totalSupply, decimals);
    }
}