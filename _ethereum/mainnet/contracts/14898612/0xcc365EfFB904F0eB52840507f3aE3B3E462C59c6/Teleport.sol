// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./PortToken.sol";

abstract contract TELEPORTFOUNDERSCLUB {
    function ownerOf(uint256 tokenId) public view virtual returns (address);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        returns (uint256);

    function balanceOf(address owner)
        external
        view
        virtual
        returns (uint256 balance);
}

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";

contract Teleport is Ownable {
    // PORT Token & TFC Contracts
    PortToken portToken;
    TELEPORTFOUNDERSCLUB private teleportfoundersclub;

    // token price for ETH
    uint256 public tokensPerEth = 200000;
    uint256 public tokensPerEthTFC = 220000;
    uint256 public tokensPerEthWhitelist = 250000;
    bool public purchasingEnabled = true;
    mapping(address => bool) public whitelist;

    // Event that log buy operation
    event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
    event TransferSent(address _destAddr, uint256 _amount);

    constructor(address tokenAddress, address _tfcContractAddress) {
        portToken = PortToken(tokenAddress);
        teleportfoundersclub = TELEPORTFOUNDERSCLUB(_tfcContractAddress);
    }

    function setTokensPerEth(uint256 newTokensPerEth) external onlyOwner {
        tokensPerEth = newTokensPerEth;
    }

    function setTokensPerEthTFC(uint256 newTokensPerEth) external onlyOwner {
        tokensPerEthTFC = newTokensPerEth;
    }

    function setTokensPerEthWhitelist(uint256 newTokensPerEth)
        external
        onlyOwner
    {
        tokensPerEthWhitelist = newTokensPerEth;
    }

    function togglePurchasing() external onlyOwner {
        purchasingEnabled = !purchasingEnabled;
    }

    function setWhitelist(address[] calldata newAddresses) external onlyOwner {
        for (uint256 i = 0; i < newAddresses.length; i++)
            whitelist[newAddresses[i]] = true;
    }

    function removeWhitelist(address[] calldata currentAddresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < currentAddresses.length; i++)
            delete whitelist[currentAddresses[i]];
    }

    /**
     * @notice Allow users to buy token with ETH
     */
    function buyTokens() public payable returns (uint256 tokenAmount) {
        require(msg.value > 0, "Send ETH to buy some tokens");

        uint256 amountToBuy;
        uint256 checkbalanceTFC = teleportfoundersclub.balanceOf(msg.sender);

        if (whitelist[_msgSender()]) {
            amountToBuy = msg.value * tokensPerEthWhitelist;
        } else if (checkbalanceTFC > 0) {
            amountToBuy = msg.value * tokensPerEthTFC;
        } else {
            amountToBuy = msg.value * tokensPerEth;
        }

        if (_msgSender() != owner()) {
            require(purchasingEnabled, "Purchasing has not been enabled");
        }

        // check if the Vendor Contract has enough amount of tokens for the transaction
        uint256 vendorBalance = portToken.balanceOf(address(this));
        require(
            vendorBalance >= amountToBuy,
            "Vendor contract has not enough tokens in its balance"
        );

        // Transfer token to the msg.sender
        bool sent = portToken.transfer(msg.sender, amountToBuy);
        require(sent, "Failed to transfer token to user");

        // emit the event
        emit BuyTokens(msg.sender, msg.value, amountToBuy);

        return amountToBuy;
    }

    /**
     * @notice Allow the owner of the contract to withdraw ETH
     */
    function withdraw() public onlyOwner {
        uint256 ownerBalance = address(this).balance;
        require(ownerBalance > 0, "Owner has not balance to withdraw");

        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Failed to send user balance back to the owner");
    }

    function withdrawPORT() public onlyOwner {
        uint256 amountToWithdraw = portToken.balanceOf(address(this));
        require(amountToWithdraw > 0, "balance is low");

        bool sent = portToken.transfer(msg.sender, amountToWithdraw);
        require(sent, "Failed to send user PORT balance back to the owner");
    }
}
