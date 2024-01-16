//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ArrayUtils.sol";
import "./AuthenticatedProxy.sol";

/// @notice StaticERC721 - static calls for ERC721 trades
contract StaticERC721 {
    function transferERC721Exact(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall howToCall,
        uint256[6] memory,
        bytes memory data
    ) public pure {
        // Decode extradata
        (address token, uint256 tokenId) = abi.decode(
            extra,
            (address, uint256)
        );

        // Call target = token to give
        require(addresses[2] == token);
        // Call type = call
        require(howToCall == AuthenticatedProxy.HowToCall.Call);
        // Assert calldata
        require(
            ArrayUtils.arrayEq(
                data,
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    addresses[1],
                    addresses[4],
                    tokenId
                )
            )
        );
    }

    function swapOneForOneERC721(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory counterdata
    ) public pure returns (uint256) {
        // Zero-value
        require(uints[0] == 0);

        // Decode extradata
        (address[2] memory tokenGiveGet, uint256[2] memory nftGiveGet) = abi
            .decode(extra, (address[2], uint256[2]));

        // Call target = token to give
        require(
            addresses[2] == tokenGiveGet[0],
            "ERC721: call target must equal address of token to give"
        );
        // Call type = call
        require(
            howToCalls[0] == AuthenticatedProxy.HowToCall.Call,
            "ERC721: call must be a direct call"
        );
        // Assert calldata
        require(
            ArrayUtils.arrayEq(
                data,
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    addresses[1],
                    addresses[4],
                    nftGiveGet[0]
                )
            )
        );

        // Countercall target = token to get
        require(
            addresses[5] == tokenGiveGet[1],
            "ERC721: countercall target must equal address of token to get"
        );
        // Countercall type = call
        require(
            howToCalls[1] == AuthenticatedProxy.HowToCall.Call,
            "ERC721: countercall must be a direct call"
        );
        // Assert countercalldata
        require(
            ArrayUtils.arrayEq(
                counterdata,
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    addresses[4],
                    addresses[1],
                    nftGiveGet[1]
                )
            )
        );

        // Mark filled
        return 1;
    }

    function swapOneForOneERC721Decoding(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory counterdata
    ) public pure returns (uint256) {
        // Calculate function signature
        bytes memory sig = ArrayUtils.arrayTake(
            abi.encodeWithSignature("transferFrom(address,address,uint256)"),
            4
        );

        // Zero-value
        require(uints[0] == 0);

        // Decode extradata
        (address[2] memory tokenGiveGet, uint256[2] memory nftGiveGet) = abi
            .decode(extra, (address[2], uint256[2]));

        // Call target = token to give
        require(
            addresses[2] == tokenGiveGet[0],
            "ERC721: call target must equal address of token to give"
        );
        // Call type = call
        require(
            howToCalls[0] == AuthenticatedProxy.HowToCall.Call,
            "ERC721: call must be a direct call"
        );
        // Assert signature
        require(ArrayUtils.arrayEq(sig, ArrayUtils.arrayTake(data, 4)));
        // Decode calldata
        (address callFrom, address callTo, uint256 nftGive) = abi.decode(
            ArrayUtils.arrayDrop(data, 4),
            (address, address, uint256)
        );
        // Assert from
        require(callFrom == addresses[1]);
        // Assert to
        require(callTo == addresses[4]);
        // Assert NFT
        require(nftGive == nftGiveGet[0]);

        // Countercall target = token to get
        require(
            addresses[5] == tokenGiveGet[1],
            "ERC721: countercall target must equal address of token to get"
        );
        // Countercall type = call
        require(
            howToCalls[1] == AuthenticatedProxy.HowToCall.Call,
            "ERC721: countercall must be a direct call"
        );
        // Assert signature
        require(ArrayUtils.arrayEq(sig, ArrayUtils.arrayTake(counterdata, 4)));
        // Decode countercalldata
        (address countercallFrom, address countercallTo, uint256 nftGet) = abi
            .decode(
                ArrayUtils.arrayDrop(counterdata, 4),
                (address, address, uint256)
            );
        // Assert from
        require(countercallFrom == addresses[4]);
        // Assert to
        require(countercallTo == addresses[1]);
        // Assert NFT
        require(nftGet == nftGiveGet[1]);

        // Mark filled
        return 1;
    }

    function ERC721WithValue(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory
    ) public pure returns (uint256) {
        // Decode extradata
        (
            address[2] memory creatorAndCollection,
            uint256[3] memory tokenIdPriceRoyalties,
            /*bytes memory ReferralCoupon*/
        ) = abi.decode(extra, (address[2], uint256[3], bytes));

        // msg.value
        require(
            uints[0] == tokenIdPriceRoyalties[1],
            "ERC721: value sent must equal to token price in eth"
        );

        // Call target = token to give
        require(
            addresses[2] == creatorAndCollection[1],
            "ERC721: call target must equal address of token to give"
        );

        // Call type = call
        require(
            howToCalls[0] == AuthenticatedProxy.HowToCall.Call,
            "ERC721: call must be a direct call"
        );

        // Assert calldata
        require(
            ArrayUtils.arrayEq(
                data,
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    addresses[1],
                    addresses[4],
                    tokenIdPriceRoyalties[0]
                )
            )
        );

        // Mark filled
        return 1;
    }
}
