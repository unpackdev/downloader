// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IERC721Enumerable.sol";
import "./Ownable.sol";
import "./VRFConsumerHelper.sol";

contract Raffle is VRFConsumerHelper, Ownable {
    IERC721Enumerable public tripster;
    uint256 index;

    event WinnerChosen(address winner, uint256 tokenId, uint256 index);

    function draw() external onlyOwner {
        requestRandomness();
    }

    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        uint256 max = tripster.totalSupply();
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(randomness, block.timestamp, block.difficulty)));
        uint256 chosen = randomNumber % max;
        address owner = tripster.ownerOf(chosen);
        emit WinnerChosen(owner, chosen, index);
        index++;
    }

    function withdrawLINK() external onlyOwner {
        uint256 balance = IERC20(Chainlink.linkToken()).balanceOf(address(this));
        _withdrawLINK(msg.sender, balance);
    }

    function updateTripsters(IERC721Enumerable _tripster) external onlyOwner {
        tripster = _tripster;
    }
}