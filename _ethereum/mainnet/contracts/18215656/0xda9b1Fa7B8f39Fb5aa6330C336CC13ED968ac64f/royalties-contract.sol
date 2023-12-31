// SPDX-License-Identifier: MIT
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
pragma solidity ^0.8.4;

contract EmpropsRoyalties is ReentrancyGuard, Ownable {
    event Received(address, uint);

    struct FundReceiver {
        address addr;
        uint16 rate;
    }
    uint256 public totalFundsCollected = 0;
    mapping(address => uint256) public receiversRegistry;
    mapping(address => uint256) public royaltiesClaimedRegistry;

    constructor(FundReceiver[] memory receivers) {
        _setRoyaltiesReceivers(receivers);
    }

    function _setRoyaltiesReceivers(
        FundReceiver[] memory newReceivers
    ) internal {
        uint256 collector = 0;
        for (uint256 i = 0; i < newReceivers.length; i++) {
            FundReceiver memory receiver = newReceivers[i];
            collector += receiver.rate;
            receiversRegistry[receiver.addr] = receiver.rate;
        }

        // Make sure total rates are equal to 10_000
        require(collector == 10000, "Royalties sum must be 10000");
    }

    receive() external payable {
        totalFundsCollected += msg.value;
        emit Received(msg.sender, msg.value);
    }

    function claimRoyalties() public nonReentrant {
        uint256 rate = receiversRegistry[msg.sender];
        require(rate != 0, "Sender is not royalty receiver");

        // Check if sender has any pending royalties
        uint256 claimed = royaltiesClaimedRegistry[msg.sender];
        uint256 maxClaimable = (totalFundsCollected * rate) / 10000;
        require(claimed < maxClaimable, "No royalties to claim");

        // Calculate how much to ether corresponds to sender
        uint256 amount = maxClaimable - claimed;
        // Update amount claimed by sender
        royaltiesClaimedRegistry[msg.sender] += amount;
        // Send ether to sender
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
    }
}
