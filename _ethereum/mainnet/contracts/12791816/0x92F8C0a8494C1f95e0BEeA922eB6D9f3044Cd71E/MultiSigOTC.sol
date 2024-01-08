pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./Pausable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./SafeMath32.sol";

contract MultiSigOTC is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SafeMath32 for uint32;


    mapping(address => bool) public isApprover;

    address[] public approverID;

    mapping(address => bool) public hasApprove;

    address public tokenToTransfer = address(0);

    uint256 public amount = 0;

    address payable public toAddress = address(0);

    uint256 public typeOfTransfer = 0;

    uint32 public expiry = 0;



    uint256 requiredApprover = 2;

    uint256 currentApprover = 0;

    modifier onlyApprover {
      require(isApprover[msg.sender] == true);
      _;
   }

    constructor(
        address approver1,
        address approver2
    ) public {
        isApprover[approver1] = true;
        isApprover[approver2] = true;
        approverID.push(approver1);
        approverID.push(approver2);
    }

    function initiateTokenTransfer(address _tokenAddress, uint256 _amount, address payable _toAddress) public onlyApprover{
        require(_tokenAddress != address(0), "MultiSigOTC: Cannot be Zero Address");
        require(typeOfTransfer == 0, "MultiSigOTC: There is already a pending Transaction");
        uint balance = IERC20(_tokenAddress).balanceOf(address(this));
        require(balance > 0, "Balance should be > 0.");
        require(_amount <= balance, "amount should be < Balance.");
        typeOfTransfer = 1;
        amount = _amount;
        uint32 startTime = SafeMath32.fromUint(now);
        expiry = startTime.add(1800);
        toAddress = _toAddress;

    }

    function initiateETHTransfer(uint256 _amount, address payable _toAddress) public onlyApprover{
        require(typeOfTransfer == 0, "MultiSigOTC: There is already a pending Transaction");
        uint balance = address(this).balance;
        require(balance > 0, "Balance should be > 0.");
        require(_amount <= balance, "amount should be < Balance.");
        typeOfTransfer = 2;
        amount = _amount;
        toAddress = _toAddress;
        uint32 startTime = SafeMath32.fromUint(now);
        expiry = startTime.add(1800);

    }

    function initiateAddApprover(address payable _toAddress) public onlyApprover{
        require(typeOfTransfer == 0, "MultiSigOTC: There is already a pending Transaction");
        typeOfTransfer = 3;
        toAddress = _toAddress;
        uint32 startTime = SafeMath32.fromUint(now);
        expiry = startTime.add(1800);
    }

    function initiateRemoveApprover(address payable _toAddress) public onlyApprover{
        require(typeOfTransfer == 0, "MultiSigOTC: There is already a pending Transaction");
        typeOfTransfer = 4;
        toAddress = _toAddress;
        uint32 startTime = SafeMath32.fromUint(now);
        expiry = startTime.add(1800);

    }

    function _withdrawToken(address _tokenAddress, uint256 _amount, address payable _toAddress) internal {
        IERC20(_tokenAddress).transferFrom(address(this), _toAddress, _amount);
        _resetDetails();

    }

    function _withdrawETH(uint256 _amount, address payable _toAddress) internal  {
        _toAddress.transfer(_amount);
        _resetDetails();
    }

    function approveTransaction() public onlyApprover{
        require(hasApprove[msg.sender] == false, "MultiSigOTC: Approver has already approved");
        require(typeOfTransfer > 0, "MultiSigOTC: There is no pending Transaction");
        uint32 currentTime = SafeMath32.fromUint(now);
        if(currentTime >= expiry){
            _resetDetails();
        } else{
            hasApprove[msg.sender] = true;
            currentApprover = currentApprover + 1;
        }

        if(typeOfTransfer != 0 && currentApprover > 1){
            if(typeOfTransfer == 1){
                _withdrawToken(tokenToTransfer,amount, toAddress);


            }else if (typeOfTransfer == 2){
                _withdrawETH(amount,toAddress);

            } else if(typeOfTransfer == 3){
                _addApprover(toAddress);

            } else if(typeOfTransfer == 4){
                _removeApprover(toAddress);

            }

        }
        
    }

    function _resetDetails() internal{
            typeOfTransfer = 0;
            amount = 0;
            tokenToTransfer = address(0);
            currentApprover = 0;
            for(uint i = 0 ; i < approverID.length ; i ++){
                hasApprove[approverID[i]] = false;
            }

    }

    function _addApprover(address _approver) internal {

        isApprover[_approver] = true;
        approverID.push(_approver);
        _resetDetails();
    }

    function _removeApprover(address _approver) internal {
        isApprover[_approver] = false;
        _resetDetails();
    }



}