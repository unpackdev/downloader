// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./ITokensManagementFacet.sol";

contract ERC20TokensManagementFacet is ITokensManagementFacet {
    using SafeERC20 for IERC20;

    error InvalidState();
    error Forbidden();

    bytes32 public constant STORAGE_POSITION = keccak256("mellow.contracts.erc20-management.storage");

    function _contractStorage() internal pure returns (ITokensManagementFacet.Storage storage ds) {
        bytes32 position = STORAGE_POSITION;

        assembly {
            ds.slot := position
        }
    }

    function vault() external pure returns (address) {
        ITokensManagementFacet.Storage memory ds = _contractStorage();
        return ds.vault;
    }

    function initERC20TokensManagementFacet() external {
        ITokensManagementFacet.Storage storage ds = _contractStorage();
        if (ds.vault != address(0)) revert InvalidState();
        ds.vault = address(this);
    }

    function approve(address token, address to, uint256 amount) external {
        if (msg.sender != address(this)) revert Forbidden();
        IERC20(token).forceApprove(to, amount);
    }

    function erc20TokensManagementInitialized() external view returns (bool) {
        return _contractStorage().vault != address(0);
    }

    function erc20TokensManagementSelectors() external view returns (bytes4[] memory selectors_) {
        selectors_ = new bytes4[](5);
        selectors_[0] = ERC20TokensManagementFacet(address(this)).erc20TokensManagementInitialized.selector;
        selectors_[1] = ERC20TokensManagementFacet(address(this)).erc20TokensManagementSelectors.selector;
        selectors_[2] = ITokensManagementFacet.vault.selector;
        selectors_[3] = ITokensManagementFacet.approve.selector;
        selectors_[4] = ERC20TokensManagementFacet.initERC20TokensManagementFacet.selector;
    }
}
