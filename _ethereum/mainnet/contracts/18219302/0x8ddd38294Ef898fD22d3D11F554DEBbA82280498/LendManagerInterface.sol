// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title MetaLend's manager error interface
 * @author MetaLend
 * @notice defines the errors for reporting during reverts
 * @dev use this with proxy and implementation to report errors
 */
interface LendManagerErrorInterface {
    /**
     * @notice Thrown when guarded function is called by non admin address
     * @param caller address of the invalid caller
     */
    error ErrCallerNotAdmin(address caller);

    /**
     * @notice Thrown when trying to set implementation of mediator to address which is not mediator
     * @param implementation the address of the invalid implementation
     */
    error ErrImplementationNotLendMediator(address implementation);

    /**
     * @notice Thrown when input param is an invalid number (e.g. does not fit constraints)
     * @param num the invalid number
     */
    error ErrInvalidNumber(uint256 num);

    /**
     * @notice Thrown when input param is an invalid address (such as address(0))
     * @param addr the invalid address
     */
    error ErrInvalidAddress(address addr);

    /**
     * @notice Thrown when user tries to create a mediator and it already exists
     * @param user the user with existing mediator
     * @param mediator the existing mediator address
     */
    error ErrMediatorExists(address user, address mediator);
}

/**
 * @title MetaLend's manager event interface
 * @author MetaLend
 * @notice defines the events emitted during interaction
 * @dev use this with proxy and implementation to emit events
 */
interface LendManagerEventInterface {
    /**
     * @notice emitted when a new mediator is created
     * @param user address of the account which creates the new mediator contract
     * @param mediator address of the mediator contract
     */
    event NewLendMediator(address indexed user, address indexed mediator);
    /**
     * @notice emitted when a global mediator implementation changes
     * @param previous the previous implementation address
     * @param next the new implementation address
     */
    event NewLendMediatorImplementation(address indexed previous, address indexed next);

    /**
     * @notice emitted when a royalties percentage changes
     * @param previous the previous percentage value
     * @param next the new percentage value
     */
    event NewRoyaltiesPercentage(uint256 indexed previous, uint256 indexed next);

    /**
     * @notice emitted when a new royalties receiver is set
     * @param previous the previous receiver
     * @param next the new receiver
     */
    event NewRoyaltiesReceiver(address indexed previous, address indexed next);

    /**
     * @notice emitted when a new offer signer is set
     * @param previous the previous offer signer
     * @param next the new offer signer
     */
    event NewOfferSigner(address indexed previous, address indexed next);
}

/**
 * @title MetaLend's manager function interface
 * @author MetaLend
 * @notice defines the functions usable in manager contracts
 * @dev use this with implementation contract to override functions
 */
interface LendManagerFunctionInterface {
    /**
     * @notice denominator to calculate percentage
     * @dev use this to calculate percentages
     * @return uint256 10000
     */
    function feeDenominator() external pure returns (uint256);

    /**
     * @notice creates a new mediator for user
     * @dev reverts if mediator already exists for given address
     */
    function createLendMediator() external;

    /**
     * @notice sets the new value for royalties percentage
     * @dev called only by MetaLend admin
     *  100 = 1%, based on {feeDenominator}
     * @param newPercentage the new percentage for royalties
     */
    function setRoyaltiesPercentage(uint256 newPercentage) external;

    /**
     * @notice sets the new royalties receiver
     * @dev called only by MetaLend admin
     * @param newReceiver address of the new receiver
     */
    function setRoyaltiesReceiver(address payable newReceiver) external;

    /**
     * @notice sets the new implementation for all mediator contracts
     * @dev called only by MetaLend admin
     * @param newImplementation address of the new implementation contract
     */
    function setLendMediatorImplementation(address newImplementation) external;

    /**
     * @notice sets the new address of the signer of offers
     * @dev called only by MetaLend admin
     * @param newSigner address of the new signer of offers
     */
    function setOfferSigner(address newSigner) external;

    /**
     * @notice returns a value modified by royalties precentage
     * @param value the uint256 value to modify
     * @return uint256 the result
     */
    function getValueByRoyaltiesPercentage(uint256 value) external view returns (uint256);
}

/**
 * @title MetaLend's manager proxy interface
 * @author MetaLend
 * @notice defines setImplementation proxy function and event and error
 * @dev use this interface with manager proxy
 */
interface LendManagerProxyInterface {
    /**
     * @notice Thrown when guarded function is called by non admin address
     * @param caller address of the invalid caller
     */
    error ErrCallerNotAdmin(address caller);

    /**
     * @notice Thrown when input param is an invalid address (such as address(0))
     * @param addr the invalid address
     */
    error ErrInvalidAddress(address addr);

    /**
     * @notice Thrown when trying to set implementation of manager to address which is not manager
     * @param implementation the address of the invalid implementation
     */
    error ErrImplementationNotLendManager(address implementation);

    /**
     * @notice Emitted when implementation is changed
     * @param previous address of the old implementation contract
     * @param next address of the new implementation contract
     */
    event NewImplementation(address indexed previous, address indexed next);

    /**
     * @notice emitted when an admin is changed
     * @param previous the previous admin
     * @param next the new admin
     */
    event NewAdmin(address indexed previous, address indexed next);

    /**
     * @notice sets the new implementation for the proxy contract
     * @dev should be available to be called only under specific cirmustances (such as an admin account)
     * @param newImplementation the address of the new implementation contract
     */
    function setImplementation(address newImplementation) external;

    /**
     * @notice sets the new admin
     * @dev called only by MetaLend admin
     * @param newAdmin the new admin of the protocol
     */
    function setAdmin(address newAdmin) external;
}
