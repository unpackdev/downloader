// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface ISplitWithdrawable {
    function withdraw() external;
    function withdrawTokens(address tokenContract) external;
    function withdrawNFT(address tokenContract, uint256[] memory id) external;
    function updateWithdrawalRecipient(address recipient) external;
    
}
