pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;

//https://vote.idmoswap.com

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}
    
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    
    function owner() public view returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    
    function isContract(address account) internal view returns (bool) {
        
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

   
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract IDMOVote is Ownable {
    using SafeMath for uint256;
	using SafeERC20 for IERC20;
	
	struct proposal{
		uint createTime;    
		string proposalCid; 
		uint proposalId;    
		uint voteNum;       
		uint startBlock;    
		uint endBlock;      
		uint userNum;       
		IERC20 delegateToken;
		uint perVoteValue;  
		uint[] voteAmount;  
		uint[] voteUserNum; 
		address createAddr; 
		uint voteLimit;     
		mapping (address=>uint) mapUserAmount; 
		
		mapping (address=> mapping(uint=>uint)) mapUserVote; 
	}


	struct retProposal{
		uint createTime;    
		string proposalCid; 
		uint proposalId;    
		uint voteNum;       
		uint startBlock;    
		uint endBlock;      
		uint userNum;       
		IERC20 delegateToken;
		uint perVoteValue;  
		uint[] voteAmount;  
		uint[] voteUserNum; 
		address createAddr; 
		uint voteLimit;     
	}
	
	bool public isAllowAllToken=false;  

	IERC20 public IDMOAddr = IERC20(0x4Ba376dec87EDaa662Cd82278d89406864118EFd);  

	uint public proposalIndex ;    

	mapping (uint=>proposal) public mapProposal;  

	uint public  createProposalFee = 1000000000000000000;   

	address public devAddr = 0xa417400C71E36eD541fFBE57D9b1F5A10DD72129;    
	
	event CreateProposalLog(address indexed createAddr, uint indexed proposalId, string proposalCid);
	event DelegateLog(address indexed user, uint indexed proposalId, uint voteIndex, uint amount);
	event WithdrawLog(address indexed user, uint indexed proposalId, uint amount);
	
	function getRetProposal(uint proposalId) public view returns(retProposal memory){
		retProposal memory ret;
		proposal memory useProposal = mapProposal[proposalId];
		ret.createTime = useProposal.createTime;
		ret.proposalCid = useProposal.proposalCid;
		ret.proposalId = useProposal.proposalId;
		ret.voteNum = useProposal.voteNum;
		ret.startBlock = useProposal.startBlock;
		ret.endBlock = useProposal.endBlock;
		ret.userNum = useProposal.userNum;
		ret.delegateToken = useProposal.delegateToken;
		ret.perVoteValue = useProposal.perVoteValue;
		ret.voteAmount = useProposal.voteAmount;
		ret.voteUserNum = useProposal.voteUserNum;
		ret.createAddr = useProposal.createAddr;
		ret.voteLimit = useProposal.voteLimit;
		return ret;
	}
	
	

	function viewProposal(uint startProposalId, uint endProposalId) public view returns( retProposal[] memory){
		uint256 length = endProposalId - startProposalId + 1;
		retProposal[] memory ret = new retProposal[](length);
		for(uint i = startProposalId; i <= endProposalId; i++){
			//ret[i - startProposalId] = mapProposal[i];
			ret[i - startProposalId] = getRetProposal(i);
		}
		return ret;
	}


	function viewUserAmount(uint proposalId, address userAddr) public view returns(uint){
		return mapProposal[proposalId].mapUserAmount[userAddr];
	}


	function viewMaxAllowAmount(uint proposalId, address userAddr) public view returns(uint){
		uint256 MAX_INT = uint256(-1);
		proposal memory useProposal = mapProposal[proposalId];
		if(useProposal.voteLimit == 0){
			return MAX_INT;
		}
		else{
			return useProposal.voteLimit.mul(useProposal.perVoteValue).sub(mapProposal[proposalId].mapUserAmount[userAddr]);
		}
	}

	
	function createProposal(string  memory proposalCid, uint voteNum, uint startBlock, uint endBlock, IERC20 delegateToken, uint perVoteAmount, uint voteLimit) public {
		require(voteNum >= 1, "voteNum error.");
		require(endBlock > block.number, "startBlock error.");
		require(endBlock > startBlock, "endBlock error.");
		if(isAllowAllToken == false){
			require(delegateToken == IDMOAddr, "delegateToken error.");
		}

		IDMOAddr.safeTransferFrom(address(msg.sender), devAddr, createProposalFee);
		
		proposal storage useProposal = mapProposal[proposalIndex];
		useProposal.createTime = now;
		useProposal.proposalCid = proposalCid;
		useProposal.proposalId = proposalIndex;
		useProposal.voteNum = voteNum;
		useProposal.startBlock = startBlock;
		useProposal.endBlock = endBlock;
		useProposal.delegateToken = delegateToken;
		useProposal.perVoteValue = perVoteAmount;
		useProposal.voteAmount = new uint[](voteNum);
		useProposal.voteUserNum = new uint[](voteNum);
		useProposal.createAddr = msg.sender;
		useProposal.voteLimit = voteLimit;
		
		CreateProposalLog(msg.sender, proposalIndex, proposalCid);
		
		proposalIndex = proposalIndex.add(1);
	}
	

	function delegate(uint proposalId, uint  voteIndex, uint amount) public{
		proposal storage useProposal = mapProposal[proposalId];
		require(voteIndex < useProposal.voteNum, "voteIndex error.");
		require(block.number > useProposal.startBlock, "not start");
		require(block.number <= useProposal.endBlock, "end");
		require(amount >= useProposal.perVoteValue, "less than perVoteValue");
		//require(amount % (useProposal.perVoteValue) == 0, "amount error.");
		require(amount.mod(useProposal.perVoteValue) == 0, "amount error.");
		
		if(useProposal.voteLimit != 0){
			require(amount.add(useProposal.mapUserAmount[msg.sender]).div(useProposal.perVoteValue) <= useProposal.voteLimit, "reach limit");
		}
		
		useProposal.delegateToken.safeTransferFrom(address(msg.sender), address(this), amount);
		
		if(useProposal.mapUserVote[msg.sender][voteIndex] == 0){ 
			useProposal.mapUserVote[msg.sender][voteIndex] = 1;  
			useProposal.voteUserNum[voteIndex] = useProposal.voteUserNum[voteIndex].add(1); 
		}
		
		
		useProposal.voteAmount[voteIndex] = useProposal.voteAmount[voteIndex].add(amount);
		if(useProposal.mapUserAmount[msg.sender] == 0){ 
			useProposal.userNum = useProposal.userNum.add(1);
		}
		useProposal.mapUserAmount[msg.sender] = useProposal.mapUserAmount[msg.sender].add(amount); 
		
		DelegateLog(msg.sender, proposalId, voteIndex, amount);
	}


	function withdraw(uint proposalId) public{
		proposal storage useProposal = mapProposal[proposalId];
		require(useProposal.endBlock < block.number, "not reach endBlock");
		uint send_amount = useProposal.mapUserAmount[msg.sender];
		if(send_amount != 0){
			useProposal.delegateToken.safeTransfer(address(msg.sender), send_amount);
			useProposal.mapUserAmount[msg.sender] = 0;
			WithdrawLog(msg.sender, proposalId, send_amount);
		}
	}

	
	function setStartEnd(uint proposalId, uint startBlock, uint endBlock)public onlyOwner{
		proposal storage useProposal = mapProposal[proposalId];
		require(startBlock < endBlock, "startBlock error");
		require(endBlock < useProposal.endBlock, "endBlock error.");
		useProposal.startBlock = startBlock;
		useProposal.endBlock = endBlock;
	}



	function setAllowAllToken(bool value) public onlyOwner{
		if(isAllowAllToken != value){
			isAllowAllToken = value;
		}
	}



	function setCreateProposalFee(uint amount) public onlyOwner{
		if(createProposalFee != amount){
			createProposalFee = amount;
		}
	}



	function setDevAddr(address addr) public onlyOwner{
		if(devAddr != addr){
			devAddr = addr;
		}
	}
	
}