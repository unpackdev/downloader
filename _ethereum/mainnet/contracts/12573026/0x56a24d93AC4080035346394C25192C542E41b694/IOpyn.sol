// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface OtokenInterface {
    function underlyingAsset() external view returns (address);

    function strikeAsset() external view returns (address);

    function collateralAsset() external view returns (address);

    function strikePrice() external view returns (uint256);

    function expiryTimestamp() external view returns (uint256);

    function isPut() external view returns (bool);

    function getOtokenDetails()
        external
        view
        returns (
            address,
            address,
            address,
            uint256,
            uint256,
            bool
        );
}

interface AddressBookInterface {
    function getController() external view returns(address);
    function getMarginCalculator() external view returns(address);
}

interface ControllerInterface {
    function operate(Actions.ActionArgs[] memory _actions) external;
    function isSettlementAllowed(address) external view returns (bool);
    function isSettlementAllowed(address,address,address,uint) external view returns (bool);
}

interface MarginCalculatorInterface {
    function addressBook() external view returns (address);
    function getExpiredPayoutRate(address _otoken) external view returns (uint256);
}

interface Actions {
    // possible actions that can be performed
    enum ActionType {
        OpenVault,
        MintShortOption,
        BurnShortOption,
        DepositLongOption,
        WithdrawLongOption,
        DepositCollateral,
        WithdrawCollateral,
        SettleVault,
        Redeem,
        Call
    }

    struct ActionArgs {
        // type of action that is being performed on the system
        ActionType actionType;
        // address of the account owner
        address owner;
        // address which we move assets from or to (depending on the action type)
        address secondAddress;
        // asset that is to be transfered
        address asset;
        // index of the vault that is to be modified (if any)
        uint256 vaultId;
        // amount of asset that is to be transfered
        uint256 amount;
        // each vault can hold multiple short / long / collateral assets but we are restricting the scope to only 1 of each in this version
        // in future versions this would be the index of the short / long / collateral asset that needs to be modified
        uint256 index;
        // any other data that needs to be passed in for arbitrary function calls
        bytes data;
    }
}

interface IChainLinkPricer {
    function setExpiryPriceInOracle(uint256 _expiryTimestamp, uint256 _roundId) external;
}
