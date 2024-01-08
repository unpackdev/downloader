//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.2;

import "./SafeERC20.sol";
import "./AbstractAdapter.sol";

interface IBalancerPool {
    function getCurrentTokens() external view returns (address[] memory tokens);
    function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) external;
}

/// @title Balancer(Indexed + Powerpool) Vampire Attack Contract
/// @author Enso.finance (github.com/EnsoFinance)
/// @notice Adapter for redeeming the underlying assets from Indexed Protocol

contract BalancerAdapter is AbstractAdapter {
    using SafeERC20 for IERC20;

    constructor(address owner_) AbstractAdapter(owner_) {}

    function outputTokens(address _lp)
        public
        view
        override
        returns (address[] memory)
    {
        return IBalancerPool(_lp).getCurrentTokens();
    }

    function encodeMigration(address _genericRouter, address _strategy, address _lp, uint256 _amount)
        public
        override
        view
        onlyWhitelisted(_lp)
        returns (Call[] memory calls)
    {
        address[] memory tokens = outputTokens(_lp);
        calls = new Call[](tokens.length + 1);
        calls[0] = encodeWithdraw(_lp, _amount)[0];
        for (uint256 i = 0; i < tokens.length; i++) {
            calls[i + 1] = Call(
                _genericRouter,
                abi.encodeWithSelector(
                    IGenericRouter(_genericRouter).settleTransfer.selector,
                    tokens[i],
                    _strategy
                )
            );
        }
        return calls;
    }

    function encodeWithdraw(address _lp, uint256 _amount)
        public
        override
        view
        onlyWhitelisted(_lp)
        returns (Call[] memory calls)
    {
        uint256[] memory _min = new uint256[](outputTokens(_lp).length);
        calls = new Call[](1);
        calls[0] = Call(
            payable(_lp),
            abi.encodeWithSelector(
                IBalancerPool(_lp).exitPool.selector,
                _amount,
                _min
            )
        );
    }
}
