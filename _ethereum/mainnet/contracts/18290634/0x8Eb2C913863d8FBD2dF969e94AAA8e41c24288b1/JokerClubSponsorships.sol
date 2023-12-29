// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IJokerClub.sol";
import "./Ownable.sol";
import "./EnumerableMap.sol";
import "./Address.sol";

/// @title JokerClub Sponsorships
contract JokerClubSponsorships is Ownable {
    using Address for address payable;

    event RewardsCollected(address indexed recipient, address indexed sponsor, uint256 quantity);
    event RewardsWithdrawn(address indexed sponsor, uint256 weiAmount);

    // counter of sponsorhips per sponsor
    mapping (address => uint256) public sponsorshipsCounters;

    IJokerClub immutable jokerClub;

    uint256 public constant SPONSORING_FEE = 0.0064 ether;

    error InvalidRecipientAddress();
    error InvalidSponsorAddress();

    constructor(address owner, IJokerClub _jokerClub) {
        _transferOwnership(owner);
        jokerClub = _jokerClub;
    }

    function mint(uint256 quantity, address recipient, address sponsor) external payable {
        if (recipient == address(0)) revert InvalidRecipientAddress();
        if (sponsor == address(0)) revert InvalidSponsorAddress();

        // check if sponsor owns some JokerClub!
        if (jokerClub.balanceOf(sponsor) > 0) {
            sponsorshipsCounters[sponsor] += quantity;
            // 8% of 0.08 ETH
            emit RewardsCollected(recipient, sponsor, quantity);
        }

        // mint the NFT
        jokerClub.mint{value: msg.value}(quantity, new bytes32[](0), recipient);
    }

    /// Redeem for a specific sponsor
    /// @dev anyone can do such an operation
    function redeem(address payable sponsor) external {
        uint256 sponsorshipsCount = sponsorshipsCounters[sponsor];
        if (sponsorshipsCount > 0) {
            sponsorshipsCounters[sponsor] = 0;
            // transfer debt to sponsor
            uint256 debt = sponsorshipsCount * SPONSORING_FEE;
            payable(sponsor).sendValue(debt);
            emit RewardsWithdrawn(sponsor, debt);
        }
    }

    /// Mass redeem
    function massRedeem(address[] calldata sponsors) external {
        for (uint i = 0; i < sponsors.length; i++) {
            address sponsor = sponsors[i];
            uint256 sponsorshipsCount = sponsorshipsCounters[sponsor];
            if (sponsorshipsCount > 0) {
                sponsorshipsCounters[sponsor] = 0;
                // transfer debt to sponsor
                uint256 debt = sponsorshipsCount * SPONSORING_FEE;
                payable(sponsor).sendValue(debt);
                emit RewardsWithdrawn(sponsor, debt);
            }
        }
    }

    /// Withdrawal from owner
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).sendValue(balance);
    }

    receive() external payable {}
}
