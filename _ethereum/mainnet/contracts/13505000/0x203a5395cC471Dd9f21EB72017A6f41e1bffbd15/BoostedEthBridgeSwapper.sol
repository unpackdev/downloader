//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

import "./ZkSyncBridgeSwapper.sol";
import "./ILido.sol";
import "./ICurvePool.sol";
import "./IYearnVault.sol";

/**
* @notice Exchanges Eth for the "Yearn vault Curve pool staked Eth" token.
* Indexes:
* 0: Eth
* 1: yvCrvStEth
*/
contract BoostedEthBridgeSwapper is ZkSyncBridgeSwapper {

    address public immutable stEth;
    address public immutable crvStEth;
    address public immutable yvCrvStEth;

    ICurvePool public immutable stEthPool;
    address public immutable lidoReferral;
    address[2] public tokens;

    constructor(
        address _zkSync,
        address _l2Account,
        address _yvCrvStEth,
        address _stEthPool,
        address _lidoReferral
    )
        ZkSyncBridgeSwapper(_zkSync, _l2Account)
    {
        require(_yvCrvStEth != address(0), "null _yvCrvStEth");
        yvCrvStEth = _yvCrvStEth;
        address _crvStEth = IYearnVault(_yvCrvStEth).token();
        require(_crvStEth != address(0), "null crvStEth");

        require(_stEthPool != address(0), "null _stEthPool");

        require(_crvStEth == ICurvePool(_stEthPool).lp_token(), "crvStEth mismatch");
        crvStEth = _crvStEth;
        stEth = ICurvePool(_stEthPool).coins(1);
        stEthPool = ICurvePool(_stEthPool);
        lidoReferral = _lidoReferral;
        tokens = [ETH_TOKEN, _yvCrvStEth];
    }

    function exchange(uint256 _indexIn, uint256 _indexOut, uint256 _amountIn) external override returns (uint256 amountOut) {
        require(_indexIn + _indexOut == 1, "invalid indexes");

        if (_indexIn == 0) {
            transferFromZkSync(ETH_TOKEN);
            amountOut = swapEthForYvCrv(_amountIn);
            transferToZkSync(yvCrvStEth, amountOut);
            emit Swapped(ETH_TOKEN, _amountIn, yvCrvStEth, amountOut);
        } else {
            transferFromZkSync(yvCrvStEth);
            amountOut = swapYvCrvForEth(_amountIn);
            transferToZkSync(ETH_TOKEN, amountOut);
            emit Swapped(yvCrvStEth, _amountIn, ETH_TOKEN, amountOut);
        }
    }

    function swapEthForYvCrv(uint256 _amountIn) public payable returns (uint256) {
        // ETH -> crvStETH
        uint256 minLpAmount = getMinAmountOut((1 ether * _amountIn) / stEthPool.get_virtual_price());
        uint256 crvStEthAmount = stEthPool.add_liquidity{value: _amountIn}([_amountIn, 0], minLpAmount);

        // crvStETH -> yvCrvStETH
        IERC20(crvStEth).approve(yvCrvStEth, crvStEthAmount);
        return IYearnVault(yvCrvStEth).deposit(crvStEthAmount);
    }

    function swapYvCrvForEth(uint256 _amountIn) public returns (uint256) {
        // yvCrvStETH -> crvStETH
        uint256 crvStEthAmount = IYearnVault(yvCrvStEth).withdraw(_amountIn);

        // crvStETH -> ETH
        uint256 minAmountOut = getMinAmountOut((crvStEthAmount * stEthPool.get_virtual_price()) / 1 ether);
        return stEthPool.remove_liquidity_one_coin(crvStEthAmount, 0, minAmountOut);
    }

    function ethPerYvCrvStEth() public view returns (uint256) {
        return IYearnVault(yvCrvStEth).pricePerShare() * stEthPool.get_virtual_price() / 1 ether;
    }

    function yvCrvStEthPerEth() public view returns (uint256) {
        return (1 ether ** 2) / ethPerYvCrvStEth();
    }
}
