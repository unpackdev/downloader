// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Ownable.sol";
import "./EthereumClockToken.sol";

contract Redeem is Ownable {
    EthereumClockToken public ethClockToken;
    /// Redeem lock time
    uint256 public redeemLockTime;

    /// Redeem Allowed Flag
    bool public _REDEEM_ALLOWED_;

    constructor(address tokenContract) {
        ethClockToken = EthereumClockToken(tokenContract);
        redeemLockTime = 90 * 24 * 60 * 60;//90 days;
        _REDEEM_ALLOWED_ = false;
    }

    // ============ System Control Functions ============

    function enableRedeem() external onlyOwner {
        _REDEEM_ALLOWED_ = true;
    }

    function disableRedeem() external onlyOwner {
        _REDEEM_ALLOWED_ = false;
    }

    function setLockTime(uint256 lockTime) external onlyOwner {
        redeemLockTime = lockTime;
    }

    function isRedeemable(uint256 tokenId) public view returns (bool) {
        uint256 timeStamp = ethClockToken.startTimestamps(tokenId);
        if (timeStamp + redeemLockTime > _getNow()) {
            return false;
        }
        if (ethClockToken.charred(tokenId)) {
            return false;
        }
        return true;
    }

    /**
     * @notice REDEEM Request
     */
    function redeem(uint256 tokenId) external returns (bool) {
        require(_REDEEM_ALLOWED_, "REDEEM NOT ALLOWED");
        require(isRedeemable(tokenId), "TOKEN IS NOT AVAILABLE TO REDEEM");
        require(msg.sender == ethClockToken.ownerOf(tokenId), "TOKEN HOLDER CAN ONLY DO REDEEM");

        ethClockToken.redeem(tokenId);
        return true;
    }

    function _getNow() internal view virtual returns (uint256) {
        return block.timestamp;
    }
}
