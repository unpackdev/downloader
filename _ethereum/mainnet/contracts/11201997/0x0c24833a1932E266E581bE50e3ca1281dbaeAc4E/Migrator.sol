//SPDX-License-Identifier: SEE LICENSE FILE
pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;

import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapIERC20.sol";
import "./SafeMath.sol";
import "./BalancerConstants.sol";
import "./CRPFactory.sol";
import "./AlpacaToken.sol";
interface IMasterRancher {

    function requestToMint(uint256 _amount) external returns (uint256 amount_minted);

}

contract Migrator {
    using SafeMath for uint256;
    IMasterRancher public masterRancher;
    address public uniswapFactory; //
    address BFactoryAddress;
    address CRPFactoryAddress;
    uint256 public notBeforeBlock;
    uint256 public desiredLiquidity = uint256(-1);
    uint256 public totalWeth;
    uint256 public totalWethforShares;
    uint256 public pacaWethValueForShares;
    // address public wethAddr = address(
    //     0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    // );
    address public wethAddr;
    address public pacaAddr;
    uint256 public initialTotalLPSupply;
    bool public setWethComplete;
    ConfigurableRightsPool.PoolParams public omniPoolParams;
    ConfigurableRightsPool public pacaOmniPool;
    RightsManager.Rights public permissions;
    CRPFactory crpFact;
    /// @notice each token's balance and weight
    struct tokenInfo {
        uint256 balance;
        uint256 wethValue;
        uint256 shares;
        bool exists;
    }

    uint256 public totalTokens;
    /// @notice input into the final omniPool
    mapping(address => tokenInfo) public omniPool;

    mapping(uint256 => address) public tokenHolder;

    constructor(
        IMasterRancher _rancher,
        address _oldFactory,
        address _bFactory,
        address _crpFactory,
        address _weth,
        address _paca,
        uint256 _notBeforeBlock
    ) public {
        masterRancher = _rancher;
        uniswapFactory = _oldFactory;
        BFactoryAddress = _bFactory;
        notBeforeBlock = _notBeforeBlock;
        CRPFactoryAddress = _crpFactory;
        totalWeth = 0;
        totalTokens = 0;
        crpFact = CRPFactory(CRPFactoryAddress);

        // set up WETH as base asset
        wethAddr = _weth;
        // set up PACA address
        pacaAddr = _paca;
        omniPool[wethAddr].exists = true;
        tokenHolder[totalTokens] = wethAddr;
        totalTokens++;
        setWethComplete = true;

        permissions = RightsManager.Rights({
            canPauseSwapping: true,
            canChangeSwapFee: true,
            canChangeWeights: true,
            canAddRemoveTokens: true,
            canWhitelistLPs: false,
            canChangeCap: false
        });

        omniPoolParams.poolTokenSymbol = "ALP";
        omniPoolParams.poolTokenName = "AlpacaSwap Liquidity Pool Token";
        //is this correct?
        //toWei("0.002") = 0.2%
        //BONE is 1 WEI so 1/1000 = 0.001
        omniPoolParams.swapFee = (BalancerConstants.BONE / 1000) * 2;
    }

    // Log the address of each new smart pool, and its creator
    event LogNewDomesticate(
        address indexed tokenAddress,
        uint256 indexed tokenAmount,
        uint256 indexed wethAmount
    );

    event LogNewBalance(
        uint256 indexed wethBalance,
        uint256 indexed tokenBalance,
        uint256 indexed tokenWethValue
    );

    event LogNewCrp(address indexed caller, address indexed pool);

    // Unlike SushiSwap, for each pair we do:
    // Step 1: Retrieve the pair form the proper swap pool
    // Step 2: transfer tokens to pair and burn.
    // Step 3: track the relative weight. this is tricky.
    // After all pairs are burned we:
    // mint liquidity shares accordingly
    // we need to modify how each individual user's shares calculated from multiple _pid into one big pool
    // Create the ultimate omniswap pool

    //note the actual contracts start with Uniswaps in poolInfo, during migration this is swapped out to be Sushi's

    //do not create uniswap pair here as we are not depositing them into the same pair, we are creating an omnipool.
    //only supports whitelisted pairs currently. time to demosticate the wild stuff in other pools
    function domesticate(IUniswapV2Pair orig)
        public
        returns (
            bool result,
            uint256 index,
            uint256 legacyTotalsupply
        )
    {
        //note that sushi and uni have different underlaying impl for IUniswapV2Pair
        require(msg.sender == address(masterRancher), "you are not the rancher");
        require(block.number >= notBeforeBlock, "too early to migrate");
        require(orig.factory() == uniswapFactory, "not from old factory");
        require(setWethComplete, "set weth address");
        address token0 = orig.token0();
        address token1 = orig.token1();
        address otherTokenAddr;
        uint256 otherTokenAmount;
        uint256 wethAmount;
        uint256 lp = orig.balanceOf(msg.sender);
        uint256 current_index;
        AlpacaToken pacaToken;
        if (lp == 0) return (false, 0, 0);

        if (token0 == wethAddr || token1 == wethAddr) {
            //migrator does not check whether the tokens are intended for the pool, its rancher's job
            //transfer to this contract first to lock in the balances
            //migrator needs to be approved first before sending

            // Note: Uniswap has a balanced pool,
            // so the value of the non-WETH token in WETH is equal to the number of WETH
            orig.transferFrom(msg.sender, address(orig), lp);
            (uint256 amount0, uint256 amount1) = orig.burn(address(this));
            if (token0 == wethAddr) {
                otherTokenAddr = token1;
                otherTokenAmount = amount1;
                wethAmount = amount0;
                if (omniPool[token1].exists == false) {
                    tokenHolder[totalTokens] = token1;
                    current_index = totalTokens;
                    totalTokens++;
                    omniPool[token1].exists = true;
                }
            } else {
                otherTokenAddr = token0;
                otherTokenAmount = amount0;
                wethAmount = amount1;
                if (omniPool[token0].exists == false) {
                    tokenHolder[totalTokens] = token0;
                    current_index = totalTokens;
                    totalTokens++;
                    omniPool[token0].exists = true;
                }
            }
            tokenInfo storage wethToken = omniPool[wethAddr];
            tokenInfo storage otherToken = omniPool[otherTokenAddr];
            wethToken.balance = wethToken.balance.add(wethAmount);
            wethToken.wethValue = wethToken.wethValue.add(wethAmount);
            otherToken.balance = otherToken.balance.add(otherTokenAmount);
            otherToken.wethValue = otherToken.wethValue.add(wethAmount);
            // totalWethforShares = totalWeth = totalWeth.add(wethAmount).add(wethAmount);
            totalWethforShares = totalWethforShares.add(wethAmount).add(wethAmount);
            totalWeth = totalWeth.add(wethAmount).add(wethAmount);

            // B O N U S  P A C A
            // a special treat for the ranch hands
            if (token0 == pacaAddr || token1 == pacaAddr) {
                //during migration, we are inflating the total supply of PACA by 50% and adding it to the pool
                pacaToken = AlpacaToken((token0 == pacaAddr ? token0 : token1));
                uint256 amountToInflate = pacaToken.totalSupply().div(2);
                //request MasterRancher to mint the tokens and assign to migrator.
                uint256 pacaInflated = masterRancher.requestToMint(amountToInflate);
                require(pacaInflated == amountToInflate, "rancher has gone insane");
                uint256 additionalPACAWethValue = pacaInflated.mul(wethAmount).div(otherTokenAmount);
                otherToken.balance = otherToken.balance.add(pacaInflated);
                pacaWethValueForShares = otherToken.wethValue;
                otherToken.wethValue = otherToken.wethValue.add(additionalPACAWethValue);
                //we are not modifying totalWethforShares because the inflated PACAs are implicitly owned by everyone
                totalWeth = totalWeth.add(additionalPACAWethValue);
            }

            emit LogNewDomesticate(
                otherTokenAddr,
                otherTokenAmount,
                wethAmount
            );
            emit LogNewBalance(
                wethToken.balance,
                otherToken.balance,
                otherToken.wethValue
            );

            return (true, current_index, lp);
        }
        return (false, 0, 0);

    }

    // Only Alpacas are allowed on the ranch
    // Liquidate unsupported tokens for WETH and give it to the ranch,
    // where it will be owned equally by the ranch hands
    // Intended mostly for UNI earned by LP tokens deposited in MasterRancher
    // Inspired by SushiMaker
    function liquidateNonalpaca(address token) public {
        // get pair
        IUniswapV2Pair pair = IUniswapV2Pair(IUniswapV2Factory(uniswapFactory).getPair(token, wethAddr));
        if (address(pair) == address(0)) {
            return;
        }

        // calculate amounts in and out
        (uint reserve0, uint reserve1,) = pair.getReserves();
        address token0 = pair.token0();
        (uint reserveIn, uint reserveOut) = token0 == token ? (reserve0, reserve1) : (reserve1, reserve0);
        uint amountIn = IERC20(token).balanceOf(address(this));
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        uint amountOut = numerator / denominator;

        // execute swap
        (uint amount0Out, uint amount1Out) = token0 == token ? (uint(0), amountOut) : (amountOut, uint(0));
        IERC20(token).transfer(address(pair), amountIn);
        pair.swap(amount0Out, amount1Out, address(this), new bytes(0));

        // we are not modifying totalWethforShares because the WETH acquired
        // from liquidating non-alpacas is implicitly owned by everyone
        totalWeth = totalWeth.add(amountOut);
    }

    function retrieveShares(uint256 index) external view returns (uint256 shares) {
        require(omniPool[tokenHolder[index]].exists, "invalid index");
        return omniPool[tokenHolder[index]].shares;
    }

    /*
    1. calculate weights
    2. add in PACAs
    3. create omniPool
    4. start Pool
    */
    function establishTokenSetting() external {
        require(msg.sender == address(masterRancher), "you are not the rancher");
        require(block.number >= notBeforeBlock, "too early to migrate");
        uint256 currentWeight = 0;

        tokenInfo storage token;
        initialTotalLPSupply = totalWethforShares < BalancerConstants.MIN_POOL_SUPPLY
            ? BalancerConstants.MIN_POOL_SUPPLY
            : totalWethforShares;

        for (uint256 i = 0; i < totalTokens; i++) {
            token = omniPool[tokenHolder[i]];
            if (token.exists == false) continue;

            //note that these division will floor, but it doesn't matter much.
            omniPoolParams.constituentTokens.push(tokenHolder[i]);
            omniPoolParams.tokenBalances.push(token.balance);
            currentWeight = (
                    token.wethValue.mul(BalancerConstants.MAX_WEIGHT)
                ).div(totalWeth);
            omniPoolParams.tokenWeights.push(currentWeight);

            // there will be minor slippage since we don't know if rounding is happening but should be very minor
            if (tokenHolder[i] != wethAddr)
            if(tokenHolder[i] == pacaAddr)
            {
            token.shares = (
                    (pacaWethValueForShares.mul(initialTotalLPSupply)).mul(2)
                ).div(totalWethforShares);
            }
            else
            {
            token.shares = (
                    (token.wethValue.mul(initialTotalLPSupply)).mul(2)
                ).div(totalWethforShares);
            }

            require(
                currentWeight >= BalancerConstants.MIN_WEIGHT,
                "do you math?"
            );
        }
    }

    function establishRanch() external returns (IERC20 alp) {
        require(msg.sender == address(masterRancher), "you are not the rancher");
        require(block.number >= notBeforeBlock, "too early to migrate");
        tokenInfo storage token;

        pacaOmniPool = crpFact.newCrp(
            BFactoryAddress,
            omniPoolParams,
            permissions
        );

        //approve all assets:
        for (uint256 i = 0; i < totalTokens; i++) {
            token = omniPool[tokenHolder[i]];
            if (token.exists == false) continue;
            //this will work because the amount of ERC20 does not change after we burn the LP in domesticate
            IERC20Uniswap(tokenHolder[i]).approve(
                address(pacaOmniPool),
                token.balance
            );
        }

        return pacaOmniPool;
    }

    function startRanch(
        address _feeTo,
        uint256 _feeToPct,
        address _exitFeeTo,
        uint256 _exitFee,
        address _payOutToken,
        address _controller
    ) external {
        require(msg.sender == address(masterRancher), "you are not the rancher");
        require(block.number >= notBeforeBlock, "too early to migrate");

        pacaOmniPool.createPool(initialTotalLPSupply);
        pacaOmniPool.approve(address(masterRancher), initialTotalLPSupply);
        pacaOmniPool.transfer(address(masterRancher), initialTotalLPSupply);

        pacaOmniPool.setFeeTo(_feeTo);
        pacaOmniPool.setFracFeePaidOut(_feeToPct);
        pacaOmniPool.setPayoutToken(_payOutToken);
        pacaOmniPool.setExitFee(_exitFee);
        pacaOmniPool.setExitFeeTo(_exitFeeTo);
        pacaOmniPool.setController(_controller);
    }
}
