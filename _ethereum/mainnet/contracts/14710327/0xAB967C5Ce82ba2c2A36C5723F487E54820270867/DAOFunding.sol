pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./MOSToken.sol";

// A funding contract that allows purchase of shares
contract DAOFunding is ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    address public governance;

    IERC20 public wantToken;
    MOSToken public daoToken;
    uint256 public rate;
    uint256 public convertCap;
    uint256 public currentBalance;

    bool public whitelistEnabled;
    mapping(address => bool) public isWhitelisted;
    address[] public whitelist;

    mapping(address => uint256) public records; // Tracking of shares of funders to avoid going over sharesCap
    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _wantToken,
        address _daoToken,
        uint _rate,
        uint _convertCap,
        bool _whitelistEnabled,
        uint _existingBalance // this is to migrate old data
    )
    {
        wantToken = IERC20(_wantToken);
        daoToken = MOSToken(_daoToken);
        rate = _rate;
        convertCap = _convertCap;
        whitelistEnabled = _whitelistEnabled;
        currentBalance = _existingBalance;

        governance = msg.sender;
    }

    /* ========== MODIFIER ========== */

    modifier onlyGovernance() {
        require(msg.sender == governance, "!gov");
        _;
    }

    modifier onlyWhitelist() {
        if (whitelistEnabled) {
          require(isWhitelisted[msg.sender] == true, "!whitelist");
        }
        _;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    // fund the dao and get dao token
    function contribute(uint256 _amount) external nonReentrant onlyWhitelist {
        uint256 w = _amount.mul(rate);
        require(currentBalance.add(w) <= convertCap, "cap-exceeded");

        wantToken.safeTransferFrom(msg.sender, address(this), _amount);
        daoToken.mint(msg.sender, w);
        currentBalance = currentBalance.add(w);
        records[msg.sender] = records[msg.sender].add(_amount);
        
    }

    /* ========== VIEW FUNCTIONS ========== */

    function whitelistLength() external view returns (uint256) {
        return whitelist.length;
    }

    function holdings(address _token)
        public
        view
        returns (uint)
    {
        return IERC20(_token).balanceOf(address(this));
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function takeOut(
        address _token,
        address _destination,
        uint _amount
    )
        external
        onlyGovernance
    {
        require(_amount <= holdings(_token), "!insufficient");
        SafeERC20.safeTransfer(IERC20(_token), _destination, _amount);
    }

    function setGovernance(address _governance)
        external
        onlyGovernance
    {
        governance = _governance;
    }

    function setWantToken(address _want)
        external
        onlyGovernance
    {
        wantToken = IERC20(_want);
    }

    function setDAOToken(address _dao)
        external
        onlyGovernance
    {
        daoToken = MOSToken(_dao);
    }

    function setRate(uint _rate)
        external
        onlyGovernance
    {
        rate = _rate;
    }

    function setConvertCap(uint _convertCap)
        external
        onlyGovernance
    {
        convertCap = _convertCap;
    }

    function setWhitelistEnabled(bool _status)
        external
        onlyGovernance
    {
        whitelistEnabled = _status;
    }

    function addToWhitelist(address _user)
        external
        onlyGovernance
    {
        require(isWhitelisted[_user] == false, "already in whitelist");
        isWhitelisted[_user] = true;
        whitelist.push(_user);
    }

    function removeFromWhitelist(address _user)
        external
        onlyGovernance
    {
        require(isWhitelisted[_user] == true, "not in whitelist");
        isWhitelisted[_user] = false;

        // find the index
        uint indexToDelete = 0;
        bool found = false;
        for (uint i = 0; i < whitelist.length; i++) {
            if (whitelist[i] == _user) {
                indexToDelete = i;
                found = true;
                break;
            }
        }

        // remove element
        require(found == true, "user not found in whitelist");
        whitelist[indexToDelete] = whitelist[whitelist.length - 1];
        whitelist.pop();
    }

    // use with cautiou
    // this is to prevent removeFromWhitelist function failed.
    function forceRemoveUserInWhitelist(address _user)
        external
        onlyGovernance
    {
        require(isWhitelisted[_user] == true, "not in whitelist");
        isWhitelisted[_user] = false;
    }

    // use with cautiou
    // this is to prevent removeFromWhitelist function failed.
    function forceRemoveIndexFromWhitelist(uint _indexToDelete)
        external
        onlyGovernance
    {
        // remove element
        whitelist[_indexToDelete] = whitelist[whitelist.length - 1];
        whitelist.pop();
    }
    
}