// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface IERC20 {
    function transferFrom(address, address, uint) external returns (bool);
}

contract OTC {

    address public constant INV = 0x41D5D79431A913C4aE7d69a668ecdfE5fF9DFB68;
    address public constant DOLA = 0x865377367054516e17014CcdED1e7d814EDC9ce4;
    address public constant buyer = 0x759a159D78342340EbACffB027c05910c093f430;
    address public constant inverse = 0x9D5Df30F475CEA915b1ed4C0CCa59255C897b61B;
    uint public constant dolaAmount = 169000 * 10 ** 18;
    uint public constant invAmount =  13300 * 10 ** 18;
    bool public swapped;

    function swap() public {
        require(!swapped);
        IERC20(INV).transferFrom(inverse, buyer, invAmount);
        IERC20(DOLA).transferFrom(buyer, inverse,  dolaAmount);
        swapped = true;
    }
}
