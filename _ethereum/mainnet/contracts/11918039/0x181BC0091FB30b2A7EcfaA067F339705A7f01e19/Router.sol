pragma solidity ^0.6.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IUniswapV2Pair.sol";
import "./TransferHelper.sol";
import "./IUniswapV2Router02.sol";

import "./IBalancerPool.sol";
import "./IStakingManager.sol";
import "./Initializable.sol";

/**
 * @title Router
 * @dev Liquidity management contract
 */
contract Router is Ownable, Initializable {
    using SafeMath for uint256;

    /**
     * @dev informs that EURxb router balance is empty
     */
    event EmptyEURxbBalance();

    address private _teamAddress;
    IStakingManager private _stakingManager;
    uint256 private _startTime;
    uint256 private _endTime;
    address private _tUSDT;
    address private _tUSDC;
    address private _tBUSD;
    address private _tDAI;
    IERC20 private _tEURxb;

    IUniswapV2Router02 private _uniswapRouter;

    bool _isClosedContract = false;

    mapping(address => address) private _pools;

    constructor(address teamAddress) public {
        _teamAddress = teamAddress;
    }

    /**
     * @dev setup uniswap router
     */
    function configure(
        address stakingManager,
        address uniswapRouter,
        address tUSDT,
        address tUSDC,
        address tBUSD,
        address tDAI,
        address tEURxb
    ) external initializer {
        // set uniswap router contract address
        _uniswapRouter = IUniswapV2Router02(uniswapRouter);
        // set staking manager contract address
        _stakingManager = IStakingManager(stakingManager);
        // set stablecoins contract addresses
        _tUSDT = tUSDT;
        _tUSDC = tUSDC;
        _tBUSD = tBUSD;
        _tDAI = tDAI;
        // set eurxb contract address
        _tEURxb = IERC20(tEURxb);
        // set stakingManager start/end times
        _startTime = _stakingManager.startTime();
        _endTime = _stakingManager.endTime();
        // set balancer pools and uniswap pairs addresses
        address[4] memory pools = _stakingManager.getPools();
        _pools[_tUSDT] = pools[0];
        _pools[_tUSDC] = pools[1];
        _pools[_tBUSD] = pools[2];
        _pools[_tDAI] = pools[3];
    }

    /**
     * @return are the tokens frozen
     */
    function isClosedContract() external view returns (bool) {
        return _isClosedContract;
    }

    /**
     * @return staking manager address
     */
    function stakingManager() external view returns (address) {
        return address(_stakingManager);
    }

    /**
     * @return uniswap router address
     */
    function uniswapRouter() external view returns (address) {
        return address(_uniswapRouter);
    }

    /**
     * @return EURxb address
     */
    function eurxb() external view returns (address) {
        return address(_tEURxb);
    }

    /**
     * @return start time
     */
    function startTime() external view returns (uint256) {
        return _startTime;
    }

    /**
     * @return end time
     */
    function endTime() external view returns (uint256) {
        return _endTime;
    }

    /**
     * @return stable coins pool addresses
     */
    function getPoolAddress(address token) external view returns (address) {
        return _pools[token];
    }

    /**
     * @return team address
     */
    function teamAddress() external view returns (address) {
        return _teamAddress;
    }

    /**
     * @dev set team address
     * @param team address
     */
    function setTeamAddress(address team) external onlyOwner {
        _teamAddress = team;
    }

    /**
     * @dev Close contract
     */
    function closeContract() external onlyOwner {
        require(_endTime < block.timestamp, "Time is not over");
        uint256 balance = _tEURxb.balanceOf(address(this));
        if (balance > 0) {
            _tEURxb.transfer(_teamAddress, balance);
        }
        _isClosedContract = true;
    }

    /**
     * @dev Adding liquidity
     * @param token address
     * @param amount number of tokens
     */
    function addLiquidity(address token, uint256 amount) external {
        require(block.timestamp >= _startTime, "The time has not come yet");
        require(!_isClosedContract, "Contract closed");
        if (token == _tUSDC || token == _tDAI) {
            _addLiquidityBalancer(_msgSender(), token, amount);
        } else if (token == _tUSDT || token == _tBUSD) {
            _addLiquidityUniswap(_msgSender(), token, amount);
        } else {
            revert("token is not supported");
        }
    }

    /**
     * @dev Adds liquidity for USDT-EURxb and BUSD-EURxb pairs
     * @param token address
     * @param amount number of tokens
     */
    function _addLiquidityUniswap(address sender, address token, uint256 amount) internal {
        address pairAddress = _pools[token];

        uint256 exchangeAmount = amount.div(2);

        (uint256 tokenRatio, uint256 eurRatio) = _getUniswapReservesRatio(token);

        uint256 amountEUR = exchangeAmount.mul(eurRatio).div(tokenRatio);
        uint256 balanceEUR = _tEURxb.balanceOf(address(this));

        require(balanceEUR >= 10 ** 18, 'EmptyEURxbBalance'); // balance great then 1 EURxb token

        // check if we don't have enough eurxb tokens
        if (balanceEUR <= amountEUR) {
            amountEUR = balanceEUR;
            // we can take only that much
            exchangeAmount = amountEUR.mul(tokenRatio).div(eurRatio);
            emit EmptyEURxbBalance();
        }

        TransferHelper.safeTransferFrom(token, sender, address(this), exchangeAmount.mul(2));

        // approve transfer tokens and eurxbs to uniswap pair
        TransferHelper.safeApprove(token, address(_uniswapRouter), exchangeAmount);
        TransferHelper.safeApprove(address(_tEURxb), address(_uniswapRouter), amountEUR);

        (, , uint256 liquidityAmount) = _uniswapRouter
        .addLiquidity(
            address(_tEURxb),
            token,
            amountEUR, // token B
            exchangeAmount, // token A
            0, // min A amount
            0, // min B amount
            address(this), // mint liquidity to router, not user
            block.timestamp + 10 minutes // deadline 10 minutes
        );

        uint256 routerTokenBalance = IERC20(token).balanceOf(address(this));
        TransferHelper.safeTransfer(token, _teamAddress, routerTokenBalance);

        // reward user with liquidity
        if (block.timestamp > _endTime) {
            TransferHelper.safeTransfer(pairAddress, sender, liquidityAmount);
        } else {
            TransferHelper.safeApprove(pairAddress, address(_stakingManager), liquidityAmount);
            _stakingManager.addStake(sender, pairAddress, liquidityAmount);
        }

        TransferHelper.safeApprove(token, address(_uniswapRouter), 0);
    }

    function _addLiquidityBalancer(address sender, address token, uint256 amount) internal {
        address poolAddress = _pools[token];
        IBalancerPool pool = IBalancerPool(poolAddress);
        uint256 totalSupply = pool.totalSupply();

        uint256 exchangeAmount = amount.div(2);

        (uint256 tokenRatio, uint256 eurRatio) = _getBalancerReservesRatio(token, pool);
        uint256 amountEUR = exchangeAmount.mul(eurRatio).div(tokenRatio);
        uint256 balanceEUR = _tEURxb.balanceOf(address(this));

        require(balanceEUR >= 10 ** 18, 'EmptyEURxbBalance'); // balance great then 1 EURxb token

        uint256 routerTokenBalance = IERC20(token).balanceOf(address(this));

        // check if we don't have enough eurxb tokens
        if (balanceEUR <= amountEUR) {
            amountEUR = balanceEUR;
            // we can take only that much
            exchangeAmount = amountEUR.mul(tokenRatio).div(eurRatio);
            emit EmptyEURxbBalance();
        }

        TransferHelper.safeTransferFrom(token, sender, address(this), exchangeAmount.mul(2));

        uint256 amountBPT;
        address addressEURxb = address(_tEURxb);

        { // to save stack space
            TransferHelper.safeApprove(token, poolAddress, exchangeAmount);
            TransferHelper.safeApprove(addressEURxb, poolAddress, amountEUR);

            uint256 balance = pool.getBalance(addressEURxb);
            amountBPT = totalSupply.mul(amountEUR).div(balance);
            amountBPT = amountBPT.mul(99).div(100);

            uint256[] memory data = new uint256[](2);
            data[0] = amountEUR;
            data[1] = exchangeAmount;
            pool.joinPool(amountBPT, data);
        }

        TransferHelper.safeTransfer(token, _teamAddress, exchangeAmount);

        routerTokenBalance = (IERC20(token).balanceOf(address(this))).sub(routerTokenBalance);
        TransferHelper.safeTransfer(token, msg.sender, routerTokenBalance);
        TransferHelper.safeTransfer(addressEURxb, msg.sender, routerTokenBalance.mul(eurRatio).div(tokenRatio));

        if (block.timestamp > _endTime) {
            TransferHelper.safeTransfer(poolAddress, sender, amountBPT);
        } else {
            TransferHelper.safeApprove(poolAddress, address(_stakingManager), amountBPT);
            _stakingManager.addStake(sender, poolAddress, amountBPT);
        }

        TransferHelper.safeApprove(token, poolAddress, 0);
    }

    /**
     * @dev returns uniswap pair reserves numbers or default numbers
     * used to get token/eurxb ratio
     */
    function _getUniswapReservesRatio(address token)
    internal
    returns (uint256 tokenRes, uint256 eurRes)
    {
        (uint112 res0, uint112 res1,) = IUniswapV2Pair(_pools[token]).getReserves();
        if (res0 == 0 || res1 == 0) {
            (tokenRes, eurRes) = (
                (10 ** uint256(_getTokenDecimals(token))).mul(27),
                (10 ** uint256(_getTokenDecimals(address(_tEURxb)))).mul(23)
            );
        } else {
            (address token0,) = _sortTokens(token, address(_tEURxb));
            (tokenRes, eurRes) = (token == token0) ? (res0, res1) : (res1, res0);
        }
    }

    /**
     * @dev returns balancer pair reserves numbers or default numbers
     * used to get token/eurxb ratio
     * guarantees, that returned numbers greater than zero
     */
    function _getBalancerReservesRatio(address token, IBalancerPool pool)
    internal
    returns (uint256, uint256)
    {
        uint256 balanceEurXB = pool.getBalance(address(_tEURxb));
        uint256 balanceToken = pool.getBalance(token);

        if (balanceEurXB == 0 || balanceToken == 0) {
            return (
                (10 ** uint256(_getTokenDecimals(token))).mul(27),
                (10 ** uint256(_getTokenDecimals(address(_tEURxb)))).mul(23)
            );
        }

        return (balanceToken, balanceEurXB);
    }

    /**
     * @dev sorts token addresses just like uniswap router does
     */
    function _sortTokens(address tokenA, address tokenB)
    internal pure
    returns (address token0, address token1)
    {
        require(tokenA != tokenB, "identical tokens");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'zero address');
    }

    function _getTokenDecimals(address token) internal returns (uint8) {
        // bytes4(keccak256(bytes('decimals()')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x313ce567));
        require(success &&
            (data.length == 0 ||
            abi.decode(data, (uint8)) > 0 ||
            abi.decode(data, (uint8)) < 100), "DECIMALS_NOT_FOUND");
        return abi.decode(data, (uint8));
    }
}
