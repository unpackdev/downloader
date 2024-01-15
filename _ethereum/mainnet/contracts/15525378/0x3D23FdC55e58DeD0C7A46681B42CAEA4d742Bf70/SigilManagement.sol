// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./Ownable.sol";
import "./BitMaps.sol";
import "./IHashes.sol";
import "./ICollectionNFTEligibilityPredicate.sol";
import "./ICollectionNFTMintFeePredicate.sol";
import "./ICollectionNFTCloneableV1.sol";

/**
 * @title  SigilManagement
 * @author Cooki.eth
 * @notice This contract defines both the mint price and mint elibility for the
 *         Sigils NFT collections. It is ownable, and active Sigil collections
 *         must be activated by the owner in order for Sigils to be minted. The 
 *         owner may also de-activate collections.
 */
contract SigilManagement is Ownable, ICollectionNFTEligibilityPredicate, ICollectionNFTMintFeePredicate {
    /// @notice The Hashes address.
    IHashes public hashes;

    /// @notice activeSigils Mapping of currently active Sigil addresses.
    mapping(ICollectionNFTCloneableV1 => bool) public activeSigils;

    /// @notice activeSigilsList Array of currently active Sigil addresses.
    ICollectionNFTCloneableV1[] public activeSigilsList;

    //The mapping (uint256 => bool) of non-DAO hashes used to mint.
    BitMaps.BitMap mintedStandardHashesTokenIds;

    /// @notice SigilActivated Emitted when a Sigil address is activated.
    event SigilActivated(ICollectionNFTCloneableV1 indexed _sigilAddress);

    /// @notice SigilDeactivated Emitted when a Sigil address is deactivated.
    event SigilDeactivated(ICollectionNFTCloneableV1 indexed _sigilAddress);

    /**
     * @notice Constructor for the Sigil Management contract. The ownership is transfered
     *         and the Hashes collection is defined.
     */
    constructor(IHashes _hashesAddress, address _sigilsManagementOwner) {
        transferOwnership(_sigilsManagementOwner);
        hashes = _hashesAddress;
    }

    /**
     * @notice  This predicate function is used to determine the mint fee of a hashes token Id for
     *          a Sigil collection. It will always returns a value of 0.
     * @param _tokenId The token Id of the associated hashes collection contract.
     * @param _hashesTokenId The Hashes token Id being used to mint.
     *
     * @return The uint256 result of the mint fee.
     */
    function getTokenMintFee(uint256 _tokenId, uint256 _hashesTokenId) external view override returns (uint256) {
        return 0;
    }

    /**
     * @notice  This predicate function is used to determine the mint eligibility of a hashes token Id for
     *          a Sigil collection. In order to do this the function first checks if the collection is an active Sigil
     *          collection. If it is not, then minting is prohibited. If it is, then it checks if the hashes token Id
     *          is a DAO hash or a non-DAO hash. All DAO hashes are eligible to mint from any active Sigil collection.
     *          Non-DAO hashes, however, are only eligible to mint a single Sigil NFT ever. Thus, if the hashes token
     *          Id represents a non-DAO hash the function then checks if it has ever been used to mint another Sigil
     *          NFT, and if it hasn't, it is eligible to mint.
     * @param _tokenId The token Id of the associated hashes collection contract.
     * @param _hashesTokenId The Hashes token Id being used to mint.
     *
     * @return The boolean result of the validation.
     */
    function isTokenEligibleToMint(uint256 _tokenId, uint256 _hashesTokenId) external view override returns (bool) {
        if (!activeSigils[ICollectionNFTCloneableV1(msg.sender)]) {
            return false;
        }

        if (_hashesTokenId < hashes.governanceCap()) {
            return true;
        }

        //If non-DAO hash has already been used then return false
        if (BitMaps.get(mintedStandardHashesTokenIds, _hashesTokenId)) {
            return false;
        }

        //Iterates over sigil list array to check if the non-DAO hash has been used before; if yes return false
        for (uint256 i = 0; i < activeSigilsList.length; i++) {
            if (getMappingExists(_hashesTokenId, activeSigilsList[i])) {
                return false;
            }
        }

        return true;
    }

    /**
     * @notice This function allows the Sigil Management contract owner to activate an array of
     *         ICollectionNFTCloneableV1 Sigil contract addresses.
     * @param _addresses An array of inactive ICollectionNFTCloneableV1 Sigil addresses.
     */
    function activateSigils(ICollectionNFTCloneableV1[] memory _addresses) public onlyOwner {
        require(_addresses.length > 0, "SigilManagement: no Sigil addresses provided.");

        for (uint256 j = 0; j < _addresses.length; j++) {
            require(!activeSigils[_addresses[j]], "SigilManagement: Sigil address already exists.");

            activeSigilsList.push(ICollectionNFTCloneableV1(_addresses[j]));

            activeSigils[_addresses[j]] = true;

            emit SigilActivated(_addresses[j]);
        }
    }

    /**
     * @notice This function allows the Sigil Management contract owner to deactivate an array of
     *         ICollectionNFTCloneableV1 Sigil contract addresses. In order to do this the Sigils
     *         Management contract owner must also provide, in addition to an array of
     *         ICollectionNFTCloneableV1 addresses, an array of arrays of hashes token Ids that have
     *         been used to mint a Sigil in the corresponding collection. The hashes token Ids must be
     *         provided in a monotonically increasing order.
     * @param _addresses An array of active ICollectionNFTCloneableV1 Sigil addresses.
     * @param _hashesIds An array of arrays of hashes token Ids that have minted Sigil NFTS. Each array
     *         of hashes token Ids must correspond to the ICollectionNFTCloneableV1 Sigil address.
     */
    function deactivateSigils(ICollectionNFTCloneableV1[] memory _addresses, uint256[][] memory _hashesIds)
        public
        onlyOwner
    {
        require(_addresses.length > 0, "SigilManagement: no Sigil addresses provided.");

        require(
            _addresses.length == _hashesIds.length,
            "SigilManagement: number of addresses not equal to the number of hashesIds arrays."
        );

        for (uint256 j = 0; j < _addresses.length; j++) {
            require(activeSigils[_addresses[j]], "SigilManagement: Sigil address doesn't exist.");

            require(
                ICollectionNFTCloneableV1(_addresses[j]).nonce() == _hashesIds[j].length,
                "SigilManagement: minted Sigils not equal to the number of hashes ids provided."
            );

            for (uint256 k = 0; k < _hashesIds[j].length; k++) {
                if (k > 0) {
                    require(
                        _hashesIds[j][k - 1] < _hashesIds[j][k],
                        "SigilManagement: hashes ids array provided is not monotonically increasing."
                    );
                }

                //Checks if the _hashes id has been used to mint a sigil and if it's a non-DAO hash
                if (
                    getMappingExists(_hashesIds[j][k], ICollectionNFTCloneableV1(_addresses[j])) &&
                    (_hashesIds[j][k] > hashes.governanceCap())
                ) {
                    //If yes, then add the mapping to mintedStandardHashesTokenIds BitMap
                    BitMaps.set(mintedStandardHashesTokenIds, _hashesIds[j][k]);
                }
            }

            //Then iterates over the activeSigilsList array and deletes the relevant entry
            for (uint256 l = 0; l < activeSigilsList.length; l++) {
                if (activeSigilsList[l] == ICollectionNFTCloneableV1(_addresses[j])) {
                    activeSigilsList[l] = activeSigilsList[(activeSigilsList.length - 1)];

                    activeSigilsList.pop();
                }
            }

            delete activeSigils[_addresses[j]];

            emit SigilDeactivated(_addresses[j]);
        }
    }

    function getMappingExists(uint256 _hashesID, ICollectionNFTCloneableV1 _address) private view returns (bool) {
        (bool exists, ) = _address.hashesIdToCollectionTokenIdMapping(_hashesID);
        return exists;
    }
}
