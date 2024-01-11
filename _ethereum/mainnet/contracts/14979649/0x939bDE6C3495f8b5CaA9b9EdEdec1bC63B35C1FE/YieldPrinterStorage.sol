// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

import "./Initializable.sol";
import "./ILendingPool.sol";
import "./Comptroller.sol";
import "./ILendingPoolAddressesProvider.sol";
import "./StorageSlot.sol";

contract YieldPrinterStorage is Initializable {

    function initializeStorage(address _comptroller, address _lpAddressesProvider)  public initializer {
        ILendingPoolAddressesProvider addressesProvider = ILendingPoolAddressesProvider(_lpAddressesProvider);
        ILendingPool lendingPool = ILendingPool(addressesProvider.getLendingPool());
        StorageSlot.setAddressAt(keccak256("yieldprinter.comptroller"), _comptroller);
        StorageSlot.setAddressAt(keccak256("yieldprinter.lendingpool"), address(lendingPool));
    }

    function getLendingPool() public view returns (address) {
        return StorageSlot.getAddressAt(keccak256("yieldprinter.lendingpool"));
    }

    function getComptroller() public view returns (address) {
        return StorageSlot.getAddressAt(keccak256("yieldprinter.comptroller"));
    }
}