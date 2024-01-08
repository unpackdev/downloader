// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./console.sol";

interface ICurvePool {
    function add_liquidity(uint[2] memory amounts, uint amountOutMin) external;
    function get_virtual_price() external view returns (uint);
}

interface ICurveVault {
    function lpToken() external view returns (address);
    function investZap(uint amount) external;
}

interface IRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface IWETH is IERC20 {
    function withdraw(uint amount) external;
}

contract CurveHBTCZap is Ownable {
    using SafeERC20 for IERC20;
    using SafeERC20 for IWETH;

    IRouter constant router = IRouter(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    ICurvePool constant curvePool = ICurvePool(0x4CA9b3063Ec5866A4B82E437059D2C43d1be596F);
    address public immutable vault;
    IERC20 public immutable lpToken;

    IWETH constant WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 constant CRV = IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
    IERC20 constant CVX = IERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    IERC20 constant WBTC = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);

    event Compound(uint CRVAmt, uint CVXAmt, uint WETHAmt, uint lpTokenBal);
    event AddLiquidity(uint WBTCAmt, uint lpTokenBal);

    constructor(address _vault) {
        vault = _vault;
        address _lpToken = ICurveVault(_vault).lpToken();
        lpToken = IERC20(_lpToken);
        IERC20(_lpToken).safeApprove(address(_vault), type(uint).max);

        WETH.safeApprove(address(router), type(uint).max);
        CRV.safeApprove(address(router), type(uint).max);
        CVX.safeApprove(address(router), type(uint).max);
        WBTC.safeApprove(address(curvePool), type(uint).max);
    }

    function compound(uint CRVAmt, uint CVXAmt, uint yieldFeePerc) external returns (uint lpTokenBal, uint fee) {
        require(msg.sender == vault, "Only authorized vault");

        uint CRVInWETH = swap(address(CRV), address(WETH), CRVAmt);
        uint CVXInWETH = swap(address(CVX), address(WETH), CVXAmt);
        uint totalWETH = CRVInWETH + CVXInWETH;

        fee = totalWETH * yieldFeePerc / 10000;
        WETH.withdraw(fee);
        (bool status,) = vault.call{value: fee}("");
        require(status, "Fee transfer failed");
        totalWETH = totalWETH - fee;
        
        lpTokenBal = addLiquidity(totalWETH);
        ICurveVault(msg.sender).investZap(lpTokenBal);
        emit Compound(CRVAmt, CVXAmt, totalWETH, lpTokenBal);
    }

    receive() external payable {}

    function addLiquidity(uint amount) private returns (uint lpTokenBal) {
        uint WBTCAmt = swap(address(WETH), address(WBTC), amount);
        uint[2] memory amounts = [0, WBTCAmt];
        curvePool.add_liquidity(amounts, 0);
        lpTokenBal = lpToken.balanceOf(address(this));
        emit AddLiquidity(WBTCAmt, lpTokenBal);
    }

    function swap(address tokenIn, address tokenOut, uint amount) private returns (uint) {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        return (router.swapExactTokensForTokens(amount, 0, path, address(this), block.timestamp))[1];
    }

    function getVirtualPrice() external view returns (uint) {
        return curvePool.get_virtual_price();
    }
}