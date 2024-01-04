pragma solidity 0.6.8;

/**
 * @title   DaoGovernable
 * @author  Stability Labs Pty. Ltd.
 * @notice  Simple contract implementing an Ownable pattern.
 * @dev     Derives from V2.3.0 @openzeppelin/contracts/ownership/Ownable.sol
 *          Modified to have custom name and features
 *              - Removed `renounceOwnership`
 *              - Changes `_owner` to `_governor`
 */
contract DaoGovernable {

    event DaoChanged(address indexed previousDao, address indexed newDao);

    address private _dao;

    /**
     * @dev Initializes the contract setting supplied address as the initial Dao.
     */
    // constructor (address _newDao) internal {
    //     _dao = _newDao;
    //     emit DaoChanged(address(0), _dao);
    // }
    
    function __DaoGovernable_init(address _newDao) internal {
        _dao = _newDao;
        emit DaoChanged(address(0), _dao);
    }

    /**
     * @dev Returns the address of the current Dao.
     */
    function dao() public view returns (address) {
        return _dao;
    }

    /**
     * @dev Throws if called by any account other than the Dao.
     */
    modifier onlyDao() {
        require(isDao(), "GOV: caller is not the Dao");
        _;
    }

    /**
     * @dev Returns true if the caller is the current Dao.
     */
    function isDao() public view returns (bool) {
        return msg.sender == _dao;
    }

    /**
     * @dev Transfers Dao of the contract to a new account (`newDao`).
     * Can only be called by the current Dao.
     * @param _newDao Address of the new Dao
     */
    function changeDao(address _newDao) external onlyDao {
        _changeDao(_newDao);
    }

    /**
     * @dev Change Dao of the contract to a new account (`newDao`).
     * @param _newDao Address of the new Governor
     */
    function _changeDao(address _newDao) internal {
        require(_newDao != address(0), "GOV: new Dao is address(0)");
        emit DaoChanged(_dao, _newDao);
        _dao = _newDao;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;

}
