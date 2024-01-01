// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

// Uncomment this line to use console.log
// import "./console.sol";

import "./Ownable.sol";
import "./IAuctionFactory.sol";

contract Sale is Ownable {
    address payable public seller;
    uint256 public price;
    uint256 public saleTime;
    uint256 public deadline;

    address public buyer;

    bool public hasPaid = false;
    bool public confirmed = false;
    bool public ended = false;
    bool public frozen = false;

    IAuctionFactory public auctionFactory;

    uint256 public sellerTax;

    event Buy(address buyer, uint256 price);
    event SaleSuccess(address buyer, address seller, uint256 price);
    event SaleReverted(address buyer, address seller, uint256 price);

    constructor(
        uint256 _price,
        address _seller,
        address admin
    ) Ownable(admin) {
        auctionFactory = IAuctionFactory(msg.sender);

        price = _price;
        seller = payable(_seller);
    }

    /**
     * @dev Allows any user to buy the item.
     * @notice Funds are stored in the contract until irl transaction is complete.
     */
    function buy() public payable {
        require(
            msg.value == price,
            "You must pay the price."
        );
        require(!hasPaid, "You have already paid.");

        deadline = block.timestamp + auctionFactory.saleDeadlineDelay();

        hasPaid = true;

        buyer = msg.sender;

        emit Buy(msg.sender, price);
    }

    /**
     * @dev Allows buyer to confirm the transaction.
     */
    function buyerConfirms() public {
        require(
            msg.sender == buyer || msg.sender == owner(),
            "Only the buyer can call this function."
        );
        require(hasPaid, "Buyer has not paid yet.");
        require(!confirmed, "Buyer has already confirmed.");

        confirmed = true;

        _saleEnd(seller);
    }

    /**
     * @dev Allows either the seller or the buyer to end the sale, depending on the situation.
     */
    function saleEnd() public {
        _saleEnd(msg.sender);
    }

    function _saleEnd(address sender) internal {
        require(!frozen, "Sale is frozen.");
        require(!ended, "Sale has already ended.");

        // If buyer has not confirmed
        if (!confirmed) {
            require(
                block.timestamp > block.timestamp + deadline,
                "Deadline not yet reached."
            );
            require(
                sender == buyer,
                "Only the buyer can end the sale."
            );

            bool tmpSuccess;
            (tmpSuccess, ) = buyer.call{
                value: price,
                gas: 30000
            }("");
            require(tmpSuccess, "Transfer failed.");

            emit SaleReverted(buyer, seller, price);
        }
        // If buyer has confirmed
        else if (confirmed) {
            require(sender == seller, "Only the seller can end the sale.");

            sellerTax = auctionFactory.saleSellerTax();
            uint256 sellerPayment = price -
                ((price * sellerTax) / 100);
            uint256 toTreasury = address(this).balance - sellerPayment;

            bool tmpSuccess;
            (tmpSuccess, ) = seller.call{value: sellerPayment, gas: 30000}("");
            require(tmpSuccess, "Transfer failed.");

            _toTreasury(toTreasury);

            emit SaleSuccess(buyer, seller, price);
        }

        ended = true;
    }

    /**
     * @dev Allows the owner to freeze the auction.
     */
    function freeze(bool a) public onlyOwner {
        frozen = a;
    }

    /**
     * @dev Allows the owner to withdraw the funds from the contract.
     * @param recipient The address to send the funds to.
     * @notice This function is only callable by the owner, IT SHOULD NOT BE USED OTHERWISE.
     */
    function emergencyWithdraw(address recipient) public onlyOwner {
        _emergencyWithdraw(recipient);
    }

    function _emergencyWithdraw(address recipient) internal {
        bool tmpSuccess;
        (tmpSuccess, ) = recipient.call{
            value: address(this).balance,
            gas: 30000
        }("");
        require(tmpSuccess, "Transfer failed.");
    }

    function _toTreasury(uint256 amount) internal {
        bool tmpSuccess;
        (tmpSuccess, ) = auctionFactory.treasury().call{
            value: amount,
            gas: 30000
        }("");
        require(tmpSuccess, "Transfer failed.");
    }
}
