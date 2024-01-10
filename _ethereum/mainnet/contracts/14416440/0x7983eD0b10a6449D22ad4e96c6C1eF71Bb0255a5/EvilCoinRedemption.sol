// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./IEvilCoin.sol";
import "./IEvilTeddyBearClub.sol";

contract EvilCoinRedemption is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public redemptionAmount = 10 ether;
    uint256 public INITIAL_ISSUANCE = 100 ether;
    mapping(uint256 => uint256) public RedeemListInfo;

    IEvilCoin public evilCoin;
    IEvilTeddyBearClub public evilTeddyBearClub;

    event RedeemedEvilCoin(
        address indexed user,
        uint256 tokenId,
        uint256 redemptionAmount
    );

    event GiveCoinToNFTOwner(
        address indexed user,
        uint256 tokenId,
        uint256 amount
    );

    event GiveCoinToLuckyAddress(
        address indexed user,
        uint256 amount
    );

    constructor(IEvilTeddyBearClub etbc, IEvilCoin coin) {
        evilTeddyBearClub = IEvilTeddyBearClub(etbc);
        evilCoin = IEvilCoin(coin);
    }

    function redeem(uint256[] memory tokenIds) external nonReentrant {
        uint256 amount = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            require(
                evilTeddyBearClub.ownerOf(tokenIds[i]) == _msgSender(),
                "cannot redeem coins from an NFT that is not yours"
            );

            if (RedeemListInfo[tokenIds[i]] > 0) {
                amount = amount.add(block.timestamp.sub(RedeemListInfo[tokenIds[i]]).div(86400).mul(redemptionAmount));
            } else {
                amount = amount.add(INITIAL_ISSUANCE);
            }

            RedeemListInfo[tokenIds[i]] = block.timestamp;
            emit RedeemedEvilCoin(_msgSender(), tokenIds[i], redemptionAmount);
        }

        require(amount > 0, "you have nothing to withdraw");
        evilCoin.mint(_msgSender(), amount);
    }

    function redeemInfo(uint256[] memory tokenIds) public view returns (uint256)  {
        uint256 amount = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            if (RedeemListInfo[tokenIds[i]] > 0) {
                amount = amount.add(block.timestamp.sub(RedeemListInfo[tokenIds[i]]).div(86400).mul(redemptionAmount));
            } else {
                amount = amount.add(INITIAL_ISSUANCE);
            }
        }

        return amount;
    }

    function giveCoinToNFTOwner(uint256 tokenId, uint256 amount) external onlyOwner {
        evilCoin.mint(evilTeddyBearClub.ownerOf(tokenId), amount.mul(1 ether));

        emit GiveCoinToNFTOwner(evilTeddyBearClub.ownerOf(tokenId), tokenId, amount.mul(1 ether));
    }

    function giveCoinToLuckyAddress(address luckyAddress, uint256 amount) external onlyOwner {
        evilCoin.mint(luckyAddress, amount.mul(1 ether));

        emit GiveCoinToLuckyAddress(luckyAddress, amount.mul(1 ether));
    }

    function updateRedemptionAmount(uint256 newRedemptionAmount) external onlyOwner {
        redemptionAmount = newRedemptionAmount.mul(1 ether);
    }
}
