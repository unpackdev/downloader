// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "./HegicOptionsNFT.sol";
/**
 * @author jmonteer
 * @title Hegic NFT options. Underlying: Any ERC20 token
 * @notice ERC721 that holds Hegic Options on any ERC20 token
 */
contract HegicERC20OptionsNFT is HegicOptionsNFT {
    
    IERC20 public underlyingToken;

    constructor(
        IHegicOptions _optionsProvider,
        IERC20 _underlyingToken,
        string memory _name,
        string memory _symbol
    ) 
        public 
        HegicOptionsNFT(_name, _symbol)
    {
        optionsProvider = _optionsProvider;
        underlyingToken = _underlyingToken;
    }

    /**
     * @notice Pays contract's balance to account
     * @param account Account to receive balance
     */
    function _transferBalance(address account) internal override {
        underlyingToken.safeTransfer(account, underlyingToken.balanceOf(address(this)));
    }

    /**
     * @notice Returns cost in ETH of buying an option with passed params
     * @param _period Option period in seconds (1 days <= period <= 4 weeks)
     * @param _amount Option amount
     * @param _strike Strike price of the option
     * @param _optionType Call or Put option type
     * @return ethCost cost of the option
     */
    function getOptionCostETH(
        uint _period,
        uint _amount,
        uint _strike,
        IHegicOptions.OptionType _optionType
    ) 
        public
        view
        override
        returns (uint ethCost)
    {
        (, ethCost, , ,) = IHegicERC20Options(address(optionsProvider)).fees(_period, _amount, _strike, _optionType);
    }
}