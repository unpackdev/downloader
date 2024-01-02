// SPDX-License-Identifier: MIT

//** DCB Token claim Contract */
//** Author: Aceson 2022.3 */

pragma solidity 0.8.19;

import "./IERC20.sol";
import "./Initializable.sol";

import "./IDCBInvestments.sol";
import "./IDCBPlatformVesting.sol";
import "./IDCBTokenClaim.sol";
import "./ILayerZeroReceiver.sol";

contract DCBTokenClaim is Initializable, ILayerZeroReceiver, IDCBTokenClaim {
    IDCBInvestments public _investment; //Investments contract
    IERC20 public _rewardToken; //Token to be used for tier calc
    IDCBPlatformVesting public _vesting; //Vesting contract
    address public layerZero; //Layerzero contract address

    //Keccack(<hidden answer>)
    /* solhint-disable var-name-mixedcase */
    bytes32 public ANSWER_HASH;
    uint256 public totalShares; //Total shares for the event

    mapping(address => UserAllocation) public userAllocation; //Allocation per user

    ClaimInfo public claimInfo;
    Tiers[] public tierInfo;

    address[] private participants;
    address[] private registeredUsers;
    address public tierMigratorAddr;
    uint16 internal nativeChainId;

    event Initialized(Params p);
    event UserRegistered(address user);
    event UserClaimed(address user, uint256 amount);

    modifier onlyManager() {
        require(_investment.hasRole(keccak256("MANAGER_ROLE"), msg.sender), "Only manager");
        _;
    }

    function initialize(Params calldata p) external initializer {
        _investment = IDCBInvestments(msg.sender);
        _rewardToken = IERC20(p.rewardTokenAddr);
        _vesting = IDCBPlatformVesting(p.vestingAddr);
        layerZero = p.layerZeroAddr;
        tierMigratorAddr = p.tierMigratorAddr;
        nativeChainId = p.nativeChainId;

        /**
         * Generate the new Claim Event
         */
        claimInfo.minTier = p.minTier;
        claimInfo.distAmount = p.distAmount;
        claimInfo.createDate = uint32(block.timestamp);
        claimInfo.startDate = p.startDate;
        claimInfo.endDate = p.endDate;

        ANSWER_HASH = p.answerHash;

        for (uint256 i = 0; i < p.tiers.length; i++) {
            tierInfo.push(Tiers({ minLimit: p.tiers[i].minLimit, multi: p.tiers[i].multi }));
        }

        emit Initialized(p);
    }

    function setParams(Params calldata p) external {
        require(msg.sender == address(_investment), "Only factory");

        claimInfo.minTier = p.minTier;
        claimInfo.distAmount = p.distAmount;
        claimInfo.startDate = p.startDate;
        claimInfo.endDate = p.endDate;

        _investment = IDCBInvestments(msg.sender);
        _rewardToken = IERC20(p.rewardTokenAddr);
        _vesting = IDCBPlatformVesting(p.vestingAddr);

        ANSWER_HASH = p.answerHash;

        for (uint256 i = 0; i < p.tiers.length; i++) {
            tierInfo.push(Tiers({ minLimit: p.tiers[i].minLimit, multi: p.tiers[i].multi }));
        }
    }

    function registerForAllocation(address _user, uint8 _tier, uint8 _multi) public returns (bool) {
        require(msg.sender == (layerZero) || msg.sender == tierMigratorAddr, "Invalid sender");

        uint256 shares = (2 ** _tier) * _multi;
        (, uint16 _holdMulti) = getTier(_user);
        shares = shares * _holdMulti / 1000;

        userAllocation[_user].active = 1;
        userAllocation[_user].shares = shares;
        userAllocation[_user].registeredTier = uint8(_tier);
        userAllocation[_user].multi = uint8(_multi);

        registeredUsers.push(_user);

        totalShares = totalShares + shares;
        emit UserRegistered(_user);

        return true;
    }

    function registerByManager(
        address[] calldata _users,
        uint256[] calldata _tierOfUser,
        uint256[] calldata _multiOfUser
    )
        external
        onlyManager
    {
        require((_users.length == _tierOfUser.length) && (_tierOfUser.length == _multiOfUser.length), "Invalid input");
        uint256 len = _users.length;
        uint256 total;
        require(block.timestamp <= claimInfo.endDate && block.timestamp >= claimInfo.startDate, "Registration closed");

        for (uint256 i = 0; i < len; i++) {
            require(_tierOfUser[i] >= claimInfo.minTier, "Minimum tier required");
            require(userAllocation[_users[i]].active == 0, "Already registered");

            uint256 shares = (2 ** _tierOfUser[i]) * _multiOfUser[i];
            (, uint16 _holdMulti) = getTier(_users[i]);
            shares = shares * _holdMulti / 1000;

            userAllocation[_users[i]].active = 1;
            userAllocation[_users[i]].shares = shares;
            userAllocation[_users[i]].registeredTier = uint8(_tierOfUser[i]);
            userAllocation[_users[i]].multi = uint8(_multiOfUser[i]);

            registeredUsers.push(_users[i]);

            total = total + shares;
            emit UserRegistered(_users[i]);
        }

        totalShares = totalShares + total;
    }

    function lzReceive(uint16 _id, bytes calldata _srcAddress, uint64, bytes memory data) public override {
        require(
            _id == nativeChainId
                && keccak256(_srcAddress) == keccak256(abi.encodePacked(tierMigratorAddr, address(this))),
            "Invalid source"
        );

        address user;
        uint8 tier;
        uint8 multi;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Extract the address from data (first 20 bytes)
            user := mload(add(data, 0x14))

            // Extract the first uint8 (21st byte)
            tier := byte(0, mload(add(data, 0x34)))

            // Extract the second uint8 (22nd byte)
            multi := byte(0, mload(add(data, 0x35)))
        }

        registerForAllocation(user, tier, multi);
    }

    function setMinTierForClaim(uint8 _minTier) external onlyManager {
        claimInfo.minTier = _minTier;
    }

    function setToken(address _token) external {
        require(msg.sender == address(_investment), "Only factory");
        _rewardToken = IERC20(_token);
    }

    function claimTokens() external returns (bool) {
        UserAllocation storage user = userAllocation[msg.sender];

        require(user.active == 1, "Not registered / Already claimed");
        require(block.timestamp >= claimInfo.endDate, "Claim not open yet");

        uint256 amount = getClaimableAmount(msg.sender);

        if (amount > 0) {
            participants.push(msg.sender);
            _investment.setUserInvestment(msg.sender, address(this), amount);
            _vesting.setTokenClaimWhitelist(msg.sender, amount);
        }

        user.shares = 0;
        user.claimedAmount = amount;
        user.active = 0;

        emit UserClaimed(msg.sender, amount);

        return true;
    }

    function getParticipants() external view returns (address[] memory) {
        return participants;
    }

    function getRegisteredUsers() external view returns (address[] memory) {
        return registeredUsers;
    }

    function getClaimForTier(uint8 _tier, uint8 _multi) public view returns (uint256) {
        if (totalShares == 0) return 0;
        return ((2 ** _tier) * _multi * claimInfo.distAmount / totalShares);
    }

    function getClaimableAmount(address _address) public view returns (uint256) {
        if (totalShares == 0) return 0;
        return (userAllocation[_address].shares * claimInfo.distAmount / totalShares);
    }

    function getTier(address _user) public view returns (uint256 _tier, uint16 _holdMulti) {
        uint256 len = tierInfo.length;
        uint256 amount = _rewardToken.balanceOf(_user);

        for (uint256 i = len - 1; i >= 0; i--) {
            if (amount >= tierInfo[i].minLimit) {
                return (i, tierInfo[i].multi);
            }
        }
    }
}
