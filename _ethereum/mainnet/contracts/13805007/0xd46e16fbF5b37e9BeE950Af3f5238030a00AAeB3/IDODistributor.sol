// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./AccessControlEnumerableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./Initializable.sol";

contract IDODistributor is AccessControlEnumerableUpgradeable, ReentrancyGuardUpgradeable {
    
    function initialize() public virtual initializer {
        IDODistributor_init();
    }
    
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public idoToken;
    address public ORNToken;
    uint256 public totalORN;
    uint256 public allocation;
    uint32 public startTime; 
    uint32 public finishTime;
    uint32 public startClaimTime;

    mapping (address => uint256) public userBalances;

    event UserParticipated(
        address participant,
        uint256 amount,
        uint256 time
    );

    event TokensClaimed(
        address receiver,
        uint256 amount,
        uint256 time
    );

    function IDODistributor_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OWNER_ROLE, msg.sender);
    }

    function addOwner(address _owner) public {
        require(hasRole(OWNER_ROLE, msg.sender), "IDD Token:NOT_OWNER");
        grantRole(OWNER_ROLE, _owner);
    }

    function setIDOParams(
        address _ornToken, 
        address _idoToken, 
        uint32 _startTime, 
        uint32 _finishTime, 
        uint256 _allocation, 
        uint32 _startClaimTime
    ) external returns(bool) {
        require(hasRole(OWNER_ROLE, msg.sender), "IDD Token:NOT_OWNER");
        ORNToken = _ornToken;
        idoToken = _idoToken;
        startTime = _startTime;
        finishTime = _finishTime;
        allocation = _allocation;
        startClaimTime = _startClaimTime;

        return true;
    }

    function participate(uint256 amount) external nonReentrant {
        require(amount > 0, "IDD:LOW_AMOUNT");
        require(block.timestamp >= startTime, "IDD:IDO_NOT_STARTED");
        require(block.timestamp < finishTime, "IDD:IDO_FINISHED");
        IERC20Upgradeable _ORNToken = IERC20Upgradeable(ORNToken);
        require(_ORNToken.allowance(msg.sender, address(this)) >= amount, "IDD:LOW_ALLOWANCE");

        uint256 oldBalance = _ORNToken.balanceOf(address(this));
        _ORNToken.safeTransferFrom(msg.sender, address(this), amount);
        require(_ORNToken.balanceOf(address(this)) == oldBalance + amount, "IDD:TransferFail");            
        totalORN += amount;

        userBalances[msg.sender] += amount; 

        emit UserParticipated(msg.sender, amount, block.timestamp);
    }


    function emergencyAssetWithdrawal(address asset, address wallet) external {
        require(hasRole(OWNER_ROLE, msg.sender), "IDD Token:NOT_OWNER");
        IERC20Upgradeable token = IERC20Upgradeable(asset);
        token.safeTransfer(wallet, token.balanceOf(address(this)));
    }

    function claimTokens() external nonReentrant {
        require(block.timestamp >= startClaimTime, "IDD:IDO_CLAIM_NOT_STARTED");
        require(userBalances[msg.sender] > 0, "IDD:NOT_PARTICIPATOR");
        uint256 idoTokenAmount = userBalances[msg.sender]*allocation/totalORN;
        userBalances[msg.sender] = 0; 
        IERC20Upgradeable(idoToken).safeTransfer(msg.sender, idoTokenAmount);

        emit TokensClaimed(msg.sender, idoTokenAmount, block.timestamp);
    } 

}