// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ZzoopersBitMap.sol";

/**
 * @title Zzoopers contract
 */
contract ZzoopersRandomizer is Ownable {
    using ZzoopersBitMaps for *;

    uint32 constant BATCH_SIZE = 1111;
    uint32 constant LIMIT_AMOUNT = 5555;

    address private _zzoopersAddress;

    mapping(uint256 => ZzoopersBitMaps.ZzoopersBitMap) private _metadataIds;

    constructor() Ownable() {
        //init _metadataIds for 5 batch, each for 1111, total is 5555;
        _metadataIds[0].init(BATCH_SIZE);
        _metadataIds[1].init(BATCH_SIZE);
        _metadataIds[2].init(BATCH_SIZE);
        _metadataIds[3].init(BATCH_SIZE);
        _metadataIds[4].init(BATCH_SIZE);
    }

    function setZzoopersAddress(address zzoopersAddress) public onlyOwner {
        _zzoopersAddress = zzoopersAddress;
    }

    //batchNo should start from 1
    function getMetadataId(uint256 batchNo, uint256 zzoopersEVOTokenId)
        external
        returns (uint256 metadataId)
    {
        require(
            msg.sender == _zzoopersAddress,
            "ZzoopersRandomizer: caller not authorized"
        );
        require(
            batchNo >= 1 && batchNo <= 5,
            "ZzoopersRandomizer: BatchNo must between: 1 and 5"
        );
        require(
            zzoopersEVOTokenId <= LIMIT_AMOUNT,
            "ZzoopersRandomizer: TokenId cannot large than 5555"
        );
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.timestamp),
                    batchNo,
                    zzoopersEVOTokenId
                )
            )
        );
        uint256 totalUnused = 0;

        unchecked {
            for (uint256 i = 0; i < batchNo; i++) {
                totalUnused += _metadataIds[i].unused();
            }
            require(totalUnused > 0, "ZzoopersRandomizer: Batch limit reached");

            uint256 index = random % totalUnused;
            uint256 count = 0;
            uint256 targetBatchNo = 0;
            for (; targetBatchNo < batchNo; targetBatchNo++) {
                count += _metadataIds[targetBatchNo].unused();
                if (index < count) {
                    break;
                }
            }
            metadataId =
                targetBatchNo *
                BATCH_SIZE +
                _metadataIds[targetBatchNo].trySetTo(
                    random % _metadataIds[targetBatchNo].cap()
                ) +
                1; //metadataId start from 1
        }
        return metadataId;
    }
}
