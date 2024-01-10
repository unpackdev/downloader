// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "./IERC721.sol";

import "./ArbitraryCall.sol";
import "./IOpenSea.sol";
import "./IMerkleValidator.sol";
import "./IOpenSea.sol";
import "./Ownable.sol";
import "./Recoverable.sol";
import "./RevertUtils.sol";
import "./SendUtils.sol";

enum OfferSchema {
    Generic,
    MatchERC721UsingCriteria,
    MatchERC1155UsingCriteria,
    ERC721TransferFrom

    // NOTE: We currently don't support ERC1155SafeTransferFrom in the contract.
    // It seems to have been phased out by OpenSea so it's not relevant to us,
    // which is fine because we only use 2 bits to encode the schema anyway.
    //ERC1155SafeTransferFrom
}

//---------------------------------------------------------------------------------//
// WARNING: Due to the extra power ArbitraryCall gives the owner of this contract, //
// the contract MUST NOT own any tokens or be trused by other contracts to         //
// perform sensitive operations without additional authorization.                  //
//---------------------------------------------------------------------------------//

contract OptimizedOpenSeaMarket is Recoverable, ArbitraryCall {
    address constant OPEN_SEA_WALLET = 0x5b3256965e7C3cF26E11FCAf296DfC8807C01073;
    address constant MERKLE_VALIDATOR_ADDRESS = 0xBAf2127B49fC93CbcA6269FAdE0F7F31dF4c88a7;

    IOpenSea immutable _openSea;

    constructor(address owner, IOpenSea openSea) Ownable(owner) {
        _openSea = openSea;
    }

    receive() external payable {}

    function optimizedBuyAssetsForEth(bytes calldata optimizedBuys) public payable {
        uint8 buyCount = uint8(optimizedBuys[0]);
        bool revertIfTrxFails = (optimizedBuys[1] > 0);

        OpenSeaBuy memory openSeaBuy;
        initOpenSeaBuyTemplate(openSeaBuy);

        uint offset = 2;
        for (uint256 i = 0; i < buyCount;) {
            uint decodedDataSize = decodeBuyIntoTemplate(optimizedBuys[offset:], openSeaBuy);
            offset += decodedDataSize;

            _buyAssetForEth(openSeaBuy, revertIfTrxFails);
            unchecked { ++i; }
        }
        SendUtils._returnAllEth();
    }

    function _buyAssetForEth(OpenSeaBuy memory openSeaBuy, bool revertIfTrxFails) internal {
        try _openSea.atomicMatch_{value: openSeaBuy.uints[4]}(
            openSeaBuy.addrs,
            openSeaBuy.uints,
            openSeaBuy.feeMethodsSidesKindsHowToCalls,
            openSeaBuy.calldataBuy,
            openSeaBuy.calldataSell,
            openSeaBuy.replacementPatternBuy,
            openSeaBuy.replacementPatternSell,
            openSeaBuy.staticExtradataBuy,
            openSeaBuy.staticExtradataSell,
            openSeaBuy.vs,
            openSeaBuy.rssMetadata
        ) {
            return;
        } catch (bytes memory lowLevelData) {
            if (revertIfTrxFails)
                RevertUtils.rawRevert(lowLevelData);
        }
    }

    function decodeCalldataERC721TF(
        address maker,
        uint tokenId,
        address taker
    )
        public
        pure
        returns (bytes memory, bytes memory, bytes memory, bytes memory)
    {
        return (
            // calldata_
            bytes.concat(
                IERC721.transferFrom.selector,
                bytes32(uint(uint160(maker))),
                bytes32(0),
                bytes32(tokenId)
            ),
            // replacementPattern
            bytes.concat(
                bytes4(0),
                bytes32(0),
                bytes32(type(uint).max),
                bytes32(0)
            ),
            // calldataFromBackend
            bytes.concat(
                IERC721.transferFrom.selector,
                bytes32(uint(uint160(maker))),
                bytes32(uint(uint160(taker))),
                bytes32(tokenId)
            ),
            // replacementPatternFromBackend
            bytes.concat(
                bytes4(0),
                bytes32(0),
                bytes32(0),
                bytes32(0)
            )
        );
    }

    function decodeCalldataMERC721UC(
        address maker,
        uint tokenId,
        address taker,
        address tokenContract
    )
        public
        pure
        returns (bytes memory, bytes memory, bytes memory, bytes memory)
    {
        return (
            // calldata_
            bytes.concat(
                IMerkleValidator.matchERC721UsingCriteria.selector,
                bytes32(uint(uint160(maker))),
                bytes32(0),
                bytes32(uint(uint160(tokenContract))),
                bytes32(tokenId),
                bytes32(0),            // root
                bytes32(uint(6 * 32)), // proof.offset
                bytes32(0)             // proof.length
            ),
            // replacementPattern
            bytes.concat(
                bytes4(0),
                bytes32(0),
                bytes32(type(uint).max),
                bytes32(0),
                bytes32(0),
                bytes32(0),
                bytes32(0),
                bytes32(0)
            ),
            // calldataFromBackend
            bytes.concat(
                IMerkleValidator.matchERC721UsingCriteria.selector,
                bytes32(uint(uint160(maker))),
                bytes32(uint(uint160(taker))),
                bytes32(uint(uint160(tokenContract))),
                bytes32(tokenId),
                bytes32(0),            // root
                bytes32(uint(6 * 32)), // proof.offset
                bytes32(0)             // proof.length
            ),
            // replacementPatternFromBackend
            bytes.concat(
                bytes4(0),
                bytes32(0),
                bytes32(0),
                bytes32(0),
                bytes32(0),
                bytes32(0),
                bytes32(0),
                bytes32(0)
            )
        );
    }

    function decodeCalldataMERC1155UC(
        address maker,
        uint tokenId,
        address taker,
        address tokenContract,
        uint tokenAmount
    )
        public
        pure
        returns (bytes memory, bytes memory, bytes memory, bytes memory)
    {
        return (
            // calldata_
            bytes.concat(
                IMerkleValidator.matchERC1155UsingCriteria.selector,
                bytes32(uint(uint160(maker))),
                bytes32(0),
                bytes32(uint(uint160(tokenContract))),
                bytes32(tokenId),
                bytes32(tokenAmount),
                bytes32(0),            // root
                bytes32(uint(7 * 32)), // proof.offset
                bytes32(0)             // proof.length
            ),
            // replacementPattern
            bytes.concat(
                bytes4(0),
                bytes32(0),
                bytes32(type(uint).max),
                bytes32(0),
                bytes32(0),
                bytes32(0),
                bytes32(0),
                bytes32(0),
                bytes32(0)
            ),
            // calldataFromBackend
            bytes.concat(
                IMerkleValidator.matchERC1155UsingCriteria.selector,
                bytes32(uint(uint160(maker))),
                bytes32(uint(uint160(taker))),
                bytes32(uint(uint160(tokenContract))),
                bytes32(tokenId),
                bytes32(tokenAmount),
                bytes32(0),            // root
                bytes32(uint(7 * 32)), // proof.offset
                bytes32(0)             // proof.length
            ),
            // replacementPatternFromBackend
            bytes.concat(
                bytes4(0),
                bytes32(0),
                bytes32(0),
                bytes32(0),
                bytes32(0),
                bytes32(0),
                bytes32(0),
                bytes32(0),
                bytes32(0)
            )
        );
    }

    function decodeBuy(bytes calldata optimizedBuy) public view returns (OpenSeaBuy memory openSeaBuy, uint offset) {
        initOpenSeaBuyTemplate(openSeaBuy);
        offset = decodeBuyIntoTemplate(optimizedBuy, openSeaBuy);
        return (openSeaBuy, offset);
    }

    /// Initializes the part of OpenSeaBuy that stays the same for all offers.
    function initOpenSeaBuyTemplate(OpenSeaBuy memory openSeaBuyToFill) internal view {
        openSeaBuyToFill.uints[0] = 0;                  // buy.uints.makerRelayerFee
        openSeaBuyToFill.uints[1] = 0;                  // buy.uints.takerRelayerFee
        openSeaBuyToFill.uints[2] = 0;                  // buy.uints.makerProtocolFee
        openSeaBuyToFill.uints[3] = 0;                  // buy.uints.takerProtocolFee
        //openSeaBuyToFill.uints[4]                     // buy.uints.basePrice
        openSeaBuyToFill.uints[5] = 0;                  // buy.uints.extra
        openSeaBuyToFill.uints[6] = 0;                  // buy.uints.listingTime
        openSeaBuyToFill.uints[7] = 0;                  // buy.uints.expirationTime

        // NOTE: Salt only matters for published orders. It is used by Wyvern Exchange to ensure that
        // two otherwise identical orders hash to different values because order hash is used as a unique
        // identifier. The hash is what gets signed (see `Exchange.hashToSign()`) and is required for order
        // cancellation to work properly.
        // Since we're the taker side for an already published order, `ExchangeCore.atomicMatch()` will
        // never even try to generate this hash (note that v, r and s are zero so there's no signature
        // for it) and we can safely set salt to zero.
        openSeaBuyToFill.uints[8] = 0;                           // buy.uints.salt

        //openSeaBuyToFill.uints[9]                              // sell.uints.makerRelayerFee
        openSeaBuyToFill.uints[10] = 0;                          // sell.uints.takerRelayerFee
        openSeaBuyToFill.uints[11] = 0;                          // sell.uints.makerProtocolFee
        openSeaBuyToFill.uints[12] = 0;                          // sell.uints.takerProtocolFee
        //openSeaBuyToFill.uints[13]                             // sell.uints.basePrice
        openSeaBuyToFill.uints[14] = 0;                          // sell.uints.extra
        //openSeaBuyToFill.uints[15]                             // sell.uints.listingTime
        //openSeaBuyToFill.uints[16]                             // sell.uints.expirationTime
        //openSeaBuyToFill.uints[17]                             // sell.uints.salt

        openSeaBuyToFill.vs[0] = 0;                              // buy.v
        //openSeaBuyToFill.vs[1]                                 // sell.v
        openSeaBuyToFill.rssMetadata[0] = 0;                     // buy.r
        openSeaBuyToFill.rssMetadata[1] = 0;                     // buy.s
        //openSeaBuyToFill.rssMetadata[2]                        // sell.r
        //openSeaBuyToFill.rssMetadata[3]                        // sell.s
        openSeaBuyToFill.rssMetadata[4] = 0;                     // metadata

        openSeaBuyToFill.addrs[0] = address(_openSea);           // buy.addrs.exchange
        openSeaBuyToFill.addrs[1] = address(this);               // buy.addrs.maker
        openSeaBuyToFill.addrs[2] = address(0);                  // buy.addrs.taker
        openSeaBuyToFill.addrs[3] = address(0);                  // buy.addrs.feeRecipient
        //openSeaBuyToFill.addrs[4]                              // buy.addrs.target
        openSeaBuyToFill.addrs[5] = address(0);                  // buy.addrs.staticTarget
        openSeaBuyToFill.addrs[6] = address(0);                  // buy.addrs.paymentToken
        openSeaBuyToFill.addrs[7] = address(_openSea);           // sell.addrs.exchange
        //openSeaBuyToFill.addrs[8]                              // sell.addrs.maker
        openSeaBuyToFill.addrs[9] = address(0);                  // sell.addrs.taker
        openSeaBuyToFill.addrs[10] = OPEN_SEA_WALLET;            // sell.addrs.feeRecipient
        //openSeaBuyToFill.addrs[11]                             // sell.addrs.target
        openSeaBuyToFill.addrs[12] = address(0);                 // sell.addrs.staticTarget
        openSeaBuyToFill.addrs[13] = address(0);                 // sell.addrs.paymentToken

        openSeaBuyToFill.feeMethodsSidesKindsHowToCalls[0] = 1;  // buy.kinds.feeMethod
        openSeaBuyToFill.feeMethodsSidesKindsHowToCalls[1] = 0;  // buy.kinds.side
        openSeaBuyToFill.feeMethodsSidesKindsHowToCalls[2] = 0;  // buy.kinds.saleKind
        //openSeaBuyToFill.feeMethodsSidesKindsHowToCalls[3]     // buy.kinds.howToCall
        openSeaBuyToFill.feeMethodsSidesKindsHowToCalls[4] = 1;  // sell.kinds.feeMethod
        openSeaBuyToFill.feeMethodsSidesKindsHowToCalls[5] = 1;  // sell.kinds.side
        openSeaBuyToFill.feeMethodsSidesKindsHowToCalls[6] = 0;  // sell.kinds.saleKind
        //openSeaBuyToFill.feeMethodsSidesKindsHowToCalls[7]     // sell.kinds.howToCall

        openSeaBuyToFill.staticExtradataBuy = '';                // buy.staticExtradata
        openSeaBuyToFill.staticExtradataSell = '';               // sell.staticExtradata
    }

    /// Decodes an optimized buy encoded as bytes into the specified OpenSeaBuy struct.
    ///
    /// @dev This function assumes that openSeaBuyToFill has already been initialized with initOpenSeaBuyTemplate()
    /// so that only the fields that may very between orders need to be initialized.
    function decodeBuyIntoTemplate(bytes calldata optimizedBuy, OpenSeaBuy memory openSeaBuyToFill) internal pure returns (uint) {
        OfferSchema offerSchema = OfferSchema(uint8(optimizedBuy[0]) >> 6);

        uint offset = 0;

        {
            uint makerRelayerFee;
            uint basePrice;
            uint listingTime;
            uint expirationTime;
            uint salt;

            assembly {
                makerRelayerFee := and(0x3fff, shr(240, calldataload(add(optimizedBuy.offset, offset))))
                offset := add(offset, 2)
                basePrice := calldataload(add(optimizedBuy.offset, offset))
                offset := add(offset, 32)

                listingTime := shr(224, calldataload(add(optimizedBuy.offset, offset)))
                offset := add(offset, 4)
                expirationTime := shr(224, calldataload(add(optimizedBuy.offset, offset)))
                offset := add(offset, 4)
                salt := calldataload(add(optimizedBuy.offset, offset))
                offset := add(offset, 32)
            }

            // ASSUMPTION: Commented-out fields were already initialized by initOpenSeaBuyTemplate()
            //openSeaBuyToFill.uints[0] = 0;                // buy.uints.makerRelayerFee
            //openSeaBuyToFill.uints[1] = 0;                // buy.uints.takerRelayerFee
            //openSeaBuyToFill.uints[2] = 0;                // buy.uints.makerProtocolFee
            //openSeaBuyToFill.uints[3] = 0;                // buy.uints.takerProtocolFee
            openSeaBuyToFill.uints[4] = basePrice;          // buy.uints.basePrice
            //openSeaBuyToFill.uints[5] = 0;                // buy.uints.extra
            //openSeaBuyToFill.uints[6] = 0;                // buy.uints.listingTime
            //openSeaBuyToFill.uints[7] = 0;                // buy.uints.expirationTime
            //openSeaBuyToFill.uints[8] = 0;                // buy.uints.salt
            openSeaBuyToFill.uints[9]  = makerRelayerFee;   // sell.uints.makerRelayerFee
            //openSeaBuyToFill.uints[10] = 0;               // sell.uints.takerRelayerFee
            //openSeaBuyToFill.uints[11] = 0;               // sell.uints.makerProtocolFee
            //openSeaBuyToFill.uints[12] = 0;               // sell.uints.takerProtocolFee
            openSeaBuyToFill.uints[13] = basePrice;         // sell.uints.basePrice
            //openSeaBuyToFill.uints[14] = 0;               // sell.uints.extra
            openSeaBuyToFill.uints[15] = listingTime;       // sell.uints.listingTime
            openSeaBuyToFill.uints[16] = expirationTime;    // sell.uints.expirationTime
            openSeaBuyToFill.uints[17] = salt;              // sell.uints.salt
        }
        {
            bytes32 r;                                      // sell.r
            bytes32 s;                                      // sell.s
            uint8 v;                                        // sell.v

            assembly {
                r := calldataload(add(optimizedBuy.offset, offset))
                offset := add(offset, 32)
                let vs := calldataload(add(optimizedBuy.offset, offset))
                offset := add(offset, 32)

                v := add(shr(255, vs), 27)
                s := and(vs, not(shl(255, 1)))
            }

            // ASSUMPTION: Commented-out fields were already initialized by initOpenSeaBuyTemplate()
            //openSeaBuyToFill.vs[0] = 0;                   // buy.v
            openSeaBuyToFill.vs[1] = v;                     // sell.v
            //openSeaBuyToFill.rssMetadata[0] = 0;          // buy.r
            //openSeaBuyToFill.rssMetadata[1] = 0;          // buy.s
            openSeaBuyToFill.rssMetadata[2] = r;            // sell.r
            openSeaBuyToFill.rssMetadata[3] = s;            // sell.s
            //openSeaBuyToFill.rssMetadata[4] = 0;          // metadata
        }
        address maker;
        {
            assembly {
                maker := shr(96, calldataload(add(optimizedBuy.offset, offset)))
                offset := add(offset, 20)
            }

            address target;
            uint8 howToCall;
            if (offerSchema == OfferSchema.MatchERC721UsingCriteria || offerSchema == OfferSchema.MatchERC1155UsingCriteria) {
                target = MERKLE_VALIDATOR_ADDRESS;
                howToCall = 1;
            }
            else
                assembly {
                    target := shr(96, calldataload(add(optimizedBuy.offset, offset)))
                    offset := add(offset, 20)
                    howToCall := shr(248, calldataload(add(optimizedBuy.offset, offset)))
                    offset := add(offset, 1)
                }

            // ASSUMPTION: Commented-out fields were already initialized by initOpenSeaBuyTemplate()
            //openSeaBuyToFill.addrs[0] = address(_openSea);                 // buy.addrs.exchange
            //openSeaBuyToFill.addrs[1] = address(this);                     // buy.addrs.maker
            //openSeaBuyToFill.addrs[2] = address(0);                        // buy.addrs.taker
            //openSeaBuyToFill.addrs[3] = address(0);                        // buy.addrs.feeRecipient
            openSeaBuyToFill.addrs[4] = target;                              // buy.addrs.target
            //openSeaBuyToFill.addrs[5] = address(0);                        // buy.addrs.staticTarget
            //openSeaBuyToFill.addrs[6] = address(0);                        // buy.addrs.paymentToken
            //openSeaBuyToFill.addrs[7] = address(_openSea);                 // sell.addrs.exchange
            openSeaBuyToFill.addrs[8] = maker;                               // sell.addrs.maker
            //openSeaBuyToFill.addrs[9] = address(0);                        // sell.addrs.taker
            //openSeaBuyToFill.addrs[10] = OPEN_SEA_WALLET;                  // sell.addrs.feeRecipient
            openSeaBuyToFill.addrs[11] = target;                             // sell.addrs.target
            //openSeaBuyToFill.addrs[12] = address(0);                       // sell.addrs.staticTarget
            //openSeaBuyToFill.addrs[13] = address(0);                       // sell.addrs.paymentToken

            //openSeaBuyToFill.feeMethodsSidesKindsHowToCalls[0] = 1;        // buy.kinds.feeMethod
            //openSeaBuyToFill.feeMethodsSidesKindsHowToCalls[1] = 0;        // buy.kinds.side
            //openSeaBuyToFill.feeMethodsSidesKindsHowToCalls[2] = 0;        // buy.kinds.saleKind
            openSeaBuyToFill.feeMethodsSidesKindsHowToCalls[3] = howToCall;  // buy.kinds.howToCall
            //openSeaBuyToFill.feeMethodsSidesKindsHowToCalls[4] = 1;        // sell.kinds.feeMethod
            //openSeaBuyToFill.feeMethodsSidesKindsHowToCalls[5] = 1;        // sell.kinds.side
            //openSeaBuyToFill.feeMethodsSidesKindsHowToCalls[6] = 0;        // sell.kinds.saleKind
            openSeaBuyToFill.feeMethodsSidesKindsHowToCalls[7] = howToCall;  // sell.kinds.howToCall
        }
        if (offerSchema == OfferSchema.Generic) {
            {
                uint dataSize;
                assembly {
                    dataSize := shr(240, calldataload(add(optimizedBuy.offset, offset)))
                    offset := add(offset, 2)
                }

                bytes memory dataPtr;
                if (openSeaBuyToFill.calldataSell.length < dataSize)
                    dataPtr = new bytes(dataSize);
                else {
                    dataPtr = openSeaBuyToFill.calldataSell;
                    assembly {
                        mstore(dataPtr, dataSize)
                    }
                }

                assembly {
                    calldatacopy(add(dataPtr, 32), add(optimizedBuy.offset, offset), dataSize)
                    offset := add(offset, dataSize)
                }
                openSeaBuyToFill.calldataSell = dataPtr;              // sell.calldata
            }
            {
                uint dataSize;
                assembly {
                    dataSize := shr(240, calldataload(add(optimizedBuy.offset, offset)))
                    offset := add(offset, 2)
                }

                bytes memory dataPtr;
                if (openSeaBuyToFill.replacementPatternSell.length < dataSize)
                    dataPtr = new bytes(dataSize);
                else {
                    dataPtr = openSeaBuyToFill.replacementPatternSell;
                    assembly {
                        mstore(dataPtr, dataSize)
                    }
                }

                assembly {
                    calldatacopy(add(dataPtr, 32), add(optimizedBuy.offset, offset), dataSize)
                    offset := add(offset, dataSize)
                }
                openSeaBuyToFill.replacementPatternSell = dataPtr;    // sell.replacementPattern
            }
            {
                uint dataSize;
                assembly {
                    dataSize := shr(240, calldataload(add(optimizedBuy.offset, offset)))
                    offset := add(offset, 2)
                }

                bytes memory dataPtr;
                if (openSeaBuyToFill.calldataBuy.length < dataSize)
                    dataPtr = new bytes(dataSize);
                else {
                    dataPtr = openSeaBuyToFill.calldataBuy;
                    assembly {
                        mstore(dataPtr, dataSize)
                    }
                }

                assembly {
                    calldatacopy(add(dataPtr, 32), add(optimizedBuy.offset, offset), dataSize)
                    offset := add(offset, dataSize)
                }
                openSeaBuyToFill.calldataBuy = dataPtr;               // buy.calldata
            }
            {
                uint dataSize;
                assembly {
                    dataSize := shr(240, calldataload(add(optimizedBuy.offset, offset)))
                    offset := add(offset, 2)
                }

                bytes memory dataPtr;
                if (openSeaBuyToFill.replacementPatternBuy.length < dataSize)
                    dataPtr = new bytes(dataSize);
                else {
                    dataPtr = openSeaBuyToFill.replacementPatternBuy;
                    assembly {
                        mstore(dataPtr, dataSize)
                    }
                }

                assembly {
                    calldatacopy(add(dataPtr, 32), add(optimizedBuy.offset, offset), dataSize)
                    offset := add(offset, dataSize)
                }
                openSeaBuyToFill.replacementPatternBuy = dataPtr;     // buy.replacementPattern
            }
        }
        else {
            uint tokenId;
            address taker;

            assembly {
                tokenId := calldataload(add(optimizedBuy.offset, offset))
                offset := add(offset, 32)
                taker := shr(96, calldataload(add(optimizedBuy.offset, offset)))
                offset := add(offset, 20)
            }

            if (offerSchema == OfferSchema.ERC721TransferFrom)
                (
                    openSeaBuyToFill.calldataSell,            // sell.calldata
                    openSeaBuyToFill.replacementPatternSell,  // sell.replacementPattern
                    openSeaBuyToFill.calldataBuy,             // buy.calldata
                    openSeaBuyToFill.replacementPatternBuy    // buy.replacementPattern
                ) = decodeCalldataERC721TF(maker, tokenId, taker);
            else {
                address tokenContract;

                assembly {
                    tokenContract := shr(96, calldataload(add(optimizedBuy.offset, offset)))
                    offset := add(offset, 20)
                }

                if (offerSchema == OfferSchema.MatchERC721UsingCriteria)
                    (
                        openSeaBuyToFill.calldataSell,            // sell.calldata
                        openSeaBuyToFill.replacementPatternSell,  // sell.replacementPattern
                        openSeaBuyToFill.calldataBuy,             // buy.calldata
                        openSeaBuyToFill.replacementPatternBuy    // buy.replacementPattern
                    ) = decodeCalldataMERC721UC(maker, tokenId, taker, tokenContract);
                else {
                    uint tokenAmount;

                    assembly {
                        tokenAmount := calldataload(add(optimizedBuy.offset, offset))
                        offset := add(offset, 32)
                    }

                    assert(offerSchema == OfferSchema.MatchERC1155UsingCriteria);
                    (
                        openSeaBuyToFill.calldataSell,            // sell.calldata
                        openSeaBuyToFill.replacementPatternSell,  // sell.replacementPattern
                        openSeaBuyToFill.calldataBuy,             // buy.calldata
                        openSeaBuyToFill.replacementPatternBuy    // buy.replacementPattern
                    ) = decodeCalldataMERC1155UC(maker, tokenId, taker, tokenContract, tokenAmount);
                }
            }
        }

        // ASSUMPTION: These fields were already initialized by initOpenSeaBuyTemplate()
        //openSeaBuyToFill.staticExtradataBuy = '';  // buy.staticExtradata
        //openSeaBuyToFill.staticExtradataSell = ''; // sell.staticExtradata

        return offset;
    }
}
