//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.2;

import "./AccessPassSale.sol";
import "./IERC20.sol";

contract AccessPassSaleBridge is AccessControl {
    using SafeMath for uint256;

    AccessPassSale public accessPassSale;
    IERC20 public Stars;

    struct Tier {
        uint256 numPasses;
        uint256 passPrice;
        uint256 starsPerPass;
        bool paused;
    }

    constructor(address payable _accessPassSale, address _Stars) public {
        accessPassSale = AccessPassSale(_accessPassSale);
        Stars = IERC20(_Stars);
    }

    receive() external payable {
        uint256 tierPurchaseQuantity;
        uint256 ethLeft = msg.value;
        uint256 currCost;
        uint256 numPasses;
        uint256 passPrice;
        uint256 starsPerPass;
        uint256 starsPurchased;
        uint8 currTier;
        bool paused;

        for (uint8 i = 0; i < 5; i++) {
            currTier = 4 - i;
            (numPasses, passPrice, starsPerPass, paused) = accessPassSale.tiers(
                currTier
            );

            if (!paused) {
                tierPurchaseQuantity = ethLeft.div(passPrice);
                if (numPasses < tierPurchaseQuantity) {
                    tierPurchaseQuantity = numPasses;
                }

                currCost = passPrice.mul(tierPurchaseQuantity);

                ethLeft = ethLeft.sub(currCost);
                accessPassSale.purchase{value: currCost}(currTier);

                starsPurchased = starsPurchased.add(
                    tierPurchaseQuantity.mul(starsPerPass)
                );
            }
        }

        Stars.transfer(msg.sender, starsPurchased);

        if (ethLeft > 0) {
            msg.sender.transfer(ethLeft);
        }
    }
}
