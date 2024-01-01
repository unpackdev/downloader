// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./IRewardReceiver.sol";

/**
 * @title RewardReceiver Implementation
 * @author Quantum3 Labs
 * @notice Contract will be used with Clones library
 */
contract RewardReceiver is IRewardReceiver, Initializable, OwnableUpgradeable {
    uint96 public constant BASIS_PTS = 10000;
    uint256 public constant INIT_WITHDRAWAL_THRESHOLD =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff; // max(type(uint256))

    uint96 public pendingComission;
    uint256 public pendingWithdrawalThreshold;
    bytes[] public validators;

    address internal _client;
    address internal _provider; // managed by stakepad NO MALICIOUS PROVIDER
    address internal _stakePad; // managed by stakepad NO MALICIOUS PROVIDER
    uint96 internal _comission;
    uint256 internal _withdrawalThreshold;

    modifier onlyOwnerClientOrProvider() {
        require(
            owner() == _msgSender() || client() == _msgSender() || provider() == _msgSender(),
            "RewardReceiver: caller is not the owner, client or provider"
        );
        _;
    }

    modifier onlyOwnerOrProvider() {
        require(
            owner() == _msgSender() || provider() == _msgSender(), "RewardReceiver: caller is not the owner or provider"
        );
        _;
    }

    modifier onlyClient() {
        require(client() == _msgSender(), "RewardReceiver: caller is not the client");
        _;
    }

    modifier onlyStakePadOrProviderOrAdmin() {
        require(
            stakePad() == _msgSender() || owner() == _msgSender() || provider() == _msgSender(),
            "RewardReceiver: caller is not stakePad or provider or owner"
        );
        _;
    }

    modifier notPendingState() {
        require(pendingComission == 0 && pendingWithdrawalThreshold == 0, "RewardReceiver: pending state");
        _;
    }

    /**
     * @notice Allows the contract to receive ETH
     * @dev execution layer rewards may be sent as plain ETH transfers
     * @dev withdrawals from consensus layer to be sent through balance increments
     */
    receive() external payable {}

    function initialize(address newClient, address newProvider, uint96 newComission, address newStakePad)
        external
        initializer
    {
        __Client_init(newClient);
        __Provider_init(newProvider);
        __Ownable_init();
        __stakePad_init(newStakePad);
        __initializeRewardReceiver(newComission);
    }

    /**
     * @notice Withdraws the rewards to the client and the comission to the provider
     */
    function withdraw() external onlyOwnerClientOrProvider notPendingState {
        uint256 balance = address(this).balance;
        uint256 weightedComission;
        uint256 rewards;
        if (balance > _withdrawalThreshold) {
            weightedComission = ((balance - _withdrawalThreshold) * _comission) / BASIS_PTS;
        } else {
            weightedComission = (balance * _comission) / BASIS_PTS;
        }
        require(weightedComission > 0, "RewardReceiver: comission too low");
        rewards = balance - weightedComission;

        // transfer to provider first for safety
        (bool success1,) = address(_provider).call{value: weightedComission}("");
        (bool success0,) = address(_client).call{value: rewards}("");

        emit RewardSent(_client, rewards);
        emit ComissionSent(_provider, weightedComission);

        require(success0 && success1, "RewardReceiver: transfer failed");
    }

    function proposeNewComission(uint96 newComission) external onlyOwnerOrProvider {
        _checkValidComission(newComission);
        pendingComission = newComission;
    }

    function proposeNewWithdrawalThreshold(uint256 newWithdrawalThreshold) external onlyOwnerOrProvider {
        _checkValidWithdrawalThreshold(newWithdrawalThreshold);
        pendingWithdrawalThreshold = newWithdrawalThreshold;
    }

    function acceptNewComission() external onlyClient {
        _checkValidComission(pendingComission);
        _comission = pendingComission;
        pendingComission = 0;
    }

    function acceptNewWithdrawalThreshold() external onlyClient {
        _checkValidWithdrawalThreshold(pendingWithdrawalThreshold);
        _withdrawalThreshold = pendingWithdrawalThreshold;
        pendingWithdrawalThreshold = 0;
    }

    function cancelNewComission() external onlyOwnerOrProvider {
        _checkValidComission(pendingComission);
        pendingComission = 0;
    }

    function cancelNewWithdrawalThreshold() external onlyOwnerOrProvider {
        _checkValidWithdrawalThreshold(pendingWithdrawalThreshold);
        pendingWithdrawalThreshold = 0;
    }

    function comission() external view returns (uint96) {
        return _comission;
    }

    function withdrawalThreshold() external view returns (uint256) {
        return _withdrawalThreshold;
    }

    function addValidator(bytes memory pubkey) external onlyStakePadOrProviderOrAdmin {
        validators.push(pubkey);
    }

    function removeValidator(uint256 index) external onlyStakePadOrProviderOrAdmin {
        uint256 len = validators.length;
        require(index < len, "RewardReceiver : invalid index");
        if (index != len - 1) {
            validators[index] = validators[len - 1];
        }
        validators.pop();
    }

    function changeStakePad(address newStakePad) external onlyOwner {
        _stakePad = newStakePad;
    }

    function getValidators() external view returns (bytes[] memory) {
        return validators;
    }

    function renounceOwnership() public pure override {
        revert("RewardReceiver: renounceOwnership is disabled");
    }

    function client() public view returns (address) {
        return _client;
    }

    function provider() public view returns (address) {
        return _provider;
    }

    function stakePad() public view returns (address) {
        return _stakePad;
    }

    function transferOwnership(address newOwner) public override(IRewardReceiver, OwnableUpgradeable) {
        super.transferOwnership(newOwner);
    }

    function __Client_init(address newClient) internal {
        require(newClient != address(0), "RewardReceiver: client is the zero address");
        _client = newClient;
    }

    function __Provider_init(address newProvider) internal {
        require(newProvider != address(0), "RewardReceiver: provider is the zero address");
        _provider = newProvider;
    }

    function __stakePad_init(address newStakePad) internal {
        require(newStakePad != address(0), "RewardReceiver: stakePad is the zero address");
        _stakePad = newStakePad;
    }

    function __initializeRewardReceiver(uint96 newComission) internal {
        _checkValidComission(newComission);
        _comission = newComission;
        _withdrawalThreshold = INIT_WITHDRAWAL_THRESHOLD;
    }

    function _checkValidComission(uint96 newComission) internal pure {
        require(newComission > 0 && newComission <= BASIS_PTS, "RewardReceiver: invalid comission");
    }

    function _checkValidWithdrawalThreshold(uint256 newWithdrawalThreshold) internal pure {
        require(newWithdrawalThreshold > 0, "RewardReceiver: invalid withdrawal threshold");
    }
}
