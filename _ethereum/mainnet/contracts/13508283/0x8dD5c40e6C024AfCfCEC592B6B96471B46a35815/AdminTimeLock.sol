// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IAddressLock.sol";
import "./IAddressRegistry.sol";
import "./IRevest.sol";
import "./ERC165.sol";

/**
 * @title
 * @dev
 */
contract AdminTimeLock is Ownable, IAddressLock, ERC165  {

    string public metadataURI = "https://revest.mypinata.cloud/ipfs/QmR9uFVk9fqKwzQHe6dvD4MNDMisJxv16PikxxJNuR6US5";

    address private registryAddress;

    mapping (uint => AdminLock) public locks;

    struct AdminLock {
        uint endTime;
        address admin;
    }

    constructor(address reg_) {
        registryAddress = reg_;
    }


    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IAddressLock).interfaceId
            || super.supportsInterface(interfaceId);
    }

    function isUnlockable(uint, uint lockId) public view override returns (bool) {
        return block.timestamp > locks[lockId].endTime;
    }


    // Create the lock within that contract DURING minting
    function createLock(uint, uint lockId, bytes memory arguments) external override {
        uint endTime;
        address admin;
        (endTime, admin) = abi.decode(arguments, (uint, address));

        // Check that we aren't creating a lock in the past
        require(block.timestamp < endTime, 'E002');

        AdminLock memory adminLock = AdminLock(endTime, admin);
        locks[lockId] = adminLock;
    }

    function updateLock(uint fnftId, uint lockId, bytes memory ) external override {
        // For an admin lock, there are no arguments
        if(_msgSender() == locks[lockId].admin) {
            IRevest revest = IRevest(IAddressRegistry(registryAddress).getRevest());
            // Utilize the ability of Address Locks to be push, pull, or in this case, both, to save gas
            revest.unlockFNFT(fnftId);
        }
    }

    function needsUpdate() external pure override returns (bool) {
        return true;
    }

    function getDisplayValues( uint, uint lockId) external view override returns (bytes memory) {
        uint endTime = locks[lockId].endTime;
        address admin = locks[lockId].admin;
        bool canUnlock = admin == _msgSender();
        return abi.encode(endTime, admin, canUnlock);
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

    function setMetadata(string memory _metadataURI) external onlyOwner {
        metadataURI = _metadataURI;
    }

    function getMetadata() external view override returns (string memory) {
        return metadataURI;
    }

}
