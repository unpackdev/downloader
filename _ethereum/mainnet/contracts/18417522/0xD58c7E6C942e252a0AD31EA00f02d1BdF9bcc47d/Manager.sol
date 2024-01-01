// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Manager{

    address immutable public uniswapRouterV2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    // mainnet weth: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    // goerli weth: 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6
    address public tokenB;
    address immutable public iUniswapV2Factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public owner;
    address public tokenA;
    address public lpToken;
    address public vault;
    address public stPool;
    address public exPool;
    address public pair;
    address public receiverA;
    address public receiverB;


    constructor(){
        owner = msg.sender;
    }

    function updateOwner(address _owner) public onlyOwner{
        owner = _owner;
    }

    function updateTokenA(address _token) public onlyOwner{
        tokenA = _token;
    }

    function updateLpToken(address _lpToken) public onlyOwner{
        lpToken = _lpToken;
    }

    function updateVault(address _vault) public onlyOwner{
        vault = _vault;
    }

    function updateStPool(address _stPool) public onlyOwner{
        stPool = _stPool;
    }

    function updateExPool(address _exPool) public onlyOwner{
        exPool = _exPool;
    }

    function updatePair() public onlyOwner{
        pair = IUniswapV2Factory(iUniswapV2Factory).getPair(tokenA,tokenB);
    }

    function updateTokenB(address _token) public onlyOwner{
        tokenB = _token;
    }

    function updateReceiverA(address _receiver) public onlyOwner{
        receiverA = _receiver;
    }

    function updateReceiverB(address _receiver) public onlyOwner{
        receiverB = _receiver;
    }

    modifier onlyOwner() {
        require(msg.sender == owner,"ERC20: address is not owner");
        _;
    }
}


interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}