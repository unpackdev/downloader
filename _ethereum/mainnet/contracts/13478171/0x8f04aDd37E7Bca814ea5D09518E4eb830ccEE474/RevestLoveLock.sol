// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IAddressLock.sol";
import "./IAddressRegistry.sol";
import "./IRevest.sol";
import "./ERC165.sol";

contract LoveLock is Ownable, IAddressLock, ERC165  {

    address private registryAddress;
    mapping(uint => string) public locks;

    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IAddressLock).interfaceId
            || super.supportsInterface(interfaceId);
    }

    function isUnlockable(uint fnftId, uint lockId) public pure override returns (bool) {
        return false;
    }

    function createLock(uint fnftId, uint lockId, bytes memory arguments) external override {
        string memory message;
        (message) = abi.decode(arguments, (string));
        locks[lockId] = message;
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
        return "https://revest.mypinata.cloud/ipfs/QmV51sTPtGxmbE3PLY6rWMQp9GeatmfSJeefjhEw2hDiQ4";
    }

    function getDisplayValues(uint fnftId, uint lockId) external view override returns (bytes memory) {
        return abi.encode(locks[lockId]);
    }
}
