// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EnumerableSet.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract EstateRegistry {
    //function encodeTokenId(int x, int y) public returns (uint256) {}
    mapping(address => mapping(address => bool)) public updateManager;

    function ownerOf(uint256 tokenId) public view returns (address) {}

    function getEstateSize(uint256 estateId) external view returns (uint256) {}

    function getLandEstateId(uint256 landId) external view returns (uint256) {}

    function transferManyLands(
        uint256 estateId,
        uint256[] calldata landIds,
        address newOwner
    ) external {}

    function transferFrom(address from, address to, uint256 tokenId) public {}

    function setManyLandUpdateOperator(
        uint256 _estateId,
        uint256[] calldata _landIds,
        address _operator
    ) public {}
}

contract ContributorEstateManager is Ownable {
    // Add the library methods
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private contributorSet;

    mapping(uint256 => address) public entitlements;
    mapping(address => uint256[]) public contributorEntitlements;

    uint256 constant clearLow =
        0xffffffffffffffffffffffffffffffff00000000000000000000000000000000;
    uint256 constant clearHigh =
        0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff;
    uint256 constant factor = 0x100000000000000000000000000000000;

    bool public lockStatus;
    address public contributorAdmin;
    EstateRegistry public myEstateRegistry;

    constructor() {}

    function setEstateRegistry(address registry) external onlyOwner {
        myEstateRegistry = EstateRegistry(registry);
    }

    function getEstateSize(uint256 estateId) external view returns (uint256) {
        return myEstateRegistry.getEstateSize(estateId);
    }

    function transferEstate(
        uint256 estateId,
        address newOwner
    ) external onlyOwner {
        myEstateRegistry.transferFrom(address(this), newOwner, estateId);
    }

    function transferParcels(
        uint256 estateId,
        uint256[] calldata landIds,
        address newOwner
    ) external onlyOwner {
        myEstateRegistry.transferManyLands(estateId, landIds, newOwner);
    }

    function setManyLandUpdateOperator(
        uint256 estateId,
        uint256[] calldata landIds,
        address operator
    ) external onlyContributor {
        checkThisContractOwnsOrManagesEstate(estateId);
        checkValidityOfLandsRequested(estateId, landIds);
        myEstateRegistry.setManyLandUpdateOperator(estateId, landIds, operator);
    }

    function claimParcels(
        uint256 estateId,
        uint256[] calldata landIds
    ) external onlyContributor {
        checkThisContractOwnsEstate(estateId);
        checkValidityOfLandsRequested(estateId, landIds);
        myEstateRegistry.transferManyLands(estateId, landIds, msg.sender);
    }

    function checkValidityOfLandsRequested(
        uint256 estateId,
        uint256[] calldata landIds
    ) private view {
        // require that msg.sender is entitled  to received all landIds from the estate
        for (uint i = 0; i < landIds.length; ) {
            require(
                entitlements[landIds[i]] == msg.sender,
                "Attempt to transact on one or more LANDs without entitlement."
            );
            require(
                myEstateRegistry.getLandEstateId(landIds[i]) == estateId,
                "Attempt to transact on one or more LANDs that does not belong to the estate."
            );
            unchecked {
                ++i;
            }
        }
    }

    function checkThisContractOwnsOrManagesEstate(
        uint256 estateId
    ) private view {
        // check that this contract instance owns or manages the estate that the user is trying to claim from
        require(
            getEstateOwner(estateId) == address(this) ||
                myEstateRegistry.updateManager(
                    getEstateOwner(estateId),
                    address(this)
                ),
            "Attempt to transact on LANDs in an estate that is not owned or managed by this contract."
        );
    }

    function checkThisContractOwnsEstate(uint256 estateId) private view {
        // check that this contract instance owns the estate that the user is trying to claim from
        require(
            getEstateOwner(estateId) == address(this),
            "Attempt to transact on LANDs in an estate that is not owned by this contract."
        );
    }

    function setContributorAdmin(address _contributorAdmin) public onlyOwner {
        contributorAdmin = _contributorAdmin;
    }

    modifier onlyContributor() {
        require(
            contributorSet.contains(_msgSender()),
            "Only Contributor can call"
        );
        _;
    }
    modifier onlyOwnerOrContributor() {
        require(
            (contributorSet.contains(_msgSender()) || owner() == _msgSender()),
            "Only Owner or Contributor can call"
        );
        _;
    }
    modifier canUpdateContributors() {
        require(!lockStatus, "Modification to contributors is disabled.");
        _;
    }
    modifier onlyContributorAdmin() {
        require(
            _msgSender() == contributorAdmin,
            "Only ContributorAdmin can call"
        );
        _;
    }
    modifier onlyOwnerOrContributorAdmin() {
        require(
            _msgSender() == contributorAdmin || owner() == _msgSender(),
            "Only Owner or ContributorAdmin can call"
        );
        _;
    }

    /**
     * @dev Adds the entire array to the contributors set
     *
     * WARNING: This operation will copy the entire memory to storage, which can be quite expensive. Keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the contributors array is too big such that it consumes too much gas to fit in a block.
     */
    function addContributors(
        address[] calldata contributors
    ) public onlyContributorAdmin canUpdateContributors {
        for (uint i = 0; i < contributors.length; ) {
            contributorSet.add(contributors[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Adds the entire array to the contributors set
     *
     * WARNING: This operation will copy the entire memory to storage, which can be quite expensive. Keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the contributors array is too big such that it consumes too much gas to fit in a block.
     */
    function removeContributors(
        address[] calldata walletAddresses
    ) public onlyContributorAdmin {
        for (uint i = 0; i < walletAddresses.length; ) {
            contributorSet.remove(walletAddresses[i]);
            removeAllEntitlements(walletAddresses[i]);
            unchecked {
                ++i;
            }
        }
    }

    function isContributor(address walletAddress) public view returns (bool) {
        return contributorSet.contains(walletAddress);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function getContributors() public view returns (address[] memory) {
        return contributorSet.values();
    }

    function disableModification() public onlyOwner {
        lockStatus = true;
    }

    function addEntitlement(
        address walletAddress,
        uint256 landId
    ) public onlyContributorAdmin {
        entitlements[landId] = walletAddress;
        contributorEntitlements[walletAddress].push(landId);
    }

    function addEntitlements(
        address walletAddress,
        uint256[] calldata landIds
    ) public onlyContributorAdmin {
        for (uint i = 0; i < landIds.length; i++) {
            addEntitlement(walletAddress, landIds[i]);
        }
    }

    /**
     * @dev Removes a single record from the entitlements mapping via its key
     *
     */
    function removeFromEntitlements(uint256 landId) internal {
        delete entitlements[landId];
    }

    /**
     * @dev Removes all records from the contributorEntitlements mapping for a given wallet address
     *
     */
    function removeFromContributorEntitlements(address walletAddress) internal {
        delete contributorEntitlements[walletAddress];
    }

    /**
     * @dev Removes a single landId from the contributorEntitlements mapping for a given wallet address
     *
     * Moves the landId to be deleted to the last position in the array and pops it to prevent a gap in the array.
     */
    function removeFromContributorEntitlements(
        address walletAddress,
        uint256 landId
    ) internal {
        for (
            uint256 i = 0;
            i < contributorEntitlements[walletAddress].length;
            i++
        ) {
            uint256 currentLandId = contributorEntitlements[walletAddress][i];
            if (landId == currentLandId) {
                // Move the last element into the place to delete
                contributorEntitlements[walletAddress][
                    i
                ] = contributorEntitlements[walletAddress][
                    contributorEntitlements[walletAddress].length - 1
                ];
                // Remove the last element
                contributorEntitlements[walletAddress].pop();
                break;
            }
        }
    }

    /**
     * @dev ContributorAdmin method to remove a single entitlement for a given wallet address
     *
     */
    function removeEntitlement(
        address walletAddress,
        uint256 landId
    ) public onlyContributorAdmin {
        removeFromEntitlements(landId);
        removeFromContributorEntitlements(walletAddress, landId);
    }

    /**
     * @dev ContributorAdmin method to remove a list of entitlements for a given wallet address
     *
     */
    function removeEntitlements(
        address walletAddress,
        uint256[] calldata landIds
    ) public onlyContributorAdmin {
        for (uint256 i = 0; i < landIds.length; i++) {
            removeEntitlement(walletAddress, landIds[i]);
        }
    }

    /**
     * @dev ContributorAdmin method to remove all entitlements for a given wallet address
     *
     */
    function removeAllEntitlements(
        address walletAddress
    ) public onlyContributorAdmin {
        uint256[] memory landIdsToRemove = contributorEntitlements[
            walletAddress
        ];
        for (uint256 i = 0; i < landIdsToRemove.length; i++) {
            removeFromEntitlements(i);
        }
        removeFromContributorEntitlements(walletAddress);
    }

    function getEntitlements() public view returns (uint256[] memory) {
        return contributorEntitlements[msg.sender];
    }

    function getEstateOwner(uint256 tokenId) public view returns (address) {
        return myEstateRegistry.ownerOf(tokenId);
    }

    function isUpdateManager(uint256 tokenId) public view returns (bool) {
        return
            myEstateRegistry.updateManager(
                getEstateOwner(tokenId),
                address(this)
            );
    }

    function getContributorEntitlementCounts()
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        address[] memory addresses = contributorSet.values();
        uint256[] memory entitlementCounts = new uint256[](addresses.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            address currentAddress = addresses[i];
            entitlementCounts[i] = contributorEntitlements[currentAddress]
                .length;
        }

        return (addresses, entitlementCounts);
    }

    /**
     * @dev Returns three arrays.
     * First contains the encoded landIds of the entitlement
     * Second contains an array twice the length of the first, representing a pair of coordinates
     * for each id in the first array i.e. [x,y,x,y,x,y...]
     * Third contains and ordered list of the relevent estate ids
     */
    function getEntitlementsByWalletAddress(address walletAddress) public view returns (uint256[] memory, string[] memory, uint256[] memory){
        uint256[] memory encoded = contributorEntitlements[walletAddress];
        uint256[] memory estateIds = new uint256[](encoded.length);
        for(uint256 i = 0; i < encoded.length; i++) {
            estateIds[i] = myEstateRegistry.getLandEstateId(encoded[i]);
        }
        string[] memory decoded = new string[](encoded.length);
        for (uint256 i = 0; i < encoded.length; i++) {
            int x;
            int y;
            (x,y) = _decodeTokenId(encoded[i]);
            decoded[i] = string.concat(Strings.toString(x),",",Strings.toString(y));

        }
        return (encoded, decoded, estateIds);
    }

    function encodeTokenId(int x, int y) external pure returns (uint) {
        return _encodeTokenId(x, y);
    }

    function _encodeTokenId(int x, int y) internal pure returns (uint result) {
        require(
            -1000000 < x && x < 1000000 && -1000000 < y && y < 1000000,
            "The coordinates should be inside bounds"
        );
        return _unsafeEncodeTokenId(x, y);
    }

    function _unsafeEncodeTokenId(int x, int y) internal pure returns (uint) {
        return ((uint(x) * factor) & clearLow) | (uint(y) & clearHigh);
    }

    function decodeTokenId(uint value) external pure returns (int, int) {
        return _decodeTokenId(value);
    }

    function _unsafeDecodeTokenId(
        uint value
    ) internal pure returns (int x, int y) {
        x = expandNegative128BitCast((value & clearLow) >> 128);
        y = expandNegative128BitCast(value & clearHigh);
    }

    function _decodeTokenId(uint value) internal pure returns (int x, int y) {
        (x, y) = _unsafeDecodeTokenId(value);
        require(
            -1000000 < x && x < 1000000 && -1000000 < y && y < 1000000,
            "The coordinates should be inside bounds"
        );
    }

    function expandNegative128BitCast(uint value) internal pure returns (int) {
        if (value & (1 << 127) != 0) {
            return int(value | clearLow);
        }
        return int(value);
    }
}
