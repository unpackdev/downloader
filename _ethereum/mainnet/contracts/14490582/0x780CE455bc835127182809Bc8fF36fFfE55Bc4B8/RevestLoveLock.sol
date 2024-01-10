// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

import "./IAddressLock.sol";
import "./IAddressRegistry.sol";
import "./IRevest.sol";
import "./ERC165.sol";
import "./SecuredAddressLock.sol";


contract LoveLock is SecuredAddressLock, ERC165  {

    address private registryAddress;
    mapping(uint => string) public locks;

    constructor(address reg_) SecuredAddressLock(reg_) {}

    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IAddressLock).interfaceId
            || super.supportsInterface(interfaceId);
    }

    function isUnlockable(uint, uint) public pure override returns (bool) {
        return false;
    }

    function createLock(uint, uint lockId, bytes memory arguments) external override onlyRevestController {
        require(bytes(locks[lockId]).length == 0, 'E077');
        string memory message;
        (message) = abi.decode(arguments, (string));
        locks[lockId] = message;
    }

    function updateLock(uint fnftId, uint lockId, bytes memory arguments) external override {}

    function needsUpdate() external pure override returns (bool) {
        return false;
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

    function getDisplayValues(uint, uint lockId) external view override returns (bytes memory) {
        return abi.encode(locks[lockId]);
    }
}
