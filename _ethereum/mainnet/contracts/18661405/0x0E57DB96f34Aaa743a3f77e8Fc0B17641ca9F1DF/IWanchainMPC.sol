// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWanchainMPC {
    /**
     * @dev Retrieves the configuration of a Storeman Group by ID
     * @param id The ID of the Storeman Group to retrieve
     * @return groupId The group ID of the Storeman Group
     * @return status The status of the Storeman Group
     * @return deposit The deposit amount of the Storeman Group
     * @return chain1 The ID of the first chain supported by the Storeman Group
     * @return chain2 The ID of the second chain supported by the Storeman Group
     * @return curve1 The ID of the first elliptic curve supported by the Storeman Group
     * @return curve2 The ID of the second elliptic curve supported by the Storeman Group
     * @return gpk1 The Group Public Key for the first elliptic curve
     * @return gpk2 The Group Public Key for the second elliptic curve
     * @return startTime The start time of the Storeman Group
     * @return endTime The end time of the Storeman Group
     */
    function getStoremanGroupConfig(
        bytes32 id
    ) external view returns (
        bytes32 groupId,
        uint8 status,
        uint deposit,
        uint chain1,
        uint chain2,
        uint curve1,
        uint curve2,
        bytes memory gpk1,
        bytes memory gpk2,
        uint startTime,
        uint endTime
    );

    /**
     * @dev Verifies a signature using the provided parameters
     * @param curveId The ID of the elliptic curve used for the signature
     * @param signature The signature to be verified
     * @param groupKeyX The X component of the group public key
     * @param groupKeyY The Y component of the group public key
     * @param randomPointX The X component of the random point
     * @param randomPointY The Y component of the random point
     * @param message The message that was signed
     * @return true if the signature is valid, false otherwise
     */
    function verify(
        uint curveId,
        bytes32 signature,
        bytes32 groupKeyX,
        bytes32 groupKeyY,
        bytes32 randomPointX,
        bytes32 randomPointY,
        bytes32 message
    ) external returns (bool);

    function getPartners() external view returns(address tokenManager, address smgAdminProxy, address smgFeeProxy, address quota, address sigVerifier);
    
    function currentChainID() external view returns (uint256);
}
