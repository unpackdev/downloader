// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./AccessControlEnumerableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";

/**
 * @dev this contract represents the credit line in the whitelist.
 * @dev the guild's credit line amount
 * @dev the decimals is 1e18.
 */
contract CreditSystem is AccessControlEnumerableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /// the role manage total credit manager
    bytes32 public constant ROLE_CREDIT_MANAGER =
        keccak256("ROLE_CREDIT_MANAGER");

    uint8 public constant G2G_MASK = 0x0E;
    uint8 public constant CCAL_MASK = 0x0D;
    uint8 constant IS_G2G_START_BIT_POSITION = 0;
    uint8 constant IS_CCAL_START_BIT_POSITION = 1;

    struct CreditInfo {
        //ERC20 credit line
        uint256 g2gCreditLine;
        //ccal module credit line
        uint256 ccalCreditLine;
        //bit 0: g2g isActive flag(0==false, 1==true)
        //bit 1: ccal isActive flag(0==false, 1==true)
        uint8 flag;
    }

    // the credit line
    mapping(address => CreditInfo) whiteList;
    //g2g whiteList Set
    EnumerableSetUpgradeable.AddressSet private g2gWhiteSet;
    //ccal whiteList Set
    EnumerableSetUpgradeable.AddressSet private ccalWhiteSet;

    event SetG2GCreditLine(address user, uint256 amount);

    event SetCCALCreditLine(address user, uint256 amount);

    // event SetPaused(address user, bool flag);
    event SetG2GActive(address user, bool active);

    event SetCCALActive(address user, bool active);

    event RemoveG2GCredit(address user);

    event RemoveCCALCredit(address user);

    modifier onlyCreditManager() {
        require(
            hasRole(ROLE_CREDIT_MANAGER, _msgSender()),
            "only the manager has permission to perform this operation."
        );
        _;
    }

    // constructor() {
    //     _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    // }
    function initialize() public initializer {
        __AccessControlEnumerable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * set the address's g2g module credit line
     * @dev user the guild in the whiteList
     * @dev amount the guild credit line amount
     * @dev 1U = 1e18
     */
    function setG2GCreditLine(address user, uint256 amount)
        public
        onlyCreditManager
    {
        whiteList[user].g2gCreditLine = amount;
        setG2GActive(user, amount > 0);

        emit SetG2GCreditLine(user, amount);
    }

    /**
     * @dev set the address's g2g module credit active status
     */
    function setG2GActive(address user, bool active) public onlyCreditManager {
        //set user flag
        setG2GFlag(user, active);
        //set user white set
        if (active) {
            uint256 userG2GCreditLine = getG2GCreditLine(user);
            userG2GCreditLine > 0 ? g2gWhiteSet.add(user) : g2gWhiteSet.remove(user);
        } else {
            g2gWhiteSet.remove(user);
        }

        emit SetG2GActive(user, active);
    }

    function setG2GFlag(address user, bool active) private {
        uint8 flag = whiteList[user].flag;
        flag =
            (flag & G2G_MASK) |
            (uint8(active ? 1 : 0) << IS_G2G_START_BIT_POSITION);
        whiteList[user].flag = flag;
    }

    /**
     * set the address's ccal module credit line
     * @dev user the guild in the whiteList
     * @dev amount the guild credit line amount
     * @dev 1U = 1e18
     */
    function setCCALCreditLine(address user, uint256 amount)
        public
        onlyCreditManager
    {
        whiteList[user].ccalCreditLine = amount;
        setCCALActive(user, amount > 0);

        emit SetCCALCreditLine(user, amount);
    }

    /**
     * @dev set the address's ccal module credit active status
     */
    function setCCALActive(address user, bool active) public onlyCreditManager {
        //set user flag
        setCCALFlag(user, active);
        //set user white set
        if (active) {
            uint256 userCCALCreditLine = getCCALCreditLine(user);
            userCCALCreditLine > 0 ? ccalWhiteSet.add(user) : ccalWhiteSet.remove(user);
        } else {
            ccalWhiteSet.remove(user);
        }

        emit SetCCALActive(user, active);
    }

    function setCCALFlag(address user, bool active) private {
        uint8 flag = whiteList[user].flag;
        flag =
            (flag & CCAL_MASK) |
            (uint8(active ? 1 : 0) << IS_CCAL_START_BIT_POSITION);
        whiteList[user].flag = flag;
    }

    /**
     * remove the address's g2g module credit line
     */
    function removeG2GCredit(address user) public onlyCreditManager {
        whiteList[user].g2gCreditLine = 0;
        setG2GActive(user, false);

        emit RemoveG2GCredit(user);
    }

    /**
     * remove the address's ccal module credit line
     */
    function removeCCALCredit(address user) public onlyCreditManager {
        whiteList[user].ccalCreditLine = 0;
        setCCALActive(user, false);

        emit RemoveCCALCredit(user);
    }


    /**
     * @dev query the user credit line
     * @param user the address which to query
     * @return G2G credit line
     */
    function getG2GCreditLine(address user) public view returns (uint256) {
        CreditInfo memory credit = whiteList[user];
        return credit.g2gCreditLine;
    }

    /**
     * @dev query the user credit line
     * @param user the address which to query
     * @return CCAL credit line
     */
    function getCCALCreditLine(address user) public view returns (uint256) {
        CreditInfo memory credit = whiteList[user];
        return credit.ccalCreditLine;
    }

    /**
     * @dev query the white list addresses in G2G
     */
    function getG2GWhiteList() public view returns (address[] memory) {
        return g2gWhiteSet.values();
    }

    /**
     * @dev query the white list addresses in CCAL
     */
    function getCCALWhiteList() public view returns (address[] memory) {
        return ccalWhiteSet.values();
    }

    /**
     * @dev query the address state
     */
    function getState(address user) public view returns (bool, bool) {
        uint8 activeFlag = whiteList[user].flag;
        return (
            activeFlag & ~G2G_MASK != 0,
            activeFlag & ~CCAL_MASK != 0
        );
    }
}
