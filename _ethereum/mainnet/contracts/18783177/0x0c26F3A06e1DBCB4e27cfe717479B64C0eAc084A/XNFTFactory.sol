// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./XNFTAssetManager.sol";

//
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@#,,,,,,,,,,,,,,,,,,,,,,,,.
//    (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%.
//    (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%.
//    (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%.
//    (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%.
//    /&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&(.
//    Created for locksonic.io
//    support@locksonic.io

/// @title XNFT Factory Contract
/// @author Wilson A.
/// @notice Used for creating proxy of XNFTClone contract
contract XNFTFactory is XNFTAssetManager {
    /**
     * @dev Initializes the contract with the specified parameters.
     * @param _minMintPrice The minimum minting price for NFTs.
     * @param _marketplaceFeeAddress The address to receive marketplace fees.
     * @param _newOperator The address of the new operator.
     * @param _whitelist The address of the whitelist contract.
     * @param _xnftBeaconAddress The address of the beacon contract.
     */
    function initialize(
        uint256 _minMintPrice,
        address _marketplaceFeeAddress,
        address _newOperator,
        address _whitelist,
        address _xnftBeaconAddress,
        address _xnftLPBeaconAddress
    ) public initializer {
        require(_marketplaceFeeAddress != address(0), "invalid address");
        require(_newOperator != address(0), "invalid address");
        require(_whitelist != address(0), "invalid address");
        require(_xnftBeaconAddress != address(0), "invalid beacon address");
        require(
            _xnftLPBeaconAddress != address(0),
            "invalid lp beacon address"
        );
        __NFTweetsBase_init();
        minMintPrice = _minMintPrice;
        marketplaceFeeAddress = _marketplaceFeeAddress;
        _operator = _newOperator;
        whitelists[_whitelist] = true;
        _xnftBeacon = _xnftBeaconAddress;
        _xnftLPBeacon = _xnftLPBeaconAddress;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Gets account information based on the account name hash.
     * @param _accountNameHash The hash of the account name.
     * @return AccountInfo struct containing account details, number of mints, account id and account addresses.
     */
    function getAccountInfo(
        bytes32 _accountNameHash
    )
        external
        view
        returns (AccountInfo memory, uint256, uint256, uint256, uint256)
    {
        uint256 _accountId = accountNames[_accountNameHash];
        require(_accountId >= 1, "account not found");
        uint256 tvl = _accountTvl(_accountId);
        uint256 nftRedeemPrice = redeemPrice(_accountId);
        return (
            accounts[_accountId],
            mintCount[_accountId],
            _accountId,
            tvl,
            nftRedeemPrice
        );
    }

    /**
     * @dev Gets the mint count for a specific user associated with an account.
     * @param _accountNameHash The hash of the account name.
     * @param user The address of the user for whom to retrieve the mint count.
     * @return The number of mints for the specified user and account.
     */
    function getUserMintCount(
        bytes32 _accountNameHash,
        address user
    ) external view returns (uint256) {
        uint256 _accountId = accountNames[_accountNameHash];
        require(_accountId >= 1, "account not found");
        return (userMintCount[_accountId][user]);
    }

    /**
     * @dev Retrieves the account address information associated with a specific account name hash.
     * @param _accountNameHash The hash of the account name.
     * @return The `AccountAddressInfo` struct containing information about the account address.
     */
    function getAccountAddresses(
        bytes32 _accountNameHash
    ) external view returns (AccountAddressInfo memory) {
        uint256 _accountId = accountNames[_accountNameHash];
        require(_accountId >= 1, "account not found");
        return accountAddresses[_accountId];
    }
}
