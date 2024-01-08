// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.2;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IUniswapV2Router01.sol";
import "./INativeVault.sol";

contract EthRewardManager is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public constant crv = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
    address public constant cvx = address(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);

    //uni/sushi router to swap rewards
    address public swapRouter;
    address public nativeVault;

    event Harvest(uint256 crvAmount, uint256 cvxAmount);

    constructor(address _nativeVault, address _swapRouter) {
        swapRouter = _swapRouter;
        nativeVault = _nativeVault;
    }

    function collect() external {
        _swapRewardsIfAny();
    }

    function setSwapRouter(address _newSwapRouter) external onlyOwner {
        swapRouter = _newSwapRouter;
    }

    function setNativeVault(address _newNativeVault) external onlyOwner {
        nativeVault = _newNativeVault;
    }

    function _swapRewardsIfAny() internal {
        uint256 crvBal = IERC20(crv).balanceOf(address(this));
        uint256 cvxBal = IERC20(cvx).balanceOf(address(this));

        if (crvBal > 0) {
            _swapRewardForEth(crv, crvBal);
        }

        if (cvxBal > 0) {
            _swapRewardForEth(cvx, cvxBal);
        }

        INativeVault(nativeVault).collect{value: address(this).balance}();

        Harvest(crvBal, cvxBal);
    }

    function _swapRewardForEth(address _tokenReward, uint256 _amount) internal {
        require(IERC20(_tokenReward).approve(swapRouter, _amount), "approved failed");

        address[] memory path = new address[](2);
        path[0] = _tokenReward;
        path[1] = IUniswapV2Router01(swapRouter).WETH();
        IUniswapV2Router01(swapRouter).swapExactTokensForETH(_amount, 0, path, address(this), block.timestamp + 10);
    }

    receive() external payable {}

}
