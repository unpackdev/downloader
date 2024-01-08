// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.6;

import "./ERC20Burnable.sol";
import "./Pixel.sol";
import "./FreeMoneyBox.sol";

contract PurchaseRulesThree {

    ERC20Burnable private mil1;
    Pixel pixel;
    FreeMoneyBox private freeMoneyBox;

    uint256 private price = 10 ** 18;

    constructor(ERC20Burnable _mil1, Pixel _pixel, FreeMoneyBox _freemoneybox){
        mil1 = _mil1;
        pixel = _pixel;
        freeMoneyBox = _freemoneybox;
    }



    function buy(uint xTopLeft, uint yTopLeft, uint xBottomRight, uint yBottomRight) public {
        require(xTopLeft <= xBottomRight && yTopLeft <= yBottomRight &&
        xBottomRight < 1000 && yBottomRight < 1000, "Invalid rectangle coordinates");


        //        uint numberPixels = (xBottomRight - xTopLeft) * (yBottomRight - yTopLeft);
        uint256 totalPrice = getTotalPrice(xTopLeft, yTopLeft, xBottomRight, yBottomRight);

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
            if (x >= 500) {
                x = 999 - x;
            }
            if (y >= 500) {
                y = 999 - y;
            }

            uint xprice = x / 100 + 1;
            uint yprice = y / 100 + 1;

            if (xprice < yprice) {
                return xprice * price;
            } else {
                return yprice * price;
            }
        }
    }

    function getTotalPrice(uint xTopLeft, uint yTopLeft, uint xBottomRight, uint yBottomRight)
    public view returns (uint256) {
        if (tx.origin == freeMoneyBox.getFree()) {
            return 0;
        } else {
            uint256 totalPrice = 0;

            for (uint ix = xTopLeft; ix <= xBottomRight; ix++) {
                for (uint iy = yTopLeft; iy <= yBottomRight; iy++) {
                    totalPrice += getPrice(ix, iy);
                }
            }
            return totalPrice;
        }
    }


}
