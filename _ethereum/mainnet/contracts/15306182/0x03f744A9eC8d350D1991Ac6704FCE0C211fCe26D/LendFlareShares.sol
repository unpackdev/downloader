// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity 0.6.12;

import "./SafeERC20.sol";
import "./Initializable.sol";
import "./ReentrancyGuard.sol";

contract LendFlareShares is ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    uint256 constant PRECISION = 1e18;
    uint256 totalShares;
    uint256 accRewardPerShare;

    address public token;

    mapping(address => bool) private owners;
    mapping(address => uint256) rewardPerSharePaid;
    mapping(address => uint256) rewards;

    struct UserInfo {
        uint256 shares;
    }

    mapping(address => UserInfo) public users;

    event NewOwner(address indexed sender, address owner);
    event RemoveOwner(address indexed sender, address owner);

    modifier onlyOwners() {
        require(isOwner(msg.sender), "LendFlareShares: caller is not an owner");
        _;
    }

    constructor(address _owner, address _token) public {
        owners[_owner] = true;
        token = _token;
    }

    function addOwner(address _newOwner) public onlyOwners {
        require(
            !isOwner(_newOwner),
            "LendFlareShares: address is already owner"
        );

        owners[_newOwner] = true;

        emit NewOwner(msg.sender, _newOwner);
    }

    function addOwners(address[] calldata _newOwners) external onlyOwners {
        for (uint256 i = 0; i < _newOwners.length; i++) {
            addOwner(_newOwners[i]);
        }
    }

    function removeOwner(address _owner) external onlyOwners {
        require(isOwner(_owner), "LendFlareShares: address is not owner");

        owners[_owner] = false;

        emit RemoveOwner(msg.sender, _owner);
    }

    function isOwner(address _owner) public view returns (bool) {
        return owners[_owner];
    }

    function _updateRewards(address _user) internal {
        uint256 pendingRewards = pendingReward(_user);

        rewards[_user] = pendingRewards;
        rewardPerSharePaid[_user] = accRewardPerShare;
    }

    function addPartners(address[] calldata _users, uint256[] calldata _amounts)
        external
        nonReentrant
        onlyOwners
    {
        require(_users.length == _amounts.length, "!length mismatch");

        for (uint256 i = 0; i < _users.length; i++) {
            addPartner(_users[i], _amounts[i]);
        }
    }

    function addPartner(address _user, uint256 _amount)
        public
        nonReentrant
        onlyOwners
    {
        _updateRewards(_user);

        totalShares = totalShares.add(_amount);

        UserInfo storage user = users[_user];

        user.shares = user.shares.add(_amount);
    }

    function removePartner(address _user) public nonReentrant onlyOwners {
        _updateRewards(_user);

        UserInfo storage user = users[_user];

        totalShares = totalShares.sub(user.shares);
        user.shares = 0;
    }

    function addRewards(uint256 _rewards) public nonReentrant onlyOwners {
        accRewardPerShare = accRewardPerShare.add(
            _rewards.mul(PRECISION).div(totalShares)
        );
    }

    function claim() public nonReentrant returns (uint256 claimed) {
        _updateRewards(msg.sender);

        uint256 pendingRewards = rewards[msg.sender];

        rewards[msg.sender] = 0;

        if (pendingRewards > 0) {
            IERC20(token).safeTransfer(msg.sender, pendingRewards);
        }

        return pendingRewards;
    }

    function pendingReward(address _user) public view returns (uint256) {
        UserInfo storage user = users[_user];

        return
            rewards[_user].add(
                accRewardPerShare
                    .sub(rewardPerSharePaid[_user])
                    .mul(user.shares)
                    .div(PRECISION)
            );
    }
}
