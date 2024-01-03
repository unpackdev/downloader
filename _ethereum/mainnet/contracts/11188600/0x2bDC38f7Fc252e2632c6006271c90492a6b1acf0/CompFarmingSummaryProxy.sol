// File: contracts/CompFarmingSummaryProxyStorage.sol

pragma solidity ^0.5.16;

contract CompFarmingSummaryProxyStorage {
    address public admin;
    address public pendingAdmin;
    address public compFarmingSummaryImplmentation;
    address public pendingCompFarmingSummaryImplmentation;
}


contract CompFarmingSummaryStorageV1 is CompFarmingSummaryProxyStorage{
  
}

// File: contracts/utility/ErrorReporter.sol

pragma solidity ^0.5.16;


contract CompFarmingSummaryErrorReporter {
    enum Error {
        NO_ERROR,
        CTOKEN_NOT_FOUND,
        CETH_NOT_SUPPORTED,
        ACCOUNT_SNAPSHOT_ERROR,
        UNAUTHORIZED
    }

    enum FailureInfo {
        SET_PENDING_IMPLEMENTATION_OWNER_CHECK,
        ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK,
        SET_PENDING_ADMIN_OWNER_CHECK,
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK
    }


     event Failure(uint error, uint info, uint detail);

     function fail(Error err, FailureInfo info) internal returns (uint) {
         emit Failure(uint(err), uint(info), 0);

         return uint(err);
     }

     function failOpaque(Error err, FailureInfo info, uint opaqueError) internal returns (uint) {
         emit Failure(uint(err), uint(info), opaqueError);

         return uint(err);
     }

}

// File: contracts/CompFarmingSummaryProxy.sol

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;




contract CompFarmingSummaryProxy is CompFarmingSummaryProxyStorage, CompFarmingSummaryErrorReporter{
    event NewPendingImplementation(address oldPendingImplementation, address newPendingImplementation);
    event NewImplementation(address oldImplementation, address newImplementation);
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
    event NewAdmin(address oldAdmin, address newAdmin);

    constructor() public {
        admin = msg.sender;
    }

    function _setPendingImplementation(address newPendingImplementation) public returns (uint) {

        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PENDING_IMPLEMENTATION_OWNER_CHECK);
        }

        address oldPendingImplementation = pendingCompFarmingSummaryImplmentation;

        pendingCompFarmingSummaryImplmentation = newPendingImplementation;

        emit NewPendingImplementation(oldPendingImplementation, pendingCompFarmingSummaryImplmentation);

        return uint(Error.NO_ERROR);
    }

    function _acceptImplementation() public returns (uint) {

        if (msg.sender != pendingCompFarmingSummaryImplmentation || pendingCompFarmingSummaryImplmentation == address(0)) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK);
        }

        // Save current values for inclusion in log
        address oldImplementation = compFarmingSummaryImplmentation;
        address oldPendingImplementation = pendingCompFarmingSummaryImplmentation;

        compFarmingSummaryImplmentation = pendingCompFarmingSummaryImplmentation;

        pendingCompFarmingSummaryImplmentation = address(0);

        emit NewImplementation(oldImplementation, compFarmingSummaryImplmentation);
        emit NewPendingImplementation(oldPendingImplementation, pendingCompFarmingSummaryImplmentation);

        return uint(Error.NO_ERROR);
    }


    function _setPendingAdmin(address newPendingAdmin) public returns (uint) {

        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PENDING_ADMIN_OWNER_CHECK);
        }

        address oldPendingAdmin = pendingAdmin;

        pendingAdmin = newPendingAdmin;

        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);

        return uint(Error.NO_ERROR);
    }

    function _acceptAdmin() public returns (uint) {

        if (msg.sender != pendingAdmin || msg.sender == address(0)) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ACCEPT_ADMIN_PENDING_ADMIN_CHECK);
        }

        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        admin = pendingAdmin;

        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);

        return uint(Error.NO_ERROR);
    }

    function () payable external {
        // delegate all other functions to current implementation
        (bool success, ) = compFarmingSummaryImplmentation.delegatecall(msg.data);

        assembly {
              let free_mem_ptr := mload(0x40)
              returndatacopy(free_mem_ptr, 0, returndatasize)

              switch success
              case 0 { revert(free_mem_ptr, returndatasize) }
              default { return(free_mem_ptr, returndatasize) }
        }
    }



}