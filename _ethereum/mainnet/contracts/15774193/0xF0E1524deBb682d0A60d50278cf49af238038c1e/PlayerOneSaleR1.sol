// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./MerkleProof.sol";
import "./Context.sol";
import "./RefundPool.sol";
import "./ReentrancyGuard.sol";


contract PlayerOneSaleR1 is ReentrancyGuard,Context{

    // Price(Wei) per PlayerOne
    uint256 immutable public price = 0.06 ether;

    // maximum supply
    uint256 immutable public maxSupply = 1000;

    //Maximum purchase quantity per address
    uint256 immutable public maxLimitPerAddress = 2;

    uint256 public whitelistSaleTime;

    uint256 public publicSaleTime;

    uint256 public saleEndTime;

    bytes32 public whitelistRoot;

    RefundPool public refundPool;


    uint256 public totalSoldQuantity;

    // address-> purchased quantity
    mapping(address => uint256) public purchasedQuantity;

    event Buy(address indexed buyer, uint256 indexed amount);


    constructor(uint256 whitelistSaleTime_, uint256 publicSaleTime_, uint256 saleEndTime_,RefundPool refundPool_, bytes32 whitelistRoot_){
        whitelistSaleTime = whitelistSaleTime_;
        publicSaleTime = publicSaleTime_;
        saleEndTime = saleEndTime_;
        refundPool = refundPool_;
        whitelistRoot = whitelistRoot_;
    }

    function checkInWhitelist(bytes32[] calldata proof) view public returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        bool verified = MerkleProof.verify(proof, whitelistRoot, leaf);
        return verified;
    }


    function buy(bytes32[] calldata proof, uint256 amount) external nonReentrant payable {
        require(block.timestamp >= whitelistSaleTime, "PlayerOneSale: not yet on sale");
        require(block.timestamp < saleEndTime, "PlayerOneSale: sale has ended");

        if (block.timestamp < publicSaleTime) {
            require(checkInWhitelist(proof), "PlayerOneSale: address not whitelisted");
        }

        uint256 totalPurchased = purchasedQuantity[_msgSender()] + amount;

        require(amount > 0 && totalPurchased <= maxLimitPerAddress, "PlayerOneSale: exceed purchase limit per address");

        //valid quantity
        totalSoldQuantity = totalSoldQuantity + amount;
        require(totalSoldQuantity <= maxSupply, "PlayerOne: sold out");

        require(msg.value == price * amount, "PlayerOne: the payment price is too low");

        purchasedQuantity[_msgSender()] = totalPurchased;

        //mint
        refundPool.mintPlayerOne{value: msg.value}(_msgSender(),amount,saleEndTime);

        emit Buy(_msgSender(), amount);
    }




}
