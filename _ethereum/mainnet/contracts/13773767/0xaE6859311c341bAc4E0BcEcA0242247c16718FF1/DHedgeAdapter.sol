//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.2;

import "./SafeERC20.sol";
import "./AbstractAdapter.sol";

interface IDHedge {
    function getFundComposition() external view returns(bytes32[] memory, uint256[] memory, uint256[] memory);
    function getAssetProxy(bytes32 key) external view returns(address);
    function withdraw(uint256 _fundTokenAmount) external;
    function deposit(uint256 _susdAmount) external returns (uint256);
    function totalSupply() external view returns (uint256);
    function totalFundValue() external view returns (uint256);
}

/// @title DHedge Vampire Attack Contract
/// @author Enso.finance (github.com/EnsoFinance)
/// @notice Adapter for redeeming the underlying assets from Dhedge Protocol

contract DHedgeAdapter is AbstractAdapter {
    using SafeERC20 for IERC20;

    address public immutable SUSD;

    constructor(address owner_, address susd_) AbstractAdapter(owner_) {
        SUSD = susd_;
    }

    function outputTokens(address _lp)
        public
        view
        override
        returns (address[] memory)
    {
        (bytes32[] memory assets, , ) = IDHedge(_lp).getFundComposition();
        address[] memory outputs = new address[](assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
            outputs[i] = IDHedge(_lp).getAssetProxy(assets[i]);
        }
        return outputs;
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
        calls = new Call[](1);
        calls[0] = Call(
            payable(_lp),
            abi.encodeWithSelector(
                IDHedge(_lp).withdraw.selector,
                _amount
            )
        );
    }

    /*
    function buy(address _lp, address _exchange, uint256 _minAmountOut, uint256 _deadline)
        public
        override
        payable
        onlyWhitelisted(_lp)
    {
        // WARNING: Cannot transfer due to dHedge's cooldown period
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = SUSD;
        IUniswapV2Router(_exchange).swapExactETHForTokens{value: msg.value}(
            1,
            path,
            address(this),
            _deadline
        );
        uint256 susdAmount = IERC20(SUSD).balanceOf(address(this));
        IERC20(SUSD).approve(_lp, susdAmount);
        IDHedge(_lp).deposit(susdAmount);
        uint256 lpAmount = IERC20(_lp).balanceOf(address(this));
        require(lpAmount >= _minAmountOut, "Insufficient LP tokens");
        IERC20(_lp).transfer(msg.sender, lpAmount);
    }
    */

    /*
    function getAmountOut(
        address _lp,
        address _exchange,
        uint256 _amountIn
    ) external override view onlyWhitelisted(_lp) returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = SUSD;
        uint256 susdAmount = IUniswapV2Router(_exchange).getAmountsOut(_amountIn, path)[1];
        uint256 totalSupply = IDHedge(_lp).totalSupply();
        if (totalSupply > 0) {
            uint256 fundValue = IDHedge(_lp).totalFundValue();
            return susdAmount * totalSupply / fundValue;
        } else {
            return susdAmount;
        }
    }
    */
}
