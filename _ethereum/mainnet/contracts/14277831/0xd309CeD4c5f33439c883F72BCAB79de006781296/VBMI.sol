// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./ERC20PermitUpgradeable.sol";

import "./IContractsRegistry.sol";
import "./IClaimVoting.sol";

import "./IVBMI.sol";

import "./AbstractDependant.sol";

contract VBMI is IVBMI, ERC20PermitUpgradeable, AbstractDependant {
    IERC20Upgradeable public stkBMIToken;
    IClaimVoting public claimVoting;
    address public reinsurancePoolAddress;
    address public bmiStakingAddress;

    event UserSlashed(address user, uint256 amount);
    event Locked(address user, uint256 amount);
    event Unlocked(address user, uint256 amount);

    modifier onlyClaimVoting() {
        require(_msgSender() == address(claimVoting), "VBMI: Not a ClaimVoting contract");
        _;
    }

    function __VBMI_init() external initializer {
        __ERC20_init("BMI Voting Token", "vBMI");
    }

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        stkBMIToken = IERC20Upgradeable(_contractsRegistry.getSTKBMIContract());
        claimVoting = IClaimVoting(_contractsRegistry.getClaimVotingContract());
        reinsurancePoolAddress = _contractsRegistry.getReinsurancePoolContract();
    }


    function setMigratablevBMI() public {
        IContractsRegistry _contractsRegistry = IContractsRegistry(
            0x8050c5a46FC224E3BCfa5D7B7cBacB1e4010118d
        );
        bmiStakingAddress = _contractsRegistry.getBMIStakingContract();
    }

    function lockStkBMI(uint256 amount) external override {
        require(amount > 0, "VBMI: can't lock 0 tokens");

        stkBMIToken.transferFrom(_msgSender(), address(this), amount);
        _mint(_msgSender(), amount);

        emit Locked(_msgSender(), amount);
    }

    function unlockStkBMI(uint256 amount) external override {
        require(
            claimVoting.canWithdraw(_msgSender()),
            "VBMI: Can't withdraw, there are pending votes"
        );
        _unlockStkBMI(_msgSender(), amount);
    }

    function ejectUsersBMI(address _user, uint256 _amount) external override {
        require(_msgSender() == bmiStakingAddress, "vBMI: not bmiStaking");

        if (claimVoting.canWithdraw(_user)) {
            _unlockStkBMI(_user, _amount);
        }
    }

    function _unlockStkBMI(address _user, uint256 _amount) internal {
        _burn(_user, _amount);
        stkBMIToken.transfer(_user, _amount);

        emit Unlocked(_user, _amount);
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
