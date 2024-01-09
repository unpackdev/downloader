// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Ownable.sol";

contract FAMRoyaltyWallet is Ownable {
    uint256 private constant FAM_PART = 25; // %

    address payable public famWallet;

    event Received(address, uint256);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function setFamWallet(address payable fam) external onlyOwner {
        famWallet = fam;
    }

    function withdraw() external onlyOwner {
        require(famWallet != address(0), "FAM address not set");

        // Send 25% of funds to FAM
        (bool famSuccess, ) = famWallet.call{
            value: (address(this).balance * FAM_PART) / 100
        }("");
        require(famSuccess, "Failed to send Ether to FAM");

        // Send the rest to owner
        (bool ownerSuccess, ) = payable(owner()).call{
            value: address(this).balance
        }("");
        require(ownerSuccess, "Failed to send Ether to owner");
    }
}
