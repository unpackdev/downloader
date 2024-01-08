// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./ERC20.sol";
import "./OwnableUpgradeable.sol";
import "./SafeERC20.sol";

import "./DecimalsConverter.sol";

import "./IContractsRegistry.sol";
import "./IReinsurancePool.sol";
import "./IBMIStaking.sol";

import "./AbstractDependant.sol";

contract ReinsurancePool is IReinsurancePool, OwnableUpgradeable, AbstractDependant {
    using SafeERC20 for ERC20;

    IERC20 public bmiToken;
    ERC20 public stblToken;
    IBMIStaking public bmiStaking;
    address public claimVotingAddress;

    uint256 public stblDecimals;

    event Recovered(address tokenAddress, uint256 tokenAmount);
    event STBLWithdrawn(address user, uint256 amount);

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
        stblToken = ERC20(_contractsRegistry.getUSDTContract());
        bmiStaking = IBMIStaking(_contractsRegistry.getBMIStakingContract());
        claimVotingAddress = _contractsRegistry.getClaimVotingContract();

        stblDecimals = stblToken.decimals();
    }

    function withdrawBMITo(address to, uint256 amount) external override onlyClaimVoting {
        bmiToken.transfer(to, amount);
    }

    function withdrawSTBLTo(address to, uint256 amount) external override onlyClaimVoting {
        stblToken.safeTransfer(to, DecimalsConverter.convertFrom18(amount, stblDecimals));

        emit STBLWithdrawn(to, amount);
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);

        emit Recovered(tokenAddress, tokenAmount);
    }
}
