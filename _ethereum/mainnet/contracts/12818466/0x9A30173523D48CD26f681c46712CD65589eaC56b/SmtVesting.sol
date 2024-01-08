//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./ERC20PresetMinterPauser.sol";

/**
 * @title SmtPriceFeed
 * @author Protofire
 * @dev Contract module used to lock SMT during Vesting period.
 */
contract SmtVesting is ERC20PresetMinterPauser {

    using SafeMath for uint256;

    /// @dev ERC20 basic token contract being held
    IERC20 public acceptedToken;
    
    /// @dev distribution start timestamp
    uint256 public distributionStartTime;

    /// @dev Know Your Asset
    string public KYA;

    /// @dev time constants
    uint256 private constant SECONDS_IN_QUARTER = 7889238; // 60*60*24×30,436875*3 = 7889238  number of seconds in one quarter
   // uint256 private constant SECONDS_IN_12HOURS = 43200; // 60*60*12
   // uint256 private constant SECONDS_IN_5_MINUTES = 300; // 60*5


    /// @dev trasnferable addresses whitelist
    mapping (address => bool) public whitelist;

    /// @dev trasnferable addresses whitelist
    mapping (address => uint256) public claimings;

    /// @dev Emitted when `owner` claims.
    event Claim(address indexed owner, uint256 amount);

    /// @dev Emitted when `owner` claims.
    event AcceptedTokenSet(address _acceptedToken);

    /// @dev Emitted when `owner` claims.
    event StartTimeSet (uint256 startTime);

    /// @dev Emitted when one address is included in trasnferable whitelist.
    event WhitelistedAddress (address whitelisted);
    
    /**
     * @dev Sets the value for {distributionStartTime}, signaling that distribution yet needs to be determined by admin
     *
     * Sets ownership to the given `_owner`.
     *
     */
    constructor(string memory name_, string memory symbol_)
        ERC20PresetMinterPauser(name_, symbol_) {
         distributionStartTime = 0;
    }

    /**
     * @dev Sets the value for `acceptedToken`.
     *
     * Requirements:
     *
     * - the caller must have DEFAULT_ADMIN_ROLE.
     * - `_token` can't be zero address
     * - `acceptedToken` should not be already set
     *
     */
    function setAcceptedToken(address _token) external {

        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "must have DEFAULT_ADMIN_ROLE");
        require(_token != address(0), "token is the zero address");
        require(address(acceptedToken) == address(0), "token is already set");

        acceptedToken = IERC20(_token);
        emit AcceptedTokenSet(_token);
    }
    
    /**
     * @dev Locks certain  _amount of `acceptedToken`.
     *
     * Requirements:
     *
     * - the caller must have DEFAULT_ADMIN_ROLE.
     * - `acceptedToken` need tbe approved first by caller on `acceptedToken` contract
     */
    function deposit(uint256 _amount) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "must have DEFAULT_ADMIN_ROLE");
        acceptedToken.transferFrom(_msgSender(), address(this), _amount);
        _mint(_msgSender(), _amount);
    }

    /**
     * @dev check funds locked by this contract in terms of acceptedToken's balance
     *
     */
    function getCurrentLockedAmount() external view {
        acceptedToken.balanceOf(address(this));
    }

    /**
     * @dev sets KYA
     *
     * Requirements:
     *
     * - the caller must have DEFAULT_ADMIN_ROLE.
     *
     */
    function setKYA(string calldata _knowYourAsset) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "must have DEFAULT_ADMIN_ROLE");
        KYA = _knowYourAsset;
    }

    /**
     * @dev add _address to the whitlist, signaling that it can make transfers of this token
     *
     * Requirements:
     *
     * - the caller must have DEFAULT_ADMIN_ROLE.
     * - `_address` can not be zero address
     */
    function addWhitelistedAddress(address _address) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "must have DEFAULT_ADMIN_ROLE");
        require(_address != address(0), "_address is the zero address");

        whitelist[_address] = true;

        emit WhitelistedAddress(_address);

    }

    /**
     * @dev burns certain `amount` of vSMT token and release quivalent balance of acceptedToken
     *
     * Requirements:
     *
     * - amount must be lower or equal than ClaimableAmount
     * - distributionStartTime must be different than 0
     * - `_address` can not be zero address
     */
    function claim (uint256 amount) public {
        require(distributionStartTime!=0, "Starttime not set");
        uint256 claimableAmount = getClaimableAmount(_msgSender());
        require(claimableAmount>=amount, "amount too big");
        acceptedToken.transfer(_msgSender(), amount);
        _burn(_msgSender(), amount);

        claimings[_msgSender()] = claimings[_msgSender()].add(amount);
        emit Claim(_msgSender(), amount);
    }

    /**
     * @dev minting directly is disallowed
     *
     */
    function mint(address to, uint256 amount) public pure override {
        revert("Minting is only allowed using deposit function");
    }
     /**
     * @dev burning directly is disallowed `amount`
     * 
     */
    function burn(uint256 amount) public pure override {
         revert("Burning is only allowed using claim function");
    }
    function burnFrom(address account, uint256 amount) public pure override {
         revert("Burning is only allowed using claim function");
    }
    /**
     * @dev only whitelisted address are allowed to transfer this token's ownership
     * address 0x0 are allowed by default cause we need to burn and mint tokens
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(!paused(), "ERC20Pausable: token transfer while paused");
        bool allowed= whitelist[from]||from==address(0)||to==address(0);
        require(allowed, "trasnfer is just allowed for whitelisted addresses");
    }

    /**
     * @dev claims maximun available amount from caller's holdings
     *
     */
    function claimMaximunAmount() external {
        uint256 amount = getClaimableAmount(_msgSender());
        require(amount!=0, "nothing to claim");
        claim(amount);
    }

    /**
     * @dev calculates how much is currently available to be claimed by caller
     * on Q1 20%, on Q2 40%, on Q3 60%, on Q4 80%, 100% after Q4
     *
     * Requirements:
     *
     * - distributionStartTime must be different from 0
     */
    function getClaimableAmount(address awarded) public view returns (uint256 amount) {

        require(distributionStartTime!=0, "Starttime not set");

        uint256 currentQuarter = currentQuarterSinceStartTime();
        uint256 balanceOnAuction = balanceOf(awarded).add(claimings[awarded]);

        if (currentQuarter == 0) {
            return (balanceOnAuction.mul(2).div(10)).sub(claimings[awarded]);
        }  
        if (currentQuarter == 1) {
           return (balanceOnAuction.mul(4).div(10)).sub(claimings[awarded]);
        }
        if (currentQuarter == 2) {
            return (balanceOnAuction.mul(6).div(10)).sub(claimings[awarded]);
        }
        if (currentQuarter == 3) {
            return (balanceOnAuction.mul(8).div(10)).sub(claimings[awarded]);
        }
        if (currentQuarter >= 4) {
            return balanceOf(awarded);
        }
    }

    /**
     * @dev returns number of quarters passed from distributionStartTime
     */
    function currentQuarterSinceStartTime() public view returns (uint256 currentQuarter){

        require(distributionStartTime!=0, "distributionStartTime not set yet");
        require(distributionStartTime<block.timestamp,  "Vesting did not start yet");
        return (block.timestamp.sub(distributionStartTime)).div(SECONDS_IN_QUARTER);
    }
    
    /**
     * @dev sets distributionStartTime as the timestamp on which funds starts a progresive release 
     *
     * Requirements:
     *
     * - distributionStartTime must be equal to 0
     * - distributionStartTime must be a unix timestamp format, grater than current timestamp
     */
    function setStartTime(uint256 startTime) external {
        
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "must have DEFAULT_ADMIN_ROLE");
        require((distributionStartTime == 0), "distributionStartTime can be set just one time");
        require(startTime > block.timestamp, "Start time must be a future timestamp");

        distributionStartTime = startTime;
        emit StartTimeSet(startTime);
    }
}