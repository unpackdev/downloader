//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./AggregatorPriceFeeds.sol";
import "./IERC20Metadata.sol";
import "./BancorFormula.sol";
import "./ITreasury.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./IFriendPerp.sol";
import "./IVesting.sol";

contract Treasury is
    BancorFormula,
    ITreasury,
    Ownable,
    ReentrancyGuard,
    Pausable
{
    using SafeERC20 for IERC20;

    /*///////////////////////////////////////////////////////////////
                                 CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 public constant SCALE = 10 ** 18;
    uint256 internal constant VALID_PERIOD = 1 days;
    uint256 internal constant MIN_VALUE = 50 * 10 ** 18;
    uint256 public RESERVE_RATIO = 800000;

    IVesting public vesting;
    IFriendPerp public token;

    /*///////////////////////////////////////////////////////////////
                                 State Variables
    //////////////////////////////////////////////////////////////*/

    address public administrator;
    uint256 public reserveBalance = 10 * SCALE;
    uint256 public valueDeposited;
    uint256 public s_totalSupply;
    address public treasury;
    uint256 public depositCap;
    bool public adminRemoved = false;

    enum WorkflowStatus {
        Closed,
        Premint,
        Presale,
        Public
    }
    WorkflowStatus public workflow;

    /*///////////////////////////////////////////////////////////////
                                 Mappings
    //////////////////////////////////////////////////////////////*/

    ///@notice listed of whitelisted ERC20s that can be deposited
    mapping(IERC20 => bool) public depositableTokens;

    ///@notice token address point to their associated price feeds.
    mapping(IERC20 => AggregatorPriceFeeds) public priceFeeds;

    mapping(address => uint256) public presaleAllocation;
    mapping(address => bool) public presaleAped;

    /*///////////////////////////////////////////////////////////////
                                 Custom Errors
    //////////////////////////////////////////////////////////////*/

    error NotDepositable();
    error NotUpdated();
    error InvalidPrice();
    error NotOwner();
    error UnderMinDeposit();
    error CapReached();
    error AdminRemoved();

    /**
     * @param _token FP ERC20 address
     * @param _treasury The treasury address that controls deposited funds
     * @param _administrator address with high level access controls
     * @notice administrator is kept initially for efficency in the early stages
     * but can be removed through governance at anytime.
     */
    constructor(address _token, address _administrator, address _treasury) {
        token = IFriendPerp(_token);
        s_totalSupply += 1e18;
        administrator = _administrator;
        treasury = _treasury;
    }

    /*///////////////////////////////////////////////////////////////
                                 User Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev allows for users to deposit whitelisted assets and calculates their USD value for the bonding curve
     * given that the cap is not reached yet.
     * @param _token the token which is to be deposited
     * @param _amount the amount for this particular deposit
     * @notice uses s_totalSupply rather than totalsupply() in order to prevent
     * accounting issues once launched on multiple chains. As the treasury will serve as
     * the global truth for pricing in the mint function.
     */

    function deposit(
        IERC20Metadata _token,
        uint256 _amount
    ) external nonReentrant depositable(_token) Capped whenNotPaused {
        require(isAllowed(msg.sender), "Not allowed");
        require(_amount > 0, "Deposit must be more than 0");
        uint8 decimals = IERC20Metadata(_token).decimals();
        (uint256 tokenPrice, AggregatorPriceFeeds tokenFeed) = getPrice(_token);
        uint256 value;
        if (decimals != 18) {
            value =
                (tokenPrice * _amount * 1e18) /
                10 ** (decimals + tokenFeed.decimals());
        } else {
            value = (tokenPrice * _amount) / 10 ** (tokenFeed.decimals());
        }
        if (
            workflow == WorkflowStatus.Presale ||
            workflow == WorkflowStatus.Premint
        ) {
            require(!presaleAped[msg.sender], "Already purchased in presale");
            require(
                value <= presaleAllocation[msg.sender],
                "Over presale allocation"
            );
            presaleAped[msg.sender] = true;
        }
        require(value >= MIN_VALUE, "less than min deposit");
        uint256 calculated = _continuousMint(value);
        s_totalSupply += calculated;
        valueDeposited += value;
        emit Deposit(msg.sender, _token, value);
        IERC20(_token).safeTransferFrom(msg.sender, treasury, _amount);
        if (workflow == WorkflowStatus.Presale) {
            vesting.increaseAllocation(msg.sender, calculated);
            token.mint(address(vesting), calculated);
        } else {
            token.mint(msg.sender, calculated);
        }
    }

    /*///////////////////////////////////////////////////////////////
                                 Admin Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice adds token to whitelisted assets with its associated oracle
     * @param _token address of the token
     * @param _pricefeed address for the pricefeed
     * @dev onlyOwnerOrAdmin allows for the administrator or the owner to call this function
     */

    function addTokenInfo(
        IERC20 _token,
        address _pricefeed
    ) external onlyOwnerOrAdmin {
        priceFeeds[_token] = AggregatorPriceFeeds(_pricefeed);
        depositableTokens[_token] = true;
        emit DepositableToken(_token, _pricefeed);
    }

    function setWorkFlow(uint256 _workflow) external onlyOwnerOrAdmin {
        workflow = WorkflowStatus(_workflow);
    }

    function setPresaleAllocation(
        address _user,
        uint256 _amount
    ) internal onlyOwnerOrAdmin {
        presaleAllocation[_user] = _amount;
    }

    function setPresaleAped(
        address _user,
        bool _aped
    ) external onlyOwnerOrAdmin {
        presaleAped[_user] = _aped;
    }

    function whiteListUsers(
        address[] memory addresses,
        uint256[] memory allocations
    ) external onlyOwnerOrAdmin {
        for (uint256 i = 0; i < addresses.length; i++) {
            setPresaleAllocation(addresses[i], allocations[i]);
        }
    }

    function removeTokenInfo(IERC20 _token) external onlyOwnerOrAdmin {
        delete depositableTokens[_token];
        delete priceFeeds[_token];
        emit TokenRemoved(_token);
    }

    /**
     * @notice setting the cap for inital deposits while code is fresh
     * @param _amount what the Cap is set to
     * @dev the cap will be evaluated in USD from the valueDeposited variable
     * so 100 * 1e18 will set the cap to 100 USD
     */
    function setCap(uint256 _amount) external onlyOwnerOrAdmin {
        depositCap = _amount;
    }

    /**
     * @notice sets the new administrtor if they have not already been removed
     * @param newAdmin the address of the new Administrator
     */
    function setAdministrator(address newAdmin) external onlyOwnerOrAdmin {
        if (adminRemoved != false) {
            revert AdminRemoved();
        }

        administrator = newAdmin;
    }

    /**
     * @notice removes the admin and set it to the zero address
     * @dev once removed a new admin cannot be set
     */
    function removeAdmin() external onlyOwner {
        administrator = address(0);
        adminRemoved = true;
    }

    ///@notice inherited from pausable, and pauses deposits
    function pauseDeposits() external onlyOwnerOrAdmin {
        _pause();
    }

    ///@notice inherited from pausable, and unpauses deposits
    function unpauseDeposits() external onlyOwnerOrAdmin {
        _unpause();
    }

    function changeTreasury(address _treasury) external onlyOwnerOrAdmin {
        treasury = _treasury;
    }

    /*///////////////////////////////////////////////////////////////
                            View Functions
    //////////////////////////////////////////////////////////////*/

    function getPrice(
        IERC20 _token
    ) internal view returns (uint256, AggregatorPriceFeeds) {
        AggregatorPriceFeeds feed = priceFeeds[_token];
        (, int256 price, , uint256 updatedAt, ) = feed.latestRoundData();
        if (block.timestamp - updatedAt > VALID_PERIOD) {
            revert NotUpdated();
        }
        if (price <= 0) {
            revert InvalidPrice();
        }
        return (uint256(price), feed);
    }

    function readSupply() external view returns (uint256) {
        return s_totalSupply;
    }

    function checkDepositable(IERC20 _token) external view returns (bool) {
        return depositableTokens[_token];
    }

    ///@notice returns the current USD price to mint 1 FP Token
    function pricePerToken() external view returns (uint256) {
        uint256 _price = (100 * 1e18) / calculateContinuousMintReturn(1e18);
        return _price;
    }

    /*///////////////////////////////////////////////////////////////
                        Modifier Functions 
    //////////////////////////////////////////////////////////////*/

    modifier depositable(IERC20 _token) {
        if (depositableTokens[_token] != true) {
            revert NotDepositable();
        }
        _;
    }

    modifier Capped() {
        _;
        if (depositCap < valueDeposited) {
            revert CapReached();
        }
    }

    modifier onlyOwnerOrAdmin() {
        require(
            msg.sender == owner() || msg.sender == administrator,
            "Not Owner"
        );
        _;
    }

    /*///////////////////////////////////////////////////////////////
                        Bonding Curve Logic
    //////////////////////////////////////////////////////////////*/

    function calculateContinuousMintReturn(
        uint256 _amount
    ) public view returns (uint256 mintAmount) {
        return
            purchaseTargetAmount(
                s_totalSupply,
                reserveBalance,
                uint32(RESERVE_RATIO),
                _amount
            );
    }

    function setReserveRatio(uint256 _reserveRatio) external onlyOwnerOrAdmin {
        require(_reserveRatio <= 1000000, "Invalid reserve ratio");
        RESERVE_RATIO = _reserveRatio;
    }

    function _continuousMint(uint256 _deposit) internal returns (uint256) {
        uint256 amount = calculateContinuousMintReturn(_deposit);
        reserveBalance += _deposit;
        return amount;
    }

    function isAllowed(address _user) public view returns (bool) {
        if (workflow == WorkflowStatus.Premint) {
            return _user == owner();
        } else if (workflow == WorkflowStatus.Presale) {
            return presaleAllocation[_user] > 0;
        } else if (workflow == WorkflowStatus.Closed) {
            return false;
        }
        return true;
    }

    function setToken(address _token) external onlyOwnerOrAdmin {
        token = IFriendPerp(_token);
    }

    function setVesting(address _vesting) external onlyOwnerOrAdmin {
        vesting = IVesting(_vesting);
    }

    receive() external payable {}
}
