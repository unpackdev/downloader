// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC20.sol";

import "./IProxyableToken.sol";

import "./IVaultFacet.sol";

import "./CommonLibrary.sol";

contract VaultFacet is IVaultFacet {
    error Forbidden();

    bytes32 public constant STORAGE_POSITION = keccak256("mellow.contracts.vault.storage");

    function _contractStorage() internal pure returns (IVaultFacet.Storage storage ds) {
        bytes32 position = STORAGE_POSITION;

        assembly {
            ds.slot := position
        }
    }

    function initializeVaultFacet(
        address[] memory tokensInOrderOfDifficulty_,
        uint256 proxyTokensMask_,
        IOracle oracle_,
        bytes[] calldata securityParams_
    ) external override {
        IPermissionsFacet(address(this)).requirePermission(msg.sender, address(this), msg.sig);
        IVaultFacet.Storage storage ds = _contractStorage();
        ds.proxyTokensMask = proxyTokensMask_;
        ds.tokens = tokensInOrderOfDifficulty_;
        ds.oracle = oracle_;
        ds.securityParams = abi.encode(securityParams_);
    }

    function updateSecurityParams(bytes[] calldata securityParams_) external {
        IPermissionsFacet(address(this)).requirePermission(msg.sender, address(this), msg.sig);
        IVaultFacet.Storage storage ds = _contractStorage();
        ds.securityParams = abi.encode(securityParams_);
    }

    function updateOracle(IOracle newOracle) external override {
        IPermissionsFacet(address(this)).requirePermission(msg.sender, address(this), msg.sig);
        IVaultFacet.Storage storage ds = _contractStorage();
        ds.oracle = newOracle;
    }

    function tvl() public view override returns (uint256) {
        IVaultFacet.Storage memory ds = _contractStorage();
        address[] memory tokens_ = ds.tokens;
        IOracle oracle_ = ds.oracle;
        address vault = ITokensManagementFacet(address(this)).vault();
        uint256[] memory tokenAmounts = new uint256[](tokens_.length);
        for (uint256 i = 0; i < tokens_.length; i++) {
            tokenAmounts[i] = IERC20(tokens_[i]).balanceOf(vault);
        }

        return oracle_.quote(tokens_, tokenAmounts, securityParams());
    }

    function quote(address[] calldata tokens_, uint256[] calldata tokenAmounts) public view override returns (uint256) {
        return _contractStorage().oracle.quote(tokens_, tokenAmounts, securityParams());
    }

    function tokens() public view override returns (address[] memory) {
        return _contractStorage().tokens;
    }

    function proxyTokensMask() public view override returns (uint256) {
        return _contractStorage().proxyTokensMask;
    }

    function getTokensAndAmounts() public view override returns (address[] memory, uint256[] memory) {
        IVaultFacet.Storage memory ds = _contractStorage();
        address[] memory tokens_ = ds.tokens;
        address vault = ITokensManagementFacet(address(this)).vault();
        uint256[] memory tokenAmounts = new uint256[](tokens_.length);
        for (uint256 i = 0; i < tokens_.length; i++) {
            tokenAmounts[i] = IERC20(tokens_[i]).balanceOf(vault);
        }
        return (tokens_, tokenAmounts);
    }

    function oracle() external pure override returns (IOracle) {
        IVaultFacet.Storage memory ds = _contractStorage();
        return ds.oracle;
    }

    function securityParams() public view returns (bytes[] memory) {
        return abi.decode(_contractStorage().securityParams, (bytes[]));
    }

    function vaultInitialized() external view returns (bool) {
        return _contractStorage().tokens.length != 0;
    }

    function vaultSelectors() external pure returns (bytes4[] memory selectors_) {
        selectors_ = new bytes4[](11);
        selectors_[0] = IVaultFacet.vaultInitialized.selector;
        selectors_[1] = IVaultFacet.vaultSelectors.selector;
        selectors_[2] = IVaultFacet.initializeVaultFacet.selector;
        selectors_[3] = IVaultFacet.updateSecurityParams.selector;
        selectors_[4] = IVaultFacet.tvl.selector;
        selectors_[5] = IVaultFacet.quote.selector;
        selectors_[6] = IVaultFacet.tokens.selector;
        selectors_[7] = IVaultFacet.proxyTokensMask.selector;
        selectors_[8] = IVaultFacet.getTokensAndAmounts.selector;
        selectors_[9] = IVaultFacet.oracle.selector;
        selectors_[10] = IVaultFacet.securityParams.selector;
    }
}
