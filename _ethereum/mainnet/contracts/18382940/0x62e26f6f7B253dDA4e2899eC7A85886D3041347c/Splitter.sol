// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./IERC20.sol";
import "./PaymentSplitter.sol";
import "./Ownable.sol";

contract Splitter is PaymentSplitter, Ownable {

    address public tgt;
    address public usdc;

    address public stakingContract;
    address public treasury;

    constructor(address _tgt, address _usdc, address[] memory _payees, uint256[] memory shares_) PaymentSplitter(_payees, shares_) {
        tgt = _tgt;
        usdc = _usdc;
        stakingContract = _payees[0];
        treasury = _payees[1];
    }

    function releaseAllFunds() public {
        release(IERC20(tgt), treasury);
        release(IERC20(usdc), treasury);

        release(IERC20(tgt), stakingContract);
        release(IERC20(usdc), stakingContract);
    }

    function releaseUsdcFunds() public {
        release(IERC20(usdc), treasury);
        release(IERC20(usdc), stakingContract);
    }

    function releaseTgtFunds() public {
        release(IERC20(tgt), treasury);
        release(IERC20(tgt), stakingContract);
    }

}
