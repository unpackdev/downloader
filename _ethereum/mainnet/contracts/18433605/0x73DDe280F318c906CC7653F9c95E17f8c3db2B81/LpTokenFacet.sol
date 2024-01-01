// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ILpTokenFacet.sol";

contract LpTokenFacet is ILpTokenFacet {
    error InvalidState();

    bytes32 public constant STORAGE_POSITION = keccak256("mellow.contracts.lp-token.storage");

    function _contractStorage() internal pure returns (ILpTokenFacet.Storage storage ds) {
        bytes32 position = STORAGE_POSITION;

        assembly {
            ds.slot := position
        }
    }

    function initializeLpTokenFacet(LpToken singleton, string memory name, string memory symbol) external override {
        IPermissionsFacet(address(this)).requirePermission(msg.sender, address(this), msg.sig);
        ILpTokenFacet.Storage storage ds = _contractStorage();
        if (address(ds.lpToken) != address(0)) revert InvalidState();
        ds.lpToken = singleton.clone(name, symbol, address(this));
    }

    function lpToken() public pure override returns (LpToken) {
        ILpTokenFacet.Storage memory ds = _contractStorage();
        return ds.lpToken;
    }

    function lpTokenInitialized() external view returns (bool) {
        return address(_contractStorage().lpToken) != address(0);
    }

    function lpTokenSelectors() external pure override returns (bytes4[] memory selectors_) {
        selectors_ = new bytes4[](4);
        selectors_[0] = ILpTokenFacet.lpTokenInitialized.selector;
        selectors_[1] = ILpTokenFacet.lpTokenSelectors.selector;
        selectors_[2] = ILpTokenFacet.initializeLpTokenFacet.selector;
        selectors_[3] = ILpTokenFacet.lpToken.selector;
    }
}
