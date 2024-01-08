// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./ERC20Upgradeable.sol";

import "./IContractsRegistry.sol";
import "./IClaimVoting.sol";

import "./IVBMI.sol";

import "./AbstractDependant.sol";

contract VBMI is IVBMI, ERC20Upgradeable, AbstractDependant {
    IERC20Upgradeable public stkBMIToken;
    IClaimVoting public claimVoting;
    address public reinsurancePoolAddress;

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

    function lockStkBMI(uint256 amount) external override {
        require(amount > 0, "VBMI: can't lock 0 tokens");

        stkBMIToken.transferFrom(_msgSender(), address(this), amount);
        _mint(_msgSender(), amount);

        emit Locked(_msgSender(), amount);
    }

    function unlockStkBMI(uint256 amount) external override {
        require(
            claimVoting.canWithdraw(_msgSender()),
            "VBMI: Can't withdrow, there are pending votes"
        );

        _burn(_msgSender(), amount);
        stkBMIToken.transfer(_msgSender(), amount);

        emit Unlocked(_msgSender(), amount);
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
