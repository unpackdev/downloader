// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.12;

import "./Ownable.sol";

contract PublicSale is Ownable {
    uint256 public publicSaleStart;

    constructor(uint256 _publicSaleStart) {
        publicSaleStart = _publicSaleStart;
    }

    modifier publicSaleActive() {
        require(_publicSaleActive(), "Public sale has not started");
        _;
    }

    function _publicSaleActive() public view returns (bool) {
        return publicSaleStart > 0 && block.timestamp > publicSaleStart;
    }

    function setPublicSaleStart(uint256 _publicSaleStart) public onlyOwner {
        publicSaleStart = _publicSaleStart;
    }
}
