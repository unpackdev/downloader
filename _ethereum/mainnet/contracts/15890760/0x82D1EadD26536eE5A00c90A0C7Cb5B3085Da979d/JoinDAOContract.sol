
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";

contract JoinDAOContract is Pausable, ReentrancyGuard {
    address private _token_address;
    uint256 private _price;

    constructor(address token_address_, uint256 price_, address owner_of_) Pausable(owner_of_) {
        _token_address = token_address_;
        _price = price_;
    }

    event poolCreated(address token_address, uint256 price, address creator);
    event priceEdited(address token_address, uint256 price);
    event ownerChanged(address token_address, address owner_of);
    event bought(address token_address, uint256 amount, uint256 amount_paid);

    function buy(uint256 amount_) public payable nonReentrant {
        require(msg.value >= _price * amount_ / 1 ether, "Not enough funds send");
        IERC20(_token_address).transfer(msg.sender, amount_);
        payable(_owner_of).send(msg.value);
        emit bought(_token_address, amount_, msg.value);
    }

    function removeLiquidity(address token_address_) public {
        require(_owner_of == msg.sender, "Permission denied");
        IERC20(token_address_).transfer(msg.sender, IERC20(token_address_).balanceOf(address(this)));
    }

    function setPrice(address token_address_, uint256 price_) public {
        require(_owner_of == msg.sender, "Permission denied");
        emit priceEdited(token_address_, price_);
    }

    function setTokenOwner(address token_address_, address owner_of_) public {
        require(_owner_of == msg.sender, "Permission denied");
        _owner_of = owner_of_;
        emit ownerChanged(token_address_, owner_of_);
    }
}