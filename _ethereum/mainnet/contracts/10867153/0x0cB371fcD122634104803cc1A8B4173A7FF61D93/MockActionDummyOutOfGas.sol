// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

import "./GelatoActionsStandard.sol";
import "./IGelatoCore.sol";

contract MockActionDummyOutOfGas is GelatoActionsStandard {

    uint256 public overflowVar;

    function action(bool) public payable virtual {
        assert(false);
    }

    function placeholder() public pure {
        assert(false);
    }

    function termsOk(uint256, address, bytes calldata _data, DataFlow, uint256, uint256)
        public
        view
        virtual
        override
        returns(string memory)
    {
        (bool isOk) = abi.decode(_data, (bool));
        bool _;
        bytes memory __;
        (_, __) = address(this).staticcall(abi.encodePacked(this.placeholder.selector));
        if (isOk) return OK;
        revert("MockActionDummyOutOfGas.termsOk");
    }
}
