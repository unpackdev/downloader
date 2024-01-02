// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./console.sol";

interface IAutoMinterERC20 {
    function mint(address to) external payable;
}

// Contract for the purchase of in-app autominter credits
contract AutoMinterCreditSales is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    uint public pricePerToken;
    uint public constant discountRate = 20; // 20%
    address public proPassNFTAddress;
    address public amrTokenAddress;
    mapping(address => uint) public purchaseLog;

    function initialize(address _proPassNFTAddress, address _amrTokenAddress) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        proPassNFTAddress = _proPassNFTAddress;
        amrTokenAddress = _amrTokenAddress;
        pricePerToken = 50000000000000; // 0.00005 ETH in wei
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function setPricePerToken(uint newPrice) public onlyOwner {
        pricePerToken = newPrice;
    }

    function getPriceQuote(uint numberOfTokens) public view returns (uint) {
        bool isProPassHolder = false;

        try IERC721Upgradeable(proPassNFTAddress).balanceOf(msg.sender) returns (uint256 balance) {
            console.log("balance: ", balance);
            isProPassHolder = balance > 0;
        } catch {
            // If the call to the ERC721 contract fails, isProPassHolder remains false
        }

        uint totalPrice = numberOfTokens * pricePerToken;
        if (isProPassHolder) {
            return totalPrice * (100 - discountRate) / 100;
        }
        return totalPrice;
    }

    function purchaseTokens(uint numberOfTokens, bool earnAMRTokens) public payable {
        uint quotedPrice = getPriceQuote(numberOfTokens);
        require(msg.value >= quotedPrice, "Insufficient funds sent");

        purchaseLog[msg.sender] += numberOfTokens;

        if (earnAMRTokens) {
            console.log("Earn AMR tokens attempt");
            console.log("msg.value: ", msg.value);
            console.log("msg.sender: ", msg.sender);
            uint halfPayment = msg.value / 2;
            IAutoMinterERC20(amrTokenAddress).mint{value: halfPayment}(msg.sender);
        }

        // Handle remaining logic, including sending back excess funds if overpaid
    }

    // Function to withdraw ETH from the contract
    function withdraw(uint256 amount) public onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance in contract");
        payable(owner()).transfer(amount);
    }
}
