// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./SerumPhaseControl.sol";
import "./IBagHolderz.sol";
import "./IBHSerum.sol";
import "./console.sol";

/// @title BagHolderz Serum Sale
/// @author 0xhohenheim <contact@0xhohenheim.com>
/// @notice NFT Sale contract for purchasing BagHolderz NFTs
contract SaleBHSerum is SerumPhaseControl, ReentrancyGuard {
    IBagHolderz public NFT;
    IBHSerum public serum;
    uint256 public price;
    uint256 public limit;
    uint256 public userLimit;
    uint256 public count;
    mapping(address => uint256) public userCount;
    mapping(uint256 => bool) public claimed;

    event Purchased(address indexed user, uint256 quantity);
    event Claimed(address indexed user, uint256[] claimed, uint256 quantity);
    event PriceUpdated(address indexed owner, uint256 price);
    event LimitUpdated(address indexed owner, uint256 limit);
    event UserLimitUpdated(address indexed owner, uint256 userLimit);

    constructor(
        IBagHolderz _NFT,
        IBHSerum _serum,
        uint256 _price,
        uint256 _limit,
        uint256 _userLimit
    ) {
        NFT = _NFT;
        serum = _serum;
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

    function _purchase(uint256 quantity) internal {
        serum.mint(msg.sender, 1, quantity);
        count = count + quantity;
        userCount[msg.sender] = userCount[msg.sender] + quantity;
        emit Purchased(msg.sender, quantity);
    }

    function purchase(uint256 quantity)
        external
        payable
        restrictForPhase(Action.PURCHASE)
        nonReentrant
    {
        uint256 totalPrice = price * quantity;
        require(msg.value >= totalPrice, "Insufficient Value");
        require((serum.totalSupply(1) + quantity) <= limit, "Sold out");
        require(
            ((userCount[msg.sender] + quantity) <= userLimit) ||
                msg.sender == owner(),
            "Wallet limit reached"
        );
        _purchase(quantity);
    }

    function _claim(uint256[] calldata tokenIds) internal {
        uint256 balance = tokenIds.length;
        uint256 quantity = balance / 4;
        uint256[] memory _claimed = new uint256[](quantity * 4);
        for (uint256 i; i < (quantity * 4); i++) {
            claimed[tokenIds[i]] = true;
            _claimed[i] = tokenIds[i];
        }
        serum.mint(msg.sender, 1, quantity);
        count = count + quantity;
        userCount[msg.sender] = userCount[msg.sender] + quantity;
        emit Claimed(msg.sender, _claimed, quantity);
    }

    function claim(uint256[] calldata tokenIds)
        external
        restrictForPhase(Action.CLAIM)
        nonReentrant
    {
        uint256 tokenCount = tokenIds.length;
        uint256 quantity = tokenCount / 4;
        require(tokenCount >= 4, "Minimum 4 tokenIds required");
        require((serum.totalSupply(1) + quantity) <= limit, "Sold out");
        require(
            ((userCount[msg.sender] + quantity) <= userLimit) ||
                msg.sender == owner(),
            "Wallet limit reached"
        );
        for (uint256 i; i < tokenCount; i++) {
            require(
                NFT.ownerOf(tokenIds[i]) == msg.sender,
                "Must own all NFTs"
            );
            require(!claimed[tokenIds[i]], "Already claimed");
        }
        _claim(tokenIds);
    }

    function withdraw(address payable wallet, uint256 amount)
        external
        onlyOwner
    {
        wallet.transfer(amount);
    }
}
