// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.14;

import "./ERC721A.sol";
import "./Ownable.sol";

contract GHOST is ERC721A, Ownable {

    uint256 public totalGhosts = 0;
    bool public SALE_LIVE = false;

    constructor() ERC721A("G H O S T", "GHOST") {}
   
    function flipSaleState() public {
        SALE_LIVE = !SALE_LIVE;
    }

    function mint() public {
        require(SALE_LIVE, "Sale is not live");
        _safeMint(msg.sender, 1);
        totalGhosts ++;
    }

    function mintWithFlipBack() public {
        require(SALE_LIVE, "Sale is not live");
        _safeMint(msg.sender, 1);
        totalGhosts ++;
        SALE_LIVE = false;
    }
}