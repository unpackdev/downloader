// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "./PokeMeReady.sol";
import "./SafeERC20.sol";

interface ICvxStaking {
    function distribute() external;

    function callIncentive() external view returns (uint256);
}

interface IRouter {
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IPokeMe {
    function getFeeDetails() external view returns (uint256, address);
}

contract CvxDistributor is PokeMeReady {
    using SafeERC20 for IERC20;

    address public immutable WETH =
        address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public immutable CVXCRV =
        address(0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7);
    ICvxStaking public immutable cvxStaking =
        ICvxStaking(0xE096ccEc4a1D36F191189Fe61E803d8B2044DFC3);
    IRouter public immutable sushiRouter =
        IRouter(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

    constructor()
        PokeMeReady(address(0xB3f5503f93d5Ef84b06993a1975B9D21B962892F))
    {
        IERC20(CVXCRV).approve(address(sushiRouter), 2**256 - 1);
    }

    function distribute() external onlyPokeMe {
        require(
            IERC20(CVXCRV).balanceOf(address(cvxStaking)) > 0,
            "CvxDistributor: Nothing to distribute"
        );

        address[] memory path = new address[](2);
        path[0] = CVXCRV;
        path[1] = WETH;

        cvxStaking.distribute();

        uint256 cvxCrvBalance = IERC20(CVXCRV).balanceOf(address(this));

        uint256[] memory amounts = sushiRouter.getAmountsOut(
            cvxCrvBalance,
            path
        );
        uint256 amountOutMin = (amounts[amounts.length - 1] * 95) / 100;

        sushiRouter.swapExactTokensForETH(
            cvxCrvBalance,
            amountOutMin,
            path,
            address(this),
            block.timestamp
        );

        uint256 fee;
        address feeToken;
        (fee, feeToken) = IPokeMe(pokeMe).getFeeDetails();

        _transfer(fee, feeToken);
    }

    function claimTokens(uint256 _amount, address _token) external {
        IERC20(_token).safeTransfer(gelato, _amount);
    }
}
