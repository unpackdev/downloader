// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import "./TomiLP.sol";
import "./Ownable.sol";

interface ITomiLP {
    function addLiquidity(
        address user,
        uint256 amountA,
        uint256 amountB,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline) external returns (
            uint256 _amountA,
            uint256 _amountB,
            uint256 _liquidity
        );
    function removeLiquidity(
        address user,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline) external returns (
            uint256 _amountA,
            uint256 _amountB
        );
    function addLiquidityETH(
        address user,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256 deadline) external payable returns (
            uint256 _amountToken,
            uint256 _amountETH,
            uint256 _liquidity
        );
    function removeLiquidityETH (
        address user,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256 deadline) external returns (uint256 _amountToken, uint256 _amountETH);
    function initialize(address _tokenA, address _tokenB, address _TOMI, address _POOL, address _PLATFORM, address _WETH) external;
    function upgrade(address _PLATFORM) external;
    function tokenA() external returns(address);
}

contract TomiDelegate is Ownable{
    using SafeMath for uint;
    
    address public PLATFORM;
    address public POOL;
    address public TOMI;
    address public WETH;
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;
    mapping(address => bool) public isPair;
    mapping(address => address[]) public playerPairs;
    mapping(address => mapping(address => bool)) public isAddPlayerPair;

    bytes32 public contractCodeHash;
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);
    
    constructor(address _PLATFORM, address _POOL, address _TOMI, address _WETH) public {
        PLATFORM = _PLATFORM;
        POOL = _POOL;
        TOMI = _TOMI;
        WETH = _WETH;
    }
    
    receive() external payable {
    }
    
    function upgradePlatform(address _PLATFORM) external onlyOwner {
        for(uint i = 0; i < allPairs.length;i++) {
            ITomiLP(allPairs[i]).upgrade(_PLATFORM);
        }
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    function getPlayerPairCount(address player) external view returns (uint256) {
        return playerPairs[player].length;
    }

    function _addPlayerPair(address _user, address _pair) internal {
        if (isAddPlayerPair[_user][_pair] == false) {
            isAddPlayerPair[_user][_pair] = true;
            playerPairs[_user].push(_pair);
        }
    }

    function addPlayerPair(address _user) external {
        require(isPair[msg.sender], 'addPlayerPair Forbidden');
        _addPlayerPair(_user, msg.sender);
    }
    
    function approveContract(address token, address spender, uint amount) internal {
        uint allowAmount = IERC20(token).totalSupply();
        if(allowAmount < amount) {
            allowAmount = amount;
        }
        if(IERC20(token).allowance(address(this), spender) < amount) {
            TransferHelper.safeApprove(token, spender, allowAmount);
        }
    }

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256 deadline
        ) payable external returns (
            uint256 _amountToken,
            uint256 _amountETH,
            uint256 _liquidity
        ) {
        address pair = getPair[token][WETH];
            if(pair == address(0)) {
                pair = _createPair(token, WETH);
            }
            
            _addPlayerPair(msg.sender, pair);

            TransferHelper.safeTransferFrom(token, msg.sender, address(this), amountTokenDesired);
            approveContract(token, pair, amountTokenDesired);
            (_amountToken, _amountETH, _liquidity) = ITomiLP(pair).addLiquidityETH{value: msg.value}(msg.sender, amountTokenDesired, amountTokenMin, amountETHMin, deadline);
    }
    
    
    
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline) external returns (
            uint256 _amountA,
            uint256 _amountB,
            uint256 _liquidity
        ) {
            address pair = getPair[tokenA][tokenB];
            if(pair == address(0)) {
                pair = _createPair(tokenA, tokenB);
            }

            _addPlayerPair(msg.sender, pair);

            if(tokenA != ITomiLP(pair).tokenA()) {
                (tokenA, tokenB) = (tokenB, tokenA);
                (amountA, amountB, amountAMin, amountBMin) = (amountB, amountA, amountBMin, amountAMin);
            }
            
            TransferHelper.safeTransferFrom(tokenA, msg.sender, address(this), amountA);
            TransferHelper.safeTransferFrom(tokenB, msg.sender, address(this), amountB);
            approveContract(tokenA, pair, amountA);
            approveContract(tokenB, pair, amountB);

            (_amountA, _amountB, _liquidity) = ITomiLP(pair).addLiquidity(msg.sender, amountA, amountB, amountAMin, amountBMin, deadline);
            if(tokenA != ITomiLP(pair).tokenA()) {
                (_amountA, _amountB) = (_amountB, _amountA);
            }
    }
    
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        uint deadline
        ) external returns (uint _amountToken, uint _amountETH) {
            address pair = getPair[token][WETH];
            (_amountToken, _amountETH) = ITomiLP(pair).removeLiquidityETH(msg.sender, liquidity, amountTokenMin, amountETHMin, deadline);
        }
    
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline) external returns (
            uint256 _amountA,
            uint256 _amountB
        ) {
        address pair = getPair[tokenA][tokenB];
        (_amountA, _amountB) = ITomiLP(pair).removeLiquidity(msg.sender, liquidity, amountAMin, amountBMin, deadline);
    }

    function _createPair(address tokenA, address tokenB) internal returns (address pair){
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'TOMI FACTORY: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'TOMI FACTORY: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(TomiLP).creationCode;
        if (uint256(contractCodeHash) == 0) {
            contractCodeHash = keccak256(bytecode);
        }
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        isPair[pair] = true;
        ITomiLP(pair).initialize(token0, token1, TOMI, POOL, PLATFORM, WETH);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }
}