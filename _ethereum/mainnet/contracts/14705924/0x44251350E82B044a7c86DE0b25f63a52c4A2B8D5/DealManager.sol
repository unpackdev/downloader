// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./Clones.sol";
import "./Ownable.sol";
import "./IDaoDepositManager.sol";
import "./IModuleBase.sol";

/**
 * @title                   PrimeDeals Deal Manager
 * @notice                  Smart contract to serve as the manager
                            for the PrimeDeals architecture
 */
contract DealManager is Ownable {
    /// Address of the current implementation of the
    /// DaoDepositManager
    address public daoDepositManagerImplementation;
    /// Address of the ETH wrapping contract
    address public immutable weth;
    /// Address DAO => address DaoDepositManager of the DAO
    mapping(address => address) public daoDepositManager;
    /// module address => true/false
    mapping(address => bool) public isModule;

    /**
     * @notice                      This event is emitted when a DaoDepositManager is created
     * @param dao                   DAO address to which the DaoDepositManager is linked
     * @param daoDepositManager     Newly created DaoDepositManager contract address
     */
    event DaoDepositManagerCreated(
        address indexed dao,
        address indexed daoDepositManager
    );

    /**
     * @notice                      Constructor
     * @param _daoDepositManager    The address of the DaoDepositManager implementation
     */
    constructor(address _daoDepositManager, address _weth) {
        require(
            _daoDepositManager != address(0) &&
                _daoDepositManager != address(this),
            "DealManager: Error 100"
        );
        require(
            _weth != address(0) && _weth != address(this),
            "DealManager: Error 100"
        );
        daoDepositManagerImplementation = _daoDepositManager;
        weth = _weth;
    }

    /**
     * @notice                      Sets a new address for the DaoDepositManager implementation
     * @param _newImplementation    The new address of the DaoDepositManager
     */
    function setDaoDepositManagerImplementation(address _newImplementation)
        external
        onlyOwner
    {
        // solhint-disable-next-line reason-string
        require(
            _newImplementation != address(0) &&
                _newImplementation != address(this),
            "DealManager: Error 100"
        );
        daoDepositManagerImplementation = _newImplementation;
    }

    function setDealManagerInModule(address _newDealManager, address _module)
        external
        onlyOwner
    {
        require(
            _newDealManager != address(0) && _newDealManager != address(this),
            "DealManager: Error 100"
        );
        IDaoDepositManager(_module).setDealManager(_newDealManager);
    }

    /**
     * @notice                  Activates a new Deals module
     * @param _moduleAddress    The address of a Deals module
     */
    function activateModule(address _moduleAddress) external onlyOwner {
        require(
            _moduleAddress != address(0) && _moduleAddress != address(this),
            "DealManager: Error 100"
        );
        require(
            IModuleBase(_moduleAddress).dealManager() == address(this),
            "DealManager: Error 260"
        );

        isModule[_moduleAddress] = true;
    }

    /**
     * @notice                  Deactivates a Deals module
     * @param _moduleAddress    The address of a Deals module
     */
    function deactivateModule(address _moduleAddress) external onlyOwner {
        require(
            _moduleAddress != address(0) && _moduleAddress != address(this),
            "DealManager: Error 100"
        );

        isModule[_moduleAddress] = false;
    }

    /**
     * @notice              Creates a DaoDepositManager for a DAO
     * @param _dao          Address of the DAO for the DaoDepositContract
     */
    function createDaoDepositManager(address _dao) public {
        require(
            _dao != address(0) && _dao != address(this),
            "DealManager: Error 100"
        );
        require(
            daoDepositManager[_dao] == address(0),
            "DealManager: Error 001"
        );
        require(
            daoDepositManagerImplementation != address(0),
            "DealManager: Error 261"
        );
        address newContract = Clones.clone(daoDepositManagerImplementation);
        IDaoDepositManager(newContract).initialize(_dao);
        require(
            IDaoDepositManager(newContract).dealManager() == address(this),
            "DealManager: Error 260"
        );
        daoDepositManager[_dao] = newContract;
        emit DaoDepositManagerCreated(_dao, newContract);
    }

    /**
     * @notice              Returns whether a DAO already has a DaoDepositManager
     * @param _dao          DAO address for which to check for an existing DaoDepositManger
     * @return bool         A bool flag indicating whether a DaoDepositManager contract exists
     */
    function hasDaoDepositManager(address _dao) external view returns (bool) {
        return getDaoDepositManager(_dao) != address(0) ? true : false;
    }

    /**
     * @notice              Returns the DaoDepositManager of a DAO
     * @param _dao          DAO address for which to return the DaoDepositManger
     * @return address      Address of the DaoDepositManager associated with the _dao
     */
    function getDaoDepositManager(address _dao) public view returns (address) {
        return daoDepositManager[_dao];
    }
}
