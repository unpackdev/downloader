// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;


import "./SafeMath.sol";
import "./IERC20.sol";
import "./Address.sol";
import "./SafeERC20.sol";

interface IPickleGauge {
    function deposit(uint256) external;
    function balanceOf(address) external view returns (uint256);
    function withdraw(uint256) external;   
    function getReward() external;
    function vote(address[] calldata,uint256[] calldata) external;
}

interface IPickleVoteEscrow {
    function create_lock(uint256, uint256) external;
    function increase_amount(uint256) external;
    function increase_unlock_time(uint256) external;
    function withdraw() external;        
}

interface IVoting{
    function vote(uint256, bool, bool) external;  
}

interface IFeeDistro{
    function claim() external;   
}

interface IDeposit{
    function isShutdown() external view returns(bool);   
}

contract PickleVoterProxy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    
    address public constant pickle = address(0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5);

    address public constant escrow = address(0xbBCf169eE191A1Ba7371F30A1C344bFC498b29Cf);
    address public constant gaugeProxy = address(0x2e57627ACf6c1812F99e274d0ac61B786c19E74f);
    
    address public owner;
    address public operator;
    address public depositor;
    
    mapping (address => bool) private stashPool;
    mapping (address => bool) private protectedTokens;

    constructor() public {
        owner = msg.sender;
    }

    function getName() external pure returns (string memory) {
        return "PickleVoterProxy";
    }

    function setOwner(address _owner) external {
        require(msg.sender == owner, "!auth");
        owner = _owner;
    }

    function setOperator(address _operator) external {
        require(msg.sender == owner, "!auth");
        require(operator == address(0) || IDeposit(operator).isShutdown() == true, "needs shutdown");
        
        operator = _operator;
    }

    function setDepositor(address _depositor) external {
        require(msg.sender == owner, "!auth");

        depositor = _depositor;
    }

    function setStashAccess(address _stash, bool _status) external returns(bool){
        require(msg.sender == operator, "!auth");
        if(_stash != address(0)){
            stashPool[_stash] = _status;
        }
        return true;
    }


    function deposit(address _token, address _gauge) external returns(bool){
        require(msg.sender == operator, "!auth");
        if(protectedTokens[_token] == false){
            protectedTokens[_token] = true;
        }
        if(protectedTokens[_gauge] == false){
            protectedTokens[_gauge] = true;
        }
        uint256 balance = IERC20(_token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(_token).safeApprove(_gauge, 0);
            IERC20(_token).safeApprove(_gauge, balance);
            IPickleGauge(_gauge).deposit(balance);
        }
        return true;
    }

    //stash only function for pulling extra incentive reward tokens out
    function withdraw(IERC20 _asset) external returns (uint256 balance) {
        require(stashPool[msg.sender] == true, "!auth");

        //check protection
        if(protectedTokens[address(_asset)] == true){
            return 0;
        }

        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(msg.sender, balance);
        return balance;
    }

    // Withdraw partial funds
    function withdraw(address _token, address _gauge, uint256 _amount) public returns(bool){
        require(msg.sender == operator, "!auth");
        uint256 _balance = IERC20(_token).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_gauge, _amount.sub(_balance));
            _amount = _amount.add(_balance);
        }
        IERC20(_token).safeTransfer(msg.sender, _amount);
        return true;
    }

     function withdrawAll(address _token, address _gauge) external returns(bool){
        require(msg.sender == operator, "!auth");
        uint256 amount = balanceOfPool(_gauge).add(IERC20(_token).balanceOf(address(this)));
        withdraw(_token, _gauge, amount);
        return true;
    }

    function _withdrawSome(address _gauge, uint256 _amount) internal returns (uint256) {
        IPickleGauge(_gauge).withdraw(_amount);
        return _amount;
    }

    function createLock(uint256 _value, uint256 _unlockTime) external returns(bool){
        require(msg.sender == depositor, "!auth");
        IERC20(pickle).safeApprove(escrow, 0);
        IERC20(pickle).safeApprove(escrow, _value);
        IPickleVoteEscrow(escrow).create_lock(_value, _unlockTime);
        return true;
    }

    function increaseAmount(uint256 _value) external returns(bool){
        require(msg.sender == depositor, "!auth");
        IERC20(pickle).safeApprove(escrow, 0);
        IERC20(pickle).safeApprove(escrow, _value);
        IPickleVoteEscrow(escrow).increase_amount(_value);
        return true;
    }

    function increaseTime(uint256 _value) external returns(bool){
        require(msg.sender == depositor, "!auth");
        IPickleVoteEscrow(escrow).increase_unlock_time(_value);
        return true;
    }

    function release() external returns(bool){
        require(msg.sender == depositor, "!auth");
        IPickleVoteEscrow(escrow).withdraw();
        return true;
    }

    function vote(uint256 _voteId, address _votingAddress, bool _support) external returns(bool){
        require(msg.sender == operator, "!auth");
        IVoting(_votingAddress).vote(_voteId,_support,false);
        return true;
    }

    function voteGaugeWeight(address[] calldata _tokenVote, uint256[] calldata _weight) external returns(bool){
        require(msg.sender == operator, "!auth");

        //vote
        IPickleGauge(gaugeProxy).vote(_tokenVote, _weight);
        return true;
    }

    function claimPickle(address _gauge) external returns (uint256){
        require(msg.sender == operator, "!auth");
        
        uint256 _balance = 0;
        try IPickleGauge(_gauge).getReward(){
            _balance = IERC20(pickle).balanceOf(address(this));
            IERC20(pickle).safeTransfer(operator, _balance);
        }catch{}

        return _balance;
    }

    function claimRewards(address _gauge) external returns(bool){
        require(msg.sender == operator, "!auth");
        IPickleGauge(_gauge).getReward();
        return true;
    }

    function claimFees(address _distroContract, address _token) external returns (uint256){
        require(msg.sender == operator, "!auth");
        IFeeDistro(_distroContract).claim();
        uint256 _balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(operator, _balance);
        return _balance;
    }    

    function balanceOfPool(address _gauge) public view returns (uint256) {
        return IPickleGauge(_gauge).balanceOf(address(this));
    }

    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external returns (bool, bytes memory) {
        require(msg.sender == operator,"!auth");

        (bool success, bytes memory result) = _to.call{value:_value}(_data);

        return (success, result);
    }

}