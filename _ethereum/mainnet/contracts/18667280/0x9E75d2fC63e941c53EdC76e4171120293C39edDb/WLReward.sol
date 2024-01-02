// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./AccessControlUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./IERC721.sol";
import "./IPart.sol";
import "./IWLBox.sol";
import "./IWLReward.sol";

contract WLReward is 
    AccessControlUpgradeable, 
    UUPSUpgradeable, 
    ReentrancyGuardUpgradeable {
    
    /**
     * @dev Roles
     * DEFAULT_ADMIN_ROLE
     * - can update role of each account
     *
     * OPERATOR_ROLE
     * - can update encryptor
     *
     * DEPLOYER_ROLE
     * - can update the logic contract     
     */
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE"); 
    bytes32 public constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");
    
    address public encryptor;
    mapping(uint =>mapping(uint => address)) public rewardClaimed;
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function _authorizeUpgrade(address) internal override only(DEPLOYER_ROLE) {}
    
    /**
     * `adminAddress`: `DEFAULT_ADMIN_ROLE` will be granted
     * `_encryptor`: admin address that encrypts openBox transaction data
     */
    function initialize(
        address adminAddress,
        address operatorAddress,
        address _encryptor) initializer public {
        encryptor = _encryptor;
       
        __ReentrancyGuard_init();
        _setupRole(DEFAULT_ADMIN_ROLE, adminAddress);
        _setupRole(OPERATOR_ROLE, operatorAddress);
        _setupRole(DEPLOYER_ROLE, _msgSender());
    }
    
    // modifier
    modifier only(bytes32 role) {
        require(hasRole(role, _msgSender()), "Caller does not have permission");
       _;
    }
    
    function claimReward(
        uint tournamentId,
        uint rank,
        uint rewardType,      
        uint rewardCount,
        address rewardContract,
        uint256 blockNumberLimit,
        bytes calldata signature) external nonReentrant {
        require(block.number <= blockNumberLimit, "Transaction has expired");
        require(rewardClaimed[tournamentId][rank] == address(0), "Reward for the rank has already been claimed");
        require(
            validateClaimReward(tournamentId, rank, rewardType, rewardCount, rewardContract, blockNumberLimit, signature),
            "Invalid signature"
        );
        
        uint256 start = 0;
        uint256 end = 0;
         
        rewardClaimed[tournamentId][rank] = _msgSender();
        if(rewardType == RewardType.REWARD_TYPE_HOLOSPEC) {
            (start, end) = IWLMint(rewardContract).mint(_msgSender(), rewardCount);
        } else if(rewardType == RewardType.REWARD_TYPE_BOX) {
            (start, end) = IWLBoxMint(rewardContract).mint(_msgSender(), rewardCount, false);
        } else if (rewardType == RewardType.REWARD_TYPE_PART) {
            (start, end) = IPart(rewardContract).mintPart(_msgSender(), rewardCount);
        } else {
            revert("Invalid reward type");
        }
        
        emit RewardClaimed(_msgSender(), rewardContract, start, end, tournamentId, rank, rewardType);
    }
    
    /**
     * @dev Validates claimReward function parameters
     */
    function validateClaimReward(
        uint tournamentId,
        uint rank,
        uint rewardType,
        uint rewardCount,
        address rewardContract,        
        uint256 blockNumberLimit,
        bytes calldata signature) internal view returns (bool) {
        bytes32 hashed = keccak256(abi.encode(
            _msgSender(), tournamentId, rank, rewardType, rewardCount, rewardContract, blockNumberLimit));
        (address recovered, ECDSAUpgradeable.RecoverError error) = ECDSAUpgradeable.tryRecover(hashed, signature);

        if (error == ECDSAUpgradeable.RecoverError.NoError && recovered == encryptor ) {
            return true;
        }
        
        return false;
    }
    
    /**
     * @dev Sets Encryptor
     *
     * Requirements
     * - the caller must have the `OPERATOR_ROLE`
     */
    function updateEncryptor(address _encryptor) external only(OPERATOR_ROLE) {
        require(_encryptor != address(0), "Zero address cannot be used");
        encryptor = _encryptor;
    }
    
    event RewardClaimed(
        address indexed owner,
        address rewardContract,
        uint256 start,
        uint256 end,
        uint tournamentId,
        uint rank,
        uint rewardType
    );
    
    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
