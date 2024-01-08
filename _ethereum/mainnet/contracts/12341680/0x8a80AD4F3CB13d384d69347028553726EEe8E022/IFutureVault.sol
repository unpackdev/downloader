pragma solidity 0.7.6;

interface IFutureVault {
    /**
     * @notice Intializer
     * @param _futureAddress the address of the corresponding future
     * @param _adminAddress the address of the corresponding admin
     */
    function initialize(address _futureAddress, address _adminAddress) external;

    /**
     * @notice Getter for the future address
     * @return the future address linked to this vault
     */
    function getFutureAddress() external view returns (address);

    /**
     * @notice Approve another token to be transfered from this contract by the future
     */
    function approveAdditionalToken(address _tokenAddress) external;
}
