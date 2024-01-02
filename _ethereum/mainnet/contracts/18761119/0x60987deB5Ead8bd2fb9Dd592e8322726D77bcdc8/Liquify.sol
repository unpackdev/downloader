// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.23;

struct Vault {
    uint128 collateral;
    uint128 debt;
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface ILiquidation {
    function price(address user) external view returns (uint256);
    function vaults(address user) external view returns (Vault calldata);
    //function liquidate(address user) external;

    function buy(
        address from,
        address to,
        address liquidated,
        uint256 daiAmount
    ) external returns (uint256);
}

interface IPair {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
}

contract Liquify {
    ILiquidation liq = ILiquidation(0x357B7E1Bd44f5e48b988a61eE38Bfe9a76983E33);
    IERC20 dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address treasury = 0xFa21DE6f225c25b8F13264f1bFF5e1e44a37F96E;
    IPair pair = IPair(0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11);
    address owner;

    constructor() {
        owner = msg.sender;
    }

    function luvubae(uint req, uint minOut, address[] calldata tars) public {
        require(msg.sender == owner, "not owner");

        bytes memory data = abi.encode(tars);
        pair.swap(req, 0, address(this), data);

        require(weth.balanceOf(address(this)) >= minOut, "not enough");
        pls(weth);
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external {
        amount1;
        require(msg.sender == address(pair), "not pair");
        require(sender == address(this), "not sender");

        address[] memory tars = abi.decode(data, (address[]));

        for (uint i = 0; i< tars.length; i++) {
            address t = tars[i];
            uint price = liq.price(t);
            uint daiAmount = liq.vaults(t).collateral * price / 10**27;
            dai.approve(treasury, daiAmount);
            liq.buy(address(this), address(this), t, daiAmount);
        }

        (uint reserveOut, uint reserveIn,) = pair.getReserves();
        
        uint numerator = reserveIn * amount0 * 1000;
        uint denominator = (reserveOut - amount0) * 997;
        uint amountIn = (numerator / denominator) + 1;
        weth.transfer(address(pair), amountIn);
    }

    function pls(IERC20 token) public {
        token.transfer(owner, token.balanceOf(address(this)));
    }
}