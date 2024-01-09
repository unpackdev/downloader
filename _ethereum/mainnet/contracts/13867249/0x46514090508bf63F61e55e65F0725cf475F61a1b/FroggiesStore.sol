// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Context.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract FroggiesStore is Context, Ownable, Pausable {

    // Where funds should be sent to
    address payable public payoutAddress;

    constructor(address payable _payoutAddress) {
        payoutAddress = _payoutAddress;
    }

    // Player functions
    event Purchase(address indexed sender, uint256 amount, string nonce);

    function purchase(string memory nonce) payable external whenNotPaused {
        emit Purchase(_msgSender(), msg.value, nonce);
    }

    // Admin functions
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function updatePayoutAddress(address payable newPayoutAddress) external onlyOwner {
        payoutAddress = newPayoutAddress;
    }

    function claimBalance() external onlyOwner {
        (bool success, ) = payoutAddress.call{value: address(this).balance}("");
        require(success, "transfer failed");
    }
}
