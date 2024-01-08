//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.2;

import "./AbstractAdapter.sol";

interface IPieDaoPool {
    function getTokens() external view returns (address[] memory);
    function exitPool(uint256 _amount) external;
}

contract PieDaoAdapter is AbstractAdapter {
    constructor(address owner_) AbstractAdapter(owner_) {}

    function outputTokens(address _lp)
        public
        view
        override
        returns (address[] memory outputs)
    {
        return IPieDaoPool(_lp).getTokens();
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
                IPieDaoPool(_lp).exitPool.selector,
                _amount
            )
        );
    }
}
