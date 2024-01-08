// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ISVGTypes.sol";

/// @title ICloudTraits interface
interface ICloudTraits {

    /// Represents the cloud condition
    enum Condition {
        Luminous, Overcast, Stormy, Golden, Magic
    }

    /// Represents the Categories of energies
    enum EnergyCategory {
        Soothe, Center, Grow, Connect, Empower, Enlighten
    }

    /// Represents the formations in CloudCollective
    enum Formation {
        A, B, C, D, E
    }

    /// Represents the cloud scales
    enum Scale {
        Tiny, Petite, Moyenne, Milieu, Grande, Super, Monstre
    }

    /// Represents the seed that forms a group of clouds
    /// @dev organized to fit within 256 bits and consume the least amount of resources
    struct ButterflyEffect {
        uint256 seed;
    }

    /// Represents the forecast of a CloudCollective Cloud
    struct Forecast {
        Formation formation;
        bool mirrored;
        Scale scale;
        Condition condition;
        ISVGTypes.Color color;
        EnergyCategory energyCategory;
        uint8 energy;
        uint200 chaos;
    }
}
