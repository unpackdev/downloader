// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.15;

import "./IBeacon.sol";
import "./BeaconProxy.sol";
import "./Address.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./EnumerableSet.sol";

import "./IAsset.sol";
import "./IBribeRewarderFactory.sol";
import "./IBoostedMasterWombat.sol";
import "./IVoter.sol";
import "./BoostedMultiRewarder.sol";
import "./BribeV2.sol";

contract BribeRewarderFactory is IBribeRewarderFactory, Initializable, OwnableUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;

    IBoostedMasterWombat public masterWombat;
    IBeacon public rewarderBeacon;

    IVoter public voter;
    IBeacon public bribeBeacon;

    /// @notice Rewarder deployer is able to deploy rewarders, and it will become the rewarder operator
    mapping(IAsset => address) public rewarderDeployers;
    /// @notice Bribe deployer is able to deploy bribe, and it will become the bribe operator
    mapping(IAsset => address) public bribeDeployers;
    /// @notice whitelisted reward tokens can be added to rewarders and bribes
    EnumerableSet.AddressSet internal whitelistedRewardTokens;

    event DeployRewarderContract(
        IAsset _lpToken,
        uint256 _startTimestamp,
        IERC20 _rewardToken,
        uint96 _tokenPerSec,
        address rewarder
    );
    event SetRewarderContract(IAsset _lpToken, address rewarder);
    event SetRewarderBeacon(IBeacon beacon);
    event SetRewarderDeployer(IAsset token, address deployer);
    event DeployBribeContract(
        IAsset _lpToken,
        uint256 _startTimestamp,
        IERC20 _rewardToken,
        uint96 _tokenPerSec,
        address bribe
    );
    event SetBribeContract(IAsset _lpToken, address bribe);
    event SetBribeBeacon(IBeacon beacon);
    event SetBribeDeployer(IAsset token, address deployer);
    event WhitelistRewardTokenUpdated(IERC20 token, bool isAdded);
    event SetVoter(IVoter voter);

    function initialize(
        IBeacon _rewarderBeacon,
        IBeacon _bribeBeacon,
        IBoostedMasterWombat _masterWombat,
        IVoter _voter
    ) public initializer {
        require(Address.isContract(address(_rewarderBeacon)), 'initialize: _rewarderBeacon must be a valid contract');
        require(Address.isContract(address(_bribeBeacon)), 'initialize: _bribeBeacon must be a valid contract');
        require(Address.isContract(address(_masterWombat)), 'initialize: mw must be a valid contract');

        rewarderBeacon = _rewarderBeacon;
        bribeBeacon = _bribeBeacon;
        masterWombat = _masterWombat;
        voter = _voter;

        __Ownable_init();
    }

    function isRewardTokenWhitelisted(IERC20 _token) public view returns (bool) {
        return whitelistedRewardTokens.contains(address(_token));
    }

    function getWhitelistedRewardTokens() external view returns (address[] memory) {
        return whitelistedRewardTokens.values();
    }

    /// @notice Deploy bribe contract behind a beacon proxy, and add it to the voter
    function deployRewarderContractAndSetRewarder(
        IAsset _lpToken,
        uint256 _startTimestamp,
        IERC20 _rewardToken,
        uint96 _tokenPerSec
    ) external returns (address rewarder) {
        uint256 pid = masterWombat.getAssetPid(address(_lpToken));
        require(address(masterWombat.boostedRewarders(pid)) == address(0), 'rewarder contract alrealdy exists');

        rewarder = address(_deployRewarderContract(_lpToken, pid, _startTimestamp, _rewardToken, _tokenPerSec));
        masterWombat.setBoostedRewarder(pid, BoostedMultiRewarder(payable(rewarder)));
        emit SetRewarderContract(_lpToken, rewarder);
    }

    /// @notice Deploy bribe contract behind a beacon proxy, and add it to the voter
    function deployRewarderContract(
        IAsset _lpToken,
        uint256 _startTimestamp,
        IERC20 _rewardToken,
        uint96 _tokenPerSec
    ) external returns (address rewarder) {
        uint256 pid = masterWombat.getAssetPid(address(_lpToken));
        rewarder = address(_deployRewarderContract(_lpToken, pid, _startTimestamp, _rewardToken, _tokenPerSec));
    }

    function _deployRewarderContract(
        IAsset _lpToken,
        uint256 _pid,
        uint256 _startTimestamp,
        IERC20 _rewardToken,
        uint96 _tokenPerSec
    ) internal returns (BoostedMultiRewarder rewarder) {
        if (Address.isContract(address(voter))) {
            (, , , , , IGauge gaugeManager, ) = voter.infos(_lpToken);
            require(address(gaugeManager) != address(0), 'gauge does not exist');
        }
        require(address(masterWombat.boostedRewarders(_pid)) == address(0), 'rewarder contract alrealdy exists');

        require(rewarderDeployers[_lpToken] == msg.sender, 'Not authurized.');
        require(isRewardTokenWhitelisted(_rewardToken), 'reward token is not whitelisted');

        // deploy a rewarder contract behind a proxy
        // BoostedMultiRewarder rewarder = new BoostedMultiRewarder()
        rewarder = BoostedMultiRewarder(payable(new BeaconProxy(address(rewarderBeacon), bytes(''))));

        rewarder.initialize(this, masterWombat, _lpToken, _startTimestamp, _rewardToken, _tokenPerSec);
        rewarder.addOperator(msg.sender);
        rewarder.transferOwnership(owner());

        emit DeployRewarderContract(_lpToken, _startTimestamp, _rewardToken, _tokenPerSec, address(rewarder));
    }

    /// @notice Deploy bribe contract behind a beacon proxy, and add it to the voter
    function deployBribeContractAndSetBribe(
        IAsset _lpToken,
        uint256 _startTimestamp,
        IERC20 _rewardToken,
        uint96 _tokenPerSec
    ) external returns (address bribe) {
        (, , , , bool whitelist, IGauge gaugeManager, IBribe currentBribe) = voter.infos(_lpToken);
        require(address(currentBribe) == address(0), 'bribe contract already exists for gauge');
        require(address(gaugeManager) != address(0), 'gauge does not exist');
        require(whitelist, 'bribe contract is paused');

        bribe = address(_deployBribeContract(_lpToken, _startTimestamp, _rewardToken, _tokenPerSec));
        voter.setBribe(_lpToken, IBribe(address(bribe)));
        emit SetBribeContract(_lpToken, bribe);
    }

    /// @notice Deploy bribe contract behind a beacon proxy, and add it to the voter
    function deployBribeContract(
        IAsset _lpToken,
        uint256 _startTimestamp,
        IERC20 _rewardToken,
        uint96 _tokenPerSec
    ) external returns (address bribe) {
        bribe = address(_deployBribeContract(_lpToken, _startTimestamp, _rewardToken, _tokenPerSec));
    }

    function _deployBribeContract(
        IAsset _lpToken,
        uint256 _startTimestamp,
        IERC20 _rewardToken,
        uint96 _tokenPerSec
    ) internal returns (BribeV2 bribe) {
        (, , , , , IGauge gaugeManager, ) = voter.infos(_lpToken);
        require(address(gaugeManager) != address(0), 'gauge does not exist');

        require(bribeDeployers[_lpToken] == msg.sender, 'Not authurized.');
        require(isRewardTokenWhitelisted(_rewardToken), 'reward token is not whitelisted');

        // deploy a bribe contract behind a proxy
        // BribeV2 bribe = new BribeV2();
        bribe = BribeV2(payable(new BeaconProxy(address(bribeBeacon), bytes(''))));

        bribe.initialize(this, address(voter), _lpToken, _startTimestamp, _rewardToken, _tokenPerSec);
        bribe.addOperator(msg.sender);
        bribe.transferOwnership(owner());

        emit DeployBribeContract(_lpToken, _startTimestamp, _rewardToken, _tokenPerSec, address(bribe));
    }

    function setVoter(IVoter _voter) external onlyOwner {
        require(Address.isContract(address(_voter)), 'invalid address');
        voter = _voter;

        emit SetVoter(_voter);
    }

    function setRewarderBeacon(IBeacon _rewarderBeacon) external onlyOwner {
        require(Address.isContract(address(_rewarderBeacon)), 'invalid address');
        rewarderBeacon = _rewarderBeacon;

        emit SetRewarderBeacon(_rewarderBeacon);
    }

    function setBribeBeacon(IBeacon _bribeBeacon) external onlyOwner {
        require(Address.isContract(address(_bribeBeacon)), 'invalid address');
        bribeBeacon = _bribeBeacon;

        emit SetBribeBeacon(_bribeBeacon);
    }

    function setRewarderDeployer(IAsset _token, address _deployer) external onlyOwner {
        require(rewarderDeployers[_token] != _deployer, 'already set as deployer');
        rewarderDeployers[_token] = _deployer;
        emit SetRewarderDeployer(_token, _deployer);
    }

    function setBribeDeployer(IAsset _token, address _deployer) external onlyOwner {
        require(bribeDeployers[_token] != _deployer, 'already set as deployer');
        bribeDeployers[_token] = _deployer;
        emit SetBribeDeployer(_token, _deployer);
    }

    function whitelistRewardToken(IERC20 _token) external onlyOwner {
        require(!isRewardTokenWhitelisted(_token), 'already whitelisted');
        whitelistedRewardTokens.add(address(_token));
        emit WhitelistRewardTokenUpdated(_token, true);
    }

    function revokeRewardToken(IERC20 _token) external onlyOwner {
        require(isRewardTokenWhitelisted(_token), 'reward token is not whitelisted');
        whitelistedRewardTokens.remove(address(_token));
        emit WhitelistRewardTokenUpdated(_token, false);
    }
}
