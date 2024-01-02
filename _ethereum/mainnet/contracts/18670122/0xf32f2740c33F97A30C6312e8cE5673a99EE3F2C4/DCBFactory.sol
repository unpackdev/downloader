// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./AccessControlUpgradeable.sol";
import "./ClonesUpgradeable.sol";

import "./IDCBInvestments.sol";
import "./IDCBPlatformVesting.sol";

import "./IDCBCrowdfunding.sol";
import "./IDCBTokenClaim.sol";
import "./IDCBPlatformVesting.sol";

contract DCBFactory is AccessControlUpgradeable {
    enum Type {
        Crowdfunding,
        TokenClaim
    }

    struct Event {
        string name;
        address paymentToken;
        address tokenAddress;
        address vestingAddress;
        Type eventType;
    }

    struct CrowdFundingParams {
        uint8 minTier;
        uint32 startDate;
        uint32 gracePeriod;
        address innovator;
        address paymentReceiver;
        address tierMigrator;
        address paymentToken;
        address saleTokenAddr;
        uint256 hardcap;
        uint256 totalTokenOnSale;
        uint256[] refundFees;
    }

    mapping(address => uint256) public numUserInvestments;
    mapping(address => mapping(address => uint256)) public userAmount;
    mapping(address => Event) public events;

    address public crowdfundingImpl;
    address public tokenClaimImpl;
    address public vestingImpl;

    address[] public eventsList;
    address public layerZero;
    uint32 public nativeChainId;
    uint16 public nativeChainIdLZ;
    bytes32 internal constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    event CrowdfundingDeployed(
        string _name, CrowdFundingParams _c, IDCBPlatformVesting.VestingSetup _v, IDCBPlatformVesting.BuybackSetup _b
    );
    event TokenClaimDeployed(
        string _name, address _token, IDCBTokenClaim.Params _t, IDCBPlatformVesting.VestingSetup _v
    );
    event UserInvestmentSet(address _address, address _event, uint256 _amount);
    event ManagerRoleSet(address _user, bool _status);
    event ImplementationsChanged(address _newVesting, address _newTokenClaim, address _newCrowdfunding);
    event DistributionClaimed(address _user, address _event);

    modifier onlyManager() {
        require(hasRole(MANAGER_ROLE, msg.sender), "Unauthorized");
        _;
    }

    function initialize() external initializer {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, msg.sender);
    }

    function deployCrowdfunding(
        string calldata _name,
        CrowdFundingParams calldata _c,
        IDCBPlatformVesting.VestingSetup calldata _v,
        IDCBPlatformVesting.BuybackSetup calldata _b
    )
        external
        onlyManager
    {
        require(
            _c.innovator != address(0) && _c.paymentReceiver != address(0) && _c.paymentToken != address(0)
                && _c.saleTokenAddr != address(0) && _c.tierMigrator != address(0) && _b.router != address(0),
            "Zero address"
        );
        address newCrowdfunding = ClonesUpgradeable.clone(crowdfundingImpl);
        address newVesting = ClonesUpgradeable.clone(vestingImpl);

        IDCBCrowdfunding c = IDCBCrowdfunding(newCrowdfunding);
        IDCBPlatformVesting v = IDCBPlatformVesting(newVesting);

        IDCBPlatformVesting.ContractSetup memory _s;
        IDCBCrowdfunding.Params memory _p;

        _s._innovator = _c.innovator;
        _s._paymentReceiver = _c.paymentReceiver;
        _s._vestedToken = _c.saleTokenAddr;
        _s._paymentToken = _c.paymentToken;
        _s._totalTokenOnSale = _c.totalTokenOnSale;
        _s._gracePeriod = _c.gracePeriod;
        _s._refundFees = _c.refundFees;
        _s._nativeChainId = nativeChainId;

        _p.investmentAddr = address(this);
        _p.tierMigratorAddr = _c.tierMigrator;
        _p.vestingAddr = newVesting;
        _p.totalTokenOnSale = _c.totalTokenOnSale;
        _p.hardcap = _c.hardcap;
        _p.startDate = _c.startDate;
        _p.minTier = _c.minTier;
        _p.paymentToken = _c.paymentToken;
        _p.saleTokenAddr = _c.saleTokenAddr;
        _p.layerZeroAddr = layerZero;
        _p.nativeChainId = nativeChainIdLZ;

        c.initialize(_p);
        v.initializeCrowdfunding(_s, _v, _b);
        v.transferOwnership(newCrowdfunding);

        Event storage e = events[newCrowdfunding];
        e.name = _name;
        e.eventType = Type.Crowdfunding;
        e.vestingAddress = newVesting;
        e.tokenAddress = _c.saleTokenAddr;
        e.paymentToken = _c.paymentToken;

        eventsList.push(newCrowdfunding);

        emit CrowdfundingDeployed(_name, _c, _v, _b);
    }

    function deployTokenClaim(
        string calldata _name,
        address _token,
        IDCBTokenClaim.Params memory _t,
        IDCBPlatformVesting.VestingSetup calldata _v
    )
        external
        onlyManager
    {
        require(
            _token != address(0) && _t.rewardTokenAddr != address(0) && _t.tierMigratorAddr != address(0),
            "Zero address"
        );

        address newTokenClaim = ClonesUpgradeable.clone(tokenClaimImpl);
        address newVesting = ClonesUpgradeable.clone(vestingImpl);

        IDCBTokenClaim c = IDCBTokenClaim(newTokenClaim);
        IDCBPlatformVesting v = IDCBPlatformVesting(newVesting);

        _t.vestingAddr = newVesting;
        _t.layerZeroAddr = layerZero;
        _t.nativeChainId = nativeChainIdLZ;

        c.initialize(_t);
        v.initializeTokenClaim(_token, _v, nativeChainId);
        v.transferOwnership(newTokenClaim);

        Event storage e = events[newTokenClaim];
        e.name = _name;
        e.eventType = Type.TokenClaim;
        e.vestingAddress = newVesting;
        e.tokenAddress = _token;

        eventsList.push(newTokenClaim);

        emit TokenClaimDeployed(_name, _token, _t, _v);
    }

    function setUserInvestment(address _address, address _event, uint256 _amount) external returns (bool) {
        require(events[_event].vestingAddress != address(0), "Not active");
        require(msg.sender == _event, "No permission");

        if (userAmount[_event][_address] == 0) {
            numUserInvestments[_address]++;
        }

        if (_amount == 0 && numUserInvestments[_address] > 0 && events[_event].eventType != Type.TokenClaim) {
            numUserInvestments[_address] = numUserInvestments[_address] - 1;
        }

        userAmount[_event][_address] = _amount;

        emit UserInvestmentSet(_address, _event, _amount);

        return true;
    }

    function setManagerRole(address _user, bool _status) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_status) {
            grantRole(MANAGER_ROLE, _user);
        } else {
            revokeRole(MANAGER_ROLE, _user);
        }

        emit ManagerRoleSet(_user, _status);
    }

    function setChainInfo(address _layerZero, uint16 _nativeChainIdLZ, uint32 _nativeChainId) external onlyManager {
        require(_layerZero != address(0), "Zero address");
        layerZero = _layerZero;
        nativeChainIdLZ = _nativeChainIdLZ;
        nativeChainId = _nativeChainId;
    }

    function changeImplementations(
        address _newVesting,
        address _newTokenClaim,
        address _newCrowdfunding
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            _newVesting != address(0) && _newTokenClaim != address(0) && _newCrowdfunding != address(0), "Zero address"
        );
        vestingImpl = _newVesting;
        crowdfundingImpl = _newCrowdfunding;
        tokenClaimImpl = _newTokenClaim;

        emit ImplementationsChanged(_newVesting, _newTokenClaim, _newCrowdfunding);
    }

    function changeVestingParams(
        address _event,
        uint256 _cliff,
        uint256 _start,
        uint256 _duration,
        uint256 _initialUnlockPercent
    )
        external
        onlyManager
    {
        IDCBPlatformVesting vesting = IDCBPlatformVesting(events[_event].vestingAddress);
        vesting.setVestingParams(_cliff, _start, _duration, _initialUnlockPercent);
    }

    function changeCrowdfundingParams(
        address _event,
        CrowdFundingParams memory _c,
        uint256 _newFee
    )
        external
        onlyManager
    {
        IDCBCrowdfunding crowdfunding = IDCBCrowdfunding(_event);
        IDCBPlatformVesting vesting = IDCBPlatformVesting(events[_event].vestingAddress);

        IDCBPlatformVesting.ContractSetup memory _s;
        IDCBCrowdfunding.Params memory _p;

        _s._innovator = _c.innovator;
        _s._paymentReceiver = _c.paymentReceiver;
        _s._vestedToken = _c.saleTokenAddr;
        _s._paymentToken = _c.paymentToken;
        _s._totalTokenOnSale = _c.totalTokenOnSale;
        _s._gracePeriod = _c.gracePeriod;
        _s._refundFees = _c.refundFees;

        _p.tierMigratorAddr = _c.tierMigrator;
        _p.totalTokenOnSale = _c.totalTokenOnSale;
        _p.hardcap = _c.hardcap;
        _p.startDate = _c.startDate;
        _p.minTier = _c.minTier;
        _p.paymentToken = _c.paymentToken;
        _p.saleTokenAddr = _c.saleTokenAddr;

        crowdfunding.setParams(_p);
        vesting.setCrowdFundingParams(_s, _newFee);
    }

    function changeTokenClaimParams(address _event, IDCBTokenClaim.Params memory _t) external onlyManager {
        IDCBTokenClaim tokenClaim = IDCBTokenClaim(_event);
        tokenClaim.setParams(_t);
    }

    function changeToken(address _event, address _newToken) external onlyManager {
        require(events[_event].vestingAddress != address(0), "Vesting not active");

        if (events[_event].eventType == Type.TokenClaim) {
            IDCBTokenClaim tokenClaim = IDCBTokenClaim(_event);
            tokenClaim.setToken(_newToken);
        } else {
            IDCBCrowdfunding crowdfunding = IDCBCrowdfunding(_event);
            crowdfunding.setToken(_newToken);
        }

        IDCBPlatformVesting vesting = IDCBPlatformVesting(events[_event].vestingAddress);
        vesting.setToken(_newToken);
        events[_event].tokenAddress = _newToken;
    }

    function rescueTokensFromContract(address _event, address _receiver, uint256 _amount) external onlyManager {
        require(events[_event].vestingAddress != address(0), "Vesting not active");
        IDCBPlatformVesting vesting = IDCBPlatformVesting(events[_event].vestingAddress);

        vesting.rescueTokens(_receiver, _amount);
    }

    function claimDistribution(address _event) external returns (bool) {
        require(events[_event].vestingAddress != address(0), "Vesting not active");

        IDCBPlatformVesting vesting = IDCBPlatformVesting(events[_event].vestingAddress);

        emit DistributionClaimed(msg.sender, _event);

        return vesting.claimDistribution(msg.sender);
    }

    function getInvestmentInfo(
        address _account,
        address _event
    )
        external
        view
        returns (
            Event memory,
            uint256 amount,
            IDCBPlatformVesting.VestingInfo memory v,
            IDCBPlatformVesting.WhitelistInfo memory w,
            uint256 claimable
        )
    {
        (v, w, claimable) = getVestingInfo(_account, _event);
        return (events[_event], userAmount[_event][_account], v, w, claimable);
    }

    function getVestingInfo(
        address _account,
        address _event
    )
        public
        view
        returns (
            IDCBPlatformVesting.VestingInfo memory info,
            IDCBPlatformVesting.WhitelistInfo memory whitelist,
            uint256 claimable
        )
    {
        IDCBPlatformVesting vesting = IDCBPlatformVesting(events[_event].vestingAddress);

        info = vesting.getVestingInfo();
        whitelist = vesting.getWhitelist(_account);

        claimable = vesting.getReleasableAmount(_account);
    }

    function getUserInvestments(address _address) external view returns (address[] memory) {
        address[] memory addresses = new address[](
            numUserInvestments[_address]
        );
        uint256 idx = 0;

        for (uint256 i = 0; i < eventsList.length; i++) {
            if (userAmount[eventsList[i]][_address] != 0) {
                addresses[idx] = eventsList[i];
                idx++;
            }
        }

        return addresses;
    }

    uint256[48] private __gap;
}
