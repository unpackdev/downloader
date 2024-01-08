// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./OwnableUpgradeable.sol";

import "./IContractsRegistry.sol";
import "./IReinsurancePool.sol";
import "./IBMIStaking.sol";

import "./AbstractDependant.sol";

contract ReinsurancePool is IReinsurancePool, OwnableUpgradeable, AbstractDependant {
    IERC20 public bmiToken;
    IERC20 public daiToken;
    IBMIStaking public bmiStaking;
    address public claimVotingAddress;

    event Recovered(address tokenAddress, uint256 tokenAmount);
    event DAIWithdrawn(address user, uint256 amount);

    modifier onlyClaimVoting() {
        require(
            claimVotingAddress == _msgSender(),
            "ReinsurancePool: Caller is not a ClaimVoting contract"
        );
        _;
    }

    function __ReinsurancePool_init() external initializer {
        __Ownable_init();
    }

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        bmiToken = IERC20(_contractsRegistry.getBMIContract());
        daiToken = IERC20(_contractsRegistry.getDAIContract());
        bmiStaking = IBMIStaking(_contractsRegistry.getBMIStakingContract());
        claimVotingAddress = _contractsRegistry.getClaimVotingContract();
    }

    function withdrawBMITo(address to, uint256 amount) external override onlyClaimVoting {
        bmiToken.transfer(to, amount);
    }

    function withdrawDAITo(address to, uint256 amount) external override onlyClaimVoting {
        daiToken.transfer(to, amount);

        emit DAIWithdrawn(to, amount);
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);

        emit Recovered(tokenAddress, tokenAmount);
    }
}
