// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./ERC20Upgradeable.sol";
import "./LnAssetUpgradeable.sol";

contract LnRollback {
    address public owner;
    bool public isContractActive;

    struct WalletAmounts {
        uint256 expectedAmount;
        address wallet;
    }

    constructor() public {
        owner = msg.sender;
        isContractActive = true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier whenActive() {
        require(isContractActive, "Contract is not active");
        _;
    }

    function deactivateContract() public onlyOwner {
        isContractActive = false;
    }

    function cleanWallets(LnAssetUpgradeable assetContractAddress, address[] calldata wallets) public onlyOwner whenActive
    {
        LnAssetUpgradeable assetContract = LnAssetUpgradeable(assetContractAddress);
        for (uint256 i = 0; i < wallets.length; i++) 
        {
            uint256 balance = assetContract.balanceOf(wallets[i]);
            assetContract.burn(wallets[i], balance);
        }
    }

    function performBatch(LnAssetUpgradeable assetContractAddress, address[] calldata  wallets, uint256[] calldata amounts) public onlyOwner whenActive
    {
        LnAssetUpgradeable assetContract = LnAssetUpgradeable(assetContractAddress);
        require(wallets.length == amounts.length, "parameter address length not eq");
        for (uint256 i = 0; i < wallets.length; i++) 
        {
            assetContract.mint(wallets[i], amounts[i]);
        }
    }
}