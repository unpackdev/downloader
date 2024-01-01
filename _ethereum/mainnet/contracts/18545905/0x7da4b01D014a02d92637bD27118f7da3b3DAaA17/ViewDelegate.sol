// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./EnumerableSet.sol";
import "./Ownable.sol";
import "./VaultManager.sol";

contract ViewDelegate is Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    VaultManager public immutable vault;
    // delegate => colorset
    mapping(address delegate => EnumerableSet.UintSet) internal delegateColorSet;
    // superViwer => bool, superViwer can view all colors on website
    mapping(address superViewer => bool) public isSuperViewer;

    constructor(address _vault) {
        vault = VaultManager(_vault);
    }

    function addDelegate(uint32 _color, address _delegate) external {
        require(msg.sender == getColorOwner(_color), "ViewDelegate: only vault");
        delegateColorSet[_delegate].add(_color);
    }

    function getColorOwner(uint32 _color) internal view returns (address) {
        (address colorOwner, , ) = vault.colorToMinter(_color);
        return colorOwner;
    }

    function removeDelegate(uint32 _color, address _delegate) external {
        require(msg.sender == getColorOwner(_color), "ViewDelegate: only vault");
        delegateColorSet[_delegate].remove(_color);
    }

    function addSuperViewer(address _superViewer) external onlyOwner {
        require(!isSuperViewer[_superViewer], "ViewDelegate: already super viewer");
        isSuperViewer[_superViewer] = true;
    }

    function removeSuperViewer(address _superViewer) external onlyOwner {
        require(isSuperViewer[_superViewer], "ViewDelegate: not super viewer");
        isSuperViewer[_superViewer] = false;
    }

    function isAllowed(uint32 _color, address _viewer) external view returns (bool) {
        // is delegate
        if (delegateColorSet[_viewer].contains(_color)) return true;
        // or color owner itself
        if (msg.sender == getColorOwner(_color)) return true;
        return false;
    }

    function allColors(address _address) external view returns (uint[] memory) {
        return delegateColorSet[_address].values();
    }
}
