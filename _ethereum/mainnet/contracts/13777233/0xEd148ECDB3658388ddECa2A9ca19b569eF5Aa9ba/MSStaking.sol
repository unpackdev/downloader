//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import "./MSNFT.sol";
import "./MerkleProof.sol";
import "./AccessControlEnumerable.sol";
import "./Pausable.sol";

contract MSStaking is Context, AccessControlEnumerable, Pausable {
    struct StakerMetadata {
        uint256 expectAmount;
        uint256 stakedValue;
        uint256 stakeTimestamp;
    }

    mapping(address => StakerMetadata) public userData;
    mapping(address => bool) public withdrawnList;
    mapping(address => bool) public reservedList;
    mapping(string => bytes32) public roleName;
    uint256 public totalStakedValue;
    uint256 public activityId;
    uint256 public maxCirculation;
    uint256 public expectAmountLimit;
    uint256 public minReserveValue;
    uint256 public nftPrice;
    uint256 public totalStaker;
    uint256 public totalReservedCirculation;
    uint256 public stakeStartTime;
    uint256 public stakeEndTime;
    address public nftContract;
    bytes32 public root;

    event Stake(address staker, uint256 value, uint256 expectAmount, uint256 timestamp);
    event Withdraw(address staker, uint256 returnValue, uint256 timestamp);
    event Sale(
        uint256 activityId,
        address nftContract,
        address buyer,
        uint256 tokenId,
        uint256 matronId,
        uint256 sireId,
        uint256 birthDate,
        uint256 breedCount,
        bool fertile
    );

    constructor(
        uint256 _activityId,
        uint256 _maxCirculation,
        uint256 _expectAmountLimit,
        uint256 _minReserveValue,
        uint256 _nftPrice,
        uint256 _stakeStartTime,
        uint256 _stakeEndTime,
        address _nftContract
    ) {
        roleName["PAUSER_ROLE"] = keccak256("PAUSER_ROLE");
        activityId = _activityId;
        maxCirculation = _maxCirculation;
        expectAmountLimit = _expectAmountLimit;
        minReserveValue = _minReserveValue;
        nftPrice = _nftPrice;
        stakeStartTime = _stakeStartTime;
        stakeEndTime = _stakeEndTime;
        nftContract = _nftContract;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(roleName["PAUSER_ROLE"], _msgSender());
    }

    modifier onlyPauser() {
        require(
            hasRole(roleName["PAUSER_ROLE"], _msgSender()),
            "MSStaking: Must have pauser role"
        );
        _;
    }

    modifier StakeStarted() {
        require(
            block.timestamp >= stakeStartTime,
            "MSStaking: Staking hasn't started yet"
        );
        _;
    }

    modifier StakeNotEnded() {
        require(block.timestamp < stakeEndTime, "MSStaking: Staking has ended");
        _;
    }

    modifier onlyStakeEnded() {
        require(
            block.timestamp >= stakeEndTime,
            "MSStaking: Staking hasn't ended"
        );
        _;
    }

    modifier rootIsSet() {
        require(root != 0, "MSStaking: Merkle root hasn't set yet");
        _;
    }

    modifier nftContractIsSet() {
        require(nftContract != address(0), "MSStaking: nft Contract hasn't set yet");
        _;
    }

    function pause() public onlyPauser {
        _pause();
    }

    function unpause() public onlyPauser {
        _unpause();
    }

    function setRoot(bytes32 _root) public onlyRole(DEFAULT_ADMIN_ROLE) {
        root = _root;
    }

    function setNFTContract(address _nftContract) public onlyRole(DEFAULT_ADMIN_ROLE) {
        nftContract = _nftContract;
    }

    function adminWithdraw(address _to, uint256 _balance) public onlyRole(DEFAULT_ADMIN_ROLE) whenPaused {
        (bool success, ) = _to.call{value: _balance}("");
        require(
            success,
            "MSStaking: Unable to send value, recipient may have reverted"
        );
    }

    function withdraw(bytes32[] calldata _proof, uint256 _actualAmount)
        public
        whenNotPaused
        nftContractIsSet
        rootIsSet
        onlyStakeEnded
    {
        require(!withdrawnList[_msgSender()], "MSStaking: User has withdrawn");
        require(
            userData[_msgSender()].stakedValue >= _actualAmount * nftPrice,
            "MSSTaking: ExpectAmount is not matched with stake value"
        );
        require(
            _verifyProof(_proof, _actualAmount),
            "MSStaking: Proof or expectAmount qty is wrong"
        );
        withdrawnList[_msgSender()] = true;

        uint256 size;
        address sender = _msgSender();
        assembly {
            size := extcodesize(sender)
        }
        require(
            size == 0,
            "MSSTaking: Transfer to contract address not allowed"
        );
        uint256 spentValue = _actualAmount * nftPrice;
        uint256 returnValue = userData[_msgSender()].stakedValue - spentValue;
        (bool success, ) = _msgSender().call{value: returnValue}("");
        require(
            success,
            "MSStaking: Unable to send value, recipient may have reverted"
        );
        for (uint256 i = 0; i < _actualAmount; i++) {
            uint256 tokenId = MSNFT(nftContract).mint(
                _msgSender(),
                0,
                0,
                0,
                true
            );
            emit Sale(
                activityId,
                nftContract,
                _msgSender(),
                tokenId,
                0,
                0,
                block.timestamp,
                0,
                true
            );
        }
        emit Withdraw(_msgSender(), returnValue, block.timestamp);
    }

    function stake(uint256 _expectAmount)
        public
        payable
        whenNotPaused
        StakeStarted
        StakeNotEnded
    {
        require(_expectAmount != 0, "MSStaking: Expect amount cannot be 0");
        require(
            totalReservedCirculation < maxCirculation,
            "MSStaking: Reserved circulation exceeds maxCirculation"
        );
        require(
            _expectAmount <= expectAmountLimit,
            "MSStaking: ExpectAmount cannot exceed expectAmountLimit"
        );
        require(
            userData[_msgSender()].stakedValue + msg.value >=
                _expectAmount * nftPrice,
            "MSStaking: Stake value didn't match expectAmount"
        );
        if (
            userData[_msgSender()].stakedValue + msg.value >= minReserveValue &&
            reservedList[_msgSender()] == false
        ) {
            reservedList[_msgSender()] = true;
            totalReservedCirculation++;
        }
        if (userData[_msgSender()].stakedValue == 0) {
            totalStaker += 1;
        }
        userData[_msgSender()].expectAmount = _expectAmount;
        userData[_msgSender()].stakedValue += msg.value;
        userData[_msgSender()].stakeTimestamp = block.timestamp;
        totalStakedValue += msg.value;
        emit Stake(_msgSender(), msg.value, _expectAmount, block.timestamp);
    }

    function _getLeaf(uint256 _expectAmount) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(keccak256(abi.encode(_msgSender(), _expectAmount)))
            );
    }

    function _verifyProof(bytes32[] calldata _proof, uint256 _expectAmount)
        internal
        view
        returns (bool)
    {
        bytes32 leaf = _getLeaf(_expectAmount);
        return MerkleProof.verify(_proof, root, leaf);
    }
}
