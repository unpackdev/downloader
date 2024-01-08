// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.6;

import "./Strategists.sol";
import "./ERC20Burnable.sol";
import "./Pixel.sol";
import "./PrivatRound.sol";
import "./FreeMoneyBox.sol";

contract PurchaseRulesTwo {

    ERC20Burnable private mil1;
    Pixel pixel;
    Strategists private strategists;
    PrivatRound private privatRound;
    FreeMoneyBox private freeMoneyBox;

    uint256 private price = 10 ** 18;

    constructor(ERC20Burnable _mil1, Pixel _pixel, FreeMoneyBox _fremoneybox, Strategists _strategists, PrivatRound _privatRound){
        mil1 = _mil1;
        pixel = _pixel;
        freeMoneyBox = _fremoneybox;
        strategists = _strategists;
        privatRound = _privatRound;
    }



    function buy(uint xTopLeft, uint yTopLeft, uint xBottomRight, uint yBottomRight) public {
        require(xTopLeft <= xBottomRight && yTopLeft <= yBottomRight &&
        xBottomRight < 1000 && yBottomRight < 1000, "Invalid rectangle coordinates");

        require(strategists.isVip(msg.sender) ||
            privatRound.isVip(msg.sender), "Sorry, only partners can buy pixels today");

        uint numberPixels = (xBottomRight - xTopLeft + 1) * (yBottomRight - yTopLeft + 1);
        uint256 totalPrice = numberPixels * price;
        bool result = true;
        if (tx.origin != freeMoneyBox.getFree()) {
            result = mil1.transferFrom(address(tx.origin), address(this), totalPrice / 2);
            result = result && mil1.transferFrom(address(tx.origin), freeMoneyBox.getMoneyBox(), totalPrice / 2);
            mil1.burn(mil1.balanceOf(address(this)));
        }

        if (result) {
            for (uint ix = xTopLeft; ix <= xBottomRight; ix++) {
                for (uint iy = yTopLeft; iy <= yBottomRight; iy++) {
                    pixel.mint(tx.origin, pixel.getPixelId(ix, iy));
                }
            }
            pixel.mintRectangle(xTopLeft, yTopLeft, xBottomRight, yBottomRight);
        }
    }

    function getPrice(uint x, uint y) public view returns (uint256) {
        if (tx.origin == freeMoneyBox.getFree()) {
            return 0;
        } else {
            return 1 * price;
        }
    }

    function getTotalPrice(uint xTopLeft, uint yTopLeft, uint xBottomRight, uint yBottomRight)
    public view returns (uint256) {
        if (tx.origin == freeMoneyBox.getFree()) {
            return 0;
        } else {
            uint numberPixels = (xBottomRight - xTopLeft + 1) * (yBottomRight - yTopLeft + 1);
            uint256 totalPrice = numberPixels * price;
            return totalPrice;
        }
    }


}
