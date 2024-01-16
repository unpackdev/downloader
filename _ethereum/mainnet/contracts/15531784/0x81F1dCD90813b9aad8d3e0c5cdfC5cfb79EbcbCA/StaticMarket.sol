//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ArrayUtils.sol";
import "./AuthenticatedProxy.sol";

/**
 * @title StaticMarket
 * @author OasisX Protocol Developers
 * @dev each public here has the same parameters:
 * addresses an array of addresses, with each corresponding to the following:
		[0] order registry
		[1] order maker
		[2] call target
		[3] counterorder registry
		[4] counterorder maker
		[5] countercall target
		[6] matcher
 * howToCalls an array of enums: { Call | DelegateCall }
		[0] for the call
		[1] for the countercall
 * uints an array of 6 uints corresponding to the following:
		[0] value (eth value)
		[1] call max fill
		[2] order listing time
		[3] order expiration time
		[4] counterorder listing time
		[5] previous fill
 * data The data that you pass into the proxied function call. The static calls verify that the order placed actually matches up with the calldata passed to the proxied call
 * counterdata Same as data but for the countercall
 */
contract StaticMarket {
    address public atomicizerAddr;

    constructor() {
        /* solium-disable-line */
    }

    function anyERC1155ForERC20(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory counterdata
    ) public pure returns (uint256) {
        require(uints[0] == 0, "anyERC1155ForERC20: Zero value required");
        require(
            howToCalls[0] == AuthenticatedProxy.HowToCall.Call,
            "anyERC1155ForERC20: call must be a direct call"
        );

        (
            address[2] memory tokenGiveGet,
            uint256[3] memory tokenIdAndNumeratorDenominator
        ) = abi.decode(extra, (address[2], uint256[3]));

        require(
            tokenIdAndNumeratorDenominator[1] > 0,
            "anyERC20ForERC1155: numerator must be larger than zero"
        );
        require(
            tokenIdAndNumeratorDenominator[2] > 0,
            "anyERC20ForERC1155: denominator must be larger than zero"
        );
        require(
            addresses[2] == tokenGiveGet[0],
            "anyERC1155ForERC20: call target must equal address of token to give"
        );
        require(
            addresses[5] == tokenGiveGet[1],
            "anyERC1155ForERC20: countercall target must equal address of token to get"
        );

        uint256[2] memory call_amounts = [
            getERC1155AmountFromCalldata(data),
            getERC20AmountFromCalldata(counterdata)
        ];
        uint256 new_fill = (uints[5] + call_amounts[0]);
        require(
            new_fill <= uints[1],
            "anyERC1155ForERC20: new fill exceeds maximum fill"
        );
        require(
            (tokenIdAndNumeratorDenominator[1] * call_amounts[1]) ==
                (
                    tokenIdAndNumeratorDenominator[2] *
                    call_amounts[0]
                ),
            "anyERC1155ForERC20: wrong ratio"
        );
        checkERC1155Side(
            data,
            addresses[1],
            addresses[4],
            tokenIdAndNumeratorDenominator[0],
            call_amounts[0]
        );
        checkERC20Side(
            counterdata,
            addresses[4],
            addresses[1],
            call_amounts[1]
        );
        return new_fill;
    }

    function anyERC1155FforMultiERC20Calls(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory counterdata
    ) public view returns (uint256) {
        require(uints[0] == 0, "anyERC1155ForERC20: Zero value required");

        (
            address[] memory tokenGiveGet,
            uint256[] memory tokenIdAndNumeratorDenominator
        ) = abi.decode(extra, (address[], uint256[]));

        require(
            tokenIdAndNumeratorDenominator[1] > 0,
            "anyERC20ForERC1155: numerator must be larger than zero"
        );
        require(
            tokenIdAndNumeratorDenominator[2] > 0,
            "anyERC20ForERC1155: denominator must be larger than zero"
        );
        require(
            addresses[2] == atomicizerAddr,
            "anyERC1155ForERC20: call target must equal address of token to give"
        );
        require(
            addresses[5] == tokenGiveGet[1],
            "anyERC1155ForERC20: countercall target must equal atomicizer address"
        );

        (
            uint256[] memory erc20Amounts,
            bytes[] memory calls
        ) = getAmountsFromAtomizerData(data);

        uint256 nftsAmount = getERC1155AmountFromCalldata(counterdata);

        uint256 new_fill = (uints[5] + erc20Amounts[0]);

        require(
            new_fill <= uints[1],
            "anyERC1155ForERC20: new fill exceeds maximum fill"
        );

        require(
            (tokenIdAndNumeratorDenominator[2] * erc20Amounts[0]) ==
                (tokenIdAndNumeratorDenominator[1] * nftsAmount),
            "anyERC1155ForERC20: wrong ratio"
        );

        checkERC1155Side(
            counterdata,
            addresses[4],
            addresses[1],
            tokenIdAndNumeratorDenominator[0],
            nftsAmount
        );

        for (uint256 i = 0; i < calls.length; i++) {
            checkERC20Side(
                calls[i],
                addresses[1],
                i == 0 ? addresses[4] : tokenGiveGet[i + 1],
                i == 0
                    ? tokenIdAndNumeratorDenominator[i + 1]
                    : tokenIdAndNumeratorDenominator[i + 2]
            );
        }

        return new_fill;
    }

    function getAmountsFromAtomizerData(bytes memory counterdata)
        public
        pure
        returns (uint256[] memory, bytes[] memory)
    {
        (
            address[] memory caddrs,
            ,
            /*uint256[] memory cvals */
            uint256[] memory clengths,
            bytes memory calldatas
        ) = abi.decode(
                ArrayUtils.arrayDrop(counterdata, 4),
                (address[], uint256[], uint256[], bytes)
            );

        uint256[] memory amounts = new uint256[](caddrs.length);

        bytes[] memory calls = new bytes[](caddrs.length);

        uint256 j = 0;

        for (uint256 i = 0; i < caddrs.length; i++) {
            bytes memory cd = new bytes(clengths[i]);
            for (uint256 k = 0; k < clengths[i]; k++) {
                cd[k] = calldatas[j];
                j++;
            }

            amounts[i] = abi.decode(
                ArrayUtils.arraySlice(cd, 68, 32),
                (uint256)
            );
            calls[i] = cd;
        }

        return (amounts, calls);
    }

    function ERC1155WithValue(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory
    ) public pure returns (uint256) {
        // decode extraData
        (
            address[2] memory creatorAndTokenGive,
            uint256[3] memory tokenIdPriceRoyalties,
            /*bytes memory ReferralCoupon*/
        ) = abi.decode(extra, (address[2], uint256[3], bytes));

        require(
            howToCalls[0] == AuthenticatedProxy.HowToCall.Call,
            "ERC1155WithValue: call must be a direct call"
        );

        require(
            addresses[2] == creatorAndTokenGive[1],
            "ERC1155WithValue: call target must equal address of token to give"
        );

        uint256[1] memory call_amounts = [getERC1155AmountFromCalldata(data)];

        require(
            tokenIdPriceRoyalties[1] * call_amounts[0] == uints[0],
            "ERC1155WithValue: value sent must equal to token price x amount in eth"
        );

        uint256 new_fill = (uints[5] + call_amounts[0]);

        require(
            new_fill <= uints[1],
            "ERC1155WithValue: new fill exceeds maximum fill"
        );

        checkERC1155Side(
            data,
            addresses[1],
            addresses[4],
            tokenIdPriceRoyalties[0],
            call_amounts[0]
        );

        return new_fill;
    }

    function anyERC20ForERC1155(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory counterdata
    ) public pure returns (uint256) {
        require(uints[0] == 0, "anyERC20ForERC1155: Zero value required");
        require(
            howToCalls[0] == AuthenticatedProxy.HowToCall.Call,
            "anyERC20ForERC1155: call must be a direct call"
        );

        (
            address[2] memory tokenGiveGet,
            uint256[3] memory tokenIdAndNumeratorDenominator
        ) = abi.decode(extra, (address[2], uint256[3]));

        require(
            tokenIdAndNumeratorDenominator[1] > 0,
            "anyERC20ForERC1155: numerator must be larger than zero"
        );
        require(
            tokenIdAndNumeratorDenominator[2] > 0,
            "anyERC20ForERC1155: denominator must be larger than zero"
        );
        require(
            addresses[2] == tokenGiveGet[0],
            "anyERC20ForERC1155: call target must equal address of token to get"
        );
        require(
            addresses[5] == tokenGiveGet[1],
            "anyERC20ForERC1155: countercall target must equal address of token to give"
        );

        uint256[2] memory call_amounts = [
            getERC1155AmountFromCalldata(counterdata),
            getERC20AmountFromCalldata(data)
        ];
        uint256 new_fill = (uints[5] + call_amounts[1]);
        require(
            new_fill <= uints[1],
            "anyERC20ForERC1155: new fill exceeds maximum fill"
        );
        require(
            (tokenIdAndNumeratorDenominator[1] * call_amounts[0]) ==
               (
                    tokenIdAndNumeratorDenominator[2] *
                    call_amounts[1]
                ),
            "anyERC20ForERC1155: wrong ratio"
        );
        checkERC1155Side(
            counterdata,
            addresses[4],
            addresses[1],
            tokenIdAndNumeratorDenominator[0],
            call_amounts[0]
        );
        checkERC20Side(data, addresses[1], addresses[4], call_amounts[1]);
        return new_fill;
    }

    function LazyERC1155ForERC20(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory counterdata
    ) public pure returns (uint256) {
        require(uints[0] == 0, "lazyERC1155ForERC20: Zero value required");
        require(
            howToCalls[0] == AuthenticatedProxy.HowToCall.Call,
            "lazyERC1155ForERC20: call must be a direct call"
        );

        (
            address[2] memory tokenGiveGet,
            uint256[3] memory tokenIdAndNumeratorDenominator,
            bytes memory extraBytes
        ) = abi.decode(extra, (address[2], uint256[3], bytes));

        require(
            tokenIdAndNumeratorDenominator[1] > 0,
            "lazyERC1155ForERC20: numerator must be larger than zero"
        );
        require(
            tokenIdAndNumeratorDenominator[2] > 0,
            "lazyERC1155ForERC20: denominator must be larger than zero"
        );
        require(
            addresses[2] == tokenGiveGet[0],
            "lazyERC1155ForERC20: call target must equal address of token to give"
        );
        require(
            addresses[5] == tokenGiveGet[1],
            "lazyERC1155ForERC20: countercall target must equal address of token to get"
        );

        uint256[2] memory call_amounts = [
            abi.decode(ArrayUtils.arraySlice(data, 68, 32), (uint256)),
            getERC20AmountFromCalldata(counterdata)
        ];
        uint256 new_fill = (uints[5] +call_amounts[0]);
        require(
            new_fill <= uints[1],
            "anyERC1155ForERC20: new fill exceeds maximum fill"
        );
        require(
            (tokenIdAndNumeratorDenominator[1] * call_amounts[1]) ==
                (
                    tokenIdAndNumeratorDenominator[2] *
                    call_amounts[0]
                ),
            "lazyERC1155ForERC20: wrong ratio"
        );
        require(
            ArrayUtils.arrayEq(
                data,
                abi.encodeWithSignature(
                    "mint(address,uint256,uint256,bytes)",
                    addresses[4],
                    tokenIdAndNumeratorDenominator[0],
                    call_amounts[0],
                    extraBytes
                )
            ),
            "Data arity mismatch"
        );
        require(
            ArrayUtils.arrayEq(
                counterdata,
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    addresses[4],
                    addresses[1],
                    call_amounts[1]
                )
            ),
            "Counterdata arity mismatch"
        );
        return new_fill;
    }

    function LazyERC20ForERC1155(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory counterdata
    ) public pure returns (uint256) {
        require(uints[0] == 0, "lazyERC20ForERC1155: Zero value required");
        require(
            howToCalls[0] == AuthenticatedProxy.HowToCall.Call,
            "lazyERC20ForERC1155: call must be a direct call"
        );

        (
            address[2] memory tokenGiveGet,
            uint256[3] memory tokenIdAndNumeratorDenominator,
            bytes memory extraBytes
        ) = abi.decode(extra, (address[2], uint256[3], bytes));

        require(
            tokenIdAndNumeratorDenominator[1] > 0,
            "lazyERC20ForERC1155: numerator must be larger than zero"
        );
        require(
            tokenIdAndNumeratorDenominator[2] > 0,
            "lazyERC20ForERC1155: denominator must be larger than zero"
        );
        require(
            addresses[2] == tokenGiveGet[0],
            "lazyERC20ForERC1155: call target must equal address of token to get"
        );
        require(
            addresses[5] == tokenGiveGet[1],
            "lazyERC20ForERC1155: countercall target must equal address of token to give"
        );

        uint256[2] memory call_amounts = [
            abi.decode(ArrayUtils.arraySlice(counterdata, 68, 32), (uint256)),
            getERC20AmountFromCalldata(data)
        ];
        uint256 new_fill = (uints[5] + call_amounts[1]);
        require(
            new_fill <= uints[1],
            "lazyERC20ForERC1155: new fill exceeds maximum fill"
        );
        require(
            (tokenIdAndNumeratorDenominator[1] * call_amounts[0]) ==
               (
                    tokenIdAndNumeratorDenominator[2] *
                    call_amounts[1]
                ),
            "lazyERC20ForERC1155: wrong ratio"
        );
        require(
            ArrayUtils.arrayEq(
                counterdata,
                abi.encodeWithSignature(
                    "mint(address,uint256,uint256,bytes)",
                    addresses[1],
                    tokenIdAndNumeratorDenominator[0],
                    call_amounts[0],
                    extraBytes
                )
            ),
            "Counterdata arity mismatch"
        );
        require(
            ArrayUtils.arrayEq(
                data,
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    addresses[1],
                    addresses[4],
                    call_amounts[1]
                )
            ),
            "Data arity mismatch"
        );
        return new_fill;
    }

    function anyERC20ForERC20(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory counterdata
    ) public pure returns (uint256) {
        require(uints[0] == 0, "anyERC20ForERC20: Zero value required");
        require(
            howToCalls[0] == AuthenticatedProxy.HowToCall.Call,
            "anyERC20ForERC20: call must be a direct call"
        );

        (
            address[2] memory tokenGiveGet,
            uint256[2] memory numeratorDenominator
        ) = abi.decode(extra, (address[2], uint256[2]));

        require(
            numeratorDenominator[0] > 0,
            "anyERC20ForERC20: numerator must be larger than zero"
        );
        require(
            numeratorDenominator[1] > 0,
            "anyERC20ForERC20: denominator must be larger than zero"
        );
        require(
            addresses[2] == tokenGiveGet[0],
            "anyERC20ForERC20: call target must equal address of token to give"
        );
        require(
            addresses[5] == tokenGiveGet[1],
            "anyERC20ForERC20: countercall target must equal address of token to get"
        );

        uint256[2] memory call_amounts = [
            getERC20AmountFromCalldata(data),
            getERC20AmountFromCalldata(counterdata)
        ];
        uint256 new_fill = (uints[5] + call_amounts[0]);
        require(
            new_fill <= uints[1],
            "anyERC20ForERC20: new fill exceeds maximum fill"
        );
        require(
            (numeratorDenominator[0] * call_amounts[0]) ==
               (numeratorDenominator[1] * call_amounts[1]),
            "anyERC20ForERC20: wrong ratio"
        );
        checkERC20Side(data, addresses[1], addresses[4], call_amounts[0]);
        checkERC20Side(
            counterdata,
            addresses[4],
            addresses[1],
            call_amounts[1]
        );
        return new_fill;
    }

    function ERC721ForERC20(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory counterdata
    ) public pure returns (uint256) {
        require(uints[0] == 0, "ERC721ForERC20: Zero value required");
        require(
            howToCalls[0] == AuthenticatedProxy.HowToCall.Call,
            "ERC721ForERC20: call must be a direct call"
        );

        (
            address[2] memory tokenGiveGet,
            uint256[2] memory tokenIdAndPrice
        ) = abi.decode(extra, (address[2], uint256[2]));

        require(
            tokenIdAndPrice[1] > 0,
            "ERC721ForERC20: ERC721 price must be larger than zero"
        );
        require(
            addresses[2] == tokenGiveGet[0],
            "ERC721ForERC20: call target must equal address of token to give"
        );
        require(
            addresses[5] == tokenGiveGet[1],
            "ERC721ForERC20: countercall target must equal address of token to get"
        );

        checkERC721Side(data, addresses[1], addresses[4], tokenIdAndPrice[0]);
        checkERC20Side(
            counterdata,
            addresses[4],
            addresses[1],
            tokenIdAndPrice[1]
        );
        return 1;
    }

    function ERC20ForERC721(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory counterdata
    ) public pure returns (uint256) {
        require(uints[0] == 0, "ERC20ForERC721: Zero value required");
        require(
            howToCalls[0] == AuthenticatedProxy.HowToCall.Call,
            "ERC20ForERC721: call must be a direct call"
        );

        (
            address[2] memory tokenGiveGet,
            uint256[2] memory tokenIdAndPrice
        ) = abi.decode(extra, (address[2], uint256[2]));

        require(
            tokenIdAndPrice[1] > 0,
            "ERC20ForERC721: ERC721 price must be larger than zero"
        );
        require(
            addresses[2] == tokenGiveGet[0],
            "ERC20ForERC721: call target must equal address of token to give"
        );
        require(
            addresses[5] == tokenGiveGet[1],
            "ERC20ForERC721: countercall target must equal address of token to get"
        );

        checkERC721Side(
            counterdata,
            addresses[4],
            addresses[1],
            tokenIdAndPrice[0]
        );
        checkERC20Side(data, addresses[1], addresses[4], tokenIdAndPrice[1]);
        return 1;
    }

    function LazyERC721ForERC20(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory counterdata
    ) public pure returns (uint256) {
        require(uints[0] == 0, "LazyERC721ForERC20: Zero value required");
        require(
            howToCalls[0] == AuthenticatedProxy.HowToCall.Call,
            "ERC721ForERC20: call must be a direct call"
        );
        (
            address[2] memory tokenGiveGet,
            uint256[2] memory tokenIdAndPrice,
            bytes memory extraBytes
        ) = abi.decode(extra, (address[2], uint256[2], bytes));

        require(
            tokenIdAndPrice[1] > 0,
            "LazyERC721ForERC20: ERC721 price must be larger than zero"
        );
        require(
            addresses[2] == tokenGiveGet[0],
            "ERC721ForERC20: call target must equal address of token to give"
        );
        require(
            addresses[5] == tokenGiveGet[1],
            "ERC721ForERC20: countercall target must equal address of token to get"
        );
        require(
            ArrayUtils.arrayEq(
                data,
                abi.encodeWithSignature(
                    "mint(address,uint256,bytes)",
                    addresses[4],
                    tokenIdAndPrice[0],
                    extraBytes
                )
            ),
            "Data arity mismatch"
        );
        require(
            ArrayUtils.arrayEq(
                counterdata,
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    addresses[4],
                    addresses[1],
                    tokenIdAndPrice[1]
                )
            ),
            "Counterdata arity mismatch"
        );
        return 1;
    }

    function LazyERC20ForERC721(
        bytes memory extra,
        address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory counterdata
    ) public pure returns (uint256) {
        require(uints[0] == 0, "ERC20ForERC721: Zero value required");
        require(
            howToCalls[0] == AuthenticatedProxy.HowToCall.Call,
            "ERC20ForERC721: call must be a direct call"
        );

        (
            address[2] memory tokenGiveGet,
            uint256[2] memory tokenIdAndPrice,
            bytes memory extraBytes
        ) = abi.decode(extra, (address[2], uint256[2], bytes));

        require(
            tokenIdAndPrice[1] > 0,
            "ERC20ForERC721: ERC721 price must be larger than zero"
        );
        require(
            addresses[2] == tokenGiveGet[0],
            "ERC20ForERC721: call target must equal address of token to give"
        );
        require(
            addresses[5] == tokenGiveGet[1],
            "ERC20ForERC721: countercall target must equal address of token to get"
        );
        require(
            ArrayUtils.arrayEq(
                counterdata,
                abi.encodeWithSignature(
                    "mint(address,uint256,bytes)",
                    addresses[1],
                    tokenIdAndPrice[0],
                    extraBytes
                )
            ),
            "Counterdata arity mismatch"
        );
        require(
            ArrayUtils.arrayEq(
                data,
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    addresses[1],
                    addresses[4],
                    tokenIdAndPrice[1]
                )
            ),
            "Data arity mismatch"
        );
        return 1;
    }

    // internal helper functions
    function getERC1155AmountFromCalldata(bytes memory data)
        internal
        pure
        returns (uint256)
    {
        uint256 amount = abi.decode(
            ArrayUtils.arraySlice(data, 100, 32),
            (uint256)
        );
        return amount;
    }

    function getERC20AmountFromCalldata(bytes memory data)
        internal
        pure
        returns (uint256)
    {
        uint256 amount = abi.decode(
            ArrayUtils.arraySlice(data, 68, 32),
            (uint256)
        );
        return amount;
    }

    function checkERC1155Side(
        bytes memory data,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal pure {
        require(
            ArrayUtils.arrayEq(
                data,
                abi.encodeWithSignature(
                    "safeTransferFrom(address,address,uint256,uint256,bytes)",
                    from,
                    to,
                    tokenId,
                    amount,
                    ""
                )
            ),
            "Data arity mismatch"
        );
    }

    function checkERC721Side(
        bytes memory data,
        address from,
        address to,
        uint256 tokenId
    ) internal pure {
        require(
            ArrayUtils.arrayEq(
                data,
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    from,
                    to,
                    tokenId
                )
            ),
            "Data arity mismatch"
        );
    }

    function checkERC20Side(
        bytes memory data,
        address from,
        address to,
        uint256 amount
    ) internal pure {
        require(
            ArrayUtils.arrayEq(
                data,
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    from,
                    to,
                    amount
                )
            ),
            "Data arity mismatch"
        );
    }
}
