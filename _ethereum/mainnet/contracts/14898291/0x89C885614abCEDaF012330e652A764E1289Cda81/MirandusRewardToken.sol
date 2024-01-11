// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Ownable.sol";
import "./IERC1155.sol";
import "./ERC1155Holder.sol";
import "./RewardTable.sol";
import "./IRandomRewardTable.sol";

contract MirandusRewardToken is RewardTable, IRandomRewardTable {

    event onRewardTransfered(address beneficiary, uint256 tokenId, uint amount);

    constructor (address _erc1155Contract) RewardTable(_erc1155Contract) {        
    }

    function rewardRandomOne(address _to, uint256 _rand) external override {             

        require(rewarder == msg.sender, "RewardTable: caller is not the rewarder");
        require(ids.length > 0, "RewardTable: No rewards available");        
        uint256 randomIndex = _rand % totalSupply;        

        for (uint256 i = 0; i < ids.length; i += 1) 
        {
            uint256 randomId = ids[i];
            uint256 idBalance = IERC1155(erc1155Contract).balanceOf(address(this), randomId);            

            if (randomIndex < idBalance) 
            {
                IERC1155(erc1155Contract).safeTransferFrom(address(this), _to, randomId, 1, '');
                totalSupply--;                
                emit onRewardTransfered(_to, randomId, 1);
                break;
            }

            randomIndex -= idBalance;
        } 

    }
}
