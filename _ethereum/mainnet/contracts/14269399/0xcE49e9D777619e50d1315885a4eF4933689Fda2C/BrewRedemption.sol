// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./IBrew.sol";
import "./IOrcs.sol";

contract BrewRedemption is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public redemptionAmount;
    uint256 public INITIAL_ISSUANCE_FIRST_100 = 100 ether;
    mapping(uint256 => uint256) public RedeemListInfo;

    IBrew public brew;
    IOrcs public orc;

    event RedeemedBrew(
        address indexed user,
        uint256 orcId,
        uint256 redemptionAmount
    );

    event GiveBrewToOrcOwner(
        address indexed user,
        uint256 orcId,
        uint256 amount
    );

    event GiveBrewToLuckyAddress(
        address indexed user,
        uint256 amount
    );

    constructor(IBrew _brew, IOrcs _orc) {
        redemptionAmount = 10 ether;

        brew = _brew;
        orc = _orc;
    }

    function redeem(uint256[] memory orcIds ) external nonReentrant  {
        uint256 amount = 0;
        for (uint i = 0; i < orcIds.length; i++) {
            require(
                orc.ownerOf(orcIds[i]) == _msgSender(),
                "cannot redeem brew from an orc that is not yours"
            );

            if(RedeemListInfo[orcIds[i]] > 0){
                amount = amount.add(block.timestamp.sub(RedeemListInfo[orcIds[i]]).div(86400).mul(redemptionAmount));
            } else {
                if(orcIds[i] <= 100){
                    amount = amount.add(INITIAL_ISSUANCE_FIRST_100);
                } else {
                    amount = amount.add(redemptionAmount);
                }
            }

            RedeemListInfo[orcIds[i]] = block.timestamp;
            emit RedeemedBrew(_msgSender(), orcIds[i], redemptionAmount);
        }

        require(amount > 0, "you have nothing to withdraw");
        brew.mint(_msgSender(), amount);
    }

    function giveBrewToOrcOwner(uint256 orcId, uint256 amount) external onlyOwner {
        brew.mint(orc.ownerOf(orcId), amount.mul(1 ether));

        emit GiveBrewToOrcOwner(orc.ownerOf(orcId), orcId, amount.mul(1 ether));
    }

    function giveBrewToLuckyAddress(address luckyAddress, uint256 amount) external onlyOwner {
        brew.mint(luckyAddress, amount.mul(1 ether));

        emit GiveBrewToLuckyAddress(luckyAddress, amount.mul(1 ether));
    }

    function updateRedemptionAmount(uint256 newRedemptionAmount)
        external
        onlyOwner
    {
        redemptionAmount = newRedemptionAmount.mul(1 ether);
    }
}
