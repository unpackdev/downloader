// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "./HegicOptionsNFT.sol";
/**
 * @author jmonteer
 * @title Hegic NFT options. Underlying: ETH
 * @notice ERC721 that holds Hegic Options with ETH as underlying asset
 */
contract HegicETHOptionsNFT is HegicOptionsNFT {
    receive() external payable {}

    constructor(
        IHegicOptions _optionsProvider
    ) 
        public 
        HegicOptionsNFT("HegicOptionsETH", "hoETH")
    {
        optionsProvider = _optionsProvider;
    }

    /**
     * @notice Pays contract's balance to account
     * @param account Account to receive balance
     */
    function _transferBalance(address account) internal override {
        payable(account).transfer(address(this).balance);
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
        (ethCost, , , ) = IHegicETHOptions(address(optionsProvider)).fees(_period, _amount, _strike, _optionType);
    }
}