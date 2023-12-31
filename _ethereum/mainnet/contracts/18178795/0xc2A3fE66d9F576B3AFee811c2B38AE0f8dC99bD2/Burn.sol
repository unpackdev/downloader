// SPDX-License-Identifier: MIT
// @author: NFT Studios

pragma solidity ^0.8.21;

import "./Strings.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./ITrait.sol";
import "./Avatar.sol";
import "./Heroines.sol";

contract HackataoBurn is Ownable {
    using Strings for uint256;

    enum Type {
        avatar, // 0
        background, // 1
        crown, // 2
        hair, // 3
        face, // 4
        eyes, // 5
        mouth, // 6
        beard, // 7
        body, // 8
        dress, // 9
        extra, // 10
        heroines // 11
    }

    address public signerAddress;

    address private constant DEAD_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    Avatar private avatarContract;
    Heroines private heroinesContract;

    mapping(Type => address) traitTypeToAddress;
    mapping(bytes16 => uint16) public rarityStringToMaxQuantity;
    mapping(bytes16 => uint16) public rarityStringToBurnedQuantity;

    event BurnedAssets(
        address indexed _owner,
        uint8[] _types,
        uint256[] _tokenIds
    );

    constructor(
        address[] memory tokenContracts,
        bytes16[] memory rarityStrings,
        uint16[] memory maxQuantities
    ) {
        avatarContract = Avatar(tokenContracts[0]);
        traitTypeToAddress[Type.background] = tokenContracts[1];
        traitTypeToAddress[Type.crown] = tokenContracts[2];
        traitTypeToAddress[Type.hair] = tokenContracts[3];
        traitTypeToAddress[Type.face] = tokenContracts[4];
        traitTypeToAddress[Type.eyes] = tokenContracts[5];
        traitTypeToAddress[Type.mouth] = tokenContracts[6];
        traitTypeToAddress[Type.beard] = tokenContracts[7];
        traitTypeToAddress[Type.body] = tokenContracts[8];
        traitTypeToAddress[Type.dress] = tokenContracts[9];
        traitTypeToAddress[Type.extra] = tokenContracts[10];
        heroinesContract = Heroines(tokenContracts[11]);

        require(
            rarityStrings.length == maxQuantities.length,
            "RarityString and MaxQuantity must be the same length"
        );

        for (uint256 i = 0; i < rarityStrings.length; i++) {
            rarityStringToMaxQuantity[rarityStrings[i]] = maxQuantities[i];
        }
    }

    function burn(
        uint8[] memory _types,
        uint256[] memory _tokenIds,
        bytes16[] calldata _codes,
        bytes calldata _signature
    ) external {
        require(
            _types.length == _tokenIds.length && _types.length == _codes.length,
            "Burn: Types and tokenIds must be the same length"
        );

        bytes32 messageHash = generateMessageHash(_types, _tokenIds, _codes);
        address recoveredWallet = ECDSA.recover(messageHash, _signature);

        require(
            recoveredWallet == signerAddress,
            "Burn: Invalid signature for the caller"
        );

        for (uint256 i = 0; i < _types.length; i++) {
            if (_types[i] == uint8(Type.avatar)) {
                burnAvatar(_tokenIds[i], _codes[i]);
            } else if (_types[i] == uint8(Type.heroines)) {
                burnHeroines(_tokenIds[i], _codes[i]);
            } else {
                burnTrait(_types[i], _tokenIds[i], _codes[i]);
            }
        }

        emit BurnedAssets(msg.sender, _types, _tokenIds);
    }

    function burnHeroines(uint256 _tokenId, bytes16 _code) internal {
        require(
            rarityStringToBurnedQuantity[_code] <
                rarityStringToMaxQuantity[_code],
            "Burn: Max token burned"
        );

        rarityStringToBurnedQuantity[_code]++;
        heroinesContract.transferFrom(msg.sender, DEAD_ADDRESS, _tokenId);
    }

    function burnAvatar(uint256 _tokenId, bytes16 _code) internal {
        require(
            rarityStringToBurnedQuantity[_code] <
                rarityStringToMaxQuantity[_code],
            "Burn: Max token burned"
        );

        uint256 originalTokenId = avatarContract.externalToInternalMapping(
            _tokenId
        );

        uint16 originalParsedId = uint16(originalTokenId);

        require(
            avatarContract.hasMintedTraits(originalParsedId),
            "Burn: Traits have not been minted"
        );

        uint16[] memory avatarTraits = avatarContract.getAvatarTraits(_tokenId);

        bool hasAttachedTraits = false;

        for (uint8 i = 0; i < avatarTraits.length; i++) {
            if (avatarTraits[i] != 0) {
                hasAttachedTraits = true;
                break;
            }
        }

        require(
            !hasAttachedTraits,
            "Burn: The avatar should not have any traits attached"
        );

        rarityStringToBurnedQuantity[_code]++;
        avatarContract.transferFrom(msg.sender, DEAD_ADDRESS, _tokenId);
    }

    function burnTrait(uint8 _type, uint256 _tokenId, bytes16 _code) internal {
        require(
            rarityStringToBurnedQuantity[_code] <
                rarityStringToMaxQuantity[_code],
            "Burn: Max token burned"
        );

        ITrait traitContract = ITrait(traitTypeToAddress[Type(_type)]);

        uint16 tokenId = uint16(_tokenId);

        require(
            traitContract.traitToExternalAvatarID(tokenId) == 0,
            "Burn: The trait should not be attached to any avatar"
        );

        rarityStringToBurnedQuantity[_code]++;
        traitContract.transferFrom(msg.sender, DEAD_ADDRESS, tokenId);
    }

    /**
     * @dev Sets the address that generates the signatures for whitelisting
     */
    function setSignerAddress(address _signerAddress) external onlyOwner {
        signerAddress = _signerAddress;
    }

    /**
     * @dev Generate a message hash for the given parameters
     */
    function generateMessageHash(
        uint8[] memory _types,
        uint256[] memory _tokenIds,
        bytes16[] memory _codes
    ) internal view returns (bytes32) {
        bytes32 _hash = keccak256(
            bytes.concat(
                abi.encodePacked(
                    address(this),
                    msg.sender,
                    _types,
                    _tokenIds,
                    _codes
                )
            )
        );
        bytes memory result = abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            _hash
        );

        return keccak256(result);
    }
}
