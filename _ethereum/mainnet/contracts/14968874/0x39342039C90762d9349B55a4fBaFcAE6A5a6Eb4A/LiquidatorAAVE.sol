// SPDX-License-Identifier: UNLICENSED
// Specifies the version of Solidity, using semantic versioning.
// Learn more: https://solidity.readthedocs.io/en/v0.5.10/layout-of-source-files.html#pragma

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// Import ABI of:
//
// 1. Euler Contract
// 2. UniswapContract
// 3. AaveContract

import "./IERC20.sol";
import "./FlashLoanReceiverBase.sol";
import "./ILendingPool.sol";
import "./ILendingPoolAddressesProvider.sol";

interface ISwapRouterV2 {
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

contract LiquidateUsingAAVEWorker is FlashLoanReceiverBase {
    // Mainnet: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    address private immutable uniswapRouterAddr;
    // Mainnet: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    address private immutable WETH_ADDRESS;
    // Mainnet: 0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5
    // address private immutable addressProvider;
    address private retrieverAddress =
        0x6347637d45fFa7187387660A97949e5d6D63420C;

    struct LiqOpp {
        address liquidatee;
        address collateralToken;
        address debtToken;
        bool useEthPath;
        uint256 amountToRepay;
        address liquidatorAddress;
    }

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address, /* initiator */
        bytes calldata params
    ) external override returns (bool) {
        LiqOpp memory liqOpp = abi.decode(params, (LiqOpp));

        require(amounts[0] == liqOpp.amountToRepay, "A/Amount-mismatch");

        // liquidateAndSwapIfNeededAndTransferFunds(liqOpp, addressProvider);

        IERC20(assets[0]).approve(address(LENDING_POOL), amounts[0]);
        liquidateAndSwapIfNeededAndTransferFunds(liqOpp, premiums[0]);

        approveWithdrawal(assets, premiums, amounts);

        return true;
    }

    function approveWithdrawal(
        address[] calldata assets,
        uint256[] calldata premiums,
        uint256[] calldata amounts
    ) internal {
        // Approve the Lending pool to take back the flash loan + premium.
        for (uint256 i = 0; i < assets.length; i++) {
            IERC20(assets[i]).approve(
                address(LENDING_POOL),
                amounts[i].add(premiums[i])
            );
        }
    }

    function abiHelper(LiqOpp memory liqOpp)
        public
        pure
        returns (LiqOpp memory)
    {
        // This function is there so that we can see LiqOpp in the abi for encoding purposes
        return liqOpp;
    }

    function retrieveFunds(address asset, uint256 amount) public returns (bool){
        require(msg.sender == retrieverAddress, "A/can't-retrieve");
        return IERC20(asset).transfer(retrieverAddress, amount);
    }

    function liquidateAndSwapIfNeededAndTransferFunds(
        LiqOpp memory liqOpp,
        uint256 premium
    ) internal {
        // address lendingPoolAddr = ILendingPoolAddressesProvider(
        //     addressProviderAddr
        // ).getLendingPool();

        ILendingPool(LENDING_POOL).liquidationCall(
            liqOpp.collateralToken, // collateral
            liqOpp.debtToken, // debt
            liqOpp.liquidatee, // user
            liqOpp.amountToRepay, // amountdebtToCover
            false // receiveAToken
        );

        uint256 collateralReceived = IERC20(liqOpp.collateralToken).balanceOf(
            address(this)
        );

        if (liqOpp.debtToken != liqOpp.collateralToken) {
            uint256 pulledAmountIn = swapV2(liqOpp, type(uint256).max, premium);
            IERC20(liqOpp.collateralToken).transfer(
                liqOpp.liquidatorAddress,
                collateralReceived - pulledAmountIn
            );
        } else {
            require(
                collateralReceived > liqOpp.amountToRepay + premium,
                "A/not-profitable"
            );
            IERC20(liqOpp.collateralToken).transfer(
                liqOpp.liquidatorAddress,
                collateralReceived - liqOpp.amountToRepay - premium
            );
        }
    }

    function swapV2(
        LiqOpp memory liqOpp,
        uint256 amountInMax,
        uint256 premium
    ) internal returns (uint256) {
        address[] memory path;

        if (liqOpp.useEthPath) {
            path = new address[](3);
            path[0] = liqOpp.collateralToken;
            path[1] = WETH_ADDRESS;
            path[2] = liqOpp.debtToken;
        } else {
            path = new address[](2);
            path[0] = liqOpp.collateralToken;
            path[1] = liqOpp.debtToken;
        }

        uint256[] memory amounts = ISwapRouterV2(uniswapRouterAddr)
            .swapTokensForExactTokens(
                liqOpp.amountToRepay + premium,
                amountInMax, // can also set this to type(uint256).max, maxAmountToSwap,
                path,
                address(this),
                block.timestamp
            );

        return amounts[0];
    }

    // function _swapV3() {
    //      uint256 pulledAmountIn = ISwapRouter(uniswapRouterAddr).exactOutput(
    //             ISwapRouter.ExactOutputParams({
    //                 path: liqOpp.swapPath,
    //                 recipient: address(this),
    //                 deadline: block.timestamp,
    //                 amountOut: amounts[0],
    //                 amountInMaximum: type(uint256).max
    //             })
    //         );
    // }

    constructor(
        address _addressProvider,
        address _uniswapRouterAddr,
        address _WETH_ADDRESS
    )
        public
        FlashLoanReceiverBase(ILendingPoolAddressesProvider(_addressProvider))
    {
        // addressProvider = _addressProvider;
        uniswapRouterAddr = _uniswapRouterAddr;
        /* TODO: Can we get the WETH address by calling Uniswap or AddressProvider in the constructor? */
        /* Answer: Yes: https://docs.uniswap.org/protocol/V2/reference/smart-contracts/router-02#weth */
        WETH_ADDRESS = _WETH_ADDRESS;
    }
}
