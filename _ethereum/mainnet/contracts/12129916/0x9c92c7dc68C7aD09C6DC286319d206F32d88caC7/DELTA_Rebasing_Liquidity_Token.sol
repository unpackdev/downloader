import "./IWETH.sol";
import "./IDeltaToken.sol";
import "./IRebasingLiquidityToken.sol";
import "./UniswapV2Library.sol";
import "./ERC20Upgradeable.sol";

interface IRESERVE_VAULT {
    function flashBorrowEverything() external;
}

interface IDELTA_LSW {
    function totalWETHEarmarkedForReferrers() external view returns (uint256);
}

contract DELTA_Rebasing_Liquidity_Token is IRebasingLiquidityToken, ERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

    struct AddressCache {
        address deltaxWethPairAddress;
        IDeltaToken deltaToken;
        IUniswapV2Pair deltaxWethPair;
    }

    uint256 public override rlpPerLP;
    uint256 public _dailyVolumeTargetETH;
    uint256 private lastTargetUpdate;
    uint256 public ethVolumeRemaining;

    //immutables and contstancts
    IUniswapV2Pair public immutable DELTA_WETH_PAIR;
    IDeltaToken public immutable DELTA; 
    address constant internal DEAD_BEEF = 0xDeaDbeefdEAdbeefdEadbEEFdeadbeEFdEaDbeeF;
    address public constant LSW = 0xdaFCE5670d3F67da9A3A44FE6bc36992e5E2beaB;
    address public immutable RESERVE_VAULT;
    IWETH public constant WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    uint256 constant public _DAILY_PERCENTAGE_COST_INCREASE_TO_MINT_LP = 10;


    function initialize() public virtual initializer {
        __ERC20_init("Rebasing Liquidity Token - DELTA.financial", "DELTA rLP"); // Name, symbol
        // Initially set it to 1LP = 1RLP
        rlpPerLP = 1 ether;
    }

    // Rebasing LP is created before DELTA TOKEN is.
    constructor (address delta, address _reserveVault ) {
        //LSW call points
        RESERVE_VAULT = _reserveVault;
        DELTA = IDeltaToken(delta);
        DELTA_WETH_PAIR = IUniswapV2Pair(address(uint(keccak256(abi.encodePacked(
                hex'ff',
                0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f, // Mainnet uniswap factory
                keccak256(abi.encodePacked(delta, address(WETH))),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            )))));
    }

    function onlyLSW() public view {
        require(msg.sender == LSW, "!LSW GO AWAY");
    }

    // Do not remove this as this is called from the LSW
    function setBaseLPToken(address) public {
        onlyLSW();
        this; // sincence warnings
    }

    // @notice wraps all LP tokens of the caller, requires allowance
    // @dev intent of this function is to get the balance of the caller, and wrap his entire balance, update the basetoken supply, and issue the caller amount of tokens that we transfered from him
    function wrap() public override {
        _performWrap(); // This doesn't return because LSW doesn't expect a return value and we can't adjust it now.
    }

    function wrapWithReturn() external override returns (uint256) {
        return _performWrap();
    }

    function _performWrap() internal returns (uint256) {
        uint256 balanceCaller = DELTA_WETH_PAIR.balanceOf(msg.sender);
        require(balanceCaller > 0, "No tokens to wrap");
        // @dev from caller , to here , amount total of caller
        bool success = DELTA_WETH_PAIR.transferFrom(msg.sender, address(this), balanceCaller);
        require(success, "Transfer Failure");
        uint256 garnishedBalance = balanceCaller.mul(rlpPerLP).div(1e18);
        _mint(msg.sender, garnishedBalance);
        return garnishedBalance;
    }

    function rebase() public {
        require(msg.sender == tx.origin, "Smart wallets cannot call this function");

        uint256 deltaBalance = DELTA.balanceOf(address(this));
        if(deltaBalance > 0) { // remove if we have DELTA in here for some reason
            DELTA.transfer(RESERVE_VAULT, deltaBalance); 
        }

        // Collect pre-rebasing stats
        (uint256 preVolumeDELTAReserve, uint256 preVolumeWETHReserve,) = DELTA_WETH_PAIR.getReserves();
        uint256 preVolumeLPSupply = DELTA_WETH_PAIR.totalSupply();
        uint256 preVolumeLPBalance = DELTA_WETH_PAIR.balanceOf(address(this));

        // Have the delta token allow for burning of LP, temporarily.
        // This will call tokenCaller and them proceed to call reserveCaller and to numberLoops of max transfers
        // And re-add LP tokens payback loan... hence we wrap this in few safety checks
        DELTA.performLiquidityRebasing();
        // calls >tokenCaller >reserveCaller on this contract in order

        // Collect post-rebasing stats
        (uint256 postVolumeDELTAReserve, uint256 postVolumeWETHReserve,) = DELTA_WETH_PAIR.getReserves();
        uint256 postVolumeLPSupply = DELTA_WETH_PAIR.totalSupply();
        uint256 postVolumeLPBalance = DELTA_WETH_PAIR.balanceOf(address(this));

        // All my homies hate division
        // WHERE IS MY FUCKING MONEY?
        require(postVolumeDELTAReserve == preVolumeDELTAReserve, "Delta reserve has changed");
        require(preVolumeWETHReserve + 10 > postVolumeWETHReserve && postVolumeWETHReserve >= preVolumeWETHReserve , "WETH reserve out of bounds");
        require(preVolumeLPBalance + 1e4 >= postVolumeLPBalance && postVolumeLPBalance + 1e5 > preVolumeLPBalance , "LP balance change not within bounds"); 
        require(preVolumeLPSupply + 1e4 >= postVolumeLPSupply && postVolumeLPSupply + 1e5 > preVolumeLPSupply, "LP Supply change not within bounds");
    }

    // Delta token calls this after performLiquidityRebasing is in the middle of execution on the token contract
    function tokenCaller() override public {
        require(msg.sender == address(DELTA));
        IRESERVE_VAULT(RESERVE_VAULT).flashBorrowEverything();
    }

    function volumeGeneratingTrades( IDeltaToken _delta, IUniswapV2Pair _pair, uint256 ethTradeVolumeNeededToHitTarget) internal returns (uint256 newVolumeETHRemaining) {
        uint256 balanceWETH = WETH.balanceOf(address(this));
        (uint256 unsiwapReserveDelta, uint256 uniswapReserveWETH, ) = _pair.getReserves();

        uint256 amount0In = unsiwapReserveDelta.mul(1e12).div(uniswapReserveWETH).mul(balanceWETH).div(1e12);  // Amount DELTA to send every transfer to get balanceWETH if there was no fee
        uint256 amount0Out = amount0In * 10000/10161; // 0.6% slippage + ineffciencies;

        address addressPair = address(_pair);
        uint256 loops;
        while(loops < 50) {
            WETH.transfer(addressPair, balanceWETH);
            _delta.adjustBalanceOfNoVestingAccount(addressPair, amount0In, true); // Add the amountIn back uniswap treats it like a transfer and we dont have to guarantee that we have that delta

            // DELTA + WETH  for DELTA * 0.994 + WETH
            // Quadruple WETH in volume
            _pair.swap(amount0Out, balanceWETH, address(this), "");

            _delta.adjustBalanceOfNoVestingAccount(addressPair, unsiwapReserveDelta, false); // Adjust back to reserves ( would have higher else and print dragonflies)
            
            _pair.sync(); // Force reserves to show that
            // Note that WETH balance will not change

            if(balanceWETH > ethTradeVolumeNeededToHitTarget) {
                return 0;
            } else {
                ethTradeVolumeNeededToHitTarget -= balanceWETH;
                loops++;
            }
        }

        // This can be non 0 if we are over 50 loops which is straining this algorithm
        newVolumeETHRemaining = ethTradeVolumeNeededToHitTarget;
    }



    function setUpDailyVolumeTarget(uint256 ethWholeUnits, bool hourlyRebaseRightAway) public {
        onlyMultisig();
        _dailyVolumeTargetETH = ethWholeUnits * 1 ether;
        lastTargetUpdate = hourlyRebaseRightAway ? block.timestamp - 1 hours : block.timestamp; // can rebase right away rebase
    }


    function getRemainingETHInVolumeTarget() public view returns (uint256 remainingVolumeInETH, uint256 secondsSinceLastUpdate) {
        secondsSinceLastUpdate = (block.timestamp - lastTargetUpdate);
        uint256 hoursSinceLastUpdate = secondsSinceLastUpdate / 1 hours;
        remainingVolumeInETH = (_dailyVolumeTargetETH / 24).mul(hoursSinceLastUpdate).add(ethVolumeRemaining); // We dont allow partial hours to not have too much volume from calls
    }

    function updateRemainingETH() private returns (uint256) {
        (uint256 remainingVolumeInETH, uint256 secondsSinceLastUpdate) = getRemainingETHInVolumeTarget();
        lastTargetUpdate = block.timestamp - (secondsSinceLastUpdate % 1 hours); // we carry over the rest of 1hour
        return remainingVolumeInETH;
    }


    function reduceLpRatio(uint256 percentReductionE12) private {
        uint256 ratio = rlpPerLP;
        rlpPerLP = ratio.sub( ratio.mul(percentReductionE12).div(1e14) );
    }

    // The delta reserve calls this during execution in order to complete flash borrowing
    function reserveCaller(uint256 borrowedDELTA, uint256 borrowedWETH) public override {
        // Reserve vault calls this contract with the amount of DELTA and WETH it borrowed to us.
        // 1) We find a optimal DELTA to add with all the WETH to get LP tokens
        // 2) We burn half of all LP tokens we have ( the newly minted + ones in this contract)
            // Only half can be traded at a time because of uniswap reserve requirements
        // 3) We do loop of DELTA and WETH trades for DELTA and WETH. With every time removing 0.6% of delta we expect to pay the fee (0.3*2)
        // 4) We sell DELTA to get WETH
        // 5) We keep changing the uniswap balance and adding more and more liquidity in a loop until we have enough to cover what we had before
            // trading loses us lp tokens, because the ones remaining in the pool concentrate fees
        // 6) We adjust the uniswap balance to thee previos state in order to avoid price changing
        // 7) We repay the loan
        // 8) We adjust the uniswap DELTA reciever ratio, in order to make LP tokens more to mint
            // We have to take into account the totalSupply change in LP tokens
        require(msg.sender == RESERVE_VAULT);

        // We update the target timestamp and consume all remaining ETH that was unspent.
        uint256 ethTradeVolumeNeededToHitTarget = updateRemainingETH();
        require(ethTradeVolumeNeededToHitTarget > 0, "Can't generate volume, wait until a full hour still last targetUpdate is up");

        
        uint256 balanceLPBeforeMintingAndRebasing = DELTA_WETH_PAIR.balanceOf(address(this));
        // We got a loan from reserve vault
        // We have to figure out how to utilize it
        (uint256 unsiwapReserveDelta, uint256 uniswapReserveWETH,) = DELTA_WETH_PAIR.getReserves();

        // If we borrowed WETH, we mint
        if(borrowedWETH > 0) {
            uint256 balanceWETHWithLoan = WETH.balanceOf(address(this));
            uint256 optimalDELTAToMatchAllWETH = UniswapV2Library.quote(balanceWETHWithLoan, uniswapReserveWETH, unsiwapReserveDelta);
            // Send everything to add liquidity
            DELTA.adjustBalanceOfNoVestingAccount(address(DELTA_WETH_PAIR), optimalDELTAToMatchAllWETH, true);
            WETH.transfer(address(DELTA_WETH_PAIR), balanceWETHWithLoan);
            DELTA_WETH_PAIR.mint(address(this));
        }
        
        // We remove half of the liquidity
        // Note that half is the max because you cant get out more than reserves
        // Half is when we have all teh lp tokens
        DELTA_WETH_PAIR.transfer(address(DELTA_WETH_PAIR), DELTA_WETH_PAIR.balanceOf(address(this)) / 2);
        DELTA_WETH_PAIR.burn(address(this));

        // Perform volume trades, and reduce LP ratio based on the volume that gets filled successfully
        { // scope for unfilledEthVolumeRemaining, newRatio
            uint256 unfilledEthVolumeRemaining = volumeGeneratingTrades(DELTA, DELTA_WETH_PAIR, ethTradeVolumeNeededToHitTarget);
            uint256 volumeFulfilled = ethTradeVolumeNeededToHitTarget.sub(unfilledEthVolumeRemaining);
            uint256 lpRatioPercentReductionE12 = volumeFulfilled.mul(1e12).div(_dailyVolumeTargetETH).mul(_DAILY_PERCENTAGE_COST_INCREASE_TO_MINT_LP);
            // Adjust the ratio by the remianing eth to trade
            // If its 10% a day this should return 10/24 for every hour of volume = 0.41 * 1e12 = 410000000000;
            reduceLpRatio(lpRatioPercentReductionE12);
            ethVolumeRemaining = unfilledEthVolumeRemaining;
        }

        // At this point we have either too much or too little LP tokens
        // Since we borrowed we might have too much
        // Or we might have too little depending on when borrowed is less adding it than we already have
        // We branch the logic dependent on it
        uint256 balanceLPNow = DELTA_WETH_PAIR.balanceOf(address(this));

        if(balanceLPNow > balanceLPBeforeMintingAndRebasing) { // We have more or exactly the balance we had before
            // We burn the difference
            uint256 difference = balanceLPNow - balanceLPBeforeMintingAndRebasing;
            DELTA_WETH_PAIR.transfer(address(DELTA_WETH_PAIR), difference);
            DELTA_WETH_PAIR.burn(address(this));
            DELTA.adjustBalanceOfNoVestingAccount(address(DELTA_WETH_PAIR), unsiwapReserveDelta, false);
        } else { // Since we dont let accumulation to happen in the tokens vy adjusting balances directly
                // we can safely assume we just need to give back the WETH and DELTA back to previous levels to get LP tokens we need
                // This assumpion is changed in a function wrapping this one
            (, uint256 currentUniswapReserveWETH,) = DELTA_WETH_PAIR.getReserves();
            // Reserve has too little WETH
            // We need to send the difference 
            // Note this is also the case when we have less LP tokens than we should
            // Fees have not accumulated in the remaining supply of tokens as the reserves did not change
            uint256 ethNeeded = uniswapReserveWETH.sub(currentUniswapReserveWETH);
            if(ethNeeded > 0) {
                WETH.transfer(address(DELTA_WETH_PAIR), ethNeeded);
                DELTA.adjustBalanceOfNoVestingAccount(address(DELTA_WETH_PAIR), unsiwapReserveDelta, false);
                DELTA_WETH_PAIR.mint(address(this));
            }
            // Reserves now have as much DELTA and WETH as they should.
        }

        if(borrowedWETH > 0) { 
            // repay weth loan
            // note that reserves match up with weth it coudnt have gone anywhere but to us, but this convinently tests that too
            WETH.transfer(RESERVE_VAULT, WETH.balanceOf(address(this))); // -1 inefficiencies
            DELTA.adjustBalanceOfNoVestingAccount(RESERVE_VAULT, borrowedDELTA, true);
        }

        DELTA_WETH_PAIR.sync();
        // We directly set the balance of this address to 0
        DELTA.adjustBalanceOfNoVestingAccount(address(this), 0, false); 
    }


    /// @notice opens the first rebasing
    function openRebasing() public {
        onlyLSW();
        require(rlpPerLP == 1e18, "Contract not initialized");
        // we check how much LP we have
        // This call only happens once so we can assume a lot here
        uint256 totalETHInLSW = (1500 ether + WETH.balanceOf(RESERVE_VAULT) + IDELTA_LSW(LSW).totalWETHEarmarkedForReferrers()) * 2;
        uint256 totalInPairRatioE12 = uint256(1500 ether).mul(1e12).div(totalETHInLSW);

        rlpPerLP = totalInPairRatioE12.mul(1e6); // 18 - 12
        //One LP equal RLP 86606638913000000 (0.0866066389130000)
    }

    function onlyMultisig() private view {
        require(msg.sender == DELTA.governance(), "!governance");
    }




}


