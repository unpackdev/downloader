// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "./SafeERC20.sol";

interface IRouter {
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IOps {
    function getFeeDetails() external view returns (uint256, address);
}

contract ContractPoker {
    using SafeERC20 for IERC20;

    address public constant GELATO =
        address(0x3CACa7b48D0573D793d3b0279b5F0029180E83b6);

    address public constant WETH =
        address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    address public constant ETH =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    address public constant RECEIVER =
        address(0xAabB54394E8dd61Dd70897E9c80be8de7C64A895);

    IRouter public constant SUSHI_ROUTER =
        IRouter(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

    IRouter public constant UNI_ROUTER =
        IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    IOps public constant GELATO_OPS =
        IOps(0xB3f5503f93d5Ef84b06993a1975B9D21B962892F);

    receive() external payable {}

    function poke(
        address _target,
        bytes memory _data,
        address _rewardToken,
        uint256 _profitMargin,
        bool _swapAll,
        bool _useSushi
    ) external {
        require(msg.sender == address(GELATO_OPS), "Only Gelato Ops");

        uint256 preBalance = IERC20(_rewardToken).balanceOf(address(this));

        (bool success, ) = _target.call(_data);
        require(success, "ContractPoker: Low level call failed :(");

        uint256 postBalance = IERC20(_rewardToken).balanceOf(address(this));

        uint256 rewardInRewardToken = postBalance - preBalance;

        // assumes token has a uni or sushi route
        address[] memory path = new address[](2);
        path[0] = _rewardToken;
        path[1] = WETH;

        (uint256 fee, ) = GELATO_OPS.getFeeDetails();

        IRouter router = _useSushi ? SUSHI_ROUTER : UNI_ROUTER;

        if (_swapAll) {
            uint256[] memory amounts = router.swapExactTokensForETH(
                rewardInRewardToken,
                0,
                path,
                address(this),
                block.timestamp
            );

            require(
                amounts[amounts.length - 1] >= (fee * _profitMargin) / 100,
                "ContractPoker: swapAll not profitable"
            );
        } else {
            router.swapTokensForExactETH(
                fee * _profitMargin / 100,
                rewardInRewardToken,
                path,
                address(this),
                block.timestamp
            );
        }

        _transfer(fee, ETH, GELATO);
    }

    function claimTokens(uint256 _amount, address _token) external {
        _transfer(_amount, _token, RECEIVER);
    }

    function maxApprove(address _token, bool _useSushi) external {
        IERC20(_token).approve(
            _useSushi ? address(SUSHI_ROUTER) : address(UNI_ROUTER),
            type(uint256).max
        );
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
            SafeERC20.safeTransfer(IERC20(_paymentToken), _to, _amount);
        }
    }
}
