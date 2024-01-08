// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IAddressLock.sol";
import "./IAddressRegistry.sol";
import "./IRevest.sol";
import "./ITokenVault.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ERC165.sol";

contract SupplyLock is Ownable, IAddressLock, ERC165  {

    address private registryAddress;
    mapping(uint => SupplyLockDetails) private locks;

    struct SupplyLockDetails {
        uint supplyLevels;
        address asset;
        bool isLockRisingEdge;
    }

    using SafeERC20 for IERC20;

    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IAddressLock).interfaceId
            || super.supportsInterface(interfaceId);
    }

    function isUnlockable(uint fnftId, uint lockId) public view override returns (bool) {
        address asset = locks[lockId].asset;
        uint supply = locks[lockId].supplyLevels;
        if (locks[lockId].isLockRisingEdge) {
            return IERC20(asset).totalSupply() > supply;
        } else {
            return IERC20(asset).totalSupply() < supply;
        }
    }

    function createLock(uint fnftId, uint lockId, bytes memory arguments) external override {
        uint supply;
        bool isRisingEdge;
        address asset;
        (supply, asset, isRisingEdge) = abi.decode(arguments, (uint, address, bool));
        locks[lockId].supplyLevels = supply;
        locks[lockId].isLockRisingEdge = isRisingEdge;
        locks[lockId].asset = asset;
    }

    function updateLock(uint fnftId, uint lockId, bytes memory arguments) external override {}

    function needsUpdate() external pure override returns (bool) {
        return false;
    }

    function setAddressRegistry(address _revest) external override onlyOwner {
        registryAddress = _revest;
    }

    function getAddressRegistry() external view override returns (address) {
        return registryAddress;
    }

    function getRevest() private view returns (IRevest) {
        return IRevest(getRegistry().getRevest());
    }

    function getRegistry() public view returns (IAddressRegistry) {
        return IAddressRegistry(registryAddress);
    }

    function getMetadata() external pure override returns (string memory) {
        return "https://revest.mypinata.cloud/ipfs/QmWQWvdpn4ovFEZxYXEqtcGdCCmpwf2FCwDUdh198Fb62g";
    }

    function getDisplayValues(uint fnftId, uint lockId) external view override returns (bytes memory) {
        SupplyLockDetails memory lockDetails = locks[lockId];
        return abi.encode(lockDetails.supplyLevels, lockDetails.asset, lockDetails.isLockRisingEdge);
    }
}
