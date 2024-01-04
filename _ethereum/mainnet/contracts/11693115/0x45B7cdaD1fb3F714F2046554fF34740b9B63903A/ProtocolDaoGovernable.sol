pragma solidity 0.6.8;

/**
 * @title   ProtocolDaoGovernable
 * @author  Stability Labs Pty. Ltd.
 * @notice  Simple contract implementing an Ownable pattern.
 * @dev     Derives from V2.3.0 @openzeppelin/contracts/ownership/Ownable.sol
 *          Modified to have custom name and features
 *              - Removed `renounceOwnership`
 *              - Changes `_owner` to `_governor`
 */
contract ProtocolDaoGovernable {

    event ProtocolDaoChanged(address indexed previousProtocolDao, address indexed newProtocolDao);

    address private _protocolDao;

    /**
     * @dev Initializes the contract setting supplied address as the initial Protocol Dao.
     */
    // constructor (address _newProtocolDao) internal {
    //     _protocolDao = _newProtocolDao;
    //     emit ProtocolDaoChanged(address(0), _protocolDao);
    // }

    function __ProtocolDaoGovernable_init(address _newProtocolDao) internal {
        _protocolDao = _newProtocolDao;
        emit ProtocolDaoChanged(address(0), _protocolDao);
    }

    /**
     * @dev Returns the address of the current Protocol Dao.
     */
    function protocolDao() public view returns (address) {
        return _protocolDao;
    }

    /**
     * @dev Throws if called by any account other than the Protocol Dao.
     */
    modifier onlyProtocolDao() {
        require(isProtocolDao(), "GOV: caller is not the Protocol Dao");
        _;
    }

    /**
     * @dev Returns true if the caller is the current Protocol Dao.
     */
    function isProtocolDao() public view returns (bool) {
        return msg.sender == _protocolDao;
    }

    /**
     * @dev Transfers Protocol Dao of the contract to a new account (`newProtocolDao`).
     * Can only be called by the current Protocol Dao.
     * @param _newProtocolDao Address of the new Protocol Dao
     */
    function changeProtocolDao(address _newProtocolDao) external onlyProtocolDao {
        _changeProtocolDao(_newProtocolDao);
    }

    /**
     * @dev Change Protocol Dao of the contract to a new account (`newProtocolDao`).
     * @param _newProtocolDao Address of the new Governor
     */
    function _changeProtocolDao(address _newProtocolDao) internal {
        require(_newProtocolDao != address(0), "GOV: new Protocol Dao is address(0)");
        emit ProtocolDaoChanged(_protocolDao, _newProtocolDao);
        _protocolDao = _newProtocolDao;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;

}
