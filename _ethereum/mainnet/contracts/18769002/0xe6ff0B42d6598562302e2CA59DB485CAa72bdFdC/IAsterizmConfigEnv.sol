// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IAsterizmConfigEnv {

    /// Base transfer direction DTO
    /// @param externalRelayExists bool  Is external relay exists flag
    /// @param externalRelayFee uint  External relay fee
    /// @param systemFee uint  System fee
    struct ConfigDataResponseDto {
        bool externalRelayExists;
        uint externalRelayFee;
        uint systemFee;
    }
}
