// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Ownable.sol";
import "./IERC1155.sol";
import "./ERC1155Holder.sol";
import "./RewardTable.sol";
import "./IEachRewardTable.sol";

contract EachRewardTable is RewardTable, IEachRewardTable {

    constructor (address _erc1155Contract) RewardTable(_erc1155Contract) {
        
    }

    function rewardEach(address _to) external override {
        require(rewarder == msg.sender, "RewardTable: caller is not the rewarder");
        require(ids.length > 0, "RewardTable: No rewards available");

        uint256[] memory amounts = new uint256[](ids.length);

        for (uint256 i = 0; i < ids.length; i++) {
            amounts[i] = 1;
        }

        IERC1155(erc1155Contract).safeBatchTransferFrom(address(this), _to, ids, amounts, '');

        totalSupply -= ids.length;
    }
}
