// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ISyndicate {

    error TransferDisabled();
    error InvalidSignature();
    error AlreadyTransferredInTimeframe();
    error BelowMinimumAmount(uint256 amount, uint256 allowed);
    error MaximumAmountExceeded(uint256 amount, uint256 allowed);

    event SyndicateAdminAdded(address indexed wallet);
    event SyndicateAdminRemoved(address indexed wallet);
    event UsdcContractChanged(address indexed usdcAddress);
    event SignerAddressChanged(address indexed wallet);
    event DestinationWalletChanged(address indexed wallet);
    event TimeframeChanged(uint256 indexed transferStart, uint256 indexed transferEnd);
    event Transfer(address indexed from, uint256 indexed amount);

    function isTransferEnabled() external view returns(bool);
    function isSyndicateAdmin(address wallet) external view returns(bool);
    function alreadyTransferredForTimeframe(address wallet) external view returns(bool);
    function addSyndicateAdmin(address wallet) external;
    function removeSyndicateAdmin(address wallet) external;
    function setUsdcContract(address usdcAddress) external;
    function setDestinationWallet(address wallet) external;
    function setTransferTimeframe(uint256 _transferStart, uint256 _transferEnd) external;
    function setSigner(address wallet) external;
    function transfer(uint256 amount, uint256 minTransfer, uint256 maxTransfer, uint256 timestamp, bytes calldata signature) external;

}