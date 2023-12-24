// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./AccessControl.sol";
import "./Ownable.sol";

interface IBadBoysWeb3 {
    function airdrop(uint amount, address recipient) external;
}

contract BadBoysMinter is AccessControl, Ownable {
    IBadBoysWeb3 public badBoysContract;
    uint256 public manualMintPrice;
    bytes32 public constant CROSSMINT_ROLE = keccak256("CROSSMINT_ROLE");
    address public teamWallet = 0x49Aff98582160d0f7830A9459A59abf2Dcff91BA;


    constructor(address _badBoysContractAddress) {
        badBoysContract = IBadBoysWeb3(_badBoysContractAddress);
        manualMintPrice = 55000000000000000; // Initial manual mint price
    }

    function setManualMintPrice(uint256 _price) public onlyOwner {
        manualMintPrice = _price;
    }

    function Buy2Get1(uint amount, address recipient) external payable {
        require(amount > 0, "Amount must be greater than 0");
        uint totalMintAmount;
        if (amount >= 10) {
            totalMintAmount = amount + 5;
        } else if (amount >= 8) {
            totalMintAmount = amount + 4;
        } else if (amount >= 6) {
            totalMintAmount = amount + 3;
        } else if (amount >= 4) {
            totalMintAmount = amount + 2;
        } else if (amount >= 2) {
            totalMintAmount = amount + 1;
        } else {
            totalMintAmount = amount;
        }

    // Only check for payment if the sender does not have the CROSSMINT_ROLE
    if (!hasRole(CROSSMINT_ROLE, msg.sender)) {
        require(msg.value >= manualMintPrice * amount, "Insufficient ETH for minting");
    }

    badBoysContract.airdrop(totalMintAmount, recipient);
    }

    function grantCrossmintRole(address crossmintAddress) public onlyOwner {
        grantRole(CROSSMINT_ROLE, crossmintAddress);
    }

    function withdrawETH() external onlyOwner {
        require(teamWallet != address(0), "Team wallet not set");
        (bool sent, ) = payable(teamWallet).call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }
}
