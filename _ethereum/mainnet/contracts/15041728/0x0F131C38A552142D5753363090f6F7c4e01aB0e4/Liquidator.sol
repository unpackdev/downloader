//SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "./IVaultController.sol";
import "./IUSDI.sol";
import "./IOracleMaster.sol";

import "./FlashLoanReceiverBase.sol";

import "./IUniswapV2Callee.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";

import "./IUniswapV3Factory.sol";
import "./IUniswapV3FlashCallback.sol";
import "./ISwapRouter.sol";

import "./CallbackValidation.sol";

contract Liquidator is
    IUniswapV2Callee,
    FlashLoanReceiverBase,
    IUniswapV3FlashCallback
{
    IVaultController public constant CONTROLLER =
        IVaultController(0x4aaE9823Fb4C70490F1d802fC697F3ffF8D5CbE3);

    IUSDI public constant USDI =
        IUSDI(0x2A54bA2964C8Cd459Dc568853F79813a60761B58);

    IUniswapV2Factory public constant FACTORY_V2 =
        IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    ISwapRouter public constant ROUTERV3 =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    IUniswapV3Factory public constant FACTORY_V3 =
        IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);

    IERC20 public constant USDC =
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    IOracleMaster public oracle;

    event FlashLiquidate(
        string method,
        address tokenBorrow,
        uint96 vault,
        address assetLiquidated,
        uint256 amountBorrow,
        uint256 amountRepaid
    );

    ///@notice pass in LendingPoolAddressesProvider address to FlashLoanReceiverBase constructor
    constructor()
        FlashLoanReceiverBase(
            ILendingPoolAddressesProvider(
                0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5
            )
        )
    {
        setOracle();
    }

    ///@notice sets the oracle to Interest Protocol"s oracle master, call this if the oracle changes
    function setOracle() public {
        oracle = IOracleMaster(CONTROLLER.getOracleMaster());
    }

    ///@notice about how much USDC is needed to liq completely
    ///@param vault - which vault to liq
    ///@param asset - which asset in @param vault to liq
    ///@return amount - amount to borrow in USDC terms 1e6
    ///@notice it is cheaper in gas to read this first and then pass to the liq function after (~855k vs ~1MM gas for Aave)
    function calculateCost(uint96 vault, address asset)
        external
        view
        returns (uint256 amount)
    {
        //tokens to liquidate
        uint256 t2l = CONTROLLER.tokensToLiquidate(vault, asset);

        ///@notice need to take into account the liquidation incentive, or we will over borrow by that amount, resulting in a higher fee for the flash loan
        uint256 adjustedPrice = truncate(
            oracle.getLivePrice(asset) *
                (1e18 - CONTROLLER._tokenAddress_liquidationIncentive(asset))
        );
        amount = ((truncate((adjustedPrice + 1e18) * t2l)) / 1e12);
    }

    /***************UNI V3 FLASH LOANS**************************/
    ///@notice Uni V3 pool calls this after we call flash()
    ///@param fee0 - not used, how much to repay token 0 (DAI)
    ///@param fee1 - how  much to repay token 1 (USDC)
    function uniswapV3FlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata data
    ) external override {

        //decode data passed from uniV3FlashLiquidate()
        FlashCallbackData memory decoded = abi.decode(
            data,
            (FlashCallbackData)
        );

        //verify that this function is only called by the correct V3 Pool
        CallbackValidation.verifyCallback(
            address(FACTORY_V3),
            PoolAddress.PoolKey({
                token0: 0x6B175474E89094C44Da98b954EedeAC495271d0F, ///@notice DAI address hard coded to save gas
                token1: address(USDC),
                fee: 100
            })
        );
        //convert all USDC borrowed into USDI to use in liquidation
        getUSDI();

        //do the liquidation
        liquidate(decoded.amount, uint96(decoded.vault), decoded.asset);

        //convert all of asset to USDC to repay
        getUSDC(decoded.asset, IERC20(decoded.asset).balanceOf(address(this)));

        //convert any remianing USDI back to USDC to repay
        USDI.withdrawAll();

        //calcualte amount owed, the pool will conveniently tell us the fee
        uint256 amountOwed = decoded.amount + fee1;

        //emit event - could remove to save ~3k gas
        emit FlashLiquidate(
            "uniswapV3FlashCallback",
            address(USDC),
            uint96(decoded.vault),
            decoded.asset,
            decoded.amount,
            amountOwed
        );
        //repay flash loan - msg.sender is the DAI/USDC 1 bip pool as confirmed above
        USDC.transfer(msg.sender, amountOwed);
    }

    ///@param amount - USDC amount to borrow
    ///@param vault - vault to liquidate
    ///@param asset - asset to liquidate
    ///@param profitCheck - optional check to compare profit to gas cost
    struct FlashParams {
        uint256 amount;
        uint152 vault;
        address asset;
        bool profitCheck;
    }

    ///@notice data we expect to be returned from the V3 pool
    ///@param amount - USDC amount to borrow
    ///@param vault - vault to liquidate
    ///@param asset - asset to liquidate
    struct FlashCallbackData {
        uint256 amount;
        uint160 vault;
        address asset;
    }
    /// @notice The identifying key of the pool
    ///@param token0 - Should be DAI in the V3 pool
    ///@param token1 - Should be USDC in the V3 pool
    ///@param fee - should be 100 or 1 bip
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    ///@notice liquidate using USDC liquidity from the USDC/DAI pool at 100 fee
    ///@param params - struct of input params - see FlashParams
    function uniV3FlashLiquidate(FlashParams memory params) external {
        //check how much gas has been sent at the start of the tx
        uint256 startGas = gasleft();

        //USDC/DAI pool at 100 fee - this is the lowest fee for borrowing USDC
        IUniswapV3Pool pool = IUniswapV3Pool(
            0x5777d92f208679DB4b9778590Fa3CAB3aC9e2168 ///@notice pool address hard coded for reduced gas
        );

        //initiate the flashloan
        pool.flash(
            address(this), //Send borrowed tokens here
            0, //borrow 0 DAI
            params.amount, //borrow some amount of USDC
            abi.encode( //encode data to pass to uniswapV3FlashCallback
                FlashCallbackData({
                    amount: params.amount,
                    vault: params.vault,
                    asset: params.asset
                })
            )
        );

        //calculate revenue in USDC terms
        uint256 revenue = USDC.balanceOf(address(this)) * 1e12;

        //send revenue to user
        USDC.transfer(msg.sender, USDC.balanceOf(address(this)));

        //optional profit check - happens last to include cost to transfer revenue to user
        if (params.profitCheck) {
            checkGas(startGas, revenue);
        }
    }

    /***************AAVE FLASH LOANS**************************/
    ///@notice liquidate using a flash loan from aave
    ///@param amount - amount of USDC to borrow, see calculateCost()
    ///@param vault - which vault to liquidate
    ///@param asset - which asset in @param vault to liquidate
    ///@param profitCheck - check to make sure revenue > gas cost
    function aaveFlashLiquidate(
        uint256 amount,
        uint96 vault,
        address asset,
        bool profitCheck
    ) external {
        //check how much gas has been sent at the start of the tx
        uint256 startGas = gasleft();

        //Aave expects an array, even though we are only going to pass 1
        address[] memory assets = new address[](1);
        assets[0] = address(USDC);

        //Aave expects an array, even though we are only going to pass 1
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        // 0 = no debt, 1 = stable, 2 = variable
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;

        LENDING_POOL.flashLoan(
            address(this), //who receives flash loan
            assets, //borrowed assets, can be just 1
            amounts, //amounts to borrow
            modes, //what kind of loan - 0 for full repay
            address(this), //address to receive debt if mode is !0
            abi.encode(amount, vault, asset), //extra data to pass abi.encode(...)
            0 //referralCode - not used
        );

        //transfer USDC to msg.sender, should not leave on here due to griefing attack https://ethereum.stackexchange.com/questions/92391/explain-griefing-attack-on-aave-flash-loan/92457#92457
        uint256 revenue = USDC.balanceOf(address(this)) * 1e12;
        USDC.transfer(msg.sender, USDC.balanceOf(address(this)));

        //optional profit check - happens last to include cost to transfer revenue to user
        if (profitCheck) {
            checkGas(startGas, revenue);
        }
    }

    ///@notice aave calls this after we call flashloan() inside aaveFlashLiquidate()
    ///@param assets - should always be length 1 and == USDC -- NOT USED
    ///@param amounts - should always be length 1 and == USDC borrow amount
    ///@param premiums - should always be length 1 and == Fee amount to be added to repay amount
    ///@param initiator - Who initiated the flash loan, should be this contract
    ///@param params - data we encoded in aaveFlashLiquidate() is passed back to us here
    function executeOperation(
        address[] calldata assets, //should be usdc
        uint256[] calldata amounts,
        uint256[] calldata premiums, //fees
        address initiator, //address executed flash loan
        bytes calldata params //encoded data
    ) external override returns (bool) {
        (uint256 amount, uint96 vault, address asset) = abi.decode(
            params,
            (uint256, uint96, address)
        );
        //convert all USDC borrowed into USDI to use in liquidation
        getUSDI();

        //do the liquidation
        liquidate(amount, vault, asset);

        //convert all of asset to USDC to repay
        getUSDC(asset, IERC20(asset).balanceOf(initiator));

        //convert any remianing USDI back to USDC to repay
        USDI.approve(address(USDI), USDC.balanceOf(initiator));
        USDI.withdrawAll();

        uint256 amountOwing = amounts[0] + (premiums[0]);

        //emit event - could remove to save ~3k gas
        emit FlashLiquidate(
            "executeOperation",
            address(USDC),
            vault,
            asset,
            amount,
            amountOwing
        );

        //approve aave to take from this contract to repay
        USDC.approve(address(LENDING_POOL), amountOwing);
        return true;
    }

    /***************UNI V2 FLASH LOANS**************************/
    ///@notice liquidate vault
    ///@param tokenBorrow - USDI to borrow USDI and be paid in USDI, USDC to borrow USDC and be paid in USDC
    ///@param amount - amount of USDI to borrow, should be close to the amount needed to liquidate
    ///@param vault - which vault to liquidate
    ///@param asset - which asset to liquidate from the vault
    ///@param profitCheck - check to make sure revenue > gas cost
    function uniV2FlashLiquidate(
        address tokenBorrow,
        uint256 amount,
        uint96 vault,
        address asset,
        bool profitCheck
    ) external {
        uint256 startGas = gasleft();
        address pair = FACTORY_V2.getPair(tokenBorrow, asset);
        require(pair != address(0), "invalid pair");

        // scope for token{0,1}, avoids stack too deep errors
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();

        uint256 amount0Out = tokenBorrow == token0 ? amount : 0;
        uint256 amount1Out = tokenBorrow == token1 ? amount : 0;

        bytes memory data = abi.encode(tokenBorrow, amount, vault, asset);

        //perform flash swap
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data); //final arg determines if flash swap or normal swap, pass "" for normal swap

        if (tokenBorrow == address(USDI)) {
            uint256 revenue = USDI.balanceOf(address(this));
            USDI.transfer(msg.sender, revenue);
            if (profitCheck) {
                checkGas(startGas, revenue);
            }
        } else if (tokenBorrow == address(USDC)) {
            uint256 revenue = USDC.balanceOf(address(this)) * 1e12;
            USDC.transfer(msg.sender, USDC.balanceOf(address(this)));
            if (profitCheck) {
                checkGas(startGas, revenue);
            }
        }
    }

    ///@notice - The V2 pair we are borrowing from calls this after we call swap() in uniV2FlashLiquidate()
    ///@param sender - Who initiated the FlashSwap, should be this contract, there is a check for this below
    ///@param amount0 - not used, see @param data instead
    ///@param amount1 - not used, see @param data instead
    ///@param data - data we encoded in uniV2FlashLiquidate() is passed back to us here
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override {
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();

        address pair = FACTORY_V2.getPair(token0, token1);
        require(pair == pair, "!pair");

        require(sender == address(this), "!sender"); //this contract is sender

        (address tokenBorrow, uint256 amount, uint96 vault, address asset) = abi
            .decode(data, (address, uint256, uint96, address));

        // ~~0.3% fee
        uint256 fee = ((amount * 3) / 997) + 1;
        uint256 amountToRepay = amount + fee;

        if (tokenBorrow == address(USDI)) {
            //do the liquidation
            liquidate(amount, vault, asset);

            //swap asset for USDi
            getUSDC(asset, IERC20(asset).balanceOf(address(this))); //full amount
            getUSDI();
            require(
                USDI.balanceOf(address(this)) > amountToRepay,
                "Insufficient repay"
            );
        } else if (tokenBorrow == address(USDC)) {
            getUSDI();

            //do the liquidation
            liquidate(amount, vault, asset);

            //convert all of asset to USDC to repay
            getUSDC(asset, IERC20(asset).balanceOf(address(this)));

            //convert any remianing USDI back to USDC to repay
            USDI.approve(address(USDI), USDC.balanceOf(address(this)));
            USDI.withdrawAll();

            require(
                USDC.balanceOf(address(this)) > amountToRepay,
                "Insufficient repay"
            );
        } else {
            revert("Unsupported borrow");
        }

        //emit event - could remove to save ~3k gas
        emit FlashLiquidate(
            "uniswapV2Call",
            token0,
            vault,
            asset,
            amount,
            amountToRepay
        );

        //repay + fee
        IERC20(tokenBorrow).transfer(pair, amountToRepay);
    }

    /***************HELPER FUNCS**************************/
    ///@notice - internal function to perform the liquidation on Interest Protocol
    ///@param amount - amount of USDI we have available to liquidate
    ///@param vault - which vault to liq
    ///@param asset - which asset in @param vault to liq
    function liquidate(
        uint256 amount,
        uint96 vault,
        address asset
    ) internal {
        require(!CONTROLLER.checkVault(vault), "Vault is solvent");

        USDI.approve(address(CONTROLLER), amount);

        IVaultController(address(CONTROLLER)).liquidateVault(
            vault,
            asset,
            2**256 - 1 //liquidate maximum
        );
    }

    ///@notice convert collateral liquidated to USDC on Uniswap V3
    ///@notice Because using V2 flashSwap places a lock on the pair, we can"t use that pair to sell the asset again in the same TX, hence V3
    ///@param asset - convert this asset to USDC
    ///@param amount - convert this amount of @param asset into USDC
    function getUSDC(address asset, uint256 amount) internal {
        IERC20(asset).approve(address(ROUTERV3), amount);
        ROUTERV3.exactInputSingle(
            ISwapRouter.ExactInputSingleParams(
                asset,
                address(USDC),
                500,
                address(this),
                block.timestamp + 10,
                amount,
                0,
                0
            )
        );
    }

    ///@notice converts all USDC held by this contract to USDI using Interest Protocol
    function getUSDI() internal {
        uint256 amount = USDC.balanceOf(address(this));
        USDC.approve(address(USDI), amount);
        USDI.deposit(amount);
    }

    ///@notice ensure the gas cost does not exceed revenue so tx is always profitable
    ///@param startGas - gas available at the start of the tx
    ///@param revenue - in USDI terms, dollars e18
    function checkGas(uint256 startGas, uint256 revenue) internal view {
        uint256 txCost = (oracle.getLivePrice(WETH) *
            (startGas - gasleft()) *
            tx.gasprice) / 1e18;

        require(int256(revenue) - int256(txCost) > 0, "Gas cost too high");
    }

    function truncate(uint256 u) internal pure returns (uint256) {
        return u / 1e18;
    }
}
