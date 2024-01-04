// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

abstract contract FeeApproverLike {
    function calculateAmountsAfterFee(
        address sender,
        address recipient,
        uint256 amount
    )
        public
        virtual
        returns (
            uint256 transferToAmount,
            uint256 transferToFeeDistributorAmount
        );
    function setFeeMultiplier(uint8 _feeMultiplier) public virtual;
}
