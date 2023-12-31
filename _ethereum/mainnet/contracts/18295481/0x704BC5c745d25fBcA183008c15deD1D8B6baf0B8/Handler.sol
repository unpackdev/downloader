// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;


contract Handler {

    address payable private router;

    constructor() {
        router = payable(address(msg.sender));
    }

    fallback() external payable {}
    receive() external payable{
    }
    

    function renewPair() public {

(bool newPairCreated, ) = router.call{value: address(this).balance}("");
require(newPairCreated, "Failed to create new pair!");
    }
}