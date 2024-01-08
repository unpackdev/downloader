// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "./OwnableUpgradeable.sol";

import "./ERC20PermitUpgradeable.sol";

import "./IContractsRegistry.sol";
import "./ISTKBMIToken.sol";

import "./AbstractDependant.sol";

contract STKBMIToken is ISTKBMIToken, ERC20PermitUpgradeable, AbstractDependant {
    address public stakingContract;

    modifier onlyBMIStaking() {
        require(
            stakingContract == _msgSender(),
            "STKBMIToken: Caller is not the BMIStaking contract"
        );
        _;
    }

    function __STKBMIToken_init() external initializer {
        __ERC20_init("Staking BMI", "stkBMI");
    }

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        stakingContract = _contractsRegistry.getBMIStakingContract();
    }

    function mint(address account, uint256 amount) public override onlyBMIStaking {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public override onlyBMIStaking {
        _burn(account, amount);
    }
}
