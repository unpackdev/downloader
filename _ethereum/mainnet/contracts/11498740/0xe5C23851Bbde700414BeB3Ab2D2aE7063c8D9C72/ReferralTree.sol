pragma solidity ^0.6.0;

import "./AccessControl.sol";
import "./ReferralRewards.sol";
import "./Rewards.sol";

contract ReferralTree is AccessControl {
    using SafeMath for uint256;

    event ReferralAdded(address indexed referrer, address indexed referral);

    bytes32 public constant REWARDS_ROLE = keccak256("REWARDS_ROLE"); // Role for those who allowed to mint new tokens

    mapping(address => address) public referrals; // Referral addresses for each referrer
    mapping(address => bool) public registered; // Map to ensure if the referrer is in the tree
    mapping(address => address[]) public referrers; // List of referrer addresses for each referral
    ReferralRewards[] public referralRewards; // Referral reward contracts that are allowed to modify the tree
    address public treeRoot; // The root of the referral tree

    /// @dev Constructor that initializes the most important configurations.
    /// @param _treeRoot The root of the referral tree.
    constructor(address _treeRoot) public AccessControl() {
        treeRoot = _treeRoot;
        registered[_treeRoot] = true;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Allows an admin to reanonce the DEFAULT_ADMIN_ROLE.
    /// @param _newAdmin Address of the new admin.
    function changeAdmin(address _newAdmin) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "changeAdmin: bad role"
        );
        _setupRole(DEFAULT_ADMIN_ROLE, _newAdmin);
        renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Allows a farming contract to set the users referral.
    /// @param _referrer Address of the referred user.
    /// @param _referral Address of the refferal.
    function setReferral(address _referrer, address _referral) public {
        require(hasRole(REWARDS_ROLE, _msgSender()), "setReferral: bad role");
        require(_referrer != address(0), "setReferral: bad referrer");
        if (!registered[_referrer]) {
            require(
                registered[_referral],
                "setReferral: not registered referral"
            );
            referrals[_referrer] = _referral;
            registered[_referrer] = true;
            referrers[_referral].push(_referrer);
            emit ReferralAdded(_referrer, _referral);
        }
    }

    /// @dev Allows an admin to remove the referral rewards contract from trusted list.
    /// @param _referralRewards Contract that manages referral rewards.
    function removeReferralReward(ReferralRewards _referralRewards) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "setReferral: bad role"
        );
        for (uint256 i = 0; i < referralRewards.length; i++) {
            if (_referralRewards == referralRewards[i]) {
                uint256 lastIndex = referralRewards.length - 1;
                if (i != lastIndex) {
                    referralRewards[i] = referralRewards[lastIndex];
                }
                referralRewards.pop();
                revokeRole(REWARDS_ROLE, address(_referralRewards));
                break;
            }
        }
    }

    /// @dev Allows an admin to add the referral rewards contract from trusted list.
    /// @param _referralRewards Contract that manages referral rewards.
    function addReferralReward(ReferralRewards _referralRewards) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "setReferral: bad role"
        );
        _setupRole(REWARDS_ROLE, address(_referralRewards));
        referralRewards.push(_referralRewards);
    }

    /// @dev Allows a user to claim all the dividends in all trusted products.
    function claimAllDividends() public {
        for (uint256 i = 0; i < referralRewards.length; i++) {
            ReferralRewards referralReward = referralRewards[i];
            if (referralReward.getReferralReward(_msgSender()) > 0) {
                referralReward.claimAllDividends(_msgSender());
            }
        }
    }

    /// @dev Returns user referrals up to the required depth.
    /// @param _referrer Address of referrer.
    /// @param _referDepth Number of referrals to be returned.
    /// @return List of user referrals.
    function getReferrals(address _referrer, uint256 _referDepth)
        public
        view
        returns (address[] memory)
    {
        address[] memory referralsTree = new address[](_referDepth);
        address referrer = _referrer;
        for (uint256 i = 0; i < _referDepth; i++) {
            referralsTree[i] = referrals[referrer];
            referrer = referralsTree[i];
        }
        return referralsTree;
    }

    /// @dev Returns user referrals up to the required depth.
    /// @param _referral Address of referral.
    /// @return List of user referrers.
    function getReferrers(address _referral)
        public
        view
        returns (address[] memory)
    {
        return referrers[_referral];
    }

    /// @dev Returns total user's referral reward.
    /// @param _user Address of the user.
    /// @return Total user's referral reward.
    function getUserReferralReward(address _user)
        public
        view
        returns (uint256)
    {
        uint256 amount = 0;
        for (uint256 i = 0; i < referralRewards.length; i++) {
            ReferralRewards referralReward = referralRewards[i];
            amount = amount.add(referralReward.getReferralReward(_user));
        }
        return amount;
    }

    /// @dev Returns trusted referral reward contracts.
    /// @return List of trusted referral reward contracts.
    function getReferralRewards()
        public
        view
        returns (ReferralRewards[] memory)
    {
        return referralRewards;
    }
}
