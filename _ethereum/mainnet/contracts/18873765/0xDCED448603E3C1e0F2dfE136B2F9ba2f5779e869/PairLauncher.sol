// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import "./ButtonswapRouter.sol";
import "./ButtonswapFactory.sol";
import "./console.sol";


interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

// ToDo: Confirm this
interface IERC20Tether {
    function approve(address spender, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}


/**
 * Flow:
    * 1. Deploy this contract
    * 2. Transfer all tokens to this contract
    * 3. Call setUpApprovals()
    * 4. buttonswapFactory.isCreationRestrictedSetter calls buttonswapFactory.setIsCreationRestrictedSetter(ADDRESS_THIS);
    * 5. Call deployFirstBatch()
    * 6. Call deploySecondBatch()
    * 7. Call returnPermission()
 */
contract PairLauncher {
    address immutable public owner;
    address immutable public executer;
    ButtonswapRouter immutable public buttonswapRouter;
    ButtonswapFactory immutable public buttonswapFactory;

    constructor(address payable buttonswapRouter_, address ownerAddress_, address executerAddress_) {
        owner = ownerAddress_;
        executer = executerAddress_;
        buttonswapRouter = ButtonswapRouter(buttonswapRouter_);
        buttonswapFactory = ButtonswapFactory(buttonswapRouter.factory());
    }

    address constant rswETH = 0xabE3f6d59fd9Cd70493A10d9bdB89c1D38a3b00C;
    address constant rrETH = 0x5396b0e6314B7dEdfbb23913CB43C9735ECD8099;
    address constant rmevETH = 0x8Be0bE4C411eE0AfcDBf0F84A26C90CE1d54240E;
    address constant rankrETH = 0xa918A6b92d38EeEc8EFcc02B8F78Ef778052FaBb;
    address constant rETHx = 0x94454d17C23a876D6e9cCdA866Ff2b21bD5ac5af;
    address constant rsDAI = 0xd34D24552119bF248D1D1332D9c41b35f605a75a;

    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant eETH = 0x35fA164735182de50811E8e2E824cFb9B6118ac2;

    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    uint256 constant ETH_DEPOSIT = 1e15;
    uint256 constant DAI_DEPOSIT = 1e18;
    uint256 constant USD_DEPOSIT = 1e6;

    function setUpApprovals() public {
        // approve rswETH
        IERC20(rswETH).approve(address(buttonswapRouter), type(uint256).max);
        // approve rrETH
        IERC20(rrETH).approve(address(buttonswapRouter), type(uint256).max);
        // approve rmevETH
        IERC20(rmevETH).approve(address(buttonswapRouter), type(uint256).max);
        // approve rankrETH
        IERC20(rankrETH).approve(address(buttonswapRouter), type(uint256).max);
        // approve rETHx
        IERC20(rETHx).approve(address(buttonswapRouter), type(uint256).max);
        // approve rsDAI
        IERC20(rsDAI).approve(address(buttonswapRouter), type(uint256).max);
        // approve WETH
        IERC20(WETH).approve(address(buttonswapRouter), type(uint256).max);
        // approve eETH
        IERC20(eETH).approve(address(buttonswapRouter), type(uint256).max);
        // approve USDT // Not a regular IERC20
        IERC20Tether(USDT).approve(address(buttonswapRouter), type(uint256).max);
        // approve USDC
        IERC20(USDC).approve(address(buttonswapRouter), type(uint256).max);
        // approve DAI
        IERC20(DAI).approve(address(buttonswapRouter), type(uint256).max);
    }

    function validateSufficientBalances() public view returns (bool){
        if (IERC20(rswETH).balanceOf(address(this)) < ETH_DEPOSIT) {
            return false;
        }
        if (IERC20(rrETH).balanceOf(address(this)) < ETH_DEPOSIT) {
            return false;
        }
        if (IERC20(rmevETH).balanceOf(address(this)) < ETH_DEPOSIT) {
            return false;
        }
        if (IERC20(rankrETH).balanceOf(address(this)) < ETH_DEPOSIT) {
            return false;
        }
        if (IERC20(rETHx).balanceOf(address(this)) < ETH_DEPOSIT) {
            return false;
        }
        if (IERC20(rsDAI).balanceOf(address(this)) < 3 * DAI_DEPOSIT) {
            return false;
        }
        if (IERC20(WETH).balanceOf(address(this)) < 6 * ETH_DEPOSIT) {
            return false;
        }
        if (IERC20(eETH).balanceOf(address(this)) < ETH_DEPOSIT) {
            return false;
        }
        if (IERC20(USDT).balanceOf(address(this)) < USD_DEPOSIT) {
            return false;
        }
        if (IERC20(USDC).balanceOf(address(this)) < USD_DEPOSIT) {
            return false;
        }
        if (IERC20(DAI).balanceOf(address(this)) < DAI_DEPOSIT) {
            return false;
        }
        return true;
    }

    function deployFirstBatch() public {
        // Turn off restricted creation
        buttonswapFactory.setIsCreationRestricted(false);

        // rswETH <-> WETH
        buttonswapRouter.addLiquidity(
            rswETH, WETH, ETH_DEPOSIT, ETH_DEPOSIT, 0, 0, 0, executer, block.timestamp
        );
        // rrETH <-> WETH
        buttonswapRouter.addLiquidity(rrETH, WETH, ETH_DEPOSIT, ETH_DEPOSIT, 0, 0, 0, executer, block.timestamp);
        // rmevETH <-> WETH
        buttonswapRouter.addLiquidity(
            rmevETH, WETH, ETH_DEPOSIT, ETH_DEPOSIT, 0, 0, 0, executer, block.timestamp
        );
        // rankrETH <-> WETH
        buttonswapRouter.addLiquidity(
            rankrETH, WETH, ETH_DEPOSIT, ETH_DEPOSIT, 0, 0, 0, executer, block.timestamp
        );
        // eETH <-> WETH
        buttonswapRouter.addLiquidity(eETH, WETH, ETH_DEPOSIT, ETH_DEPOSIT, 0, 0, 0, executer, block.timestamp);

        // Turn on restricted creation
        buttonswapFactory.setIsCreationRestricted(true);
    }

    function deploySecondBatch() public {
        // Turn off restricted creation
        buttonswapFactory.setIsCreationRestricted(false);

        // rETHx <-> WETH
        buttonswapRouter.addLiquidity(rETHx, WETH, ETH_DEPOSIT, ETH_DEPOSIT, 0, 0, 0, executer, block.timestamp);
        // rsDAI <-> USDT
        buttonswapRouter.addLiquidity(rsDAI, USDT, DAI_DEPOSIT, USD_DEPOSIT, 0, 0, 0, executer, block.timestamp);
        // rsDAI <-> USDC
        buttonswapRouter.addLiquidity(rsDAI, USDC, DAI_DEPOSIT, USD_DEPOSIT, 0, 0, 0, executer, block.timestamp);
        // rsDAI <-> DAI
        buttonswapRouter.addLiquidity(rsDAI, DAI, DAI_DEPOSIT, DAI_DEPOSIT, 0, 0, 0, executer, block.timestamp);

        // Turn on restricted creation
        buttonswapFactory.setIsCreationRestricted(true);
    }

    function returnPermission() public {
        buttonswapFactory.setIsCreationRestrictedSetter(owner);
        selfdestruct(payable(executer));
    }
}
