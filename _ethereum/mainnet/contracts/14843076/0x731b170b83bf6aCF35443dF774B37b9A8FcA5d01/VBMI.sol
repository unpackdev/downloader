// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./ERC20PermitUpgradeable.sol";

import "./IContractsRegistry.sol";
import "./IClaimVoting.sol";

import "./IVBMI.sol";
import "./IStkBMIStaking.sol";

import "./AbstractDependant.sol";

contract VBMI is IVBMI, ERC20PermitUpgradeable, AbstractDependant {
    IERC20Upgradeable public stkBMIToken;
    IClaimVoting public claimVoting;
    address public reinsurancePoolAddress;
    IStkBMIStaking public stkBMIStaking;

    event UserSlashed(address user, uint256 amount);
    event Locked(address user, uint256 amount);
    event Unlocked(address user, uint256 amount);

    modifier onlyClaimVoting() {
        require(_msgSender() == address(claimVoting), "VBMI: Not a ClaimVoting contract");
        _;
    }

    function __VBMI_init() external initializer {
        __ERC20Permit_init("BMI V2 Voting Token");
        __ERC20_init("BMI V2 Voting Token", "vBMIV2");
    }

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        stkBMIToken = IERC20Upgradeable(_contractsRegistry.getSTKBMIContract());
        claimVoting = IClaimVoting(_contractsRegistry.getClaimVotingContract());
        reinsurancePoolAddress = _contractsRegistry.getReinsurancePoolContract();
        stkBMIStaking = IStkBMIStaking(_contractsRegistry.getStkBMIStakingContract());
    }

    function unlockStkBMIFor(address user) external override {
        require(_msgSender() == 0x28234C11ea2665c25D60523d80659b123130da80);

        uint256 userAmount = balanceOf(user);

        stkBMIToken.transfer(address(stkBMIStaking), userAmount);

        stkBMIStaking.lockStkBMIFor(user, userAmount);

        emit Unlocked(user, userAmount);
    }

    function recoverSTKBMI() external {
        require(_msgSender() == 0x28234C11ea2665c25D60523d80659b123130da80);

        uint256 _balance = stkBMIToken.balanceOf(address(this));

        stkBMIToken.transfer(address(stkBMIStaking), _balance);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal pure override {
        revert("VBMI: Currently transfer is blocked");
    }

    function slashUserTokens(address user, uint256 amount) external override onlyClaimVoting {
        _burn(user, amount);
        stkBMIToken.transfer(reinsurancePoolAddress, amount);

        emit UserSlashed(user, amount);
    }
}
