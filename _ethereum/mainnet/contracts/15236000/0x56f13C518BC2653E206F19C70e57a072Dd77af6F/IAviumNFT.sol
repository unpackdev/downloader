// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAviumNFT {
    
    function setRecipientAddress(address _recipientAddress) external;

    function getRecipientAddress() external returns(address);

    function getCurrentIndex() external view returns (uint256);

    function getTotalMint() external view returns (uint256);

    function mint(
        address to,
        uint256 quantity,
        bytes calldata _data
    ) external;

    function owner() external returns (address);

    
}
