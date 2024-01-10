pragma solidity ^0.6.0;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./Initializable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./IRegistry.sol";

contract ReferralProgram is Initializable, ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct User {
        bool exists;
        address referrer;
    }

    mapping(address => User) public users;
    // user_address -> token_address -> token_amount
    mapping(address => mapping(address => uint256)) public rewards;

    uint256[] public distribution = [70, 20, 10];
    address[] public tokens;

    address public rootAddress;
    IRegistry public registry;

    event RegisterUser(address user, address referrer);
    event RewardReceived(
        address user,
        address referrer,
        address token,
        uint256 amount
    );
    event RewardsClaimed(address user, address[] tokens, uint256[] amounts);
    event NewDistribution(uint256[] distribution);
    event NewToken(address token);

    modifier onlyFeeDistributors() {
        address[] memory distributors = getFeeDistributors();
        for (uint256 i = 0; i < distributors.length; i++) {
            if (msg.sender == distributors[i]) {
                _;
                return;
            }
        }
        require(false, "RP!feeDistributor");
    }

    function configure(
        address[] calldata tokenAddresses,
        address _rootAddress,
        address _registry
    ) external initializer {
        require(_rootAddress != address(0), "RProotIsZero");
        require(_registry != address(0), "RPregistryIsZero");
        require(tokenAddresses.length > 0, "RPtokensNotProvided");

        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            require(tokenAddresses[i] != address(0), "RPtokenIsZero");
        }

        tokens = tokenAddresses;

        registry = IRegistry(_registry);

        rootAddress = _rootAddress;
        users[rootAddress] = User({exists: true, referrer: rootAddress});
    }

    function getFeeDistributors() public view returns (address[] memory) {
        (address[] memory distributors, , , , , ) = registry.getVaultsInfo();
        return distributors;
    }

    function registerUser(address referrer, address referral)
        external
        onlyFeeDistributors
    {
        _registerUser(referrer, referral);
    }

    function registerUser(address referrer) external {
        _registerUser(referrer, msg.sender);
    }

    function _registerUser(address referrer, address referral) internal {
        require(referral != address(0), "RPuserIsZero");
        require(!users[referral].exists, "RPuserExists");
        require(users[referrer].exists, "RP!referrerExists");
        users[referral] = User({exists: true, referrer: referrer});
        emit RegisterUser(referral, referrer);
    }

    function feeReceiving(
        address _for,
        address _token,
        uint256 _amount
    ) external onlyFeeDistributors {
        // If notify reward for unregistered _for -> register with root referrer
        if (!users[_for].exists) {
            _registerUser(rootAddress, _for);
        }
        address upline = users[_for].referrer;
        for (uint256 i = 0; i < distribution.length; i++) {
            uint256 amount = rewards[upline][_token].add(_amount.mul(distribution[i]).div(100));
            rewards[upline][_token] = amount;
            emit RewardReceived(_for, upline, _token, amount);
            upline = users[upline].referrer;
        }
    }

    function claimRewardsFor(address userAddr) public nonReentrant {
        require(users[userAddr].exists, "RP!userExists");
        uint256[] memory amounts = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            uint256 reward = rewards[userAddr][token];
            if (reward > 0) {
                amounts[i] = reward;
                IERC20(token).safeTransfer(userAddr, reward);
                rewards[userAddr][token] = 0;
            }
        }
        emit RewardsClaimed(userAddr, tokens, amounts);
    }

    function claimRewards() external {
        claimRewardsFor(msg.sender);
    }

    function claimRewardsForRoot() external {
        claimRewardsFor(rootAddress);
    }

    function getTokensList() external view returns (address[] memory) {
        return tokens;
    }

    function getDistributionList() external view returns (uint256[] memory) {
        return distribution;
    }

    function changeDistribution(uint256[] calldata newDistribution)
        external
        onlyOwner
    {
        uint256 sum;
        for (uint256 i = 0; i < newDistribution.length; i++) {
            sum = sum.add(newDistribution[i]);
        }
        require(sum == 100, "RP!fullDistribution");
        distribution = newDistribution;
        emit NewDistribution(distribution);
    }

    function addNewToken(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0), "RPtokenIsZero");
        for (uint256 i = 0; i < tokens.length; i++) {
            require(tokenAddress != tokens[i], "RPtokenAlreadyExists");
        }
        tokens.push(tokenAddress);
        emit NewToken(tokenAddress);
    }
}
