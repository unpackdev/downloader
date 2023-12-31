//SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.21;

import "./Ownable.sol";
import "./IRMRKMintaurRegistry.sol";
import "./IRMRKEquippableWithInitialAssets.sol";

error CollectionNotTracked();
error FailedToSend();
error MintingPeriodEnded();
error NotMintaur();
error WrongValueSent();

/**
 * @title RMRK Mint'aur
 * @notice This contract is used to create new RMRK collections
 */
contract RMRKMintaurRegistry is Ownable, IRMRKMintaurRegistry {
    address private _platformBeneficiary;
    address private _mintaur;

    mapping(address collection => bool deployed) private _deployedCollections;
    mapping(address collection => uint256 price) private _collectionMintPrice;
    mapping(address collection => uint256 fee) private _collectionMintFee;
    mapping(address collection => uint256 cutOffDate)
        private _collectionCutOffDate;
    mapping(address collection => address beneficiary)
        private _collectionBeneficiary;
    uint256 private _totalCollections;
    address[] private _collections;

    modifier onlyMintaur() {
        _checkOnlyMintaur();
        _;
    }

    /**
     * @notice Initializes the contract.
     * @param beneficiary The address of the beneficiary
     * @param mintaur The address of the mintaur
     */
    constructor(address beneficiary, address mintaur) {
        _platformBeneficiary = beneficiary;
        _mintaur = mintaur;
    }

    // -------------- GETTERS --------------

    /**
     * @notice Returns the address of the platform beneficiary.
     * @return beneficiary The address of the platform beneficiary
     */
    function getBeneficiary() public view returns (address) {
        return _platformBeneficiary;
    }

    /**
     * @notice Returns the address of the mintaur.
     * @return mintaur The address of the mintaur
     */
    function getMintaur() public view returns (address) {
        return _mintaur;
    }

    /**
     * @notice Returns the total number of collections.
     * @return totalCollections The total number of collections
     */
    function getTotalCollections() public view returns (uint256) {
        return _totalCollections;
    }

    // ---------- COLLECTION GETTERS ----------

    function getMintingPrice(address collection) public view returns (uint256) {
        return _collectionMintPrice[collection];
    }

    function getMintingFee(address collection) public view returns (uint256) {
        return _collectionMintFee[collection];
    }

    function getCollectionBeneficiary(
        address collection
    ) public view returns (address) {
        return _collectionBeneficiary[collection];
    }

    function getCollectionCutOffDate(
        address collection
    ) public view returns (uint256) {
        return _collectionCutOffDate[collection];
    }

    /**
     * @notice Returns the address of the collection at the given index.
     * @param index The index of the collection
     * @return collection The address of the collection
     */
    function getCollectionAtIndex(uint256 index) public view returns (address) {
        return _collections[index];
    }

    // -------------- ADMIN SETTERS --------------

    /**
     * @notice Sets the address of the beneficiary.
     * @param beneficiary The address of the beneficiary
     */
    function setBeneficiary(address beneficiary) public onlyOwner {
        _platformBeneficiary = beneficiary;
    }

    /**
     * @notice Sets the address of the mintaur.
     * @param mintaur The address of the mintaur
     */
    function setMintaur(address mintaur) public onlyOwner {
        _mintaur = mintaur;
    }

    function mint(
        address collection,
        address to,
        uint256 numToMint
    ) external payable onlyMintaur {
        if (!_deployedCollections[collection]) revert CollectionNotTracked();
        if (block.timestamp > _collectionCutOffDate[collection])
            revert MintingPeriodEnded();

        _chargeMint(collection, numToMint);
        IRMRKEquippableWithInitialAssets(collection).mint(to, numToMint);
    }

    function storeNewCollection(
        address collection,
        uint256 mintPrice,
        uint256 mintFee,
        address beneficiary,
        uint256 cutOffDate
    ) external onlyMintaur {
        _deployedCollections[collection] = true;
        _collectionMintPrice[collection] = mintPrice;
        _collectionMintFee[collection] = mintFee;
        _collectionBeneficiary[collection] = beneficiary;
        _collectionCutOffDate[collection] = cutOffDate;
        _totalCollections += 1;
        _collections.push(collection);
    }

    function _chargeMint(address collection, uint256 numToMint) private {
        uint256 price = _collectionMintPrice[collection] * numToMint;
        if (msg.value != price) revert WrongValueSent();
        uint256 platformFee = _collectionMintFee[collection] * numToMint;
        uint256 forBeneficiary = price - platformFee;

        (bool sent, bytes memory data) = _platformBeneficiary.call{
            value: platformFee
        }("");
        if (!sent) revert FailedToSend();
        (sent, data) = _collectionBeneficiary[collection].call{
            value: forBeneficiary
        }("");
        if (!sent) revert FailedToSend();
    }

    function _checkOnlyMintaur() private view {
        if (msg.sender != _mintaur) revert NotMintaur();
    }
}
