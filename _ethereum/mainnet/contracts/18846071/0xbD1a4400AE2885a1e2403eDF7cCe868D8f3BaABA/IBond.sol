pragma solidity ^0.8.9;

interface IBond {
    struct Bond {
        /// @dev  The bond ID.
        uint256 id;
        /// @dev static interest rate of the bond
        uint256 staticInterestRate;
        /// @dev accured interest of the bond in USDC
        uint256 accruedInterest;
        /// @dev The last updated epoch.
        uint256 lastUpdatedEpoch;
        /// @dev The epoch when the bond was disqualified until.
        uint256 disqualifiedUntilEpoch;
        /// @dev The number of epochs the bond was disqualified for.
        uint256 disqualifiedEpochCount;
        /// @dev The value of the bond denominated in USDC.
        uint256 value;
        /// @dev The amount of tokens deposited.
        uint256 amountDeposited;
        /// @dev The address of the token contract or zero address if ETH.
        address contractAddress;
        /// @dev The date when the bond was minted.
        uint256 mintedAt;
    }

    struct CurrencyDetails {
        /// @dev The minimum amount of tokens that can be purchased
        uint256 minimum;
        /// @dev The maximum amount of tokens that can be purchased
        uint256 maximum;
        /// @dev The maximum supply of tokens
        uint256 maximumSupply;
        /// @dev The total amount of tokens minted
        uint256 totalMinted;
        /// @dev The interest rate of the bond
        uint256 interestRate;
    }
}
