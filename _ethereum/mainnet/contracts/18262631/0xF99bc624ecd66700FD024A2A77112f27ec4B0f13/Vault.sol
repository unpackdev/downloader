// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "./Owned.sol";
import "./SafeTransferLib.sol";
import "./ERC20.sol";
import "./WETH.sol";
import "./ERC4626.sol";
import "./IUniswapV2Router.sol";

contract Vault is ERC4626, Owned {
    using SafeTransferLib for ERC20;
    ERC20 public underlying;
    WETH public weth;
    IUniswapV2Router uniswapV2Router;
    mapping(address => uint256) public shares;

    constructor(
        ERC20 _underlying,
        address uniV2Router
    )
        ERC4626(
            _underlying,
            string(abi.encodePacked("Enshrined ", _underlying.name())),
            string(abi.encodePacked("s", _underlying.symbol()))
        )
        Owned(msg.sender)
    {
        underlying = _underlying;
        uniswapV2Router = IUniswapV2Router(uniV2Router);

        weth = WETH(payable(uniswapV2Router.WETH()));

        weth.approve(uniV2Router, type(uint256).max);
    }

    function harvestVault() public onlyOwner {
        uint256 wethBalance = weth.balanceOf(address(this));
        swapForUnderlying(wethBalance);
    }

    function swapForUnderlying(uint256 amount) internal {
        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(underlying);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function totalAssets() public view virtual override returns (uint256) {
        return underlying.balanceOf(address(this));
    }
}
