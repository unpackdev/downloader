pragma solidity 0.6.0;
pragma experimental ABIEncoderV2;

// import ierc20 & safemath & non-standard
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


interface ILinearVesting {
    
    event ScheduleCreated(address indexed _beneficiary);
    
    /// @notice event emitted when a successful drawn down of vesting tokens is made
    event DrawDown(address indexed _beneficiary, uint256 indexed _amount);

    function createVestingSchedules(
        address[] calldata _beneficiaries,
        uint256[] calldata _amounts
    ) external returns (bool);

    function createVestingSchedule(address _beneficiary, uint256 _amount) external returns (bool);

    function transferOwnership(address _newOwner) external;

    function tokenBalance() external view returns (uint256) ;
    
    function vestingScheduleForBeneficiary(address _beneficiary)
    external view
    returns (uint256 _amount, uint256 _totalDrawn, uint256 _lastDrawnAt, uint256 _remainingBalance);

    function availableDrawDownAmount(address _beneficiary) external view returns (uint256 _amount);

    function remainingBalance(address _beneficiary) external view returns (uint256);
    
    function drawDown() external returns (bool);
}

contract devpool {
    address[] public approvers;
    uint public votes;
    struct Transfer {
        uint id;
        uint amount;
        address payable to;
        uint approvals;
        bool sent;
        IERC20 token;
    }
    Transfer[] public transfers;
    mapping(address => mapping(uint => bool)) public approvals;
    
    IERC20 public dai;
    ILinearVesting public linearVesting;
    
    constructor(address[] memory _approvers, uint _votes,address _linearvesting) public {
        approvers = _approvers;
        votes = _votes;
        linearVesting = ILinearVesting(_linearvesting);
    }
    
    function drawdownpool() public {
         linearVesting.drawDown();
    }
    
    function getApprovers() external view returns(address[] memory) {
        return approvers;
    }
    
    function getTransfers() external view returns(Transfer[] memory) {
        return transfers;
    }

    function createTransfer(uint amount,IERC20 _token,address payable to) external onlyApprover() {
        transfers.push(Transfer(
            transfers.length,
            amount,
            to,
            0,
            false,
            _token
        ));
    }
    
    function approveTransfer(uint id) external onlyApprover() {
        require(transfers[id].sent == false, 'transfer has already been sent');
        require(approvals[msg.sender][id] == false, 'cannot approve transfer twice');
        
        approvals[msg.sender][id] = true;
        transfers[id].approvals++;
        
        if(transfers[id].approvals >= votes && approvals[approvers[0]][id]) {
            transfers[id].sent = true;
            address payable to = transfers[id].to;
            uint amount = transfers[id].amount;
            transfers[id].token.transfer(to,amount);
        }
    }
    
    function getContractTokenBalance(IERC20 _token) public view returns (uint256) {
        return _token.balanceOf(address(this));
    }
    
    modifier onlyApprover() {
        bool allowed = false;
        for(uint i = 0; i < approvers.length; i++) {
            if(approvers[i] == msg.sender) {
                allowed = true;
            }
        }
        require(allowed == true, 'only approver allowed');
        _;
    }
    
}