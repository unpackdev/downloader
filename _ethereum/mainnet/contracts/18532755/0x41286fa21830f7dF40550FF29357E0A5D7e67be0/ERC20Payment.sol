// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./IERC20Permit.sol";
import "./ERC20Recoverable.sol";

contract ERC20Payment is Ownable, ERC20Recoverable{

    event PaymentMade(address user, uint256 package, uint256 quantity, uint256 cost);
    event BatchPaymentMade(address user, uint256[] packages, uint256[] quantities, uint256 cost);

    bool public saleOpen;
    address public payeeWallet;
    IERC20Permit public payoutToken;

    mapping(uint256 => uint256) public unitPrices;

    constructor(address _payoutToken, address _payeeWallet){
        payoutToken = IERC20Permit(_payoutToken);
        payeeWallet = _payeeWallet;
    }

    function pay(address user, uint256 package, uint256 quantity, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external{
        require(saleOpen, "Sale not yet opened");
        uint256 price = unitPrices[package];
        require(price > 0 && quantity > 0, "Invalid purchase");
        
        uint256 cost = price * quantity;

        payoutToken.permit(user, address(this), cost, deadline, v, r, s);
        payoutToken.transferFrom(user, payeeWallet, cost);

        emit PaymentMade(user, package, quantity, cost);
    }

    function payBatch(address user, uint256[] memory packages, uint256[] memory quantities, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external{
        require(saleOpen, "Sale not yet opened");
        require(packages.length == quantities.length, "Invalid configs");

        uint256 cost = 0;

        for(uint256 i; i != packages.length; i++){
            uint256 price = unitPrices[packages[i]];
            uint256 quantity = quantities[i];
            require(price > 0 && quantity > 0, "Invalid purchase");
            cost += price * quantity;
        }

        payoutToken.permit(user, address(this), cost, deadline, v, r, s);
        payoutToken.transferFrom(user, payeeWallet, cost);

        emit BatchPaymentMade(user, packages, quantities, cost);
    }

    function setUnitPrice(uint256 package, uint256 price) external onlyOwner(){
        unitPrices[package] = price;
    }

    function setUnitPrices(uint256[] memory packages, uint256[] memory prices) external onlyOwner(){
        require(packages.length == prices.length, "Invalid configs");
        for (uint256 i; i < packages.length; i++) {
            unitPrices[packages[i]] = prices[i];
        }
    }

    function getBatchUnitPrice(uint256[] memory packages) external view returns (uint256[] memory) {
        uint256[] memory prices = new uint256[](packages.length);
        for (uint256 i = 0; i < packages.length; i++) {
            prices[i] = unitPrices[packages[i]];
        }
        return prices;
    }

    function setPayoutToken(address _payoutToken) external onlyOwner{
        payoutToken = IERC20Permit(_payoutToken);
    }

    function setPayeeWallet(address _payeeWallet) external onlyOwner{
        payeeWallet = _payeeWallet;
    }

    function recoverToken(IERC20 token, address to, uint256 value) external onlyOwner{
        recover(token, to, value);
    }

    function toggleSale() external onlyOwner(){
        saleOpen = !saleOpen;
    }
}