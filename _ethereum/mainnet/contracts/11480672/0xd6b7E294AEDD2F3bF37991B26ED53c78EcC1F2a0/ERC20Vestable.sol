// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
import "./RoleAware.sol";
import "./ERC20.sol";

abstract contract ERC20Vestable is RoleAware, ERC20 {
    uint256 public vestingTime = 4 days;
    bool public canAddVesters = true;
    function setVestingTime(uint256 newTime) public onlyDeveloper {
        vestingTime = newTime;
    }

    // tokens vest 10% every n days. `claimFunds` can be called once every n days
    struct VestingAllowance {
        uint256 frequency;
        uint256 allowance;
        uint256 claimAmount;
        uint256 lastClaimed;
    }

    mapping(address => VestingAllowance) public vestingAllowances;

    function _grantFunds(address beneficiary) internal {
        
        VestingAllowance memory userAllowance = vestingAllowances[beneficiary];
        require(
            userAllowance.allowance > 0 &&
                userAllowance.allowance >= userAllowance.claimAmount,
            "Entire allowance already claimed, or no initial allowance"
        );
        userAllowance.allowance = userAllowance.allowance.sub(userAllowance.claimAmount);
        vestingAllowances[beneficiary] = userAllowance;
        _mint(beneficiary, userAllowance.claimAmount.mul(10**uint256(decimals())));
    }

    // internal function only ever called from constructor
    function _addBeneficiary(
        address beneficiary,
        uint256 amount,
        uint256 claimFrequency,
        bool grant
    ) internal {
        vestingAllowances[beneficiary] = VestingAllowance(
            claimFrequency,
            amount,
            amount.div(10),
            now
        );
        // beneficiary gets 10% of funds immediately
        if (grant) {
            _grantFunds(beneficiary);
        }
    }

    function claimFunds() public {
        VestingAllowance memory allowance = vestingAllowances[msg.sender];
        require(
            allowance.lastClaimed != 0 &&
                (now >= allowance.lastClaimed.add(allowance.frequency) || now >= allowance.lastClaimed.add(vestingTime)),
            "Allowance already claimed for this time period"
        );
        allowance.lastClaimed = now;
        vestingAllowances[msg.sender] = allowance;
        _grantFunds(msg.sender);
    }


    // function callable before uinswap listing to allow v1 holders to be compensated
    function addV1Beneficiary(address[] memory addresses, uint256[] memory amounts, uint256[] memory period)
        public
        onlyDeveloper
    {
        require(canAddVesters == true);
        for (uint256 index = 0; index < addresses.length; index++) {
            _addBeneficiary(addresses[index], amounts[index], period[index], false);
        }
    }

    function renounceVesting() public onlyDeveloper {
        canAddVesters = false;
    }
}
