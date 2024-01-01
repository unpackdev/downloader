// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./EnumerableSet.sol";
import "./Clones.sol";
import "./StakePadUtils.sol";
import "./IRewardReceiver.sol";
import "./IDepositContract.sol";
import "./IStakePad.sol";

//........................................................................................................
//....SSSSSS....TTTTTTTTT.....AAA.......K......KKK...EEEEEEEE.........PPPPP.........AA.......AADDD........
//...SSSSSSSS..STTTTTTTTTT...AAAAA.....KKK...KKKKKK.EEEEEEEEEE....... PPPPPPPP....AAAAA.....AAADDDDDDD....
//..SSSSSSSSSS.STTTTTTTTTT...AAAAA.....KKK..KKKKKK..EEEEEEEEEE....... PPPPPPPPP...AAAAAA....AAADDDDDDDD...
//..SSSSSSSSSS.STTTTTTTTTT..AAAAAAA....KKK.KKKKKK...EEEEEEEEEE....... PPPPPPPPP...AAAAAA....AAADDDDDDDD...
//.SSSS...SSSSS....TTTT.....AAAAAAA....KKKKKKKKK....EEE.............. PP...PPPPP.PAAAAAA....AAAD...DDDDD..
//.SSSSSS..........TTTT....AAAAAAAA....KKKKKKKK.....EEEEEEEEEE....... PP....PPPP.PAAAAAAA...AAAD....DDDD..
//..SSSSSSSSS......TTTT....AAAAAAAAA...KKKKKKK......EEEEEEEEEE....... PPPPPPPPPP.PAAAAAAA...AAAD....DDDD..
//..SSSSSSSSSS.....TTTT....AAAA.AAAA...KKKKKKKK.....EEEEEEEEEE....... PPPPPPPPP.PPAA.AAAA...AAAD....DDDD..
//....SSSSSSSSS....TTTT...TAAAAAAAAA...KKKKKKKKK....EEEEEEEEEE....... PPPPPPPPP.PPAAAAAAAA..AAAD....DDDD..
//.SSSS..SSSSSS....TTTT...TAAAAAAAAAA..KKKKKKKKK....EEE.............. PPPPPPP...PPAAAAAAAA..AAAD....DDDD..
//.SSSS....SSSS....TTTT...TAAAAAAAAAA..KKK..KKKKK...EEE.............. PP.......PPPAAAAAAAAA.AAAD...DDDDD..
//.SSSSSSSSSSSS....TTTT..TTAAAAAAAAAA..KKK..KKKKKK..EEEEEEEEEEE...... PP.......PPPAAAAAAAAA.AAADDDDDDDD...
//..SSSSSSSSSS.....TTTT..TTAA....AAAAA.KKK...KKKKKK.EEEEEEEEEEE...... PP......PPPPA....AAAA.AAADDDDDDDD...
//...SSSSSSSSS.....TTTT..TTAA.....AAAA.KKK....KKKKK.EEEEEEEEEEE...... PP......PPPP.....AAAAAAAADDDDDDD....
//....SSSSSS..............................................................................................
//........................................................................................................

/**
 * @title StakePadV1
 * @author Quantum3 Labs
 * @notice V1 of StakePad contracts
 */
