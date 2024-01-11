// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";

contract Test is ERC721A, Ownable {
    bool public saleIsActive = false;
    uint256 public mintPrice = 0.00000001 ether;

    constructor() ERC721A("Test", "TST") {}

    function mint(uint256 nMints) external payable checksIfSaleActive {
        require(msg.value == mintPrice * nMints, "Incorrect eth amount sent");
        _safeMint(msg.sender, nMints);
    }

    function toggleSaleIsActive() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setPrice(uint256 priceInWei) external onlyOwner {
        mintPrice = priceInWei;
    }

     function withdraw()
        external
        onlyOwner
    {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(
            success,
            "Withdraw Failed."
        );
    }

    modifier checksIfSaleActive() {
        require(saleIsActive, "Public sale not active");
        _;
    }
}
