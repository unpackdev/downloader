//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IVaultFactory {

    /// ###### only admin ######


    /// @dev set LogEvent Contract address
    /// @param _addr logEvent contract address
    function setLogEventAddress(address _addr) external ;


    /// @dev designate an admin to upgrade the vault logic later.
    /// @param addr the upgradeAdmin address
    function setUpgradeAdmin(
        address addr
    )   external;


    /// @dev set the logic address
    /// @param _logic  the logic address
    function setLogic(
        address _logic
    )   external;


    /// @dev set the contract's logic
    /// @param _contract  the contract address
    /// @param _logic  the logic address
    /// @param _index  logic index
    /// @param _alive  alive flag , true or false
    function upgradeContractLogic(
        address _contract,
        address _logic,
        uint256 _index,
        bool _alive
    )   external;


    /// @dev set the contract's function's logic
    /// @param _contract  the contract address
    /// @param _selectors  function's selectors
    /// @param _imp  logic  address
    function upgradeContractFunction(
        address _contract,
        bytes4[] calldata _selectors,
        address _imp
    )   external;


    /// @dev view the upgradeAdmin address
    /// @param admin  the upgradeAdmin address
    function upgradeAdmin() external view returns (address admin);


    /// @dev view the logic address
    /// @param logic the logic address
    function vaultLogic() external view returns (address logic);


    /// ### anybody can use

    /// @dev Last generated contract information
    /// @return contractAddress the address created
    /// @return name name
    function lastestCreated() external view returns (address contractAddress, string memory name);


    /// @dev Contract information stored in the index
    /// @return contractAddress the vault address
    /// @return name name
    function getContracts(uint256 _index) external view returns (address contractAddress, string memory name);


    /// @dev the number of total created contracts
    /// @return total  total count
    function totalCreatedContracts() external view returns (uint256 total);

}