contract StakePadV1 is IStakePad, Initializable, UUPSUpgradeable, OwnableUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;

    IDepositContract public immutable beaconDeposit;
    address internal _rewardReceiverImpl;
    EnumerableSet.AddressSet internal _rewardReceivers;

    constructor(address _beaconDeposit) {
        // no checks on zero address
        beaconDeposit = IDepositContract(_beaconDeposit);
    }

    /**
     * @notice initilizes the owner and the implementation of the rewardReceiverContract
     * @param newRewardReceiverImpl the implementation of the rewardReceiverContract
     */
    function initialize(address newRewardReceiverImpl) external initializer {
        _updateRewardReceiverImpl(newRewardReceiverImpl);
        __Ownable_init();
    }

    /**
     * @notice creates a contract that will receive the rewards
     * @param client Beneficiary of the rewards
     * @param provider Account on behalf of this contract
     * @param comission percentage of the rewards that will be sent to the provider
     */
    function deployNewRewardReceiver(address client, address provider, uint96 comission) external override onlyOwner {
        address newRewardReceiver = Clones.clone(rewardReceiverImpl());
        IRewardReceiver(newRewardReceiver).initialize(client, provider, comission, address(this));
        IRewardReceiver(newRewardReceiver).transferOwnership(owner());
        _rewardReceivers.add(newRewardReceiver);
        emit NewRewardReceiver(_rewardReceivers.length(), newRewardReceiver, client, provider, comission);
    }

    /**
     * @notice funds a set of validators with 32 ETH each
     * @param DepositDataArray Array of DepositData. See StakePadUtils.sol
     */
    function fundValidators(StakePadUtils.BeaconDepositParams[] calldata DepositDataArray) external payable override {
        require(msg.value == 32 ether * DepositDataArray.length, "StakePadV1: incorrect amount of ETH");
        for (uint256 i = 0; i < DepositDataArray.length; ++i) {
            StakePadUtils.BeaconDepositParams calldata DepositData = DepositDataArray[i];
            _validateWithdrawalCredentials(DepositData.withdrawal_credentials);
            _addValidatorPubKey(DepositData.pubkey, DepositData.withdrawal_credentials);
            beaconDeposit.deposit{value: 32 ether}(
                DepositData.pubkey,
                DepositData.withdrawal_credentials,
                DepositData.signature,
                DepositData.deposit_data_root
            );
        }
    }

    /**
     * @dev Updates the implementation of the Reward Receiver Contract
     * @param newRewardReceiverImpl the implementation of the Reward Receiver Contract
     */
    function updateRewardReceiverImpl(address newRewardReceiverImpl) external onlyOwner {
        _updateRewardReceiverImpl(newRewardReceiverImpl);
    }

    /**
     * @dev Retrieve any mistakenly sent funds to this contract
     */
    function retrieveETH() external onlyOwner {
        (bool success,) = owner().call{value: address(this).balance}("");
        require(success, "StakePadV1: retrieveETH failed");
    }

    function owner() public view override(OwnableUpgradeable, IStakePad) returns (address) {
        return super.owner();
    }

    /**
     * @param rewardReceiver withdrawal address
     * @dev helper function users can call to check anytime before calling fundValidators()
     */
    function isRegisteredRewardReceiver(address rewardReceiver) external view returns (bool) {
        return _isRegisteredRewardReceiver(rewardReceiver);
    }

    function transferOwnership(address newOwner) public override(OwnableUpgradeable, IStakePad) onlyOwner {
        super.transferOwnership(newOwner);
    }

    /**
     * @dev Renouncing ownership is not allowed
     */
    function renounceOwnership() public view override onlyOwner {
        revert("StakePadV1: cannot renounce ownership");
    }

    /**
     * @dev Returns the implementation of the Reward Receiver Contract.
     */
    function rewardReceiverImpl() public view returns (address) {
        return _rewardReceiverImpl;
    }

    /**
     * @param withdrawalCredentials formatted reward receiver address
     * @dev helper function to validate the withdrawal credentials format and address
     */
    function _validateWithdrawalCredentials(bytes calldata withdrawalCredentials) internal view {
        require(withdrawalCredentials.length == 32, "StakePadV1: invalid withdrawal_credentials length");

        address withdrawalCredentialsAddress = address(bytes20(withdrawalCredentials[12:]));

        require(
            _isRegisteredRewardReceiver(withdrawalCredentialsAddress) && uint8(bytes1(withdrawalCredentials[:1])) == 1,
            "StakePadV1: invalid withdrawal_credentials"
        );
    }

    function _isRegisteredRewardReceiver(address rewardReceiver) internal view returns (bool) {
        return _rewardReceivers.contains(rewardReceiver);
    }

    /**
     * @dev perform some address checks
     */
    function _updateRewardReceiverImpl(address newRewardReceiverImpl) internal {
        require(newRewardReceiverImpl != address(0), "StakePadV1: new implementation is the zero address");
        _rewardReceiverImpl = newRewardReceiverImpl;
    }

    function _addValidatorPubKey(bytes calldata pubkey, bytes calldata withdrawal_credentials) internal {
        require(pubkey.length == 48, "StakePadV1: invalid pubkey length");
        IRewardReceiver(address(bytes20(withdrawal_credentials[12:]))).addValidator(pubkey);
    }

    /**
     * @dev Upgrade the implementation of the proxy
     * @param newImplementation address of the new implementation
     * @notice only the ADMIN ( owner ) can upgrade this contract
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
