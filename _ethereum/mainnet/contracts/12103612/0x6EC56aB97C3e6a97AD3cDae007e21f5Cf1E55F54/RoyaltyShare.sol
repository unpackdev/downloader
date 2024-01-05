// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

import "./Ownable.sol";
import "./IERC1155.sol";
import "./ERC1155Holder.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./SafeMath.sol";

contract RoyaltyShare is Ownable, ERC1155Holder, ReentrancyGuard {
    using Address for address payable;
    using SafeMath for uint256;

    uint256 constant public MEMBER_COUNT = 10;

    uint256 public totalWithdrawn = 0;

    uint256[MEMBER_COUNT] public amountWithdrawn;
    address[MEMBER_COUNT] public members;

    constructor(address[MEMBER_COUNT] memory _members) {
        for (uint256 i = 0; i < MEMBER_COUNT; i++) {
            members[i] = _members[i];
        }
    }

    /// Member functions

    function withdraw(uint256 index) nonReentrant external {
        require(members[index] == msg.sender, "Sender not authorized");

        // (TotalWithdrawn + CurrentBalance) / MEMBER_COUNT => Each member's current total rewards
        uint256 totalMemberRoyalties = totalWithdrawn.add(address(this).balance).div(MEMBER_COUNT);

        // Current disbursement is total reward minus amount already claimecd
        uint256 royalty = totalMemberRoyalties.sub(amountWithdrawn[index]);

        // Increment the amount withdrawn for msg.sender
        amountWithdrawn[index] = amountWithdrawn[index].add(royalty);

        totalWithdrawn = totalWithdrawn.add(royalty);

        msg.sender.sendValue(royalty);
    }

    function update(uint256 index, address newOwner) external {
        require(members[index] == msg.sender, "Sender not authorized");
        members[index] = newOwner;
    }

    /// Helpful getters

    // Returns available royalties for a particular index
    function availableRoyalties(uint256 index) external view returns (uint256 royalty) {
        uint256 totalRewards = totalWithdrawn.add(address(this).balance).div(MEMBER_COUNT);
        royalty = totalRewards.sub(amountWithdrawn[index]);
    }

    function getIndex(address sender) external view returns (uint256) {
        for (uint i = 0; i < MEMBER_COUNT; i++) {
            if (sender == members[i]) {
                return i;
            }
        }
        revert('Address not found');
    }

    /// Admin

    // Contract owner can transfer any held 1155 tokens (eg for sale)
    function transfer(address tokenContract, uint256 tokenId, address newOwner) onlyOwner external {
        IERC1155(tokenContract).safeTransferFrom(address(this), newOwner, tokenId, 1, "");
    }

    // Enable royalty payments
    receive() external payable {}
}
