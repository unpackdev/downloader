// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./AppStorage.sol";
import "./LibConstants.sol";
import "./LibHelpers.sol";
import "./LibObject.sol";
import "./LibERC20.sol";

import "./CustomErrors.sol";

import "./IDiamondProxy.sol";

library LibAdmin {
    event MaxDividendDenominationsUpdated(uint8 oldMax, uint8 newMax);
    event SupportedTokenAdded(address indexed tokenAddress);
    event FunctionsLocked(bytes4[] functionSelectors);
    event FunctionsUnlocked(bytes4[] functionSelectors);
    event ObjectMinimumSellUpdated(bytes32 objectId, uint256 newMinimumSell);

    function _getSystemId() internal pure returns (bytes32) {
        return LibHelpers._stringToBytes32(LC.SYSTEM_IDENTIFIER);
    }

    function _getEmptyId() internal pure returns (bytes32) {
        return LibHelpers._stringToBytes32(LC.EMPTY_IDENTIFIER);
    }

    function _updateMaxDividendDenominations(uint8 _newMaxDividendDenominations) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint8 old = s.maxDividendDenominations;
        require(_newMaxDividendDenominations > old, "_updateMaxDividendDenominations: cannot reduce");
        s.maxDividendDenominations = _newMaxDividendDenominations;

        emit MaxDividendDenominationsUpdated(old, _newMaxDividendDenominations);
    }

    function _getMaxDividendDenominations() internal view returns (uint8) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.maxDividendDenominations;
    }

    function _isSupportedExternalTokenAddress(address _tokenId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.externalTokenSupported[_tokenId];
    }

    function _isSupportedExternalToken(bytes32 _tokenId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return LibHelpers._isAddress(_tokenId) && s.externalTokenSupported[LibHelpers._getAddressFromId(_tokenId)];
    }

    function _addSupportedExternalToken(address _tokenAddress, uint256 _minimumSell) internal {
        if (LibERC20.decimals(_tokenAddress) > 18) {
            revert CannotSupportExternalTokenWithMoreThan18Decimals();
        }
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(!s.externalTokenSupported[_tokenAddress], "external token already added");
        require(s.objectTokenWrapperId[_tokenAddress] == bytes32(0), "cannot add participation token wrapper as external");

        if (_minimumSell == 0) revert MinimumSellCannotBeZero();

        string memory symbol = LibERC20.symbol(_tokenAddress);
        if (s.tokenSymbolObjectId[symbol] != bytes32(0)) {
            revert ObjectTokenSymbolAlreadyInUse(LibHelpers._getIdForAddress(_tokenAddress), symbol);
        }

        s.externalTokenSupported[_tokenAddress] = true;
        bytes32 tokenId = LibHelpers._getIdForAddress(_tokenAddress);
        LibObject._createObject(tokenId, LC.OBJECT_TYPE_ADDRESS);
        s.supportedExternalTokens.push(_tokenAddress);
        s.tokenSymbolObjectId[symbol] = tokenId;
        s.objectMinimumSell[tokenId] = _minimumSell;

        emit SupportedTokenAdded(_tokenAddress);
    }

    function _getSupportedExternalTokens() internal view returns (address[] memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // Supported tokens cannot be removed because they may exist in the system!
        return s.supportedExternalTokens;
    }

    function _lockFunction(bytes4 functionSelector) internal {
        FunctionLockedStorage storage s = LibAppStorage.functionLockStorage();
        s.locked[functionSelector] = true;

        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = functionSelector;
        emit FunctionsLocked(functionSelectors);
    }

    function _unlockFunction(bytes4 functionSelector) internal {
        FunctionLockedStorage storage s = LibAppStorage.functionLockStorage();
        s.locked[functionSelector] = false;

        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = functionSelector;
        emit FunctionsUnlocked(functionSelectors);
    }

    function _isFunctionLocked(bytes4 functionSelector) internal view returns (bool) {
        FunctionLockedStorage storage s = LibAppStorage.functionLockStorage();
        return s.locked[functionSelector];
    }

    function _lockAllFundTransferFunctions() internal {
        FunctionLockedStorage storage s = LibAppStorage.functionLockStorage();
        s.locked[IDiamondProxy.startTokenSale.selector] = true;
        s.locked[IDiamondProxy.paySimpleClaim.selector] = true;
        s.locked[IDiamondProxy.paySimplePremium.selector] = true;
        s.locked[IDiamondProxy.checkAndUpdateSimplePolicyState.selector] = true;
        s.locked[IDiamondProxy.cancelOffer.selector] = true;
        s.locked[IDiamondProxy.executeLimitOffer.selector] = true;
        s.locked[IDiamondProxy.internalTransferFromEntity.selector] = true;
        s.locked[IDiamondProxy.payDividendFromEntity.selector] = true;
        s.locked[IDiamondProxy.internalBurn.selector] = true;
        s.locked[IDiamondProxy.wrapperInternalTransferFrom.selector] = true;
        s.locked[IDiamondProxy.withdrawDividend.selector] = true;
        s.locked[IDiamondProxy.withdrawAllDividends.selector] = true;
        s.locked[IDiamondProxy.externalWithdrawFromEntity.selector] = true;
        s.locked[IDiamondProxy.externalDeposit.selector] = true;

        bytes4[] memory lockedFunctions = new bytes4[](14);
        lockedFunctions[0] = IDiamondProxy.startTokenSale.selector;
        lockedFunctions[1] = IDiamondProxy.paySimpleClaim.selector;
        lockedFunctions[2] = IDiamondProxy.paySimplePremium.selector;
        lockedFunctions[3] = IDiamondProxy.checkAndUpdateSimplePolicyState.selector;
        lockedFunctions[4] = IDiamondProxy.cancelOffer.selector;
        lockedFunctions[5] = IDiamondProxy.executeLimitOffer.selector;
        lockedFunctions[6] = IDiamondProxy.internalTransferFromEntity.selector;
        lockedFunctions[7] = IDiamondProxy.payDividendFromEntity.selector;
        lockedFunctions[8] = IDiamondProxy.internalBurn.selector;
        lockedFunctions[9] = IDiamondProxy.wrapperInternalTransferFrom.selector;
        lockedFunctions[10] = IDiamondProxy.withdrawDividend.selector;
        lockedFunctions[11] = IDiamondProxy.withdrawAllDividends.selector;
        lockedFunctions[12] = IDiamondProxy.externalWithdrawFromEntity.selector;
        lockedFunctions[13] = IDiamondProxy.externalDeposit.selector;

        emit FunctionsLocked(lockedFunctions);
    }

    function _unlockAllFundTransferFunctions() internal {
        FunctionLockedStorage storage s = LibAppStorage.functionLockStorage();
        s.locked[IDiamondProxy.startTokenSale.selector] = false;
        s.locked[IDiamondProxy.paySimpleClaim.selector] = false;
        s.locked[IDiamondProxy.paySimplePremium.selector] = false;
        s.locked[IDiamondProxy.checkAndUpdateSimplePolicyState.selector] = false;
        s.locked[IDiamondProxy.cancelOffer.selector] = false;
        s.locked[IDiamondProxy.executeLimitOffer.selector] = false;
        s.locked[IDiamondProxy.internalTransferFromEntity.selector] = false;
        s.locked[IDiamondProxy.payDividendFromEntity.selector] = false;
        s.locked[IDiamondProxy.internalBurn.selector] = false;
        s.locked[IDiamondProxy.wrapperInternalTransferFrom.selector] = false;
        s.locked[IDiamondProxy.withdrawDividend.selector] = false;
        s.locked[IDiamondProxy.withdrawAllDividends.selector] = false;
        s.locked[IDiamondProxy.externalWithdrawFromEntity.selector] = false;
        s.locked[IDiamondProxy.externalDeposit.selector] = false;

        bytes4[] memory lockedFunctions = new bytes4[](14);
        lockedFunctions[0] = IDiamondProxy.startTokenSale.selector;
        lockedFunctions[1] = IDiamondProxy.paySimpleClaim.selector;
        lockedFunctions[2] = IDiamondProxy.paySimplePremium.selector;
        lockedFunctions[3] = IDiamondProxy.checkAndUpdateSimplePolicyState.selector;
        lockedFunctions[4] = IDiamondProxy.cancelOffer.selector;
        lockedFunctions[5] = IDiamondProxy.executeLimitOffer.selector;
        lockedFunctions[6] = IDiamondProxy.internalTransferFromEntity.selector;
        lockedFunctions[7] = IDiamondProxy.payDividendFromEntity.selector;
        lockedFunctions[8] = IDiamondProxy.internalBurn.selector;
        lockedFunctions[9] = IDiamondProxy.wrapperInternalTransferFrom.selector;
        lockedFunctions[10] = IDiamondProxy.withdrawDividend.selector;
        lockedFunctions[11] = IDiamondProxy.withdrawAllDividends.selector;
        lockedFunctions[12] = IDiamondProxy.externalWithdrawFromEntity.selector;
        lockedFunctions[13] = IDiamondProxy.externalDeposit.selector;

        emit FunctionsUnlocked(lockedFunctions);
    }
}
