//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ByteUtils.sol";
import "./interfaces.sol";

/// @title Contract allows to resolve multiple addresses or names at once
/// @author asimaranov
/// @notice Can be used to convert addresses [names] to names [addresses] and text fields e.g. avatars
contract MultiEnsResolver {
    using NameEncoder for string;

    IUniversalResolver public defaultUniversalResolver;
    bytes constant _base = "0123456789abcdef";

    constructor(address universalResolverAddress) {
        defaultUniversalResolver = IUniversalResolver(universalResolverAddress);
    }

    /// @notice Converts addresses to names and text records
    /// @param addresses Addresses to convert to names
    /// @param textFields text fields to fetch e.g. ["avatar"]
    function resolveAddresses(
        address[] calldata addresses, 
        string[] memory textFields
    ) 
        public view 
        returns (
            string[] memory names, 
            string[][] memory textRecords
        ) 
    {
        return resolveAddresses(address(0), addresses, textFields);
    }

    /// @notice Converts addresses to names and text records
    /// @param universalResolver address of the universal resolver
    /// @param addresses Addresses to convert to names
    /// @param textFields text fields to fetch e.g. ["avatar"]
    function resolveAddresses(
        address universalResolver, 
        address[] calldata addresses, 
        string[] memory textFields
    ) 
        public view 
        returns (
            string[] memory names, 
            string[][] memory textRecords
        ) 
    {
        IUniversalResolver universalResolver_ = 
            universalResolver == address(0) ? defaultUniversalResolver : IUniversalResolver(universalResolver);

        names = new string[](addresses.length);
        textRecords = new string[][](addresses.length);

        for (uint256 i = 0; i < addresses.length; i++) {
            textRecords[i] = new string[](textFields.length);
        }

        bytes memory request = hex"28000000000000000000000000000000000000000000000000000000000000000000000000000000000461646472077265766572736500";

        for (uint256 addressId = 0; addressId < names.length; addressId++) {
            uint160 addressToResolve = uint160(addresses[addressId]);
            
            for (uint256 i = 0; i < 20; i++) { 
                request[(20*2 - 1) - i*2] = _base[uint8(addressToResolve >> (i * 8)) / 16];
                request[(20*2 - 1) - i*2 + 1] = _base[uint8(addressToResolve >> (i * 8)) % 16];
            }
            try universalResolver_.reverse(request) returns (string memory name, address, address, address res) {
                (, bytes32 namehash) = name.dnsEncodeName();
                
                for (uint256 i = 0; i < textFields.length; i++) {
                    textRecords[addressId][i] = ITextResolver(res).text(namehash, textFields[i]);
                }

                names[addressId] = name;
            } catch {}
        }
    }

    /// @notice Converts names to addresses and text records
    /// @param names Names to convert to addresses
    /// @param textFields text fields to fetch e.g. ["avatar"]
    function resolveNames(
        string[] calldata names, 
        string[] memory textFields
    ) 
        public view 
        returns (
            address[] memory addresses, 
            string[][] memory textRecords
    ) {
        return resolveNames(address(0), names, textFields);
    }

    /// @notice Converts names to addresses and text records
    /// @param universalResolver address of the universal resolver
    /// @param names Names to convert to addresses
    /// @param textFields text fields to fetch e.g. ["avatar"]
    function resolveNames(
        address universalResolver, 
        string[] calldata names, 
        string[] memory textFields
    ) 
        public view 
        returns (
            address[] memory addresses, 
            string[][] memory textRecords
        ) 
    {
        IUniversalResolver universalResolver_ = 
            universalResolver == address(0) ? defaultUniversalResolver : IUniversalResolver(universalResolver);

        addresses = new address[](names.length);
        textRecords = new string[][](addresses.length);

        for (uint256 i = 0; i < addresses.length; i++) {
            textRecords[i] = new string[](textFields.length);
        }

        for (uint256 nameId = 0; nameId < names.length; nameId++) {
            string memory nameToResolve = names[nameId];
            
            (bytes memory encodedName, bytes32 namehash) = nameToResolve.dnsEncodeName();

            bytes memory encodedCall = abi.encodeCall(
                IAddrResolver.addr,
                namehash
            );

            try universalResolver_.resolve(encodedName, encodedCall) returns (
                bytes memory resolvedData, 
                address resolverAddress
            ) {
                for (uint256 i = 0; i < textFields.length; i++) {
                    textRecords[nameId][i] = ITextResolver(resolverAddress).text(namehash, textFields[i]);
                }

                address resolvedAddress = abi.decode(resolvedData, (address));

                addresses[nameId] = resolvedAddress;
            } catch {}
        }
    }
}
