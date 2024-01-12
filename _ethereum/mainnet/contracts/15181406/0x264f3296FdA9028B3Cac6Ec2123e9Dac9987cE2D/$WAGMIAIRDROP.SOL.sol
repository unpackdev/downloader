// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.14;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./AccessControl.sol";

contract WagmiCoinAirdrop is ReentrancyGuard, AccessControl {
    using SafeERC20 for IERC20;

    
    IERC20 public rewardsToken;

    // Constructor function to set the rewards token and the NFT collection addresses
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    struct AirdropClaim {
        address wallet;
        uint256 amount;
    }

    function setRewardTokenVault(IERC20 _rewardToken) public onlyRole(DEFAULT_ADMIN_ROLE) {
        rewardsToken = _rewardToken;
    }
    
    function sendCoinAirdrop(AirdropClaim[] calldata _claims) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_claims.length > 0, "Airdrop wallet not set");

        unchecked {
            for(uint256 i; i < _claims.length; ++i) {
                AirdropClaim memory claim = _claims[i];
                rewardsToken.safeTransfer(claim.wallet, claim.amount * (1 ether));
            }
        }
    }
}