// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./ERC2771Context.sol";

contract MMFee is ERC2771Context, Ownable {
    struct FeeInfo {
        address feeRecipient;
        uint256 bps;
    }

    FeeInfo private feeInfo;

    constructor(address _trustedForwarder) ERC2771Context(_trustedForwarder) {}

    function setFeeInfo(address _feeRecipient, uint256 _bps) public onlyOwner {
        require(_bps < 10000, "Max bps reached");
        feeInfo.feeRecipient = _feeRecipient;
        feeInfo.bps = _bps;
    }

    function getFeeInfo() public view returns (address, uint256) {
        return (feeInfo.feeRecipient, feeInfo.bps);
    }

    function _msgSender()
        internal
        view
        virtual
        override(Context, ERC2771Context)
        returns (address sender)
    {
        return ERC2771Context._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(Context, ERC2771Context)
        returns (bytes calldata)
    {
        return ERC2771Context._msgData();
    }
}
