import "./LibSmartWallet.sol";
import "./SmartWalletDiamond.sol";
import "./BaseModule.sol";

pragma solidity 0.8.19;

// SPDX-License-Identifier: MIT

interface ISmartWallet {
    function initialize(address diamond) external;
}


contract SmartWalletDiamondFactory is BaseModule {
    constructor() BaseModule("DezySmartWalletFactory") {}

    error Create2Fail();
    error Unauthorized();

    event WalletCreation(address, address);

    function createWallet() public returns (address) {
        return createWallet(msg.sender);
    }

    function createWallet(address user) public returns (address) {
        if (address(this) != BaseModule.diamond) revert Unauthorized();
        bytes32 salt = keccak256(abi.encode("DezySmartWalletFactory"));
        address create2Addr = address(
            new SmartWalletDiamond{salt: salt}(user)
        );
        if (create2Addr == address(0)) revert Create2Fail();
        ISmartWallet(create2Addr).initialize(BaseModule.diamond);
        LibSmartWallet.setUserWallet(user, create2Addr);
        emit WalletCreation(user, create2Addr);
        return create2Addr;
    }

    /// @dev gets the user address given a smartwallet address
    function getUserFromWallet(address wallet) public view returns (address) {
        return LibSmartWallet.getUserFromWallet(wallet);
    }

    /// @dev gets the smartwallet address given a user address
    function getWalletFromUser(address user) public view returns (address) {
        return LibSmartWallet.getWalletFromuser(user);
    }
}
