// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.6;

import "./Pixel.sol";
import "./FreeMoneyBox.sol";

contract PurchaseRulesZero {

    Pixel pixel;
    FreeMoneyBox private freeMoneyBox;

    constructor(Pixel _pixel, FreeMoneyBox _freemoneybox){
        pixel = _pixel;
        freeMoneyBox = _freemoneybox;
    }



    function buy(uint xTopLeft, uint yTopLeft, uint xBottomRight, uint yBottomRight) public {
        require(xTopLeft <= xBottomRight && yTopLeft <= yBottomRight &&
        xBottomRight < 1000 && yBottomRight < 1000, "Invalid rectangle coordinates");

        require(address(msg.sender) == freeMoneyBox.getFree(), "Sorry, only Owner can mint pixels now");


        for (uint ix = xTopLeft; ix <= xBottomRight; ix++) {
            for (uint iy = yTopLeft; iy <= yBottomRight; iy++) {
                pixel.mint(tx.origin, pixel.getPixelId(ix, iy));
            }
        }
        pixel.mintRectangle(xTopLeft, yTopLeft, xBottomRight, yBottomRight);

    }

    function getPrice(uint x, uint y) public view returns (uint256) {
        return 0;
    }

    function getTotalPrice(uint xTopLeft, uint yTopLeft, uint xBottomRight, uint yBottomRight)
    public view returns (uint256) {
        return 0;
    }


}
