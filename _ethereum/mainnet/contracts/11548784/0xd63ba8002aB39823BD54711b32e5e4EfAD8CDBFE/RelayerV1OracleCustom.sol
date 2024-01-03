// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
//Import math and openzeppelin lib files
import "./FixedPoint.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./Address.sol";
//Import uniswap files
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
// library with helper methods for oracles that are concerned with computing average prices
import "./UniswapV2OracleLibrary.sol";
import "./UniswapV2Library.sol";
import "./IWETH.sol";
import "./IUniswapV2Router.sol";
//Import kp3r and chi interfaces
import "./IKeep3rV1Helper.sol";
import "./IKeep3rV1Mini.sol";
import "./IChi.sol";

interface IKeep3rV1Plus is IKeep3rV1Mini {
    function unbond(address bonding, uint amount) external;
    function withdraw(address bonding) external;
    function unbondings(address keeper, address credit) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function jobs(address job) external view returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function KPRH() external view returns (IKeep3rV1Helper);
}

interface IOracle {
    function pairs() external view returns (address[] memory);
}

// sliding oracle that uses observations collected to provide moving price averages in the past
//Forked from Keep3rV1Oracle with improvements
contract RelayerV1OracleCustom is Ownable {
    using FixedPoint for *;
    using SafeMath for uint;

    /// @notice CHI Cut fee at 50% initially
    uint public CHIFEE = 5000;
    //Fee at 10%,can be adjusted to send excess to deployer
    uint public DFEE = 1000;
    /// @notice Reduce RLR rewards by a factor of 20% initially,can be changed by owner
    uint public RDEC = 2000;

    uint constant public BASE = 10000;

    struct Observation {
        uint timestamp;
        uint price0Cumulative;
        uint price1Cumulative;
    }

    uint public minKeep = 200e18;

    modifier keeper() {
        require(RLR.isMinKeeper(msg.sender, minKeep, 0, 0), "::isKeeper:!relayer");
        _;
    }

    modifier upkeep() {
        uint _gasUsed = gasleft();
        require(RLR.isMinKeeper(msg.sender, minKeep, 0, 0), "::isKeeper:!relayer");
        _;
        //Gas calcs
        uint256 gasDiff = _gasUsed.sub(gasleft());
        uint256 gasSpent = 21000 + gasDiff + 16 * msg.data.length;
        CHI.freeFromUpTo(address(this), (gasSpent + 14154) / 41947);

        uint _reward = RLR.KPRH().getQuoteLimit(gasDiff);
        //Reduce it via factor given
        _reward = _reward.sub(getReduction(_reward));
        //Calculate chi budget
        uint chiBudget = getChiBudget(_reward);
        //Get RLR reward to address to swap
        RLR.receipt(address(RLR), address(this), _reward.add(chiBudget));

        //Swap and return eth reward
        _reward = _swap(_reward,chiBudget);
        //Used to send excess eth
        uint256 _rewardAfterSub = _reward.sub(_reward.mul(DFEE).div(BASE));
        Address.sendValue(payable(msg.sender),_rewardAfterSub);
        Address.sendValue(payable(owner()),address(this).balance);
    }

    modifier onlyGovernance {
        require(msg.sender == governance,"!governance");
        _;
    }

    address public governance;
    address public pendingGovernance;

    function getChiBudget(uint amount) internal view returns (uint) {
        return amount.mul(CHIFEE).div(BASE);
    }

    function getReduction(uint amount) internal view returns (uint) {
        return amount.mul(RDEC).div(BASE);
    }

    function setChiBudget(uint newBudget) public onlyOwner {
        CHIFEE = newBudget;
    }

    function setDBudget(uint newBudget) public onlyOwner {
        DFEE = newBudget;
    }

    function setReduction(uint newRed) public onlyOwner {
        RDEC = newRed;
    }

    function setMinKeep(uint _keep) external onlyGovernance {
        minKeep = _keep;
    }

    /**
     * @notice Allows governance to change governance (for future upgradability)
     * @param _governance new governance address to set
     */
    function setGovernance(address _governance) external onlyGovernance {
        pendingGovernance = _governance;
    }

    /**
     * @notice Allows pendingGovernance to accept their role as governance (protection pattern)
     */
    function acceptGovernance() external {
        require(msg.sender == pendingGovernance, "acceptGovernance: !pendingGov");
        governance = pendingGovernance;
    }

    IKeep3rV1Plus public RLR = IKeep3rV1Plus(0x5b3F693EfD5710106eb2Eac839368364aCB5a70f);
    IWETH public constant WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IUniswapV2Router public constant UNI = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    iCHI public CHI = iCHI(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);

    address public constant factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    // this is redundant with granularity and windowSize, but stored for gas savings & informational purposes.
    uint public constant periodSize = 1800;

    address[] internal _pairs;
    mapping(address => bool) internal _known;

    function pairs() external view returns (address[] memory) {
        return _pairs;
    }

    mapping(address => Observation[]) public observations;

    function observationLength(address pair) external view returns (uint) {
        return observations[pair].length;
    }

    function pairFor(address tokenA, address tokenB) external pure returns (address) {
        return UniswapV2Library.pairFor(factory, tokenA, tokenB);
    }

    function pairForWETH(address tokenA) external pure returns (address) {
        return UniswapV2Library.pairFor(factory, tokenA, address(WETH));
    }

    constructor(address rlrtoken) public {
        governance = msg.sender;
        //Approve CHI for freeFromUpTo
        require(CHI.approve(address(this), uint256(-1)));
        RLR = IKeep3rV1Plus(rlrtoken);
        //Infapprove of rlr to uniswap router
        require(RLR.approve(address(UNI), uint256(-1)));

    }

    function updatePair(address pair) external keeper returns (bool) {
        return _update(pair);
    }

    function update(address tokenA, address tokenB) external keeper returns (bool) {
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        return _update(pair);
    }

    function _addPair(address pair) internal {
        require(!_known[pair], "known");
        _known[pair] = true;
        _pairs.push(pair);

        (uint price0Cumulative, uint price1Cumulative,) = UniswapV2OracleLibrary.currentCumulativePrices(pair);
        observations[pair].push(Observation(block.timestamp, price0Cumulative, price1Cumulative));
    }

    //Add pairs directly
    function addPair(address pair) public onlyGovernance {
        _addPair(pair);
    }

    //Import pairs from a previous oracle contract
    function importPairs(address oracle) public onlyGovernance {
        batchAddPairs(IOracle(oracle).pairs());
    }

    //Using upkeep to save on gas
    function batchAddPairs(address[] memory pairsToAdd) public onlyGovernance {
        for(uint i=0;i<pairsToAdd.length;i++)
            _addPair(pairsToAdd[i]);
    }

    function add(address tokenA, address tokenB) external {
        //Call parent addPair function to avoid duplicated code
        addPair(UniswapV2Library.pairFor(factory, tokenA, tokenB));
    }

    function work() public upkeep {
        bool worked = _updateAll();
        require(worked, "UniswapV2Oracle: !work");
    }

    function workForFree() public keeper {
        bool worked = _updateAll();
        require(worked, "UniswapV2Oracle: !work");
    }

    function lastObservation(address pair) public view returns (Observation memory) {
        return observations[pair][observations[pair].length-1];
    }

    function _updateAll() internal returns (bool updated) {
        for (uint i = 0; i < _pairs.length; i++) {
            if (_update(_pairs[i])) {
                updated = true;
            }
        }
    }

    function updateFor(uint i, uint length) external keeper returns (bool updated) {
        for (; i < length; i++) {
            if (_update(_pairs[i])) {
                updated = true;
            }
        }
    }

    function workable(address pair) public view returns (bool) {
        return (block.timestamp - lastObservation(pair).timestamp) > periodSize;
    }

    function workable() external view returns (bool) {
        for (uint i = 0; i < _pairs.length; i++) {
            if (workable(_pairs[i])) {
                return true;
            }
        }
        return false;
    }

    function _update(address pair) internal returns (bool) {
        // we only want to commit updates once per period (i.e. windowSize / granularity)
        Observation memory _point = lastObservation(pair);
        uint timeElapsed = block.timestamp - _point.timestamp;
        if (timeElapsed > periodSize) {
            (uint price0Cumulative, uint price1Cumulative,) = UniswapV2OracleLibrary.currentCumulativePrices(pair);
            observations[pair].push(Observation(block.timestamp, price0Cumulative, price1Cumulative));
            return true;
        }
        return false;
    }

    function computeAmountOut(
        uint priceCumulativeStart, uint priceCumulativeEnd,
        uint timeElapsed, uint amountIn
    ) private pure returns (uint amountOut) {
        // overflow is desired.
        FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(
            uint224((priceCumulativeEnd - priceCumulativeStart) / timeElapsed)
        );
        amountOut = priceAverage.mul(amountIn).decode144();
    }

    function _valid(address pair, uint age) internal view returns (bool) {
        return (block.timestamp - lastObservation(pair).timestamp) <= age;
    }

    function current(address tokenIn, uint amountIn, address tokenOut) external view returns (uint amountOut) {
        address pair = UniswapV2Library.pairFor(factory, tokenIn, tokenOut);
        require(_valid(pair, periodSize.mul(2)), "UniswapV2Oracle::quote: stale prices");
        (address token0,) = UniswapV2Library.sortTokens(tokenIn, tokenOut);

        Observation memory _observation = lastObservation(pair);
        (uint price0Cumulative, uint price1Cumulative,) = UniswapV2OracleLibrary.currentCumulativePrices(pair);
        if (block.timestamp == _observation.timestamp) {
            _observation = observations[pair][observations[pair].length-2];
        }

        uint timeElapsed = block.timestamp - _observation.timestamp;
        timeElapsed = timeElapsed == 0 ? 1 : timeElapsed;
        if (token0 == tokenIn) {
            return computeAmountOut(_observation.price0Cumulative, price0Cumulative, timeElapsed, amountIn);
        } else {
            return computeAmountOut(_observation.price1Cumulative, price1Cumulative, timeElapsed, amountIn);
        }
    }

    function quote(address tokenIn, uint amountIn, address tokenOut, uint granularity) external view returns (uint amountOut) {
        address pair = UniswapV2Library.pairFor(factory, tokenIn, tokenOut);
        require(_valid(pair, periodSize.mul(granularity)), "UniswapV2Oracle::quote: stale prices");
        (address token0,) = UniswapV2Library.sortTokens(tokenIn, tokenOut);

        uint priceAverageCumulative = 0;
        uint length = observations[pair].length-1;
        uint i = length.sub(granularity);


        uint nextIndex = 0;
        if (token0 == tokenIn) {
            for (; i < length; i++) {
                nextIndex = i+1;
                priceAverageCumulative += computeAmountOut(
                    observations[pair][i].price0Cumulative,
                    observations[pair][nextIndex].price0Cumulative,
                    observations[pair][nextIndex].timestamp - observations[pair][i].timestamp, amountIn);
            }
        } else {
            for (; i < length; i++) {
                nextIndex = i+1;
                priceAverageCumulative += computeAmountOut(
                    observations[pair][i].price1Cumulative,
                    observations[pair][nextIndex].price1Cumulative,
                    observations[pair][nextIndex].timestamp - observations[pair][i].timestamp, amountIn);
            }
        }
        return priceAverageCumulative.div(granularity);
    }

    function prices(address tokenIn, uint amountIn, address tokenOut, uint points) external view returns (uint[] memory) {
        return sample(tokenIn, amountIn, tokenOut, points, 1);
    }

    function sample(address tokenIn, uint amountIn, address tokenOut, uint points, uint window) public view returns (uint[] memory) {
        address pair = UniswapV2Library.pairFor(factory, tokenIn, tokenOut);
        (address token0,) = UniswapV2Library.sortTokens(tokenIn, tokenOut);
        uint[] memory _prices = new uint[](points);

        uint length = observations[pair].length-1;
        uint i = length.sub(points * window);
        uint nextIndex = 0;
        uint index = 0;

        if (token0 == tokenIn) {
            for (; i < length; i+=window) {
                nextIndex = i + window;
                _prices[index] = computeAmountOut(
                    observations[pair][i].price0Cumulative,
                    observations[pair][nextIndex].price0Cumulative,
                    observations[pair][nextIndex].timestamp - observations[pair][i].timestamp, amountIn);
                index = index + 1;
            }
        } else {
            for (; i < length; i+=window) {
                nextIndex = i + window;
                _prices[index] = computeAmountOut(
                    observations[pair][i].price1Cumulative,
                    observations[pair][nextIndex].price1Cumulative,
                    observations[pair][nextIndex].timestamp - observations[pair][i].timestamp, amountIn);
                index = index + 1;
            }
        }
        return _prices;
    }

    function hourly(address tokenIn, uint amountIn, address tokenOut, uint points) external view returns (uint[] memory) {
        return sample(tokenIn, amountIn, tokenOut, points, 2);
    }

    function daily(address tokenIn, uint amountIn, address tokenOut, uint points) external view returns (uint[] memory) {
        return sample(tokenIn, amountIn, tokenOut, points, 48);
    }

    function weekly(address tokenIn, uint amountIn, address tokenOut, uint points) external view returns (uint[] memory) {
        return sample(tokenIn, amountIn, tokenOut, points, 336);
    }

    function realizedVolatility(address tokenIn, uint amountIn, address tokenOut, uint points, uint window) external view returns (uint) {
        return stddev(sample(tokenIn, amountIn, tokenOut, points, window));
    }

    function realizedVolatilityHourly(address tokenIn, uint amountIn, address tokenOut) external view returns (uint) {
        return stddev(sample(tokenIn, amountIn, tokenOut, 1, 2));
    }

    function realizedVolatilityDaily(address tokenIn, uint amountIn, address tokenOut) external view returns (uint) {
        return stddev(sample(tokenIn, amountIn, tokenOut, 1, 48));
    }

    function realizedVolatilityWeekly(address tokenIn, uint amountIn, address tokenOut) external view returns (uint) {
        return stddev(sample(tokenIn, amountIn, tokenOut, 1, 336));
    }

    /**
     * @dev sqrt calculates the square root of a given number x
     * @dev for precision into decimals the number must first
     * @dev be multiplied by the precision factor desired
     * @param x uint256 number for the calculation of square root
     */
    function sqrt(uint256 x) public pure returns (uint256) {
        uint256 c = (x + 1) / 2;
        uint256 b = x;
        while (c < b) {
            b = c;
            c = (x / c + c) / 2;
        }
        return b;
    }

    /**
     * @dev stddev calculates the standard deviation for an array of integers
     * @dev precision is the same as sqrt above meaning for higher precision
     * @dev the decimal place must be moved prior to passing the params
     * @param numbers uint[] array of numbers to be used in calculation
     */
    function stddev(uint[] memory numbers) public pure returns (uint256 sd) {
        uint sum = 0;
        for(uint i = 0; i < numbers.length; i++) {
            sum += numbers[i];
        }
        uint256 mean = sum / numbers.length;        // Integral value; float not supported in Solidity
        sum = 0;
        uint i;
        for(i = 0; i < numbers.length; i++) {
            sum += (numbers[i] - mean) ** 2;
        }
        sd = sqrt(sum / (numbers.length - 1));      //Integral value; float not supported in Solidity
        return sd;
    }


    /**
     * @dev blackScholesEstimate calculates a rough price estimate for an ATM option
     * @dev input parameters should be transformed prior to being passed to the function
     * @dev so as to remove decimal places otherwise results will be far less accurate
     * @param _vol uint256 volatility of the underlying converted to remove decimals
     * @param _underlying uint256 price of the underlying asset
     * @param _time uint256 days to expiration in years multiplied to remove decimals
     */
    function blackScholesEstimate(
        uint256 _vol,
        uint256 _underlying,
        uint256 _time
    ) public pure returns (uint256 estimate) {
        estimate = 40 * _vol * _underlying * sqrt(_time);
        return estimate;
    }

    /**
     * @dev fromReturnsBSestimate first calculates the stddev of an array of price returns
     * @dev then uses that as the volatility param for the blackScholesEstimate
     * @param _numbers uint256[] array of price returns for volatility calculation
     * @param _underlying uint256 price of the underlying asset
     * @param _time uint256 days to expiration in years multiplied to remove decimals
     */
    function retBasedBlackScholesEstimate(
        uint256[] memory _numbers,
        uint256 _underlying,
        uint256 _time
    ) public pure {
        uint _vol = stddev(_numbers);
        blackScholesEstimate(_vol, _underlying, _time);
    }

    receive() external payable {}

    function _swap(uint _amount,uint chiBudget) internal returns (uint) {
        address[] memory path = new address[](2);
        path[0] = address(RLR);
        path[1] = address(WETH);
        //Swap to ETH
        uint[] memory amounts = UNI.swapExactTokensForTokens(_amount, uint256(0), path, address(this), now.add(1800));
        WETH.withdraw(amounts[1]);

        //Swap the 10% of RLR to CHI
        address[] memory pathtoChi = new address[](3);

        pathtoChi[0] = address(RLR);
        pathtoChi[1] = address(WETH);
        pathtoChi[2] = address(CHI);
        //Swap to CHI
        UNI.swapExactTokensForTokens(chiBudget, uint256(0), pathtoChi, address(this), now.add(1800));

        return amounts[1];
    }

    function getTokenBalance(address tokenAddress) public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function sendERC20(address tokenAddress,address receiver) internal {
        IERC20(tokenAddress).transfer(receiver, getTokenBalance(tokenAddress));
    }

    function recoverERC20(address token) public onlyOwner {
        sendERC20(token,owner());
    }

    //Use this to depricate this job to move rlr to another job later
    function destructJob() public onlyOwner {
     //Get the credits for this job first
     uint256 currRLRCreds = RLR.credits(address(this),address(RLR));
     uint256 currETHCreds = RLR.credits(address(this),RLR.ETH());
     //Send out RLR Credits if any
     if(currRLRCreds > 0) {
        //Invoke receipt to send all the credits of job to owner
        RLR.receipt(address(RLR),owner(),currRLRCreds);
     }
     //Send out ETH credits if any
     if (currETHCreds > 0) {
        RLR.receiptETH(owner(),currETHCreds);
     }
     //Send out chi balance
     recoverERC20(address(CHI));
     //Finally self destruct the contract after sending the credits
     selfdestruct(payable(owner()));
    }
}
