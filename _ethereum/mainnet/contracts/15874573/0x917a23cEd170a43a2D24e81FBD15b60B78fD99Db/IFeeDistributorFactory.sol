// SPDX-FileCopyrightText: 2022 P2P Validator <info@p2p.org>
// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./IERC165.sol";
import "./IOwnable.sol";

/**
 * @dev External interface of FeeDistributorFactory declared to support ERC165 detection.
 */
interface IFeeDistributorFactory is IOwnable, IERC165 {
    // Events

    /**
    * @notice Emits when a new FeeDistributor instance has been created for a client
    * @param _newFeeDistributorAddress address of the newly created FeeDistributor contract instance
    * @param _clientAddress address of the client for whom the new instance was created
    */
    event FeeDistributorCreated(address indexed _newFeeDistributorAddress, address indexed _clientAddress);

    /**
    * @notice Emits when a new FeeDistributor contract address has been set as a reference instance.
    * @param _referenceFeeDistributor the address of the new reference implementation contract
    */
    event ReferenceInstanceSet(address indexed _referenceFeeDistributor);

    // Functions

    /**
    * @notice Set a new reference implementation of FeeDistributor contract
    * @param _referenceFeeDistributor the address of the new reference implementation contract
    */
    function setReferenceInstance(address _referenceFeeDistributor) external;

    /**
    * @notice Creates a FeeDistributor instance for a client
    * @dev Emits `FeeDistributorCreated` event with the address of the newly created instance
    * @param _client the address of the client
    * @param _serviceBasisPoints basis points (percent * 100) of EL rewards that should go to the service (P2P)
    */
    function createFeeDistributor(address _client, uint96 _serviceBasisPoints) external;

    /**
     * @dev Returns the reference FeeDistributor contract address
     */
    function getReferenceFeeDistributor() external view returns (address);
}
