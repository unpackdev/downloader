//SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "./IVaultController.sol";
import "./IUSDI.sol";
import "./IOracleMaster.sol";

import "./FlashLoanReceiverBase.sol";

import "./IUniswapV2Callee.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";

import "./ISwapRouter.sol";

contract Liquidator is IUniswapV2Callee, FlashLoanReceiverBase {
    IVaultController public constant CONTROLLER =
        IVaultController(0x4aaE9823Fb4C70490F1d802fC697F3ffF8D5CbE3);

    IUSDI public constant USDI =
        IUSDI(0x2A54bA2964C8Cd459Dc568853F79813a60761B58);

    IUniswapV2Factory public constant FACTORY =
        IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    ISwapRouter public constant ROUTERV3 =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    IERC20 public constant USDC =
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

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

    ///@notice sets the oracle to Interest Protocol's oracle master, call this if the oracle changes
    function setOracle() public {
        oracle = IOracleMaster(CONTROLLER.getOracleMaster());
    }

    ///@notice how much USDC is needed to liq completely
    ///@param vault - which vault to liq
    ///@param asset - which asset in @param vault to liq
    ///@return amount - amount to borrow in USDC terms 1e6
    ///@notice it is cheaper in gas to read this first and then pass to the liq function after (~855k vs ~1MM gas)
    function calculateCost(uint96 vault, address asset)
        external
        view
        returns (uint256 amount)
    {
        uint256 price = oracle.getLivePrice(asset);
        uint256 t2l = CONTROLLER.tokensToLiquidate(vault, asset);

        amount = ((price * t2l) / 1e18) / 1e12;
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

        address[] memory assets = new address[](1);
        assets[0] = address(USDC);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        // 0 = no debt, 1 = stable, 2 = variable
        // 0 = pay all loaned
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
        address pair = FACTORY.getPair(tokenBorrow, asset);
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

        address pair = FACTORY.getPair(token0, token1);
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
    ///@notice Because using V2 flashSwap places a lock on the pair, we can't use that pair to sell the asset again in the same TX, hence V3
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
        uint256 txCost = (oracle.getLivePrice(
            0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2//WETH
        ) *
            (startGas - gasleft()) *
            tx.gasprice) / 1e18;

        require(int256(revenue) - int256(txCost) > 0, "Gas cost too high");
    }
}
