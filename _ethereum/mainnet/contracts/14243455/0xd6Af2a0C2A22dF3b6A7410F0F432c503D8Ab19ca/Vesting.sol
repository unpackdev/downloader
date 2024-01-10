// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";

/**
 * @title Vesting
 * @dev This contract handles the vesting of Eth and ERC20 tokens for the owner.
 */
contract Vesting is Ownable, ReentrancyGuard {
    uint256 public vestingDuration = 3650 days;
    uint256 public deploymentTimestamp;
    mapping(address => uint256) public lastWithdraws;

    /**
     * @dev Set the deployment datetime
     */
    constructor() {
        deploymentTimestamp = block.timestamp;
    }

    /**
     * @dev The contract should be able to receive Eth.
     */

    receive() external payable virtual {}

    /**
     * @dev Test is a token is vested or not
     */
    function isVested(address tokenAddress) public view returns (bool) {
        uint256 lastWithdraw;
        if (lastWithdraws[tokenAddress] == 0) {
            lastWithdraw = deploymentTimestamp;
        } else {
            lastWithdraw = lastWithdraws[tokenAddress];
        }
        return lastWithdraw + vestingDuration < block.timestamp;
    }

    /**
     * @dev Withdraw half of the tokens if vested and reset the vesting schedule
     */
    function withdraw(address tokenAddress) public nonReentrant {
        require(isVested(tokenAddress), "VESTING: not yet vested");
        lastWithdraws[tokenAddress] = block.timestamp;
        if (tokenAddress == address(0)) {
            Address.sendValue(payable(owner()), address(this).balance / 2);
        } else {
            IERC20(tokenAddress).transfer(
                owner(),
                IERC20(tokenAddress).balanceOf(address(this)) / 2
            );
        }
    }
}
