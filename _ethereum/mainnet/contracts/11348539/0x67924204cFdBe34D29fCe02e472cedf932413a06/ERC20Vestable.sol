// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
import "./RoleAware.sol";
import "./ERC20.sol";

abstract contract ERC20Vestable is RoleAware, ERC20 {

    // tokens vest 10% every 10 days. `claimFunds` can be called once every 10 days
    uint256 public claimFrequency = 10 days;
    mapping(address => uint256) public _vestingAllowances;
    mapping(address => uint256) public _claimAmounts;
    mapping(address => uint256) public _lastClaimed;

    function _grantFunds(address beneficiary) internal {
        require(
            _vestingAllowances[beneficiary] > 0 &&
                _vestingAllowances[beneficiary] >= _claimAmounts[beneficiary],
            "Entire allowance already claimed, or no initial aloowance"
        );
        _vestingAllowances[beneficiary] = _vestingAllowances[beneficiary].sub(
            _claimAmounts[beneficiary]
        );
        _mint(
            beneficiary,
            _claimAmounts[beneficiary].mul(10**uint256(decimals()))
        );
    }

    // internal function only ever called from constructor
    function _addBeneficiary(address beneficiary, uint256 amount)
        internal
        onlyBeforeUniswap
    {
        _vestingAllowances[beneficiary] = amount;
        _claimAmounts[beneficiary] = amount.div(10);
        _lastClaimed[beneficiary] = now;
        // beneficiary gets 10% of funds immediately
        _grantFunds(beneficiary);
    }

    function claimFunds() public {
        require(
            _lastClaimed[msg.sender] != 0 &&
                now >= _lastClaimed[msg.sender].add(claimFrequency),
            "Allowance cannot be claimed more than once every 10 days"
        );
        _lastClaimed[msg.sender] = now;
        _grantFunds(msg.sender);
    }
}
