//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "PaymentSplitter.sol";
import "IERC721.sol";

contract PaySplitter is PaymentSplitter {

    constructor(address[] memory payees, uint256[] memory shares_) PaymentSplitter(payees, shares_) payable {
    }

    function releaseAll() public {
        uint256 sharesLeft = PaymentSplitter.totalShares();
        for (uint256 i=0; sharesLeft > 0; i++) {
            address payee = PaymentSplitter.payee(i);
            PaymentSplitter.release(payable(payee));
            sharesLeft -= PaymentSplitter.shares(payee);
        }
    }

    function rescueERC721(IERC721 tokenToRescue, uint256 n) external {
        require(PaymentSplitter.shares(_msgSender()) > 0, "only shareholders can rescue");
        tokenToRescue.safeTransferFrom(address(this), _msgSender(), n);
    }
}
