// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./IERC20.sol";

contract BuyTokenContract is Ownable {
    bool internal locked;
    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    IERC20 public usdt;
    IERC20 public worldCupToken;
    uint256 public purchaseRatio;

    event Transfer(address indexed from, address indexed to, uint value);

    constructor(address _usdt, address _worldCupToken) {
        usdt = IERC20(_usdt);
        worldCupToken = IERC20(_worldCupToken);
        purchaseRatio = 100;
    }

    function buyTokenWithUSDT(uint256 amount) public {
        uint256 userAllowance = usdt.allowance(_msgSender(), address(this));
        require(
            userAllowance >= amount * purchaseRatio * 10**6,
            "Make sure to add enough allowance"
        );
        require(
            usdt.balanceOf(msg.sender) >= amount,
            "You don't have enough USDT to purchase "
        );
        (bool success, ) = address(usdt).call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                _msgSender(),
                address(this),
                amount * purchaseRatio * 10**6
            )
        );
        require(success, "purchase failed");
        worldCupToken.transfer(msg.sender, amount * 10**18);
    }

    function withdrawUSDT() public onlyOwner {
        require(usdt.balanceOf(address(this)) > 0, "no USDT in contract");
        (bool success, ) = address(usdt).call(
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                _msgSender(),
                usdt.balanceOf(address(this))
            )
        );
        require(success, "withdraw failed");
    }

    function updatePurchasePrice(uint256 price) public onlyOwner {
        require(price > 0, "wrong price");
        purchaseRatio = price;
    }

    function withdrawETH() public payable onlyOwner noReentrant {
        require(address(this).balance > 0, "not enough ETH balance");
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Failed to send ETH");
    }

    receive() external payable {}
}
