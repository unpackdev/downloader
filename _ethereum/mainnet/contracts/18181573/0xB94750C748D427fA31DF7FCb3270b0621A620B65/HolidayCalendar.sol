// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/// @notice Data contract encoding NYSE holidays from 2023 to 2123. Each 14-byte
///         block encodes one year, consisting of 12 9-bit values, each
///         representing a month and day. Use HolidaysLibrary to decode.
contract HolidayCalendar {
    constructor() {
        bytes memory data = (
            hex"00" // STOP opcode
            hex"0110c0a8bd69b924949b55df3200" // 2023
            hex"0108bca6bb69b92454eb5df33200" // 2024
            hex"0108d0a2ba69b92434db5def3200" // 2025
            hex"0108cca0b969b8e4f4cb5deb3200" // 2026
            hex"0108c89ebf693964d4bb5de7319f" // 2027
            hex"0000c4aabd69b924949b55df3200" // 2028
            hex"0108bca6bc69b924748b65db3200" // 2029
            hex"0108d4a4bb69b92454eb5df33200" // 2030
            // 2031 - 2040
            hex"0108d0a2ba69b92434db5def32000108cca0bf693964d4bb5de7319f"
            hex"0000c4aabe6a3924b4ab5de334000110c0a8bd69b924949b55df3200"
            hex"0108bca6bc69b924748b65db32000108d4a4ba69b92434db5def3200"
            hex"0108cca0b969b8e4f4cb5deb32000108c89ebf693964d4bb5de7319f"
            hex"0000c4aabe6a3924b4ab5de334000110c0a8bc69b924748b65db3200"
            // 2041 - 2050
            hex"0108d4a4bb69b92454eb5df332000108d0a2ba69b92434db5def3200"
            hex"0108cca0b969b8e4f4cb5deb32000108c89ebe6a3924b4ab5de33400"
            hex"0110c0a8bd69b924949b55df32000108bca6bc69b924748b65db3200"
            hex"0108d4a4bb69b92454eb5df332000108d0a2b969b8e4f4cb5deb3200"
            hex"0108c89ebf693964d4bb5de7319f0000c4aabe6a3924b4ab5de33400"
            // 2051 - 2060
            hex"0110c0a8bd69b924949b55df32000108bca6bb69b92454eb5df33200"
            hex"0108d0a2ba69b92434db5def32000108cca0b969b8e4f4cb5deb3200"
            hex"0108c89ebf693964d4bb5de7319f0000c4aabd69b924949b55df3200"
            hex"0108bca6bc69b924748b65db32000108d4a4bb69b92454eb5df33200"
            hex"0108d0a2ba69b92434db5def32000108cca0bf693964d4bb5de7319f"
            // 2061 - 2070
            hex"0000c4aabe6a3924b4ab5de334000110c0a8bd69b924949b55df3200"
            hex"0108bca6bc69b924748b65db32000108d4a4ba69b92434db5def3200"
            hex"0108cca0b969b8e4f4cb5deb32000108c89ebf693964d4bb5de7319f"
            hex"0000c4aabe6a3924b4ab5de334000110c0a8bc69b924748b65db3200"
            hex"0108d4a4bb69b92454eb5df332000108d0a2ba69b92434db5def3200"
            // 2071 - 2080
            hex"0108cca0b969b8e4f4cb5deb32000108c89ebe6a3924b4ab5de33400"
            hex"0110c0a8bd69b924949b55df32000108bca6bc69b924748b65db3200"
            hex"0108d4a4bb69b92454eb5df332000108d0a2b969b8e4f4cb5deb3200"
            hex"0108c89ebf693964d4bb5de7319f0000c4aabe6a3924b4ab5de33400"
            hex"0110c0a8bd69b924949b55df32000108bca6bb69b92454eb5df33200"
            // 2081 - 2090
            hex"0108d0a2ba69b92434db5def32000108cca0b969b8e4f4cb5deb3200"
            hex"0108c89ebf693964d4bb5de7319f0000c4aabd69b924949b55df3200"
            hex"0108bca6bc69b924748b65db32000108d4a4bb69b92454eb5df33200"
            hex"0108d0a2ba69b92434db5def32000108cca0bf693964d4bb5de7319f"
            hex"0000c4aabe6a3924b4ab5de334000110c0a8bd69b924949b55df3200"
            // 2091 - 2100
            hex"0108bca6bc69b924748b65db32000108d4a4ba69b92434db5def3200"
            hex"0108cca0b969b8e4f4cb5deb32000108c89ebf693964d4bb5de7319f"
            hex"0000c4aabe6a3924b4ab5de334000110c0a8bc69b924748b65db3200"
            hex"0108d4a4bb69b92454eb5df332000108d0a2ba69b92434db5def3200"
            hex"0108cca0b969b8e4f4cb5deb32000108c89ebf693964d4bb5de7319f"
            // 2101 - 2110
            hex"0000c4aabe6a3924b4ab5de334000110c0a8bd69b924949b55df3200"
            hex"0108bca6bc69b924748b65db32000108d4a4ba69b92434db5def3200"
            hex"0108cca0b969b8e4f4cb5deb32000108c89ebf693964d4bb5de7319f"
            hex"0000c4aabe6a3924b4ab5de334000110c0a8bc69b924748b65db3200"
            hex"0108d4a4bb69b92454eb5df332000108d0a2ba69b92434db5def3200"
            // 2111 - 2120
            hex"0108cca0b969b8e4f4cb5deb32000108c89ebe6a3924b4ab5de33400"
            hex"0110c0a8bd69b924949b55df32000108bca6bc69b924748b65db3200"
            hex"0108d4a4bb69b92454eb5df332000108d0a2b969b8e4f4cb5deb3200"
            hex"0108c89ebf693964d4bb5de7319f0000c4aabe6a3924b4ab5de33400"
            hex"0110c0a8bd69b924949b55df32000108bca6bb69b92454eb5df33200"
            // 2121 - 2123
            hex"0108d0a2ba69b92434db5def32000108cca0b969b8e4f4cb5deb3200"
            hex"0108c89ebf693964d4bb5de7319f"
        );
        assembly {
            return(add(data, 0x20), mload(data))
        }
    }
}
