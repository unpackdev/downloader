// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./UpgraderBase.sol";

contract VPoolUpgrader is UpgraderBase {
    constructor(address _multicall)
        UpgraderBase(_multicall) // solhint-disable-next-line no-empty-blocks
    {}

    function _calls() internal pure override returns (bytes[] memory calls) {
        calls = new bytes[](5);
        calls[0] = abi.encodeWithSignature("token()");
        calls[1] = abi.encodeWithSignature("poolAccountant()");
        calls[2] = abi.encodeWithSignature("withdrawFee()");
        calls[3] = abi.encodeWithSignature("pricePerShare()");
        calls[4] = abi.encodeWithSignature("tokensHere()");
    }

    function _checkResults(bytes[] memory _beforeResults, bytes[] memory _afterResults) internal pure override {
        address beforeToken = abi.decode(_beforeResults[0], (address));
        address beforePoolAccountant = abi.decode(_beforeResults[1], (address));
        uint256 beforeWithdrawFee = abi.decode(_beforeResults[2], (uint256));
        uint256 beforePricePerShare = abi.decode(_beforeResults[3], (uint256));
        uint256 beforeTokensHere = abi.decode(_beforeResults[4], (uint256));

        address afterToken = abi.decode(_afterResults[0], (address));
        address afterPoolAccountant = abi.decode(_afterResults[1], (address));
        uint256 afterWithdrawFee = abi.decode(_afterResults[2], (uint256));
        uint256 afterPricePerShare = abi.decode(_afterResults[3], (uint256));
        uint256 afterTokensHere = abi.decode(_afterResults[4], (uint256));

        require(
            beforeToken == afterToken &&
                beforePoolAccountant == afterPoolAccountant &&
                beforeWithdrawFee == afterWithdrawFee,
            "fields-test-failed"
        );
        require(
            beforePricePerShare == afterPricePerShare && beforeTokensHere == afterTokensHere,
            "methods-test-failed"
        );
    }
}
