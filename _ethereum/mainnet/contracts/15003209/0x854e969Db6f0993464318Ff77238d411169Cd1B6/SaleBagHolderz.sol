// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./PhaseControl.sol";
import "./IBagHolderz.sol";

/// @title BagHolderz Sale
/// @author 0xhohenheim <contact@0xhohenheim.com>
/// @notice NFT Sale contract for purchasing BagHolderz NFTs
contract SaleBagHolderz is PhaseControl, ReentrancyGuard {
    IBagHolderz public NFT;
    uint256 public price;
    uint256 public limit;
    uint256 public userLimit;
    uint256 public count;
    mapping(address => uint256) public userCount;

    event Purchased(address indexed user, uint256 quantity);
    event PriceUpdated(address indexed owner, uint256 price);
    event LimitUpdated(address indexed owner, uint256 limit);
    event UserLimitUpdated(address indexed owner, uint256 userLimit);

    constructor(
        IBagHolderz _NFT,
        uint256 _price,
        uint256 _limit,
        uint256 _userLimit
    ) {
        NFT = _NFT;
        setPrice(_price);
        setLimit(_limit);
        setUserLimit(_userLimit);
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
        emit PriceUpdated(owner(), _price);
    }

    function setLimit(uint256 _limit) public onlyOwner {
        limit = _limit;
        emit LimitUpdated(owner(), limit);
    }

    function setUserLimit(uint256 _userLimit) public onlyOwner {
        userLimit = _userLimit;
        emit UserLimitUpdated(owner(), userLimit);
    }

    function _purchase(uint256 quantity) private {
        NFT.mint(msg.sender, quantity);
        count = count + quantity;
        userCount[msg.sender] = userCount[msg.sender] + quantity;
        emit Purchased(msg.sender, quantity);
    }

    function purchase(uint256 quantity)
        external
        payable
        restrictForPhase
        nonReentrant
    {
        uint256 totalPrice = getPrice(msg.sender, quantity);
        require(msg.value >= totalPrice, "Insufficient Value");
        require((count + quantity) <= limit, "Sold out");
        require(
            ((userCount[msg.sender] + quantity) <= userLimit) ||
                msg.sender == owner(),
            "Wallet limit reached"
        );
        _purchase(quantity);
    }

    function getPrice(address user, uint256 quantity) public view returns (uint256) {
        uint256 totalPrice = quantity * price;
        if (userCount[user] == 0) totalPrice = totalPrice - price;
        return totalPrice;
    }

    function withdraw(address payable wallet, uint256 amount)
        external
        onlyOwner
    {
        wallet.transfer(amount);
    }
}
