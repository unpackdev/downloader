// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.5;

import "./SafeMath.sol";
import "./SafeERC20.sol";

import "./IOwnable.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./ISTAR.sol";
import "./ISTARDUST.sol";
import "./IBondingCalculator.sol";
import "./ITreasury.sol";

import "./StarshipAccessControlled.sol";

contract StarshipTreasuryV2 is StarshipAccessControlled, ITreasury {
    /* ========== DEPENDENCIES ========== */

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== EVENTS ========== */

    event Claim(address voter, uint256 amount, uint256 value);
    
    event Withdrawal(address indexed token, uint256 amount, uint256 value);
    event CreateDebt(address indexed debtor, address indexed token, uint256 amount, uint256 value);
    event RepayDebt(address indexed debtor, address indexed token, uint256 amount, uint256 value);
    event Managed(address indexed token, uint256 amount);
    event MetaverseManaged(address indexed token, uint256 amount);
    event MetaverseDeposited(address indexed token, uint256 amount);
    event metaverseWrittenOff(uint256 value);
    event metaverseAppreciated(uint256 value);
    event ReservesAudited(uint256 indexed treasuryReserves);
    event Minted(address indexed caller, address indexed recipient, uint256 amount);
    event PermissionQueued(STATUS indexed status, address queued);
    event Permissioned(address addr, STATUS indexed status, bool result);

    /* ========== DATA STRUCTURES ========== */

    enum STATUS {
        RESERVEDEPOSITOR,
        RESERVESPENDER,
        RESERVETOKEN,
        RESERVEMANAGER,
        LIQUIDITYDEPOSITOR,
        LIQUIDITYTOKEN,
        LIQUIDITYMANAGER,
        RESERVEDEBTOR,
        REWARDMANAGER,
        STARDUST,
        STARDEBTOR,
        METAVERSEMANAGER
    }

    /* ========== STATE VARIABLES ========== */

    ISTAR public immutable STAR;
    ISTARDUST public STARDUST;

    mapping(STATUS => address[]) public registry;
    mapping(STATUS => mapping(address => bool)) public permissions;
    mapping(address => address) public bondCalculator;

    mapping(address => uint256) public debtLimit;

    uint256 public treasuryReserves;
    uint256 public metaverseReserves;
    uint256 public totalDebt;
    uint256 public starDebt;

    string internal notAccepted = "Treasury: not accepted";
    string internal notApproved = "Treasury: not approved";
    string internal invalidToken = "Treasury: invalid token";
    string internal insufficientReserves = "Treasury: insufficient reserves";

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _star,
        address _authority
    ) StarshipAccessControlled(IStarshipAuthority(_authority)) {
        require(_star != address(0), "Zero address: STAR");
        STAR = ISTAR(_star);

    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice allow approved address to deposit an asset for STAR
     * @param _from address
     * @param _amount uint256
     * @param _token address
     * @param _profit uint256
     * @return send_ uint256
     */
    function deposit(
        address _from,
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external override returns (uint256 send_) {
        if (permissions[STATUS.RESERVETOKEN][_token]) {
            require(permissions[STATUS.RESERVEDEPOSITOR][msg.sender], notApproved);
        } else if (permissions[STATUS.LIQUIDITYTOKEN][_token]) {
            require(permissions[STATUS.LIQUIDITYDEPOSITOR][msg.sender], notApproved);
        } else {
            revert(invalidToken);
        }

        IERC20(_token).safeTransferFrom(_from, address(this), _amount);

        uint256 value = tokenValue(_token, _amount);
        emit Claim(_token, _profit, value);
        
        // mint STAR needed and store amount of rewards for distribution
        send_ = value.sub(_profit);
        STAR.mint(_from, send_);

        treasuryReserves = treasuryReserves.add(value);
    }

    /**
     * @notice allow approved address to burn STAR for reserves
     * @param _amount uint256
     * @param _token address
     */
    function withdraw(uint256 _amount, address _token) external override {
        require(permissions[STATUS.RESERVETOKEN][_token], notAccepted); // Only reserves can be used for redemptions
        require(permissions[STATUS.RESERVESPENDER][msg.sender], notApproved);

        uint256 value = tokenValue(_token, _amount);
        STAR.burnFrom(msg.sender, value);

        treasuryReserves = treasuryReserves.sub(value);

        IERC20(_token).safeTransfer(msg.sender, _amount);

        emit Withdrawal(_token, _amount, value);
    }

    /**
     * @notice allow approved address to withdraw assets
     * @param _token address
     * @param _amount uint256
     */
    function manage(address _token, uint256 _amount) external override {
        if (permissions[STATUS.LIQUIDITYTOKEN][_token]) {
            require(permissions[STATUS.LIQUIDITYMANAGER][msg.sender], notApproved);
        } else {
            require(permissions[STATUS.RESERVEMANAGER][msg.sender], notApproved);
        }
        if (permissions[STATUS.RESERVETOKEN][_token] || permissions[STATUS.LIQUIDITYTOKEN][_token]) {
            uint256 value = tokenValue(_token, _amount);
            require(value <= excessReserves(), insufficientReserves);
            treasuryReserves = treasuryReserves.sub(value);
        }
        IERC20(_token).safeTransfer(msg.sender, _amount);
        emit Managed(_token, _amount);
    }

    /**
     * @notice allow approved address to deploy treasury funds to the metaverse
     * @param _token address
     * @param _amount uint256
     */
    function withdrawToMetaverse(address _token, uint256 _amount) external {
        require(permissions[STATUS.METAVERSEMANAGER][msg.sender], notApproved);

        uint256 value = tokenValue(_token, _amount);
        treasuryReserves = treasuryReserves.sub(value);
        metaverseReserves = metaverseReserves.add(value);

        IERC20(_token).safeTransfer(msg.sender, _amount);
        emit MetaverseManaged(_token, _amount);
    }

    /**
     * @notice allow approved address to return metaverse funds to the treasury
     * @param _token address
     * @param _amount uint256
     */
    function depositFromMetaverse(address _token, uint256 _amount) external {
        require(permissions[STATUS.METAVERSEMANAGER][msg.sender], notApproved);

        uint256 value = tokenValue(_token, _amount);
        treasuryReserves = treasuryReserves.add(value);
        metaverseReserves = metaverseReserves.sub(value);

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        emit MetaverseDeposited(_token, _amount);
    }

    /**
     * @notice allow approved address to return metaverse funds to the treasury
     * @param _token address
     * @param _amount uint256
     */
    function metaverseWriteOff(address _token, uint256 _amount) external {
        require(permissions[STATUS.METAVERSEMANAGER][msg.sender], notApproved);

        uint256 value = tokenValue(_token, _amount);
        metaverseReserves = metaverseReserves.sub(value);

        emit metaverseWrittenOff(value);
    }
    /**
     * @notice allow approved address to return metaverse funds to the treasury
     * @param _token address
     * @param _amount uint256
     */
    function metaverseAppreciation(address _token, uint256 _amount) external {
        require(permissions[STATUS.METAVERSEMANAGER][msg.sender], notApproved);

        uint256 value = tokenValue(_token, _amount);
        metaverseReserves = metaverseReserves.add(value);

        emit metaverseAppreciated(value);
    }

    /**
     * @notice mint new STAR using excess reserves
     * @param _recipient address
     * @param _amount uint256
     */
    function mint(address _recipient, uint256 _amount) external override {
        require(permissions[STATUS.REWARDMANAGER][msg.sender], notApproved);
        require(_amount <= excessReserves(), insufficientReserves);
        STAR.mint(_recipient, _amount);
        emit Minted(msg.sender, _recipient, _amount);
    }

    /**
     * DEBT: The debt functions allow approved addresses to borrow treasury assets
     * or STAR from the treasury, using STAR as collateral. 
     */

    /**
     * @notice allow approved address to borrow reserves
     * @param _amount uint256
     * @param _token address
     */
    function incurDebt(uint256 _amount, address _token) external override {
        uint256 value;
        if (_token == address(STAR)) {
            require(permissions[STATUS.STARDEBTOR][msg.sender], notApproved);
            value = _amount;
        } else {
            require(permissions[STATUS.RESERVEDEBTOR][msg.sender], notApproved);
            require(permissions[STATUS.RESERVETOKEN][_token], notAccepted);
            value = tokenValue(_token, _amount);
        }
        require(value != 0, invalidToken);

        STARDUST.changeDebt(value, msg.sender, true);
        require(STARDUST.debtBalances(msg.sender) <= debtLimit[msg.sender], "Treasury: exceeds limit");
        totalDebt = totalDebt.add(value);

        if (_token == address(STAR)) {
            STAR.mint(msg.sender, value);
            starDebt = starDebt.add(value);
        } else {
            treasuryReserves = treasuryReserves.sub(value);
            IERC20(_token).safeTransfer(msg.sender, _amount);
        }
        emit CreateDebt(msg.sender, _token, _amount, value);
    }

    /**
     * @notice allow approved address to repay borrowed reserves with reserves
     * @param _amount uint256
     * @param _token address
     */
    function repayDebtWithReserve(uint256 _amount, address _token) external override {
        require(permissions[STATUS.RESERVEDEBTOR][msg.sender], notApproved);
        require(permissions[STATUS.RESERVETOKEN][_token], notAccepted);
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        uint256 value = tokenValue(_token, _amount);
        STARDUST.changeDebt(value, msg.sender, false);
        totalDebt = totalDebt.sub(value);
        treasuryReserves = treasuryReserves.add(value);
        emit RepayDebt(msg.sender, _token, _amount, value);
    }

    /**
     * @notice allow approved address to repay borrowed reserves with star
     * @param _amount uint256
     */
    function repayDebtWithSTAR(uint256 _amount) external {
        require(
            permissions[STATUS.RESERVEDEBTOR][msg.sender] || permissions[STATUS.STARDEBTOR][msg.sender],
            notApproved
        );
        STAR.burnFrom(msg.sender, _amount);
        STARDUST.changeDebt(_amount, msg.sender, false);
        totalDebt = totalDebt.sub(_amount);
        starDebt = starDebt.sub(_amount);
        emit RepayDebt(msg.sender, address(STAR), _amount, _amount);
    }

    /* ========== MANAGERIAL FUNCTIONS ========== */

    /**
     * @notice takes inventory of all tracked assets
     * @notice always consolidate to recognized reserves before audit
     */
    function auditReserves() external onlyGovernor {
        uint256 reserves;
        address[] memory reserveToken = registry[STATUS.RESERVETOKEN];
        for (uint256 i = 0; i < reserveToken.length; i++) {
            if (permissions[STATUS.RESERVETOKEN][reserveToken[i]]) {
                reserves = reserves.add(tokenValue(reserveToken[i], IERC20(reserveToken[i]).balanceOf(address(this))));
            }
        }
        address[] memory liquidityToken = registry[STATUS.LIQUIDITYTOKEN];
        for (uint256 i = 0; i < liquidityToken.length; i++) {
            if (permissions[STATUS.LIQUIDITYTOKEN][liquidityToken[i]]) {
                reserves = reserves.add(
                    tokenValue(liquidityToken[i], IERC20(liquidityToken[i]).balanceOf(address(this)))
                );
            }
        }
        treasuryReserves = reserves;
        emit ReservesAudited(reserves);
    }

    /**
     * @notice set max debt for address
     * @param _address address
     * @param _limit uint256
     */
    function setDebtLimit(address _address, uint256 _limit) external onlyGovernor {
        debtLimit[_address] = _limit;
    }

    /**
     * @notice enable permission from queue
     * @param _status STATUS
     * @param _address address
     * @param _calculator address
     */
    function enable(
        STATUS _status,
        address _address,
        address _calculator
    ) external onlyGovernor {
        if (_status == STATUS.STARDUST) {
            STARDUST = ISTARDUST(_address);
        } else {
            permissions[_status][_address] = true;

            if (_status == STATUS.LIQUIDITYTOKEN) {
                bondCalculator[_address] = _calculator;
            }

            (bool registered, ) = indexInRegistry(_address, _status);
            if (!registered) {
                registry[_status].push(_address);

            }
        }
        emit Permissioned(_address, _status, true);
    }

    /**
     *  @notice disable permission from address
     *  @param _status STATUS
     *  @param _toDisable address
     */
    function disable(STATUS _status, address _toDisable) external {
        require(msg.sender == authority.governor() || msg.sender == authority.guardian(), "Only governor or guardian");
        permissions[_status][_toDisable] = false;
        if (_status == STATUS.LIQUIDITYTOKEN || _status == STATUS.RESERVETOKEN) {
            (bool reg, uint256 index) = indexInRegistry(_toDisable, _status);
            if (reg) {
                delete registry[_status][index];
            }
        }

        emit Permissioned(_toDisable, _status, false);
    }

    /**
     * @notice check if registry contains address
     * @return (bool, uint256)
     */
    function indexInRegistry(address _address, STATUS _status) public view returns (bool, uint256) {
        address[] memory entries = registry[_status];
        for (uint256 i = 0; i < entries.length; i++) {
            if (_address == entries[i]) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice returns excess reserves not backing tokens
     * @return uint
     */
    function excessReserves() public view override returns (uint256) {
        uint256 totalReserve = treasuryReserves + metaverseReserves;
        return totalReserve.sub(STAR.totalSupply().sub(totalDebt));
    }   

    /**
     * @notice returns total reserves in treasury and metaverse
     * @return uint
     */
    function totalReserves() public view returns (uint256) {
        return treasuryReserves.add(metaverseReserves);
    }   

    /**
     * @notice returns star'd valuation of asset
     * @param _token address
     * @param _amount uint256
     * @return value_ uint256
     */
    function tokenValue(address _token, uint256 _amount) public view override returns (uint256 value_) {
        value_ = _amount.mul(10**IERC20Metadata(address(STAR)).decimals()).div(10**IERC20Metadata(_token).decimals());
        if (permissions[STATUS.LIQUIDITYTOKEN][_token]) {
            value_ = IBondingCalculator(bondCalculator[_token]).valuation(_token, _amount);
        }
    }

    /**
     * @notice returns supply metric that cannot be manipulated by debt
     * @dev use this any time you need to query supply
     * @return uint256
     */
    function baseSupply() external view override returns (uint256) {
        return STAR.totalSupply() - starDebt;
    }
}
