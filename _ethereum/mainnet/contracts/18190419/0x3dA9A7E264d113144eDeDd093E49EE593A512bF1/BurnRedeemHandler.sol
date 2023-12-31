// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Upgradeable.sol";
import "./INFTify721.sol";
import "./INFTify1155.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ECDSA.sol";

struct Items {
    uint256 id; // NFT tokenID
    uint256 quantity; // NFT number of copies
    uint256 tokenType; // ERC1155: 0, ERC721: 1
    address collection; // collection address of NFT
}

struct BurnRedeemComponent {
    Items[] burnItems;
    Items[] redeemItems;
    address receiver; // address of caller
    uint256 redeemTimes; // number of redeem times
    uint256 totalRedeemTimes; // maximum redeem times
    uint256 startAt; // timestamp when event started
    uint256 expireAt; // timestamp when event ended
    bytes eventId; // burn redeem event id
    bytes signature; // signature signed by signer
}

contract BurnRedeemHandler is Upgradeable {
    using SafeERC20 for IERC20;

    uint256 constant ERC_721 = 1;
    uint256 constant ERC_1155 = 0;

    address constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    // utilize airdrop event for redeem tokens
    // this helps worker service update the db
    event AirdropClaimed(
        address indexed receiver,
        uint256[] tokenIds,
        uint256[] amounts,
        uint256[] types,
        address[] collections,
        string internalTxId
    );

    function executeBurnRedeem(BurnRedeemComponent memory param) external {
        {
            require(
                param.startAt <= block.timestamp || param.startAt == 0,
                "BurnRedeemHandler: burn & redeem event haven't started"
            );
            require(
                param.expireAt >= block.timestamp || param.expireAt == 0,
                "BurnRedeemHandler: burn & redeem event was ended"
            );
            require(
                !invalidBurnRedeemEvents[param.eventId],
                "BurnRedeemHandler: event was cancelled"
            );
            require(
                burnRedeemTimes[param.eventId] + param.redeemTimes <=
                    param.totalRedeemTimes,
                "BurnRedeemHandler: redeem limit exceeded"
            );

            burnRedeemTimes[param.eventId] += param.redeemTimes;
        }

        {
            bytes32 digest = ECDSA.toEthSignedMessageHash(hash(param));
            address recoveredAddr = ECDSA.recover(digest, param.signature);

            require(
                signers[recoveredAddr],
                "BurnRedeemHandler: Only signer's signature"
            );
        }

        {
            for (uint256 i = 0; i < param.burnItems.length; i++) {
                if (param.burnItems[i].tokenType == ERC_721) {
                    INFTify721(param.burnItems[i].collection).safeTransferFrom(
                        param.receiver,
                        address(BURN_ADDRESS),
                        param.burnItems[i].id,
                        ""
                    );
                } else if (param.burnItems[i].tokenType == ERC_1155) {
                    INFTify1155(param.burnItems[i].collection).safeTransferFrom(
                        param.receiver,
                        address(BURN_ADDRESS),
                        param.burnItems[i].id,
                        param.burnItems[i].quantity,
                        ""
                    );
                }
            }
        }

        {
            uint256 redeemQuantity = param.redeemItems.length;
            uint256[] memory _tokenIds = new uint256[](redeemQuantity);
            uint256[] memory _amounts = new uint256[](redeemQuantity);
            uint256[] memory _types = new uint256[](redeemQuantity);
            address[] memory _collections = new address[](redeemQuantity);
            for (uint256 i = 0; i < redeemQuantity; i++) {
                if (param.redeemItems[i].tokenType == ERC_721) {
                    INFTify721(param.redeemItems[i].collection).mint(
                        param.receiver,
                        param.redeemItems[i].id,
                        ""
                    );
                } else if (param.redeemItems[i].tokenType == ERC_1155) {
                    INFTify1155(param.redeemItems[i].collection).mint(
                        param.receiver,
                        param.redeemItems[i].id,
                        param.redeemItems[i].quantity,
                        ""
                    );
                }
                _tokenIds[i] = param.redeemItems[i].id;
                _amounts[i] = param.redeemItems[i].quantity;
                _types[i] = param.redeemItems[i].tokenType;
                _collections[i] = param.redeemItems[i].collection;
            }
            emit AirdropClaimed(
                param.receiver,
                _tokenIds,
                _amounts,
                _types,
                _collections,
                string(param.eventId)
            );
        }
    }

    /**
     * @dev Hash the BurnRedeemComponent data using abi.encodePacked.
     */
    function hash(
        BurnRedeemComponent memory component
    ) public pure returns (bytes32 digest) {
        return
            keccak256(
                abi.encodePacked(
                    encodeItems(component.burnItems),
                    encodeItems(component.redeemItems),
                    component.receiver,
                    component.redeemTimes,
                    component.totalRedeemTimes,
                    component.startAt,
                    component.expireAt,
                    component.eventId
                )
            );
    }

    /**
     * @dev Helper function to encode an array of Items using abi.encodePacked.
     */
    function encodeItems(
        Items[] memory items
    ) private pure returns (bytes memory) {
        bytes memory encodedItems;
        for (uint256 i = 0; i < items.length; i++) {
            encodedItems = abi.encodePacked(
                encodedItems,
                items[i].id,
                items[i].quantity,
                items[i].tokenType,
                items[i].collection
            );
        }
        return encodedItems;
    }
}
