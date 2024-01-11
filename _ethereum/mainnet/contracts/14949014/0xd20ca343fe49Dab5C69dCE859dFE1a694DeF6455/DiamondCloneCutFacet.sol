// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DiamondCloneLib.sol";
import "./AccessControlModifiers.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

contract DiamondCloneCutFacet is IDiamondCut, AccessControlModifiers {
    // NOTE: ownership must be set already so this is impossible
    // to call on the implementation instance
    //
    // NOTE: can only be called once
    // (enforced in the library via saw Address)
    function initializeDiamondClone(
        address diamondSawAddress,
        address[] calldata facetAddresses
    ) external onlyOwner {
        DiamondCloneLib.initializeDiamondClone(
            diamondSawAddress,
            facetAddresses
        );
    }

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override onlyOwner {
        require(
            !DiamondCloneLib.isImmutable(),
            "Cannot cut the diamond while immutable"
        );
        DiamondCloneLib.cutWithDiamondSaw(_diamondCut, _init, _calldata);
    }

    function setGasCacheForSelector(bytes4 selector) external onlyOperator {
        DiamondCloneLib.setGasCacheForSelector(selector);
    }

    function gasCacheForSelector(bytes4 selector)
        public
        view
        returns (address)
    {
        return DiamondCloneLib.diamondCloneStorage().selectorGasCache[selector];
    }

    function setImmutableUntilBlock(uint256 blockNumber) external onlyOwner {
        require(
            !DiamondCloneLib.isImmutable(),
            "Cannot set immutable block while immutable"
        );
        DiamondCloneLib.setImmutableUntilBlock(blockNumber);
    }

    function immutableUntilBlock() external view returns (uint256) {
        return DiamondCloneLib.immutableUntilBlock();
    }

    // to prevent this function from being called
    // use the immutability window
    function upgradeDiamondSaw(
        address _upgradeSaw,
        address[] calldata _oldFacetAddresses,
        address[] calldata _newFacetAddresses,
        address _init,
        bytes calldata _calldata
    ) external onlyOwner {
        DiamondCloneLib.upgradeDiamondSaw(
            _upgradeSaw,
            _oldFacetAddresses,
            _newFacetAddresses,
            _init,
            _calldata
        );
    }
}
