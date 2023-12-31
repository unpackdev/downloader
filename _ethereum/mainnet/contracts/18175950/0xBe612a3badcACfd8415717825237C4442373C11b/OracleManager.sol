// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./AccessControlUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./Initializable.sol";
import "./PausableUpgradeable.sol";
import "./Math.sol";

import "./INodeStakingPool.sol";

/* import "./console.sol"; */
/// @custom:security-contact security@ovmi.sh
contract OracleManager is
    Initializable,
    AccessControlEnumerableUpgradeable,
    PausableUpgradeable
{
    using Math for uint256;

    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    address payable public StakingPool;

    uint8 public MIN_THRESHOLD;
    uint256 public MAX_DIFFERENCE_PERCENTAGE;

    uint256 public currentOracleValue;

    struct OracleReportStruct {
        uint256 value;
        uint256 rewards;
        bool hasReported;
        bytes signature;
        uint256 blockNumber;
    }

    mapping(address => OracleReportStruct) public oracleSubmissions;
    uint256 public oracleSubmissionsCount;

    bytes[] public validatorsPool;
    mapping(bytes32 => uint256) public validatorsPoolIndex;

    /************
    ERRORS
    *************/
    error InvalidAddress();
    error InvalidThreshold();
    error InvalidSignature(); 
    error AlreadyReportedValue();
    error InvalidValues();

    /************
    EVENTS
    *************/
    event LogNewOracleSubmission(address sender, uint256 value);
    event LogUpdateOracleSubmission(address sender, uint256 value);
    event LogUpdatedOracleValue(uint256 value);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract
     * @param _stakingPool Address of the Staking Pool contract
     */
    function initialize(
        address payable _stakingPool,
        address _manager
    ) public initializer {
        __AccessControl_init();

        if (_stakingPool == address(0) || _manager == address(0)) {
            revert InvalidAddress();
        }

        MIN_THRESHOLD = 3;
        MAX_DIFFERENCE_PERCENTAGE = 10;

        StakingPool = _stakingPool;

        _grantRole(DEFAULT_ADMIN_ROLE, _manager);
        _grantRole(MANAGER_ROLE, _manager);
    }

    /**
     * @dev Update the minimum threshold of oracles required to update the oracle value
     * @param _minThreshold Minimum threshold of oracles required to update the oracle value
     */
    function updateMinThreshold(
        uint8 _minThreshold
    ) external onlyRole(MANAGER_ROLE) {
        // min threshold must be greater than 0 and less than the number of oracles
        if (
            _minThreshold == 0 ||
            _minThreshold > getRoleMemberCount(ORACLE_ROLE)
        ) {
            revert InvalidThreshold();
        }

        MIN_THRESHOLD = _minThreshold;
    }

    /**
     * @dev Update the maximum difference percentage between the reported values
     * @param _maxDifferencePercentage Maximum difference percentage between the reported values
     */
    function updateMaxDifferencePercentage(
        uint256 _maxDifferencePercentage
    ) external onlyRole(MANAGER_ROLE) {
        MAX_DIFFERENCE_PERCENTAGE = _maxDifferencePercentage;
    }

    /**
     * @dev Update the Staking Pool contract address
     * @param _stakingPool Address of the Staking Pool contract
     */
    function updateStakingPool(
        address payable _stakingPool
    ) external onlyRole(MANAGER_ROLE) {
        if (_stakingPool == address(0) || _stakingPool == StakingPool)
            revert InvalidAddress();

        StakingPool = _stakingPool;
    }

    /**
     * @dev Pause contract using OpenZeepelin Pausable
     */
    function pause() external onlyRole(MANAGER_ROLE) {
        _pause();
    }

    /**
     * @dev Unpause contract using OpenZeepelin Pausable
     */
    function unpause() external onlyRole(MANAGER_ROLE) {
        _unpause();
    }

    /**
     * @dev Send a new oracle submission
     * @param _value Value to be reported
     * @param _blockNumber Block number
     * @param _signature Signature of the message
     */
    function sendOracleSubmission(
        uint256 _value,
        uint256 _rewards,
        uint256 _blockNumber,
        bytes memory _signature
    ) public onlyRole(ORACLE_ROLE) whenNotPaused {
        if (oracleSubmissions[msg.sender].value == _value)
            revert AlreadyReportedValue();

        // verify the signature
        bytes32 messageHash = getEthSignedMessageHash(
            getMessageHash(_value, _blockNumber)
        );
        address signer = recoverSigner(messageHash, _signature);
        if (signer != msg.sender) revert InvalidSignature();

        oracleSubmissions[msg.sender] = OracleReportStruct({
            value: _value,
            rewards: _rewards,
            hasReported: true,
            signature: _signature,
            blockNumber: _blockNumber
        });

        oracleSubmissionsCount++;
        emit LogNewOracleSubmission(msg.sender, _value);

        if (oracleSubmissionsCount >= MIN_THRESHOLD) {
            _processOracleStats();
        }
    }

    function _processOracleStats() internal {
        uint256[] memory reportedValues = new uint256[](oracleSubmissionsCount);
        uint256 index = 0;

        uint256 oraclesCount = getRoleMemberCount(ORACLE_ROLE);
        for (uint256 i = 0; i < oraclesCount; i++) {
            address oa = getRoleMember(ORACLE_ROLE, i);
            if (oracleSubmissions[oa].hasReported) {
                reportedValues[index] = oracleSubmissions[oa].value;
                index++;
            }
        }

        uint256 min = reportedValues[0];
        uint256 max = reportedValues[0];
        for (uint256 i = 0; i < reportedValues.length; i++) {
            if (reportedValues[i] < min) {
                min = reportedValues[i];
            }
            if (reportedValues[i] > max) {
                max = reportedValues[i];
            }
        }

        if (max - min > (max * MAX_DIFFERENCE_PERCENTAGE) / 100)
            revert InvalidValues();

        // Reset reports
        for (uint256 i = 0; i < oraclesCount; i++) {
            delete oracleSubmissions[getRoleMember(ORACLE_ROLE, i)];
        }
        oracleSubmissionsCount = 0;

        // Set beacon balance to median
        currentOracleValue = median(reportedValues);

        // Update Staking Pool contract
        INodeStakingPool(StakingPool).updateOracleStats(currentOracleValue, 0);

        emit LogUpdatedOracleValue(currentOracleValue);
    }

    /************
    UTILITIES
    *************/

    /**
     * @dev Returns the hash of a message
     * @param _message Message
     * @param _blockNumber Block number
     */
    function getMessageHash(
        uint256 _message,
        uint256 _blockNumber
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_message, _blockNumber));
    }

    /**
     * @dev Returns the hash of a signed message
     * @param _messageHash Hash of the message
     * @return bytes32 Hash of the signed message
     */
    function getEthSignedMessageHash(
        bytes32 _messageHash
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    /**
     * @dev Verifies that a message's signer is the owner of the signature
     * @param _signer Signer address
     * @param _message Message
     * @param _blockNumber Block number
     * @param signature Signature
     * @return bool True if the signature is valid
     */
    function verify(
        address _signer,
        uint256 _message,
        uint256 _blockNumber,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(_message, _blockNumber);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    /**
     * @dev Recover signer address from a message by using his signature
     * @param _ethSignedMessageHash Hash of the signed message
     * @param _signature Signature
     * @return address Signer address
     */
    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    /**
     * @dev Split signature into `r`, `s` and `v` components.
     * @param sig Signature
     * @return r
     * @return s
     * @return v
     */
    function splitSignature(
        bytes memory sig
    ) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        if (sig.length != 65) revert InvalidSignature();

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    /**
     * @dev Swaps two elements in an array
     * @param array Array of uint256
     * @param i Index of the first element
     * @param j Index of the second element
     */
    function swap(uint256[] memory array, uint256 i, uint256 j) internal pure {
        (array[i], array[j]) = (array[j], array[i]);
    }

    /**
     * @dev Sorts an array of uint256 in ascending order
     * @param array Array of uint256 to sort
     * @param begin Beginning index
     * @param end Ending index
     */
    function sort(
        uint256[] memory array,
        uint256 begin,
        uint256 end
    ) internal pure {
        if (begin < end) {
            uint256 j = begin;
            uint256 pivot = array[j];
            for (uint256 i = begin + 1; i < end; ++i) {
                if (array[i] < pivot) {
                    swap(array, i, ++j);
                }
            }
            swap(array, begin, j);
            sort(array, begin, j);
            sort(array, j + 1, end);
        }
    }

    /**
     * @dev Returns the median of an array of uint256
     * @param _thresholds Array of uint256
     * @return uin256 The median value
     */
    function median(
        uint256[] memory _thresholds
    ) internal pure returns (uint256) {
        sort(_thresholds, 0, _thresholds.length);
        return
            _thresholds.length % 2 == 0
                ? Math.average(
                    _thresholds[_thresholds.length / 2 - 1],
                    _thresholds[_thresholds.length / 2]
                )
                : _thresholds[_thresholds.length / 2];
    }
}
