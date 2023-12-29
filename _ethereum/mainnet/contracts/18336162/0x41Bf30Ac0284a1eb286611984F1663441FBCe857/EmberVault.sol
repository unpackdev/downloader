// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./GenericERC20Token.sol";
import "./Owned.sol";
import "./IWETH.sol";
import "./IEsEMBR.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";

contract EmberVault is Owned {
    struct Package {
        uint8 Enabled;
        uint80 Price;
        uint80 BorrowedLiquidity;
        uint16 Duration; // IN WEEKS!
        uint16 DebtGrowthPerWeek; // for 40% apy its 65. 0.65% per week = ~40% apy
    } // total size 1 slot

    struct SetupParams {
        string TokenName;
        string TokenSymbol;
        uint8 TokenDecimals;
        uint256 TotalSupply;
        uint256 TransferTax;
    }

    struct TokenInfo {
        uint40 CreationTime;
        uint16 PackageId;
        uint24 Reserved; // reserved
        uint16 LastPaidWeek; // 0 = no payments, 1 = paid off first week, etc
        uint80 Pending;
        uint80 RemainingDebt; // uint80 is fine here because the debt will never be more than 1.2 million ethers.

        uint256 TotalPaid;
    } // total size 2 slots

    struct ClaimInfo {
        uint256 EthAmount;
        uint256 TokenAmount;
    } // total size 2 slots

    mapping(address => address) public tokenDeployers; // mapping(Token => Deployer)
    mapping(address => address) public liquidityPools; // mapping(Token => UniV2Pool)
    mapping(uint256 => Package) public packages; // mapping(PackageId => Package)
    mapping(address => TokenInfo) public tokens; // mapping(Token => TokenInfo)
    mapping(address => ClaimInfo) public claims; // mapping(CookedToken => ClaimInfo)

    mapping(address => bool) allowed_factories; // mapping(UniV2Factory => bool)
    mapping(address => bool) allowed_routers; // mapping(Router => bool)
    mapping(address => address) router_factory; // mapping(Router => Factory)

    IWETH public WETH;
    address payable public esEmbr;

    uint256 nextPackageId;

    uint256 public pullingMaxHoursReward = 100;
    uint256 public pullingRewardPerHour;
    uint256 public pullingBaseReward;

    uint256 private rentrancy_lock = 1;

    event TokenDeployed(
        address indexed deployer,
        address token_address,
        GenericERC20Token.ConstructorCalldata params,
        uint256 package_id,
        uint256 initialLiq
    );

    constructor(address _router, address _factory) Owned(msg.sender) {
        require(_router != address(0), "Router address cannot be 0");
        require(_factory != address(0), "Factory address cannot be 0");

        allowed_routers[_router] = true;
        allowed_factories[_factory] = true;
        router_factory[_router] = _factory;

        WETH = IWETH(payable(IUniswapV2Router02(_router).WETH()));
        WETH.approve(_router, type(uint256).max);
    }

    modifier onlyEsEMBR() {
        require(msg.sender == esEmbr, "Vault: Only esEMBR contract can call this function");
        _;
    }

    modifier nonReentrant() {
        require(rentrancy_lock == 1);

        rentrancy_lock = 2;
        _;
        rentrancy_lock = 1;
    }

    function create(
        GenericERC20Token.ConstructorCalldata calldata params,
        uint16 package_id
    ) external payable returns (address) {
        Package memory package = packages[package_id];

        require(package.BorrowedLiquidity != 0, "Vault: Invalid package provided");
        require(msg.value == package.Price, "Vault: Invalid package cost provided");

        require(package.Enabled == 1, "Vault: Package is disabled");

        require(address(this).balance >= package.BorrowedLiquidity, "Vault: Not enough funds available to lend");
        require(allowed_routers[params.UniV2SwapRouter], "Vault: Unsupported Swap Router provided");
        require(router_factory[params.UniV2SwapRouter] == params.UniV2Factory, "Vault: Invalid UniswapV2 factory provided");

        // Check if we can verify contract-deployed tokens on etherscan
        address token = address(new GenericERC20Token(params, address(WETH)));
        address pool = GenericERC20Token(payable(token)).addLiquidity{value: package.BorrowedLiquidity}(params.TotalSupply);

        tokenDeployers[token] = msg.sender;
        liquidityPools[token] = pool;
        tokens[token] = TokenInfo({
           CreationTime: uint40(block.timestamp),
           PackageId: package_id,
           Reserved: 0,
           LastPaidWeek: 0,
           Pending: 0,
           RemainingDebt: uint80(package.BorrowedLiquidity),

           TotalPaid: 0
        });

        emit TokenDeployed(
            msg.sender,
            token,
            params,
            package_id,
            package.BorrowedLiquidity
        );

        // Send package cost to esEMBR so it can be distributed
        (bool success, ) = esEmbr.call{value: msg.value}("");
        require(success, "Vault: Failed to send ether to esEMBR");

        return token;
    }

    // Transfers all tokens from the token contract to this vault and sells them
    // @returns the amount of eth received from selling
    function liquidateToken(GenericERC20Token token, address swap_router, uint256 minTokenOut) internal {
        uint256 contract_token_balance = token.withdrawTokens();
        if (contract_token_balance == 0) {
            return;
        }

        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(WETH);

        // Wrap in a try catch to prevent losing access to the borrowed ETH if the token or dex revert for whatever reason.
        try IUniswapV2Router01(swap_router).swapExactTokensForETHSupportingFeeOnTransferTokens(
            contract_token_balance,
            minTokenOut,
            path,
            address(this),
            type(uint256).max
        ) { } catch {
			// Ignore
        }
    }

    function removeLiquidityETH(IUniswapV2Pair pair, uint256 amount) internal returns(uint256, uint256) {
        pair.transfer(address(pair), amount); // Must send liquidity to pair first before pulling (burning)
        (uint256 amount0, uint256 amount1) = pair.burn(address(this));
        (uint256 amountToken, uint256 amountEth) = address(WETH) == pair.token0() ? (amount1, amount0) : (amount0, amount1);

        WETH.withdraw(amountEth);

        return (amountToken, amountEth);
    }

	event TokenDefaulted(address token, address liquidator, uint256 eth_amount, uint256 token_amount);
    function tryPullLiq(GenericERC20Token token, uint256 minTokenOut) external {
        TokenInfo memory tokenInfo = tokens[address(token)];
        require(tokenInfo.RemainingDebt != 0, "Vault: Invalid token provided or debt is already paid off");

        // first we check if token actually missed their payments
        uint16 currentWeek = uint16((block.timestamp - tokenInfo.CreationTime) / 604800) + 1;
        require(currentWeek > tokenInfo.LastPaidWeek + 1, "Vault: Only unhealthy tokens can be liquidated");

        Package memory package = packages[tokenInfo.PackageId];

        address swap_router = token.swapRouter();

        // Sell whatever tax tokens are left in the token's contract
        liquidateToken(token, swap_router, minTokenOut);

        IUniswapV2Pair pair = IUniswapV2Pair(token.initial_liquidity_pool());

        (uint256 amntTokenPulled, uint256 amntEthPulled) = removeLiquidityETH(pair, pair.balanceOf(address(this)));

        uint256 _borrowedLiquidity = package.BorrowedLiquidity;
        uint256 _tokenTotalSupply = token.totalSupply();

        // Uniswap burns a very small amount of tokens, so if you add 1eth to LP then instantly pull you will get 0.999..99 eth back. 
        // Make sure we don't underflow when that happens
        uint256 ethAmount = amntEthPulled < _borrowedLiquidity ? 0 : amntEthPulled - _borrowedLiquidity;
        uint256 tokenAmount = amntTokenPulled > _tokenTotalSupply ? 0 : _tokenTotalSupply - amntTokenPulled; 

        // Make ppl claim it turbo
        claims[address(token)] = ClaimInfo({
            EthAmount: ethAmount, // Total eth amount available for users to claim
            TokenAmount: tokenAmount // The tokens circulating outside the LP
        });

        // stop transfers
        token.disableTransfers();

        delete tokens[address(token)];

        // Reward the user esEMBR for pulling liq

        // Clamp reward by `pullingMaxHoursReward`
        uint256 hoursSinceWeekStarted = (block.timestamp - (tokenInfo.CreationTime + tokenInfo.LastPaidWeek * 604800)) / 3600;
        if (hoursSinceWeekStarted > pullingMaxHoursReward) hoursSinceWeekStarted = pullingMaxHoursReward;

        IEsEMBR(esEmbr).reward(msg.sender, hoursSinceWeekStarted * pullingRewardPerHour + pullingBaseReward);

		emit TokenDefaulted(address(token), msg.sender, ethAmount, tokenAmount);
    }

    // When a failed project's liquidity is pulled, users can exchange their tokens to the ETH the vault pulled from LP, proportional to their share
    function redeemToken(GenericERC20Token token, uint256 amount) nonReentrant external returns (uint) {
        require(tokenDeployers[address(token)] != address(0) && token.emberStatus() == GenericERC20Token.EmberDebtStatus.DEFAULTED, "Vault: Unable to claim eth from a token that hasn't defaulted");

        // Tokens will be sent to this contract where they will basically count as burned
        token.transferFrom(msg.sender, address(this), amount);

        ClaimInfo memory claimInfo = claims[address(token)];
        uint256 refund = amount * claimInfo.EthAmount / claimInfo.TokenAmount;

        (bool success,) = msg.sender.call{value: refund}("");
        require(success, "Vault: Failed to send ether");

        return refund;
    }

    // Users can also exchange LP tokens for their share of the pulled LP
    function redeemLPToken(GenericERC20Token token, uint256 amount) nonReentrant external returns (uint) {
        require(tokenDeployers[address(token)] != address(0) && token.emberStatus() == GenericERC20Token.EmberDebtStatus.DEFAULTED, "Vault: Unable to claim eth from a token that hasn't defaulted");
        IUniswapV2Pair lp_token = IUniswapV2Pair(token.initial_liquidity_pool());

        // We could directly transfer the LP token to the LP and burn it to save gas
        lp_token.transferFrom(msg.sender, address(this), amount);

        // Using lp_token.burn saves gas fosho but gotta rewrite some code, will do later
        // both the tokens and the eth will be sent to the vault contract
        (uint256 amntTokenPulled, uint256 amntEthPulled) = removeLiquidityETH(lp_token, amount);

        ClaimInfo memory claimInfo = claims[address(token)];
        uint256 refund = amntTokenPulled * claimInfo.EthAmount / claimInfo.TokenAmount;

        (bool success,) = msg.sender.call{value: refund + amntEthPulled}("");
        require(success, "Vault: Failed to send ether");

        return refund + amntEthPulled;
    }

    // interest_paid: the amount of interest the protocol made from interest
    function onDebtPaidOff(GenericERC20Token token, uint256 interest_paid) internal {
        address deployer = tokenDeployers[address(token)];

        // Free up space
        delete tokens[address(token)];
        delete tokenDeployers[address(token)];

        token.transferOwnershipToRealOwner(deployer);

		IERC20 lp_token = IERC20(liquidityPools[address(token)]);
		lp_token.transfer(deployer, lp_token.balanceOf(address(this)));

        // Send the eth made from interest to esEMBR so its revshared
        (bool success, ) = esEmbr.call{value: interest_paid}("");
        require(success, "Vault: Failed to send ether to esEMBR");
    }

    receive() external payable {
		// Vault can receive ETH
    }

    // This function can be called to collect fees and pay off debt but also by sending in eth to help pay off debt faster
    event DebtDecrease(address token, uint256 new_debt);
    event DebtPaidOff(address token);
    function payup(GenericERC20Token token) nonReentrant payable external returns(uint80, uint80, uint80, uint) {
        require(msg.sender == tokenDeployers[address(token)], "Vault: Only token deployer can claim fees");

        TokenInfo memory tokenInfo = tokens[address(token)];

        Package memory package = packages[tokenInfo.PackageId];

        uint80 collectedEth = uint80(token.withdrawEth()) + uint80(msg.value) + tokenInfo.Pending;

        // from now on, this function wont revert. It will simply try to pay off as much as it can and update the info.
        uint16 currentWeek = uint16((block.timestamp - tokenInfo.CreationTime) / 604800) + 1;
        if (currentWeek > package.Duration) {
            currentWeek = package.Duration;
        }

        (uint16 paidForWeeks, uint80 newDebt, uint80 newPending) = payOffWeeks(tokenInfo.RemainingDebt, collectedEth, currentWeek - tokenInfo.LastPaidWeek, package.Duration - tokenInfo.LastPaidWeek, package.DebtGrowthPerWeek);
        tokenInfo.LastPaidWeek += paidForWeeks;
        tokenInfo.RemainingDebt = newDebt;
        tokenInfo.Pending = newPending;
        tokenInfo.TotalPaid += collectedEth;

        tokens[address(token)] = tokenInfo;

        // Check if deployer just paid off all debt
        if (newDebt == 0) {
            // Send any leftover ETH to the owner
            if (newPending != 0) {
                (bool success, ) = msg.sender.call{value: newPending}("");
                require(success, "Vault: payup: Failed to send ether");
            }

            onDebtPaidOff(token, tokenInfo.TotalPaid - package.BorrowedLiquidity);

            emit DebtPaidOff(address(token));
            return (collectedEth, 0, 0, tokenInfo.TotalPaid);
        }

        emit DebtDecrease(address(token), newDebt);

        return (collectedEth, newDebt, newPending, tokenInfo.TotalPaid);
    }

    function payOffWeeks(uint80 debt, uint80 balance, uint16 shouldPayOffWeeks, uint16 weeksRemaining, uint16 growthPerWeek) public pure returns (uint16, uint80, uint80) {
        // Increate debt according to apy
        uint80 nextWeeksDebt;
        uint16 paidForWeeks;
        uint80 newDebt = debt;
        uint80 newPending = balance;

        // Is it possible to run out of gas here?
        for (uint256 i = 0; i < shouldPayOffWeeks; i++) {
            uint80 newDebt2 = newDebt + newDebt * growthPerWeek / 10000;
            nextWeeksDebt = newDebt2 / weeksRemaining;
            if (newPending >= nextWeeksDebt) {
                // can pay off a week
                newDebt = newDebt2;
                newDebt -= nextWeeksDebt;
                newPending -= nextWeeksDebt;
                paidForWeeks++;
                weeksRemaining--;
            } else {
                // no paid offs turbo
                return (paidForWeeks, newDebt, newPending);
            }
        }

        // if theres anything LEFT after paying off the current weeks, we put it towards paying off the real debt
        if (newDebt >= newPending) {
            newDebt -= newPending;
            newPending = 0;
        } else {
            newPending -= newDebt;
            newDebt = 0;
        }

        return (paidForWeeks, newDebt, newPending);
    }

    // ============================== OWNER-ONLY FUNCTIONS ==============================
    function setRewardSettings(uint256 _base, uint256 _max, uint256 _rate) onlyOwner external {
        pullingBaseReward = _base;
        pullingMaxHoursReward = _max;
        pullingRewardPerHour = _rate;
    }

    function setEsEMBR(address payable _esEmbr) onlyOwner external {
        require(address(esEmbr) == address(0), "Vault: Cannot set esEMBR again");
        esEmbr = _esEmbr;
    }

    // Owner can add new packages
    function addPackage(Package calldata _package) external onlyOwner {
        require(_package.BorrowedLiquidity > 0, "Vault: Liquidity cannot be 0");

        packages[nextPackageId++] = _package;
    }

    // Packages can be enabled & disabled, but never removed
    function setPackageEnabled(uint256 package_id, uint8 _status) external onlyOwner {
        require(packages[package_id].BorrowedLiquidity != 0, "Vault: Invalid package provided");

        packages[package_id].Enabled = _status;
    }

    // Manage DEX routers and factories
    function setRouterStatus(address _router, address _factory, bool status) external onlyOwner {
        require(_router != address(0), "Router address cannot be 0");
        require(_factory != address(0), "Factory address cannot be 0");

        allowed_routers[_router] = status;
        allowed_factories[_factory] = status;

        router_factory[_router] = _factory;
    }

    // ============================== FUNCTIONS CALLED BY ESEMBR ==============================

    // Called by esEMBR when a user wants to unstake their eth, note that the user will have to wait if the amount they're trying to unstake is currently utilized
    function unstakeEth(uint256 amount, address unstaker) onlyEsEMBR external {
        (bool success, ) = unstaker.call{value: amount}("");
        require(success, "Vault: unstakeEth: Failed to send ether");
    }
}
