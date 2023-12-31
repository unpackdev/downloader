// SPDX-License-Identifier: MIT

// This contract holds the FriendSniper tokens migrated from the Base chain, and distributes them to users on ETH mainnet.
// Users must have used the Migration contract to recieve tokens from this contract.
// A full list of eligible users is available on the website.

// If users do not claim within 14 days, tokens may be burnt without notice.

// Website: https://friendsniper.tech
// Telegram: https://t.me/FrenSnipe
// Twitter: https://twitter.com/FriendSniperTch
// Email: frensniper@proton.me

pragma solidity >=0.8.10 >=0.8.0 <0.9.0;

import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./Context.sol";

contract FriendSniperMigrationRepository is Ownable {
    using SafeERC20 for IERC20;

    mapping(address => bool) public hasBeenMigrated;
    uint256 startTime;
    IERC20 public fSniper;
    uint256 totalMigratedTokens;

    constructor(address _newToken) {
        fSniper = IERC20(_newToken);
        startTime = block.timestamp;
    }

    event MigratedTokens(address[] user, uint256[] amounts);

    receive() external payable {}

    function MigrateForUsersBatch(
        address[] memory users,
        uint256[] memory amounts
    ) public onlyOwner {
        require(block.timestamp < startTime + 14 days, "Migration has ended");

        require(
            users.length == amounts.length,
            "Users and amounts arrays should must have the same length"
        );

        for (uint256 i = 0; i < users.length; ) {
            if (hasBeenMigrated[users[i]]) continue;
            fSniper.safeTransfer(users[i], amounts[i]);
            hasBeenMigrated[users[i]] = true;
            unchecked {
                ++i;
            }
        }
        emit MigratedTokens(users, amounts);
    }

    function RecoverToken(address _token, uint256 _amount) external onlyOwner {
        require(_token != address(0), "Invalid address");
        require(_amount > 0, "Invalid amount");
        require(block.timestamp > startTime + 30 days, "Too early to recover");
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    // If un claimed tokens remain after 14 days, they may be burned.
    function burnNonClaimed(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Invalid amount");
        require(block.timestamp > startTime + 14 days, "Too early to withdraw");
        fSniper.transfer(address(0xdead), _amount);
    }
}
