//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

abstract contract AlbumBuyoutManager {
    event BuyoutSet(address buyer, uint256 cost, uint256 end);
    event Buyout(address buyer, uint256 cost);
    event BuyoutPortionClaimed(address claimer, uint256 amount, uint256 owed);
    event MinReservePriceSet(uint256 minReservePrice);

    address private buyer;
    uint256 private buyoutCost;
    uint256 private buyoutEnd;
    bool private bought;
    uint256 private minReservePrice;
    // Initialized to 7 days in seconds
    uint256 private timeout = 60 * 60 * 24 * 7;

    function sendAllToSender() internal virtual;

    function checkOwedAmount(uint256 _amount, uint256 _buyoutCost)
        internal
        virtual
        returns (uint256 owed);

    // Requires no completed or ongoing buyout.
    modifier noBuyout() {
        require(!bought, "A buyout was already completed");
        require(
            block.timestamp >= buyoutEnd || buyer == address(0),
            "A buyout is in progress"
        );
        _;
    }

    function getBuyoutData()
        public
        view
        returns (
            address _buyer,
            uint256 _buyoutCost,
            uint256 _buyoutEnd,
            bool _bought,
            uint256 _timeout,
            uint256 _minReservePrice
        )
    {
        return (buyer, buyoutCost, buyoutEnd, bought, timeout, minReservePrice);
    }

    function _setTimeout(uint256 _timeout) internal {
        timeout = _timeout;
    }

    function _setMinReservePrice(uint256 _minReservePrice) internal {
        minReservePrice = _minReservePrice;
        emit MinReservePriceSet(_minReservePrice);
    }

    function _setBuyout(address _buyer, uint256 _cost) internal noBuyout {
        require(
            _cost >= minReservePrice,
            "Album can't be bought out for amount less than minReservePrice!"
        );
        buyer = _buyer;
        buyoutCost = _cost;
        buyoutEnd = block.timestamp + timeout;
        emit BuyoutSet(buyer, buyoutCost, buyoutEnd);
    }

    function buyout() public payable {
        require(!bought, "Album has already been bought out");
        require(msg.sender == buyer, "Caller is not the buyer.");
        require(msg.value == buyoutCost, "Not enough ETH.");
        require(block.timestamp < buyoutEnd, "Buyout timeout already passed.");
        sendAllToSender();
        bought = true;
        emit Buyout(buyer, buyoutCost);
    }

    function claim(uint256 _amount) public {
        require(bought, "No buyout yet.");
        uint256 owed = checkOwedAmount(_amount, buyoutCost);
        payable(msg.sender).transfer(owed);
        emit BuyoutPortionClaimed(msg.sender, _amount, owed);
    }
}
