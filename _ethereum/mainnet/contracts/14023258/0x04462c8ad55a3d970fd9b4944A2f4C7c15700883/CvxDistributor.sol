// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "./SafeERC20.sol";

interface ICvxStaking {
    function distribute() external;
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

    function gelato() external view returns (address payable);
}

contract CvxDistributor {
    using SafeERC20 for IERC20;

    address public constant GELATO =
        address(0x3CACa7b48D0573D793d3b0279b5F0029180E83b6);
    address public constant WETH =
        address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public constant CVXCRV =
        address(0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7);
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    ICvxStaking public constant cvxStaking =
        ICvxStaking(0xE096ccEc4a1D36F191189Fe61E803d8B2044DFC3);
    IRouter public constant sushiRouter =
        IRouter(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    IPokeMe public constant pokeMe =
        IPokeMe(0xB3f5503f93d5Ef84b06993a1975B9D21B962892F);

    constructor() {
        IERC20(CVXCRV).approve(address(sushiRouter), 2**256 - 1);
    }

    receive() external payable {}

    function distribute() external {
        require(msg.sender == address(pokeMe), "Only PokeMe");

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

        (fee, ) = pokeMe.getFeeDetails();

        _transfer(fee, ETH, GELATO);
        _transfer(address(this).balance, ETH, tx.origin);
    }

    function _transfer(
        uint256 _amount,
        address _paymentToken,
        address _to
    ) internal {
        if (_paymentToken == ETH) {
            (bool success, ) = _to.call{value: _amount}("");
            require(success, "_transfer: ETH transfer failed");
        } else {
            SafeERC20.safeTransfer(IERC20(_paymentToken), GELATO, _amount);
        }
    }

    function claimTokens(uint256 _amount, address _token) external {
        _transfer(_amount, _token, GELATO);
    }
}
