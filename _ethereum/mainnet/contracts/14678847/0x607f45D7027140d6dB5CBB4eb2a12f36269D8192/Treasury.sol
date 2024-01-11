pragma solidity ^0.8.12;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ISwap.sol";
import "./IPair.sol";
import "./IERC20.sol";
import "./Math.sol";


contract Treasury is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    address public lsc;

    modifier onlyLsc() {
        require(_msgSender() == lsc);
        _;
    }

    modifier onlyOwnerOrLsc() {
        require(_msgSender() == owner() || _msgSender() == lsc);
        _;
    }

    struct Pool {
        string name;
        address router;
        address pair;
        uint percentage;
        uint amountOfLPTokens;
        uint amountLiquidity;
    }

    struct FindPoolArgs {
        uint amountLiquidity;
        uint expectedToken;
        uint expectedBlxm;
        uint liquidityInPools;
        uint[] currentAmounts0;
        uint[] currentAmounts1;
    }

    uint public constant MINIMUM_LIQUIDITY = 1000;
    uint private constant PERCENT_PRECISION = 10000000000000000;

    mapping(uint => Pool) public pools;
    uint public numberOfPools;

    uint public maximumBuffer;
    uint public minimumCash;
    uint public balancingThresholdPercent;
    uint private threshold;

    address public token1Address;
    address public token0Address;
    // token0 bsc 0x139E61EA6e1cb2504cf50fF83B39A03c79850548
    // token1 bsc 0x1c326fCB30b38116573284160BE0F9Ee62Dd562F
    // suhsi lp 0x48dA8e025841663eC62d9A5deac921A1137840d1
    // uni lp 0x47EBF7c41f8EF6F786819A51dB2765f3179ad4b8
    // eth and blxm contract balances
    uint public reserve1;
    uint public reserve0;
    // minimum amount of liquidity that has to stay in contract
    uint public cash;
    // amount of liquidity that is not stored in cash and will be transferred to pools if buffer >= maximumBuffer,
    uint public buffer;

    mapping(address => uint) public balances;

    address[] public tokenReceivers;

    uint sentReserve0;
    uint sentReserve1;
    mapping(uint => uint) sentLPTokens;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function initialize(address _lsc, address _token0, address _token1, uint _minimumCash, uint _maximumBuffer, uint _balancingThresholdPercent) initializer public {
        __Ownable_init();
        lsc = _lsc;
        maximumBuffer = _maximumBuffer;
        minimumCash = _minimumCash;
        token1Address = _token1;
        token0Address = _token0;
        balancingThresholdPercent = _balancingThresholdPercent;
        threshold = _balancingThresholdPercent * PERCENT_PRECISION;
    }

    function add_liquidity(uint amountBlxm, uint amountToken, address to) external onlyLsc {
        (uint liquidity) = calculate_liquidity_amount(
            amountToken,
            amountBlxm
        );
        updateBalance(liquidity, to);
        reserve1 += amountToken;
        reserve0 += amountBlxm;
        cash += liquidity;
        if (cash > minimumCash) {
            buffer += cash - minimumCash;
            cash = minimumCash;
        }
        if (buffer >= maximumBuffer) {
            send_tokens_investment_buffer();
        }
    }

    function send_tokens_investment(uint amount0, uint amount1, uint poolIndex) public onlyOwner {
        require(reserve0 >= amount0 || reserve1 >= amount1, "Not enough tokens");
        (uint depositedToken, uint depositedBlxm) = send_tokens_to_pool(pools[poolIndex], amount1, amount0);
        (uint depositedLiquidity) = calculate_liquidity_amount(
            depositedToken,
            depositedBlxm
        );
        reserve0 -= amount0;
        reserve1 -= amount1;
        uint reservesLiquidity = calculate_liquidity_amount(reserve0, reserve1);
        if (reservesLiquidity > minimumCash) {
            cash = minimumCash;
            buffer = reservesLiquidity - minimumCash;
        } else {
            cash = reservesLiquidity;
            buffer = 0;
        }
        pools[poolIndex].amountLiquidity += depositedLiquidity;
    }

    function retrieve_tokens(uint amountLpTokens, uint poolIndex) public onlyOwner {
        Pool storage pool = pools[poolIndex];
        require(pool.amountOfLPTokens >= amountLpTokens, "Not enough liquidity in pool");
        (uint amountBlxm, uint amountToken) = retrieve_tokens_from_pool(amountLpTokens, pool.pair, pool.router);
        pool.amountOfLPTokens -= amountLpTokens;
        reserve1 += amountToken;
        reserve0 += amountBlxm;
        uint reservesLiquidity = calculate_liquidity_amount(reserve0, reserve1);
        if (reservesLiquidity > minimumCash) {
            cash = minimumCash;
            buffer = reservesLiquidity - minimumCash;
        } else {
            cash = reservesLiquidity;
            buffer = 0;
        }
        (,,,,uint[] memory currentAmounts0, uint[] memory currentAmounts1) = get_total_amounts();
        pool.amountLiquidity = calculate_liquidity_amount(currentAmounts0[poolIndex], currentAmounts1[poolIndex]);
    }

    function update_pools_liquidity(uint[] memory currentAmounts0, uint[] memory currentAmounts1) private {
        for (uint i = 0; i < numberOfPools; i++) {
            pools[i].amountLiquidity = calculate_liquidity_amount(currentAmounts0[i], currentAmounts1[i]);
        }
    }

    function get_tokens(uint reward, uint requestedAmount0, uint requestedAmount1, address payable to) external onlyLsc returns (uint sentToken, uint sentBlxm) {
        require(IERC20(token0Address).balanceOf(address(this)) - (reserve0) >= reward, "Not enough reward");
        if (requestedAmount0 > reserve0 || requestedAmount1 > reserve1) {
            (uint amount0, uint amount1,,,uint[] memory currentAmounts0, uint[] memory currentAmounts1) = get_total_amounts();
            update_pools_liquidity(currentAmounts0, currentAmounts1);
            require(requestedAmount0 <= amount0 && requestedAmount1 <= amount1, "No enough tokens to retreive");
            uint liquidityInPools = calculate_liquidity_amount(amount0 - reserve0, amount1 - reserve1);
            uint expectedTokenToRetrieve = Math.min(minimumCash * (amount1 - reserve1) / liquidityInPools + requestedAmount1 - reserve1, amount1 - reserve1);
            uint expectedBlxmToRetrieve = Math.min(minimumCash * (amount0 - reserve0) / liquidityInPools + requestedAmount0 - reserve0, amount0 - reserve0);
            uint liquidityToRetrieve = calculate_liquidity_amount(expectedTokenToRetrieve, expectedBlxmToRetrieve);
            // fill over from pools
            FindPoolArgs memory args;
            args.amountLiquidity = liquidityToRetrieve;
            args.expectedToken = expectedTokenToRetrieve;
            args.expectedBlxm = expectedBlxmToRetrieve;
            args.liquidityInPools = liquidityInPools;
            args.currentAmounts0 = currentAmounts0;
            args.currentAmounts1 = currentAmounts1;
            (uint[] memory poolsIndexes, uint[] memory amountsToRemove) = find_pool_to_fill_reserves(args);
            for (uint i = 0; i < poolsIndexes.length; i++) {
                Pool storage pool = pools[poolsIndexes[i]];
                uint tokensToRetreive = pool.amountOfLPTokens * amountsToRemove[i] / pool.amountLiquidity;
                if (tokensToRetreive > pool.amountOfLPTokens) {
                    tokensToRetreive = pool.amountOfLPTokens;
                }
                (uint amountBlxm, uint amountToken) = retrieve_tokens_from_pool(tokensToRetreive, pool.pair, pool.router);
                pool.amountOfLPTokens -= tokensToRetreive;
                pool.amountLiquidity -= amountsToRemove[i];
                reserve1 += amountToken;
                reserve0 += amountBlxm;
            }
        }
        if (reserve1 > requestedAmount1) {
            reserve1 -= requestedAmount1;
            sentToken = requestedAmount1;
            IERC20(token1Address).transfer(to, requestedAmount1);
        } else {
            IERC20(token1Address).transfer(to, reserve1);
            sentToken = reserve1;
            reserve1 = 0;
        }
        if (reserve0 > requestedAmount0) {
            reserve0 -= requestedAmount0;
            sentBlxm = requestedAmount0 + reward;
            IERC20(token0Address).transfer(to, requestedAmount0 + reward);
        } else {
            IERC20(token0Address).transfer(to, reserve0 + reward);
            sentBlxm = reserve0 + reward;
            reserve0 = 0;
        }

        uint reservesLiquidity = calculate_liquidity_amount(reserve0, reserve1);
        if (reservesLiquidity > minimumCash) {
            cash = minimumCash;
            buffer = reservesLiquidity - minimumCash;
        } else {
            cash = reservesLiquidity;
            buffer = 0;
        }
    }

    function get_total_amounts() public view onlyOwnerOrLsc returns (
        uint amount0,
        uint amount1,
        uint[] memory,
        uint[] memory,
        uint[] memory,
        uint[] memory
    ) {
        uint[] memory totalAmounts0 = new uint[](numberOfPools);
        uint[] memory totalAmounts1 = new uint[](numberOfPools);
        uint[] memory currentAmounts0 = new uint[](numberOfPools);
        uint[] memory currentAmounts1 = new uint[](numberOfPools);
        amount0 = reserve0;
        amount1 = reserve1;
        for (uint i = 0; i < numberOfPools; i++) {
            Pool storage pool = pools[i];
            uint totalSupply = IPair(pool.pair).totalSupply();
            uint112 reserve0Pool;
            uint112 reserve1Pool;
            if (token0Address < token1Address) {
                (reserve0Pool, reserve1Pool,) = IPair(pool.pair).getReserves();
            } else {
                (reserve1Pool, reserve0Pool,) = IPair(pool.pair).getReserves();
            }
            totalAmounts0[i] = reserve0Pool;
            totalAmounts1[i] = reserve1Pool;
            currentAmounts0[i] = reserve0Pool * pool.amountOfLPTokens / totalSupply;
            currentAmounts1[i] = reserve1Pool * pool.amountOfLPTokens / totalSupply;
            amount0 += reserve0Pool * pool.amountOfLPTokens / totalSupply;
            amount1 += reserve1Pool * pool.amountOfLPTokens / totalSupply;
        }
        return (amount0, amount1, totalAmounts0, totalAmounts1, currentAmounts0, currentAmounts1);
    }

    function get_nominal_amounts() public view returns (
        uint amount0,
        uint amount1
    ) {
        amount0 = reserve0 + sentReserve0;
        amount1 = reserve1 + sentReserve1;
        for (uint i = 0; i < numberOfPools; i++) {
            Pool storage pool = pools[i];
            uint totalSupply = IPair(pool.pair).totalSupply();
            uint112 reserve0Pool;
            uint112 reserve1Pool;
            if (token0Address < token1Address) {
                (reserve0Pool, reserve1Pool,) = IPair(pool.pair).getReserves();
            } else {
                (reserve1Pool, reserve0Pool,) = IPair(pool.pair).getReserves();
            }
            amount0 += reserve0Pool * (pool.amountOfLPTokens + sentLPTokens[i]) / totalSupply;
            amount1 += reserve1Pool * (pool.amountOfLPTokens + sentLPTokens[i]) / totalSupply;
        }
        return (amount0, amount1);
    }

    function set_maximum_buffer(uint _buffer) public onlyOwner {
        maximumBuffer = _buffer;
    }

    function set_minimum_cash(uint _cash) public onlyOwner {
        minimumCash = _cash;
    }

    function set_balancing_threshold_percent(uint new_percent) public onlyOwner {
        balancingThresholdPercent = new_percent;
        threshold = new_percent * PERCENT_PRECISION;
    }

    function add_new_investment_product(string memory name, address router, address pair, uint[] memory newPercentages) public onlyOwner {
        require(newPercentages.length == numberOfPools + 1, "New percentages should be provided for all products");
        uint totalPercent;
        for (uint i; i < newPercentages.length; i++) {
            totalPercent += newPercentages[i];
            pools[i].percentage = newPercentages[i];
        }
        require(totalPercent == 100, "Total percent of all products must be 100");
        pools[numberOfPools] = Pool(name, router, pair, newPercentages[numberOfPools], 0, 0);
        numberOfPools += 1;
    }

    function remove_investment_product(uint index, uint[] memory newPercentages) public onlyOwner {
        require(newPercentages.length == numberOfPools - 1, "New percentages should be provided for all products");
        require(index < numberOfPools, "Index is out of pools range");
        require(pools[index].amountOfLPTokens == 0, "Pool is not empty");
        uint totalPercent;
        for (uint i = index; i < numberOfPools - 1; i++) {
            pools[i] = pools[i + 1];
        }
        delete pools[numberOfPools - 1];
        numberOfPools--;
        for (uint i; i < newPercentages.length; i++) {
            totalPercent += newPercentages[i];
            pools[i].percentage = newPercentages[i];
        }
        require(totalPercent == 100, "Total percent of all products must be 100");
    }

    function change_pools_percentages(uint[] memory newPercentages) public onlyOwner {
        require(newPercentages.length == numberOfPools, "New percentages should be provided for all products");
        uint totalPercent;
        for (uint i; i < newPercentages.length; i++) {
            totalPercent += newPercentages[i];
            pools[i].percentage = newPercentages[i];
        }
        require(totalPercent == 100, "Total percent of all products must be 100");
    }

    function send_lp_tokens(uint receiverIndex, uint poolIndex, uint amount) public onlyOwner {
        require(receiverIndex < tokenReceivers.length && poolIndex < numberOfPools, "Index is out range");
        Pool storage pool = pools[poolIndex];
        require(amount <= pools[poolIndex].amountOfLPTokens, "Not enough tokens");
        IERC20(pool.pair).transfer(tokenReceivers[receiverIndex], amount);
        pool.amountOfLPTokens -= amount;
        sentLPTokens[poolIndex] += amount;
    }

    function send_reserve_tokens(uint receiverIndex, uint amount0, uint amount1) public onlyOwner {
        require(receiverIndex < tokenReceivers.length, "Index is out range");
        require(amount0 <= reserve0 && amount1 <= reserve1, "Not enough tokens");
        IERC20(token0Address).transfer(tokenReceivers[receiverIndex], amount0);
        IERC20(token1Address).transfer(tokenReceivers[receiverIndex], amount1);
        reserve0 -= amount0;
        reserve1 -= amount1;
        sentReserve0 += amount0;
        sentReserve1 += amount1;
        uint liquidity = calculate_liquidity_amount(reserve0, reserve1);
        cash = Math.min(liquidity, minimumCash);
        buffer = liquidity - cash;
    }

    function add_token_receiver(address receiver) public onlyOwner {
        tokenReceivers.push(receiver);
    }

    function remove_token_receiver(uint index) public onlyOwner {
        require(index < tokenReceivers.length, "Index is out of array range");
        for (uint i = index; i < tokenReceivers.length - 1; i++) {
            tokenReceivers[i] = tokenReceivers[i + 1];
        }
        tokenReceivers.pop();
    }

    function set_lp_amount(uint index, uint amountOfLP) public onlyOwner {
        require(index < numberOfPools, "Index is out of array range");
        require(amountOfLP > pools[index].amountOfLPTokens, "Set amount is lower than current");
        sentLPTokens[index] -= Math.min(amountOfLP - pools[index].amountOfLPTokens, sentLPTokens[index]);
        pools[index].amountOfLPTokens = amountOfLP;
    }

    function set_reserves_amount(uint amount0, uint amount1) public onlyOwner {
        require(amount0 >= reserve0 && amount1 >= reserve1, "Set amount is lower than current");
        sentReserve0 -= Math.min(amount0 - reserve0, sentReserve0);
        sentReserve1 -= Math.min(amount1 - reserve1, sentReserve1);
        reserve0 = amount0;
        reserve1 = amount1;
        uint liquidity = calculate_liquidity_amount(amount0, amount1);
        cash = Math.min(liquidity, minimumCash);
        buffer = liquidity - cash;
    }

    function find_pool_to_add(uint amountLiquidity, uint amountAll0, uint amountAll1) private view returns (uint[] memory, uint[] memory){
        uint liquidityInPools = calculate_liquidity_amount(amountAll0 - reserve0, amountAll1 - reserve1);
        Pool memory poolToAdd = pools[0];
        uint poolIndex;
        uint poolMismatch;
        // find most imbalanced pool
        for (uint i = 0; i < numberOfPools; i++) {
            uint currentPoolPercentage = pools[i].amountLiquidity * PERCENT_PRECISION * 100 / Math.max(liquidityInPools, 1);
            if (pools[i].percentage * PERCENT_PRECISION > currentPoolPercentage &&
                (pools[i].percentage * PERCENT_PRECISION - currentPoolPercentage > poolMismatch ||
                (pools[i].percentage * PERCENT_PRECISION - currentPoolPercentage == poolMismatch && pools[i].percentage > poolToAdd.percentage))
            ) {
                poolToAdd = pools[i];
                poolMismatch = pools[i].percentage * PERCENT_PRECISION - currentPoolPercentage;
                poolIndex = i;
            }
        }
        uint finalLiquidity = liquidityInPools + amountLiquidity;
        uint[] memory poolIndexes;
        uint[] memory amountsToAdd;
        // check if adding liquidity to one pool leads to disbalance
        if ((poolToAdd.amountLiquidity + amountLiquidity) * PERCENT_PRECISION * 100 / finalLiquidity > poolToAdd.percentage * PERCENT_PRECISION &&
            (poolToAdd.amountLiquidity + amountLiquidity) * PERCENT_PRECISION * 100 / finalLiquidity - poolToAdd.percentage * PERCENT_PRECISION > threshold) {
            // balance pools
            poolIndexes = new uint[](numberOfPools);
            amountsToAdd = new uint[](numberOfPools);
            for (uint i = 0; i < numberOfPools; i++) {
                poolIndexes[i] = i;
                amountsToAdd[i] = finalLiquidity * pools[i].percentage / 100 - pools[i].amountLiquidity;
            }
        } else {
            poolIndexes = new uint[](1);
            amountsToAdd = new uint[](1);
            poolIndexes[0] = poolIndex;
            amountsToAdd[0] = amountLiquidity;
        }
        return (poolIndexes, amountsToAdd);
    }

    function send_tokens_investment_buffer() private {
        (uint amount0,
        uint amount1,
        uint[] memory totalAmounts0,
        uint[] memory totalAmounts1,
        uint[] memory currentAmounts0,
        uint[] memory currentAmounts1
        ) = get_total_amounts();
        update_pools_liquidity(currentAmounts0, currentAmounts1);
        uint depositedTokenAll;
        uint depositedBlxmAll;
        uint depositedLiquidityAll;
        (uint[] memory poolIndexes, uint[] memory amountsToAdd) = find_pool_to_add(buffer, amount0, amount1);
        for (uint i = 0; i < poolIndexes.length; i++) {
            uint amountToken = reserve1 * amountsToAdd[i] / (buffer + cash);
            uint amountBlxm = amountToken * totalAmounts0[i] / totalAmounts1[i];
            if (amountBlxm > reserve0) {
                amountBlxm = reserve0 * amountsToAdd[i] / (buffer + cash);
                amountToken = amountBlxm * totalAmounts1[i] / totalAmounts0[i];
            }
            uint poolIndex = poolIndexes[i];
            (uint depositedToken, uint depositedBlxm) = send_tokens_to_pool(pools[poolIndex], amountToken, amountBlxm);
            (uint depositedLiquidity) = calculate_liquidity_amount(
                depositedToken,
                depositedBlxm
            );
            pools[poolIndex].amountLiquidity += depositedLiquidity;
            depositedTokenAll += depositedToken;
            depositedBlxmAll += depositedBlxm;
            depositedLiquidityAll += depositedLiquidity;
        }
        reserve1 -= depositedTokenAll;
        reserve0 -= depositedBlxmAll;
        cash = calculate_liquidity_amount(reserve0, reserve1);
        if (cash > minimumCash) {
            buffer = cash - minimumCash;
            cash = minimumCash;
        } else {
            buffer = 0;
        }
    }

    function send_tokens_to_pool(Pool storage pool, uint amountToken, uint amountBlxm) private returns (uint depositedToken, uint depositedBlxm) {
        IERC20(token1Address).approve(pool.router, amountToken);
        IERC20(token0Address).approve(pool.router, Math.min(amountBlxm + (amountBlxm * 5 / 100), reserve0));
        (uint addedAmountToken, uint addedAmountBlxm, uint lpTokens) = ISwap(pool.router).addLiquidity(
            token1Address,
            token0Address,
            amountToken,
            Math.min(amountBlxm + (amountBlxm * 5 / 100), reserve0),
            amountToken - (amountToken * 5 / 100),
            amountBlxm - (amountBlxm * 5 / 100),
            address(this),
            block.timestamp + 300
        );
        pool.amountOfLPTokens += lpTokens;
        return (addedAmountToken, addedAmountBlxm);
    }


    function calculate_liquidity_amount(uint amount0, uint amount1) private pure returns (uint liquidity) {
        liquidity = Math.sqrt(amount0 * amount1);
    }

    function is_possible_to_balance_on_get(uint finalLiquidity, uint expectedToken, uint expectedBlxm, uint[] memory currentAmounts0, uint[] memory currentAmounts1) private view returns (bool) {
        uint sumToken;
        uint sumBlxm;
        for (uint i = 0; i < numberOfPools; i++) {
            if (finalLiquidity * pools[i].percentage / 100 > pools[i].amountLiquidity) {
                return false;
            }
            uint amountToRemove = pools[i].amountLiquidity - finalLiquidity * pools[i].percentage / 100;
            uint poolToRemoveLiquidity = Math.max(amountToRemove * currentAmounts1[i] * expectedBlxm / (currentAmounts0[i] * expectedToken), amountToRemove * currentAmounts0[i] * expectedToken / (currentAmounts1[i] * expectedBlxm));
            poolToRemoveLiquidity = Math.min(poolToRemoveLiquidity, pools[i].amountLiquidity);
            sumToken += poolToRemoveLiquidity * currentAmounts1[i] / pools[i].amountLiquidity;
            sumBlxm += poolToRemoveLiquidity * currentAmounts0[i] / pools[i].amountLiquidity;
        }
        if (sumToken < expectedToken || sumBlxm < expectedBlxm) return false;
        return true;
    }

    function find_pool_to_fill_reserves(FindPoolArgs memory args) private view returns (uint[] memory, uint[] memory) {
        uint[] memory poolsIndexes;
        uint[] memory amountsToRemove;
        if (args.liquidityInPools - args.amountLiquidity == 0) {
            poolsIndexes = new uint[](numberOfPools);
            amountsToRemove = new uint[](numberOfPools);
            for (uint i = 0; i < numberOfPools; i++) {
                poolsIndexes[i] = i;
                amountsToRemove[i] = pools[i].amountLiquidity;
            }
        } else {
            Pool memory poolToRemove = pools[0];
            uint poolMismatch;
            uint poolIndex;
            for (uint i = 0; i < numberOfPools; i++) {
                uint poolPercentage = pools[i].amountLiquidity * PERCENT_PRECISION * 100 / args.liquidityInPools;
                if (poolPercentage > pools[i].percentage * PERCENT_PRECISION &&
                    (poolPercentage - pools[i].percentage * PERCENT_PRECISION > poolMismatch ||
                    (poolPercentage - pools[i].percentage * PERCENT_PRECISION == poolMismatch && pools[i].percentage > poolToRemove.percentage))
                ) {
                    poolToRemove = pools[i];
                    poolMismatch = poolPercentage - pools[i].percentage * PERCENT_PRECISION;
                    poolIndex = i;
                }
            }
            uint liq = Math.max(
                args.amountLiquidity * args.currentAmounts1[poolIndex] * args.expectedBlxm / args.currentAmounts0[poolIndex] * args.expectedToken,
                args.amountLiquidity * args.currentAmounts0[poolIndex] * args.expectedToken / args.currentAmounts1[poolIndex] * args.expectedBlxm
            );
            // recalculate poolToRemove.amountLiquidity
            if (poolToRemove.amountLiquidity < liq ||
                (poolToRemove.percentage * PERCENT_PRECISION > (poolToRemove.amountLiquidity - liq) * PERCENT_PRECISION * 100 / (args.liquidityInPools - args.amountLiquidity) &&
                poolToRemove.percentage * PERCENT_PRECISION - (poolToRemove.amountLiquidity - liq) * PERCENT_PRECISION * 100 / (args.liquidityInPools - args.amountLiquidity) > threshold)
            ) {
                poolsIndexes = new uint[](numberOfPools);
                amountsToRemove = new uint[](numberOfPools);
                bool isPossibleToBalance = is_possible_to_balance_on_get(args.liquidityInPools - args.amountLiquidity, args.expectedToken, args.expectedBlxm, args.currentAmounts0, args.currentAmounts1);
                for (uint i = 0; i < numberOfPools; i++) {
                    poolsIndexes[i] = i;
                    if (isPossibleToBalance) {
                        amountsToRemove[i] = pools[i].amountLiquidity - (args.liquidityInPools - args.amountLiquidity) * pools[i].percentage / 100;
                        amountsToRemove[i] = Math.max(amountsToRemove[i] * args.currentAmounts1[i] * args.expectedBlxm / (args.currentAmounts0[i] * args.expectedToken), amountsToRemove[i] * args.currentAmounts0[i] * args.expectedToken / (args.currentAmounts1[i] * args.expectedBlxm));
                        amountsToRemove[i] = Math.min(amountsToRemove[i], pools[i].amountLiquidity);
                    } else {
                        amountsToRemove[i] = args.amountLiquidity * pools[i].amountLiquidity / args.liquidityInPools;
                    }
                }
            } else {
                poolsIndexes = new uint[](1);
                amountsToRemove = new uint[](1);
                poolsIndexes[0] = poolIndex;
                amountsToRemove[0] = liq;
            }
        }
        return (poolsIndexes, amountsToRemove);
    }

    function retrieve_tokens_from_pool(uint lp, address pair, address router) private returns (uint amountBlxm, uint amountToken) {
        IPair(pair).approve(router, lp);
        return ISwap(router).removeLiquidity(token0Address, token1Address, lp, 0, 0, address(this), block.timestamp + 300);
    }

    function updateBalance(uint newBalance, address sender) private {
        balances[sender] = balances[sender] + newBalance;
    }

    receive() payable external {}

}