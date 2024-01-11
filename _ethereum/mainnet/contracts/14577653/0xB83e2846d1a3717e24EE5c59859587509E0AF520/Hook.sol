// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <0.9.0;

import "./IPublicLockV10.sol";
import "./Strings.sol";
import "./Base64.sol";
import "./console.sol";
import "./Layer.sol";
import "./BokkyPooBahsDateTimeLibrary.sol";

/**
 * @notice Functions to be implemented by a tokenURIHook.
 * @dev Lock hooks are configured on the lock contract by calling `setEventHooks` on the lock.
 */
contract Hook {
    address public _avatarLock;
    address public _buntaiLock;
    address public _gundanLock;
    address public _mappingContract;
    string public _ipfsHash;

    /**
     * The hook is initialized with each lock contract as well as each layer contract
     */
    constructor(
        address avatarLock,
        address buntaiLock,
        address gundanLock,
        address mappingContract,
        string memory ipfsHash
    ) {
        _avatarLock = avatarLock;
        _buntaiLock = buntaiLock;
        _gundanLock = gundanLock;
        _mappingContract = mappingContract;
        _ipfsHash = ipfsHash;
    }

    /**
     * Not altering the price by default
     */
    function keyPurchasePrice(
        address, /* from */
        address, /* recipient */
        address, /* referrer */
        bytes calldata /* data */
    ) external view returns (uint256 minKeyPrice) {
        // TODO Let's look at the list? 
        return IPublicLock(msg.sender).keyPrice();
    }

    /**
     * When a new key is purchased, we need to grant a weapon
     * Challenge: we
     */
    function onKeyPurchase(
        address, /*from*/
        address recipient,
        address, /*referrer*/
        bytes calldata, /*data*/
        uint256, /*minKeyPrice*/
        uint256 /*pricePaid*/
    ) external {
        if (msg.sender == _avatarLock) {
            // If the sender is the avatar lock
            IPublicLock avatar = IPublicLock(_avatarLock);
            uint id = avatar.totalSupply();

            address[] memory recipients = new address[](1);
            recipients[0] = recipient;

            uint[] memory expirations = new uint[](1);
            expirations[0] = type(uint256).max; // Not expiring!

            address[] memory managers = new address[](1);
            managers[0] = recipient;

            if (id % 2 == 0) {
                IPublicLock(_buntaiLock).grantKeys(recipients, expirations, managers);
            } else {
                IPublicLock(_gundanLock).grantKeys(recipients, expirations, managers);
            }
        }
    }

    // see https://github.com/unlock-protocol/unlock/blob/master/smart-contracts/contracts/interfaces/hooks/IHook.sol
    function tokenURI(
        address, // lockAddress,
        address, // operator, // We could alter the rendering based on _who_ is viewing!
        address, // owner,
        uint256, // keyId,
        uint256  //expirationTimestamp //  a cool trick could be to render based on how far the expiration of the key is!
    ) external view returns (string memory) {

        // uint timeOfDay = 0;
        // string memory kind = "";
        string memory image = "QmYkkshevBxHg7XwdP1pw6A4T82xzD8G2RpLDFo6KDy3zm";

        // (, , , uint hour, , ) = BokkyPooBahsDateTimeLibrary.timestampToDateTime(block.timestamp);
        // if (hour <= 8) {
        //     timeOfDay = 0; // 0 => night
        // } else if (hour <= 17) {
        //     timeOfDay = 1; // 1 => day
        // } else if (hour <= 21) {
        //     timeOfDay = 2; // 2 => sunset
        // } else {
        //     timeOfDay = 0; // 0 => night
        // }

        // // If the calling contract is the avatar contract
        // if (lockAddress == _avatarLock) {
        //     kind = "avatars";
        //     uint weapon = 0;

        //     // Check if there is a mapping!
        //     if (avatarsWeapons[keyId] > 0) {
        //         // If there is one, let's check the owner and make sure it's the correct one
        //         IPublicLock weaponLock = IPublicLock(_weaponLock);
        //         // TODO change me in v10!
        //         uint weaponExpiration = weaponLock.keyExpirationTimestampFor(owner);
        //         address weaponOwner = weaponLock.ownerOf(keyId);
        //         if (weaponExpiration > block.timestamp && weaponOwner == owner) {
        //             weapon = avatarsWeapons[keyId];
        //         }
        //     }

        //     image = string(
        //         abi.encodePacked(
        //             _ipfsHash,
        //             "/",
        //             kind,
        //             "/",
        //             Strings.toString(keyId),
        //             "-",
        //             Strings.toString(weapon),
        //             "-",
        //             Strings.toString(timeOfDay)
        //         )
        //     );
        // }
        // else if (lockAddress == _weaponLock) {
        //     kind = "weapons";

        //     image = string(
        //         abi.encodePacked(
        //             _ipfsHash,
        //             "/",
        //             kind,
        //             "/",
        //             Strings.toString(keyId)
        //         )
        //     );

        // }


        // create the json that includes the image
        // We need to include more properties!
        string memory json = string(
            abi.encodePacked('{"image":"', image, '"}')
        );

        // render the base64 encoded json metadata
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(bytes(abi.encodePacked(json)))
                )
            );
    }
}
