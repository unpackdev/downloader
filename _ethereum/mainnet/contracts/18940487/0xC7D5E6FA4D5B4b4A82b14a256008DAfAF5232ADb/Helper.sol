// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

interface IAuction {
    function getCurrentReserves() external view returns (uint dolaReserve, uint dbrReserve);
    function buyDBR(uint exactDolaIn, uint exactDbrOut, address to) external;
}

interface IERC20 {
    function approve(address,uint) external returns (bool);
    function transferFrom(address,address,uint) external returns (bool);
}

contract Helper {

    IAuction public immutable auction;
    IERC20 public immutable dola;

    constructor(
        address _auction,
        address _dola
    ) {
        auction = IAuction(_auction);
        dola = IERC20(_dola);
        dola.approve(_auction, type(uint).max);
    }
    
    function getDbrOut(uint dolaIn) public view returns (uint dbrOut) {
        require(dolaIn > 0, "dolaIn must be positive");
        (uint dolaReserve, uint dbrReserve) = auction.getCurrentReserves();
        uint numerator = dolaIn * dbrReserve;
        uint denominator = dolaReserve + dolaIn;
        dbrOut = numerator / denominator;
    }

    function getDolaIn(uint dbrOut) public view returns (uint dolaIn) {
        require(dbrOut > 0, "dbrOut must be positive");
        (uint dolaReserve, uint dbrReserve) = auction.getCurrentReserves();
        uint numerator = dbrOut * dolaReserve;
        uint denominator = dbrReserve - dbrOut;
        dolaIn = (numerator / denominator) + 1;
    }

    function swapExactDolaForDbr(uint dolaIn, uint dbrOutMin) external returns (uint dbrOut) {
        dbrOut = getDbrOut(dolaIn);
        require(dbrOut >= dbrOutMin, "dbrOut must be greater than dbrOutMin");
        dola.transferFrom(msg.sender, address(this), dolaIn);
        auction.buyDBR(dolaIn, dbrOut, msg.sender);
    }

    function swapDolaForExactDbr(uint dbrOut, uint dolaInMax) external returns (uint dolaIn) {
        dolaIn = getDolaIn(dbrOut);
        require(dolaIn <= dolaInMax, "dolaIn must be less than dolaInMax");
        dola.transferFrom(msg.sender, address(this), dolaIn);
        auction.buyDBR(dolaIn, dbrOut, msg.sender);
    }

}