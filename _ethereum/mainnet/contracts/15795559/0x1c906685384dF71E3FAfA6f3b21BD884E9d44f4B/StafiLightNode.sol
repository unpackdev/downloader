pragma solidity 0.7.6;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

import "./StafiBase.sol";
import "./IStafiLightNode.sol";
import "./IStafiNodeManager.sol";
import "./IStafiUserDeposit.sol";
import "./IDepositContract.sol";
import "./IStafiNetworkSettings.sol";
import "./IPubkeySetStorage.sol";
import "./SafeMath.sol";
import "./IStafiEtherWithdrawer.sol";
import "./IStafiEther.sol";

contract StafiLightNode is StafiBase, IStafiLightNode, IStafiEtherWithdrawer {
    // Libs
    using SafeMath for uint256;

    event EtherDeposited(address indexed from, uint256 amount, uint256 time);
    event Deposited(address node, bytes pubkey, bytes validatorSignature, uint256 amount);
    event Staked(address node, bytes pubkey);
    event OffBoarded(address node, bytes pubkey);
    event SetPubkeyStatus(bytes pubkey, uint256 status);

    uint256 public constant PUBKEY_STATUS_UNINITIAL = 0;
    uint256 public constant PUBKEY_STATUS_INITIAL = 1;
    uint256 public constant PUBKEY_STATUS_MATCH = 2;
    uint256 public constant PUBKEY_STATUS_STAKING = 3;
    uint256 public constant PUBKEY_STATUS_UNMATCH = 4;
    uint256 public constant PUBKEY_STATUS_OFFBOARD = 5;
    uint256 public constant PUBKEY_STATUS_CANWITHDRAW = 6; // can withdraw node deposit amount after offboard
    uint256 public constant PUBKEY_STATUS_WITHDRAWED = 7;

    // Construct
    constructor(address _stafiStorageAddress) StafiBase(_stafiStorageAddress) {
        version = 1;
    }

    // Receive a ether withdrawal
    // Only accepts calls from the StafiEther contract
    function receiveEtherWithdrawal() override external payable onlyLatestContract("stafiLightNode", address(this)) onlyLatestContract("stafiEther", msg.sender) {}

    // Deposit ETH from deposit pool
    // Only accepts calls from the StafiUserDeposit contract
    function depositEth() override external payable onlyLatestContract("stafiUserDeposit", msg.sender) {
        // Emit ether deposited event
        emit EtherDeposited(msg.sender, msg.value, block.timestamp);
    }

    function EthDeposit() private view returns (IDepositContract) {
        return IDepositContract(getContractAddress("ethDeposit"));
    }

    function StafiNetworkSettings() private view returns (IStafiNetworkSettings) {
        return IStafiNetworkSettings(getContractAddress("stafiNetworkSettings"));
    }

    function PubkeySetStorage() public view returns (IPubkeySetStorage) {
        return IPubkeySetStorage(getContractAddress("pubkeySetStorage"));
    }

    // Get the number of pubkeys owned by a light node
    function getLightNodePubkeyCount(address _nodeAddress) override public view returns (uint256) {
        return PubkeySetStorage().getCount(keccak256(abi.encodePacked("lightNode.pubkeys.index", _nodeAddress)));
    }

    // Get a light node pubkey by index
    function getLightNodePubkeyAt(address _nodeAddress, uint256 _index) override public view returns (bytes memory) {
        return PubkeySetStorage().getItem(keccak256(abi.encodePacked("lightNode.pubkeys.index", _nodeAddress)), _index);
    }
    
    // Get a light node pubkey status
    function getLightNodePubkeyStatus(bytes calldata _validatorPubkey) override public view returns (uint256) {
        return getUint(keccak256(abi.encodePacked("lightNode.pubkey.status", _validatorPubkey)));
    }

    // Set a light node pubkey status
    function _setLightNodePubkeyStatus(bytes calldata _validatorPubkey, uint256 _status) private {
        setUint(keccak256(abi.encodePacked("lightNode.pubkey.status", _validatorPubkey)), _status);
        
        emit SetPubkeyStatus(_validatorPubkey, _status);
    }

    function setLightNodePubkeyStatus(bytes calldata _validatorPubkey, uint256 _status) public onlySuperUser {
        _setLightNodePubkeyStatus(_validatorPubkey, _status);
    }

    // Node deposits currently amount
    function getCurrentNodeDepositAmount() public view returns (uint256) {
        return getUint("settings.node.deposit.amount");
    }

    function getLightNodeDepositEnabled() public view returns (bool) {
        return getBoolS("settings.lightNode.deposit.enabled");
    }
    
    function getPubkeyVoted(bytes calldata _validatorPubkey, address user) public view returns (bool) {
        return getBool(keccak256(abi.encodePacked("lightNode.memberVotes.", _validatorPubkey, user)));
    }

    function setLightNodeDepositEnabled(bool _value) public onlySuperUser {
        setBoolS("settings.lightNode.deposit.enabled", _value);
    }

    function deposit(bytes[] calldata _validatorPubkeys, bytes[] calldata _validatorSignatures, bytes32[] calldata _depositDataRoots) override external payable onlyLatestContract("stafiLightNode", address(this)) {
        require(getLightNodeDepositEnabled(), "light node deposits are currently disabled");
        uint256 len = _validatorPubkeys.length;
        require(len == _validatorSignatures.length && len == _depositDataRoots.length, "params len err");
        require(msg.value == len.mul(getCurrentNodeDepositAmount()), "msg value not match");

        for (uint256 i = 0; i < len; i++) {
            _deposit(_validatorPubkeys[i], _validatorSignatures[i], _depositDataRoots[i]);
        }
    }

    function stake(bytes[] calldata _validatorPubkeys, bytes[] calldata _validatorSignatures, bytes32[] calldata _depositDataRoots) override external onlyLatestContract("stafiLightNode", address(this)) {
        require(_validatorPubkeys.length == _validatorSignatures.length && _validatorPubkeys.length == _depositDataRoots.length, "params len err");
        // Load contracts
        IStafiUserDeposit stafiUserDeposit = IStafiUserDeposit(getContractAddress("stafiUserDeposit"));
        stafiUserDeposit.withdrawExcessBalanceForLightNode(_validatorPubkeys.length.mul(uint256(32 ether).sub(getCurrentNodeDepositAmount())));

        for (uint256 i = 0; i < _validatorPubkeys.length; i++) {
            _stake(_validatorPubkeys[i], _validatorSignatures[i], _depositDataRoots[i]);
        }
    }

    function offBoard(bytes calldata _validatorPubkey) override external onlyLatestContract("stafiLightNode", address(this)) {
        setAndCheckNodePubkeyInOffBoard(_validatorPubkey);

        emit OffBoarded(msg.sender, _validatorPubkey);
    }

    function provideNodeDepositToken(bytes calldata _validatorPubkey) override external payable onlyLatestContract("stafiLightNode", address(this)) {
        require(msg.value == getCurrentNodeDepositAmount(), "msg value not match");
        // check status
        require(getLightNodePubkeyStatus(_validatorPubkey) == PUBKEY_STATUS_OFFBOARD, "pubkey status unmatch");
        
        IStafiEther stafiEther = IStafiEther(getContractAddress("stafiEther"));
        stafiEther.depositEther{value: msg.value}();

        // set pubkey status
        _setLightNodePubkeyStatus(_validatorPubkey, PUBKEY_STATUS_CANWITHDRAW);
    }
    
    function withdrawNodeDepositToken(bytes calldata _validatorPubkey) override external onlyLatestContract("stafiLightNode", address(this)) {
        // check status
        require(getLightNodePubkeyStatus(_validatorPubkey) == PUBKEY_STATUS_CANWITHDRAW, "pubkey status unmatch");
        // check owner
        require(PubkeySetStorage().getIndexOf(keccak256(abi.encodePacked("lightNode.pubkeys.index", msg.sender)), _validatorPubkey) >= 0, "not pubkey owner");

        IStafiEther stafiEther = IStafiEther(getContractAddress("stafiEther"));
        stafiEther.withdrawEther(getCurrentNodeDepositAmount());

        // set pubkey status
        _setLightNodePubkeyStatus(_validatorPubkey, PUBKEY_STATUS_WITHDRAWED);

        (bool success,) = (msg.sender).call{value: getCurrentNodeDepositAmount()}("");
        require(success, "transferr failed");
    }

    function _deposit(bytes calldata _validatorPubkey, bytes calldata _validatorSignature, bytes32 _depositDataRoot) private {
        setAndCheckNodePubkeyInDeposit(_validatorPubkey);
        // Send staking deposit to casper
        EthDeposit().deposit{value: getCurrentNodeDepositAmount()}(_validatorPubkey, StafiNetworkSettings().getWithdrawalCredentials(), _validatorSignature, _depositDataRoot);

        emit Deposited(msg.sender, _validatorPubkey, _validatorSignature, getCurrentNodeDepositAmount());
    }

    function _stake(bytes calldata _validatorPubkey, bytes calldata _validatorSignature, bytes32 _depositDataRoot) private {
        setAndCheckNodePubkeyInStake(_validatorPubkey);
        // Send staking deposit to casper
        EthDeposit().deposit{value: uint256(32 ether).sub(getCurrentNodeDepositAmount())}(_validatorPubkey, StafiNetworkSettings().getWithdrawalCredentials(), _validatorSignature, _depositDataRoot);

        emit Staked(msg.sender, _validatorPubkey);
    }

    // Set and check a node's validator pubkey
    function setAndCheckNodePubkeyInDeposit(bytes calldata _pubkey) private {
        // check pubkey of stakingpools
        require(getAddress(keccak256(abi.encodePacked("validator.stakingpool", _pubkey))) == address(0x0), "stakingpool pubkey exists");
        // check pubkey of superNodes
        require(getUint(keccak256(abi.encodePacked("superNode.pubkey.status", _pubkey))) == PUBKEY_STATUS_UNINITIAL, "super Node pubkey exists");

        // check status
        require(getLightNodePubkeyStatus(_pubkey) == PUBKEY_STATUS_UNINITIAL, "pubkey status unmatch");
        // set pubkey status
        _setLightNodePubkeyStatus(_pubkey, PUBKEY_STATUS_INITIAL);
        // add pubkey to set
        PubkeySetStorage().addItem(keccak256(abi.encodePacked("lightNode.pubkeys.index", msg.sender)), _pubkey);
    }
    
    // Set and check a node's validator pubkey
    function setAndCheckNodePubkeyInStake(bytes calldata _pubkey) private {
        // check status
        require(getLightNodePubkeyStatus(_pubkey) == PUBKEY_STATUS_MATCH, "pubkey status unmatch");
        // check owner
        require(PubkeySetStorage().getIndexOf(keccak256(abi.encodePacked("lightNode.pubkeys.index", msg.sender)), _pubkey) >= 0, "not pubkey owner");

        // set pubkey status
        _setLightNodePubkeyStatus(_pubkey, PUBKEY_STATUS_STAKING);
    }
    
    // Set and check a node's validator pubkey
    function setAndCheckNodePubkeyInOffBoard(bytes calldata _pubkey) private {
        // check status
        require(getLightNodePubkeyStatus(_pubkey) == PUBKEY_STATUS_MATCH, "pubkey status unmatch");
        // check owner
        require(PubkeySetStorage().getIndexOf(keccak256(abi.encodePacked("lightNode.pubkeys.index", msg.sender)), _pubkey) >= 0, "not pubkey owner");
        
        // set pubkey status
        _setLightNodePubkeyStatus(_pubkey, PUBKEY_STATUS_OFFBOARD);
    }

    // Only accepts calls from trusted (oracle) nodes
    function voteWithdrawCredentials(bytes[] calldata _pubkeys, bool[] calldata _matchs) override external onlyLatestContract("stafiLightNode", address(this)) onlyTrustedNode(msg.sender) {
        require(_pubkeys.length == _matchs.length, "params len err");
        for (uint256 i = 0; i < _pubkeys.length; i++) {
            _voteWithdrawCredentials(_pubkeys[i], _matchs[i]);
        }
    }
    function _voteWithdrawCredentials(bytes calldata _pubkey, bool _match) private {
        // Check & update node vote status
        require(!getBool(keccak256(abi.encodePacked("lightNode.memberVotes.", _pubkey, msg.sender))), "Member has already voted to withdrawCredentials");
        setBool(keccak256(abi.encodePacked("lightNode.memberVotes.", _pubkey, msg.sender)), true);
       
        // Increment votes count
        uint256 totalVotes = getUint(keccak256(abi.encodePacked("lightNode.totalVotes", _pubkey, _match)));
        totalVotes = totalVotes.add(1);
        setUint(keccak256(abi.encodePacked("lightNode.totalVotes", _pubkey, _match)), totalVotes);
       
        // Check count and set status
        uint256 calcBase = 1 ether;
        IStafiNodeManager stafiNodeManager = IStafiNodeManager(getContractAddress("stafiNodeManager"));
        if (getLightNodePubkeyStatus(_pubkey) == PUBKEY_STATUS_INITIAL &&  calcBase.mul(totalVotes) >= stafiNodeManager.getTrustedNodeCount().mul(StafiNetworkSettings().getNodeConsensusThreshold())) {
            _setLightNodePubkeyStatus(_pubkey, _match ? PUBKEY_STATUS_MATCH : PUBKEY_STATUS_UNMATCH);
        }
    }
}
