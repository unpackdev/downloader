// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Address.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IELRewardVault.sol";

contract ELRewardVault is IELRewardVault, Ownable, ReentrancyGuard {
    /// @dev Commission fee receiver address
    address public commissionReceiver;

    /// @dev Operator address
    address public operatorPartOne;

    /// @dev Operator address
    address public operatorPartTwo;

    /// @dev Calculate commission fee rate
    uint256 public constant basePct = 10000;
    uint256 public commissionPct;

    /// @dev Maximum users` info that can be processed in a single distributeReward、submitELRewardInfo、updateELRewardInfo transaction
    uint256 public maxLimit;

    /// @dev Users` withdraw request id
    uint256 public nextRequestId;
    
    /// @dev ID of the next pending order info
    uint256 public nextDistributeId;

    /// @dev Operators` signature status
    mapping(address => bool) public signStatus;

    /// @dev Users` ELReward info
    mapping(uint256 => userInfo) public ELRewardInfo;

    constructor(
        address _commissionReceiver, 
        address _operatorPartOne, 
        address _operatorPartTwo, 
        uint256 _commissionPct, 
        uint256 _maxLimit
        ) payable {
        if(address(_operatorPartOne) == address(_operatorPartTwo)) revert RepeatSetup();
        commissionReceiver = _commissionReceiver;
        operatorPartOne = _operatorPartOne;
        operatorPartTwo = _operatorPartTwo;
        commissionPct = _commissionPct;
        maxLimit = _maxLimit;
    }

    modifier onlyOperator() {
        if(msg.sender != operatorPartOne && msg.sender != operatorPartTwo) revert NotOperator();
        _;
    }

    /// @dev Update commission percentage
    /// @param _newCommissionPct New commission percentage
    function updateCommissionPct(uint256 _newCommissionPct) external onlyOwner {
        if(_newCommissionPct == commissionPct ) revert RepeatSetup();
        if(_newCommissionPct > basePct) revert InvalidFeePoint();
        initSignStatus();
        commissionPct = _newCommissionPct;
        emit UpdateCommissionPct(_newCommissionPct);
    }

    /// @dev Update commission receiver address
    /// @param _newCommissionReceiver New commission receiver address
    function updateCommissionReceiver(address _newCommissionReceiver) external onlyOwner {
        if(address(_newCommissionReceiver) == address(0)) revert ZeroValueSet();
        if(_newCommissionReceiver == commissionReceiver) revert RepeatSetup();
        initSignStatus();
        commissionReceiver = _newCommissionReceiver;
        emit UpdateCommissionReceiver(_newCommissionReceiver);
    }

    /// @dev Update operatorPartOne
    /// @param _newOperatorPartOne New operatorPartOne address
    function updateOperatorPartOne(address _newOperatorPartOne) external onlyOwner {
        if(address(_newOperatorPartOne) == address(0)) revert ZeroValueSet();
        if(_newOperatorPartOne == operatorPartOne) revert RepeatSetup();
        if(_newOperatorPartOne == operatorPartTwo) revert InvalidRoleSet();
        initSignStatus();
        operatorPartOne = _newOperatorPartOne;
        emit UpdateOperatorPartOne(_newOperatorPartOne);
    }

    /// @dev Update operatorPartTwo
    /// @param _newOperatorPartTwo New operatorPartTwo address
    function updateOperatorPartTwo(address _newOperatorPartTwo) external onlyOwner {
        if(address(_newOperatorPartTwo) == address(0)) revert ZeroValueSet();
        if(_newOperatorPartTwo == operatorPartTwo) revert RepeatSetup();
        if(_newOperatorPartTwo == operatorPartOne) revert InvalidRoleSet();
        initSignStatus();
        operatorPartTwo = _newOperatorPartTwo;
        emit UpdateOperatorPartTwo(_newOperatorPartTwo);
    }

    /// @dev Update maxLimit
    /// @param _newMaxLimit New maxLimit
    function updateMaxLimit(uint256 _newMaxLimit) external onlyOwner {
        if(_newMaxLimit == 0) revert ZeroValueSet();
        if(_newMaxLimit == maxLimit) revert RepeatSetup();
        initSignStatus();
        maxLimit = _newMaxLimit;
        emit UpdateMaxLimit(_newMaxLimit);
    }

    /// @dev Submit users` ELReward info
    /// @param usersInfo Users` ELReward info
    /// @param replace bool value
    /// replace value is false: submit users` ELReward info
    /// replace value is true: correct users` historical ELReward info and set nextId to new index
    function submitELRewardInfo(userInfo[] calldata usersInfo, bool replace) external onlyOperator {
        if(usersInfo.length > maxLimit) revert OverMaxLimit();
        if(replace) {
            if(nextRequestId == 0) revert EmptyELRewardInfo();
            nextDistributeId = nextRequestId;
        }
        for(uint256 i = 0; i < usersInfo.length; ) {
            ELRewardInfo[nextRequestId] = usersInfo[i];
            unchecked {
                nextRequestId++;
                ++i;
            }
        }
        emit SubmitELRewardInfo(msg.sender, usersInfo, nextDistributeId);
    }

    /// @dev distribute users` EL reward
    function distributeReward() external onlyOperator {  
        if(signStatus[msg.sender]) revert NotSignTwice();
        if(nextRequestId == nextDistributeId) revert EmptyELRewardInfo();
        address executor = msg.sender == operatorPartOne ? operatorPartTwo : operatorPartOne;
        if(signStatus[executor]) {
            uint256 currentMaxLimit = maxLimit + nextDistributeId;
            while(nextDistributeId < nextRequestId && nextDistributeId < currentMaxLimit) {
                _distributeReward(ELRewardInfo[nextDistributeId].withdrawAddress, ELRewardInfo[nextDistributeId].ELReward);
                nextDistributeId++;
            }
            delete signStatus[executor];
            emit ExecTransaction(msg.sender, nextDistributeId);
        } else {
            signStatus[msg.sender] = true;
            emit SignTransaction(msg.sender, signStatus[msg.sender]);
        }
    }

    /// @dev Migrate ETH to a new EL reward vault contract when current contract is suspended
    /// @param newELRewardVault New ELRewardVault contract address
    function migrateFund(address newELRewardVault) external onlyOwner {
        if(address(newELRewardVault) == address(0)) revert ZeroValueSet(); 
        uint256 currentBalance = address(this).balance;
        if(currentBalance == 0) revert NotFund(); 
        Address.sendValue(payable(newELRewardVault), currentBalance);
        emit MigrateFund(msg.sender, newELRewardVault, currentBalance);
    }

    /// @dev distribute user's EL reward
    function _distributeReward(address _userAddress, uint256 _ELReward) internal nonReentrant {
        if(_ELReward > address(this).balance) revert RewardTooLarge();

        uint256 commissionFee = _ELReward * commissionPct / basePct;
        Address.sendValue(payable(_userAddress), (_ELReward - commissionFee));
        emit UserRewardDistributed(_userAddress, (_ELReward - commissionFee));
        Address.sendValue(payable(commissionReceiver), commissionFee);
        emit CommissionFeeTransferred(commissionReceiver, commissionFee);
    }

    function initSignStatus() internal {
        if(signStatus[operatorPartOne]){
            delete signStatus[operatorPartOne]; 
            emit InitSignStatus(operatorPartOne, signStatus[operatorPartOne]);
        } 
        if(signStatus[operatorPartTwo]) { 
            delete signStatus[operatorPartTwo]; 
            emit InitSignStatus(operatorPartTwo, signStatus[operatorPartTwo]);
        }
    }

    receive() external payable {}
}