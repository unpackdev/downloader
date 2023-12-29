// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./IERC20.sol";
import "./PaymentSplitter.sol";
import "./Ownable.sol";

contract Splitter is PaymentSplitter, Ownable {

    address public tgt;
    address public usdc;

    address public affiliateCollector;
    address public treasury;

    constructor(address _tgt, address _usdc, address[] memory _payees, uint256[] memory shares_) PaymentSplitter(_payees, shares_) {
        tgt = _tgt;
        usdc = _usdc;
        affiliateCollector = _payees[0];
        treasury = _payees[1];
    }

    function releaseAllFunds() public {
        release(IERC20(tgt), treasury);
        release(IERC20(usdc), treasury);

        release(IERC20(tgt), affiliateCollector);
        release(IERC20(usdc), affiliateCollector);
    }

    function releaseUsdcFunds() public {
        release(IERC20(usdc), treasury);
        release(IERC20(usdc), affiliateCollector);
    }

    function releaseTgtFunds() public {
        release(IERC20(tgt), treasury);
        release(IERC20(tgt), affiliateCollector);
    }

}
