pragma solidity ^0.5.13;
pragma experimental ABIEncoderV2;

interface Burnable {
    function burn(uint256) external returns (bool);
}

contract BurnOnly {
    Burnable internal B;

    constructor(address _b) public {
        B = Burnable(_b);
    }

    function burn(uint256 _amount) external returns (bool) {
        return B.burn(_amount);
    }
}