enum OptionType {Invalid, Put, Call}

enum PurchaseMethod {Invalid, Contract, ZeroEx}

struct OptionTerms {
    address underlying;
    address strikeAsset;
    address collateralAsset;
    uint256 expiry;
    uint256 strikePrice;
    OptionType optionType;
}

struct ZeroExOrder {
    address exchangeAddress;
    address buyTokenAddress;
    address sellTokenAddress;
    address allowanceTarget;
    uint256 protocolFee;
    uint256 makerAssetAmount;
    uint256 takerAssetAmount;
    bytes swapData;
}