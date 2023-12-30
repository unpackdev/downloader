pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

contract IERC20 {
    function allowance(address owner, address spender) public view returns(uint256);
}

contract ApprovedHelper {

    struct ApprovedItem {
        address owner;
        address spender;
        address tokenAddr;
    }

    function getApprovedData(ApprovedItem[] memory items) public view returns(uint256[] memory){

        uint256[] memory amounts = new uint256[](items.length);
        
        for (uint256 i = 0; i < items.length; i++) {
            ApprovedItem memory item = items[i];
            uint256 amount;
            amount = IERC20(item.tokenAddr).allowance(item.owner, item.spender);
            amounts[i] = amount;
        }

        return amounts;
    }
    
}