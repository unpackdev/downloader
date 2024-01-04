pragma solidity ^0.5.16;

interface IStakingFountain {
    event Deposit(address indexed from, address indexed to, uint value);
    event Withdraw(address indexed from, address indexed to, uint value);
     
    function addTokne(address token) external returns (bool);
    function deleteTokne(address token) external returns (bool);
    function deposit(address token, string calldata from, uint256 amount) external returns (bool);
    function withdraw() external returns (bool);
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract StakingFountainToken is IStakingFountain {
    using SafeMath for uint256;
    struct LockBin {
		uint256 start;
		uint256 amount;
		uint256 lpAmount;
		uint256 count;
		address token;
		uint8   state;
		string  tx;
		address from;
		address to;
	}
    address[]       public tokens;
    address[]       public recordAddr;
    uint256         public usdStakingAmount;
    uint256         public ethStakingAmount;
    uint256         public lpUsdAmount;
    uint256         public lpEthAmount;
    uint256         public usdSendAmount;
    uint256         public ethSendAmount;
    uint256         public lpWeekAmount;
    address         private fountainToken;
    uint256         public recordCount;
    address         private owner = msg.sender;
    address         private contractAddr = address(this);
    uint256         private lpWeekTime = now;
    address[]       private stakingAddr;
    address         private usdToken;
    address         private ethToken;
    mapping(address => mapping(uint256 => LockBin)) public lockbins;
    
    function _addAddr(address addr) private {
        recordAddr.push(addr);
        bool flag = false;
        for (uint8 i = 0; i < stakingAddr.length; i++) {
            if(addr == stakingAddr[i]) {
                flag = true;
                break;
            }
        }
        if (flag) {
            stakingAddr.push(addr);
        }
    }
    
    function _deleteAddr(address addr) private {
        for (uint i= 0; i < stakingAddr.length; i++) {
            if(addr == stakingAddr[i]) {
                 delete stakingAddr[i];
                 stakingAddr.length --;
                break;
            }
        }
    }
    
    function _autoStaking() private {
        uint256 pairAmount;
        for (uint i = 0; i < stakingAddr.length; i++) {
            address addr = stakingAddr[i];
            mapping(uint256 => LockBin) storage locks = lockbins[addr];
            LockBin storage info = locks[0];
            uint8 state = info.state;
            uint256 getAmount;
            if (state == 1) {
                uint index = info.count;
                for (uint8 j = 1; j <= index; j++)  {
                    LockBin storage tmpInfo =  locks[j];
                    uint8 tmpState          = tmpInfo.state;
                    if (tmpState == 1) {
                        address dToken          = tmpInfo.token;
                        uint256 lpAmount        = tmpInfo.lpAmount;
                        uint256 inTime          = tmpInfo.start;
                        uint256 dayStaking      = now / inTime;
                        if (dToken == usdToken) {
                            if (dayStaking >= 1) {
                                pairAmount      = lpAmount.div(ethStakingAmount);
                                getAmount       = dayStaking.mul(pairAmount);
                                usdSendAmount   = usdSendAmount.add(getAmount);
                            }
                        }else {
                            if (dayStaking > 1) {
                                pairAmount      = lpAmount.div(ethStakingAmount);
                                getAmount       = dayStaking.mul(pairAmount);
                                ethSendAmount   = ethSendAmount.add(getAmount);
                            }
                        }
                        if (getAmount > 0) {
                             info.amount        = info.amount.add(getAmount);
                             tmpInfo.start      = now;
                        }
                    }
                 }
            }
        }
    }
    
    function setStakingAmount(uint256 amount, address token) external returns(bool) {
        require(msg.sender == owner, 'Fountain: NO_OWNER_ADDRESS');
        require(amount > 0, 'Fountain: AMOUNT_INVALID');
        if (token == usdToken) {
            usdStakingAmount = amount;
        }else if (token == ethToken) {
            ethStakingAmount = amount;
        }
        return true;
    }
    
    function setFountainToken(address token) external returns(bool) {
        require(msg.sender == owner, 'AddLPtoken: NO_OWNER_ADDRESS');
        fountainToken = token;
        return true;
    }
    
    function addTokne(address token) external  returns (bool) {
        require(token != address(0), 'Fountain: ZERO_ADDRESS');
        require(msg.sender == owner, 'Fountain: NO_OWNER_ADDRESS');
        tokens.push(token);
        for(uint8 i=0; i < tokens.length; i++) {
            if (i==0){
                usdToken = tokens[i];
            }else if(i==1) {
                ethToken = tokens[i];
            }
        }
        return true;
    }
    
    function deleteTokne(address token) external returns (bool) {
        require(msg.sender == owner, 'Fountain: NO_OWNER_ADDRESS');
        for(uint8 i=0; i < tokens.length; i++) {
            if(token == tokens[i]) {
                delete tokens[i];
                tokens.length --;
                if (token == usdToken) {
                    usdToken = address(0);
                }else if (token == ethToken) {
                    ethToken = address(0);
                }
            }
        }
    }

    function deposit(address token,  string calldata tx, uint256 amount) external  returns (bool) {
        uint256 uniLen      = tokens.length;
        require(uniLen > 0, 'Fountain: UIN_TOKEN_ERROR');
        if (token == usdToken) {
            require(IERC20(token).balanceOf(address(contractAddr)).sub(lpUsdAmount) >= amount, 'Fountain: USD_LP_AMOUNT_INVALID');
        }else if(token == ethToken) {
              require(IERC20(token).balanceOf(address(contractAddr)).sub(lpEthAmount) >= amount, 'Fountain: ETH_LP_AMOUNT_INVALID');
        } else {
            require(false, 'Fountain: TOKNE_INVALID');
        }
        
        uint256 weekTmp = 0;
        uint256 nowTime = now;
        mapping(uint256 => LockBin) storage locks = lockbins[msg.sender];
        LockBin storage info = locks[0];
                        uint256 index = info.count + 1;
                        locks[index] = LockBin({
                        start:      now,
                        amount:     amount,
                        lpAmount:   amount,
                        count:      index,
                        token:      token,
                        state:      1,
                        tx:         tx,
                        from:       msg.sender,
                        to:         contractAddr
        });
        info.start  = now;
        info.count  = index;
        info.token  = fountainToken;
        info.lpAmount = info.lpAmount.add(amount);
        info.state  = 1;
        info.token  = fountainToken;
        info.from   = contractAddr;
        info.to     = msg.sender;        
        weekTmp     = nowTime.div(lpWeekTime);
        if (weekTmp <= 7) {
            lpWeekAmount = lpWeekAmount.add(amount);
        }else {
            lpWeekTime      = now;
            lpWeekAmount    = 0;
        }
        _addAddr(msg.sender);
        weekTmp = 0;
        recordCount = recordCount.add(1);
        if (token == usdToken) {
            lpUsdAmount = lpUsdAmount.add(amount);
        }else if(token == ethToken) {
            lpEthAmount = lpEthAmount.add(amount);
        }
        emit Deposit(msg.sender, address(this), amount);
        _autoStaking();
       return true;
    }
    
    function withdraw() external returns (bool) {
        mapping(uint256 => LockBin) storage locks = lockbins[msg.sender];
        LockBin storage info = locks[0];
        info.state = 0;
        info.start = now;
        uint index = info.count + 1;
        uint256 ftnAmount = info.amount;
        uint256 usdTokenAmount = 0;
        uint256 ethTokenAmount = 0;
        for (uint i = 0; i < index; i++) {
            if(i == 0 && ftnAmount != 0) {
                TransferHelper.safeTransfer(locks[i].token, msg.sender, locks[i].amount);
                emit Withdraw(address(this), msg.sender, locks[i].amount);
            }else if(i > 0) {
                address token =  locks[i].token;
                if (token == usdToken) {
                    usdTokenAmount = usdTokenAmount.add(locks[i].lpAmount);
                }else {
                    ethTokenAmount = ethTokenAmount.add(locks[i].lpAmount);
                }
                locks[i].state = 0;
                if (i == info.count) {
                    if (usdTokenAmount > 0) {
                        TransferHelper.safeTransfer(usdToken, msg.sender, usdTokenAmount);
                        lpUsdAmount = lpUsdAmount.sub(usdTokenAmount);
                        emit Withdraw(address(this), msg.sender, usdTokenAmount);
                    }
                    if (ethTokenAmount > 0) {
                        TransferHelper.safeTransfer(ethToken, msg.sender, usdTokenAmount);
                        lpEthAmount = lpEthAmount.sub(usdTokenAmount);
                        emit Withdraw(address(this), msg.sender, usdTokenAmount);
                    }
                }
            }
        }
        info.lpAmount   = 0;
        info.amount     =0;
        _deleteAddr(msg.sender);
        _autoStaking();
        return true;
    }
}

// helper methods for interacting with ERC20 tokens return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }
    
    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
}

// a library for performing overflow-safe math)
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
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

    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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