pragma solidity 0.7.6;

import "./ERC20.sol";

interface IAPWToken is ERC20 {
    /**
     * @notice Getter for the APWine DAO address
     * @return the address of the DAO
     */
    function getDAO() external view returns (address);

    /**
     * @notice Getter for the vesting contract address
     * @return the address of the vesting contract
     */
    function getVestingContract() external view returns (address);

    /**
     * @notice Setter for the APWine DAO
     * @param _DAO the new APWine DAO address
     * @dev the caller must be the current DAO
     */
    function setDAO(address _DAO) external;

    /**
     * @notice Mint tokens to the specified wallet
     * @param _to the address of the receiver
     * @param _amount the amount of token to mint
     * @dev caller must be granted to MINTER_ROLE
     */
    function mint(address _to, uint256 _amount) external;
}
