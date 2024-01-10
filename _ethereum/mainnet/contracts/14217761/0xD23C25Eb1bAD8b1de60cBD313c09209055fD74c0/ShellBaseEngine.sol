//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC165.sol";
import "./IEngine.sol";

// simple starting point for engines
// - default name
// - proper erc165 support
// - no royalties
// - nop on beforeTokenTransfer and afterEngineSet hooks
abstract contract ShellBaseEngine is IEngine {

    // nop
    function beforeTokenTransfer(
        address,
        address,
        address,
        uint256,
        uint256
    ) external pure virtual override {
        return;
    }

    // nop
    function afterEngineSet(uint256) external view virtual override {
        return;
    }

    // no royalties
    function getRoyaltyInfo(
        IShellFramework,
        uint256,
        uint256
    ) external view virtual returns (address receiver, uint256 royaltyAmount) {
        receiver = address(0);
        royaltyAmount = 0;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IEngine).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}
