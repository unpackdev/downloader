// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "./ERC20.sol";
import "./Ownable.sol";

import "./DevFund.sol";

contract HolderToken is Ownable, ERC20 {
    /// --- External contracts

    // fund contract
    DevFund public devFund;

    constructor(
        address _devFund,
        address _newOwner,
        address[] memory _awardees,
        uint256[] memory _amounts,
        string memory name,
        string memory symbol
    ) Ownable() ERC20(name, symbol) {

        require(
            _awardees.length == _amounts.length,
            "HolderToken: deploy issue"
        );

        // initial awards
        for (uint256 i = 0; i < _awardees.length; i++) {
            _mint(_awardees[i], _amounts[i]);
        }

        devFund = DevFund(_devFund);

        transferOwnership(_newOwner);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override onlyOwner returns (bool) {
        devFund.softWithdrawRewardFor(sender);
        devFund.softWithdrawRewardFor(recipient);
        _transfer(sender, recipient, amount);
        return true;
    }

    function transfer(address, uint256)
    public
    pure
    override
    returns (bool)
    {
        revert("HolderToken: non transferable");
    }

    function increaseAllowance(address, uint256)
    public
    pure
    override
    returns (bool)
    {
        revert("HolderToken: non transferable");
    }

    function decreaseAllowance(address, uint256)
    public
    pure
    override
    returns (bool)
    {
        revert("HolderToken: non transferable");
    }

    function approve(address, uint256)
    public
    pure
    override
    returns (bool)
    {
        revert("HolderToken: non transferable");
    }
}
