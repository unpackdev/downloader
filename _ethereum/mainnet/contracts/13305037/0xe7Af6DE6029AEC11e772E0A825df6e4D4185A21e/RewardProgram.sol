// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract RewardProgram is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bytes32 public merkleRoot;
    bool public cancelable;
    IERC20 public tokenContract;
    uint256 public fullRewardTimeoutPeriod = 180 days;
    uint256 public shortRewardTimeoutPeriod = 30 days;
    uint256 public shortRewardPercentage = 2;
    uint256 public merkleRootLastUpdateTime;
    uint256 public merkleRootLastUpdateBlock;

    struct User {
        string sidechainAddress;
        bytes signature;
        string message;
    }

    struct AmountWithTime {
        uint amount;
        uint timestamp;
        bool isWithdrowedByNominator;
        bool isFullWithdrawal;
    }

    mapping(address => uint256) public lastRewardRequestTime;

    mapping(address => AmountWithTime[]) public requestedRewards;

    mapping(address => AmountWithTime[]) public receivedRewards;

    modifier isCancelable() {
        require(!cancelable, "forbidden action");
        _;
    }

    event AddLink (address indexed ethereumAddress, string target, bytes signature, string message);
    event RequestReward (address target, uint amount, bool isFullWithdrawal);
    event ReceiveReward (address target, uint amount, bool indexed isWithdrowedByNominator);
    event UpdateMerkleRoot (bytes32 merkleRoot);

    function contractTokenBalance() public view returns(uint) {
		return tokenContract.balanceOf(address(this));
	}

    function getRequestedRewardArray(address target) public view returns(AmountWithTime[] memory) {
        return requestedRewards[target];
    }

    function getReceivedRewardArray(address target) public view returns(AmountWithTime[] memory) {
        return receivedRewards[target];
    }

    constructor(address _tokenContract, bool _cancelable) public  {
        tokenContract = IERC20(_tokenContract);
        cancelable = _cancelable;
    }

    function setCancelable(bool _cancelable) public onlyOwner {
        cancelable = _cancelable;
    }

    function setFullRewardTimeoutPeriod(uint256 period) public onlyOwner {
	    fullRewardTimeoutPeriod = period;
	}

	function setShortRewardTimeoutPeriod(uint256 period) public onlyOwner {
	    shortRewardTimeoutPeriod = period;
	}

	function setShortRewardPercentage(uint256 percentage) public onlyOwner {
	    shortRewardPercentage = percentage;
	}

    function linkAddresses(string memory target, bytes memory signature, string memory message) public {
        emit AddLink(msg.sender, target, signature, message);
    }

    function setRoot(bytes32 _merkleRoot, uint256 amount) public onlyOwner {
        address ownContractAddress = address(this);
        if (amount > 0) {
            require(tokenContract.allowance(owner(), ownContractAddress) >= amount, "approved balance not enough");
            tokenContract.transferFrom(owner(), ownContractAddress, amount);
        }
        merkleRoot = _merkleRoot;
        merkleRootLastUpdateTime = block.timestamp;
        merkleRootLastUpdateBlock = block.number;
        cancelable = false;
        emit UpdateMerkleRoot(_merkleRoot);
    }

    function requestReward(uint256 amount, bool isFullWithdrawal) internal returns (bool) {
        uint timestamp = block.timestamp;
        lastRewardRequestTime[msg.sender] = timestamp;
        requestedRewards[msg.sender].push(AmountWithTime(amount, timestamp, false, isFullWithdrawal));
        emit RequestReward(msg.sender, amount, isFullWithdrawal);
        return true;
    }

    function calculateShortAmount(uint amount) internal view returns(uint) {
        return amount.mul(shortRewardPercentage).div(10);
    }

    function getRequestAmountWithError(address target, uint item) internal view returns(uint amount, uint timestamp, bool isWithdrowedByNominator, bool isFullWithdrawal) {
        require(item < requestedRewards[target].length, "item is not exist");

        AmountWithTime storage request = requestedRewards[target][item];
        uint256 fullAmount = request.amount;
        uint256 fullTimestamp = request.timestamp;
        bool fullWithdrawal = request.isFullWithdrawal;
        uint256 timePeriod = fullWithdrawal ? fullRewardTimeoutPeriod : shortRewardTimeoutPeriod;
        require(fullAmount > 0, "item is empty");
        require(block.timestamp >= fullTimestamp + timePeriod, "expiration period is not over");
        amount = fullAmount;
        timestamp = request.timestamp;
        isWithdrowedByNominator = request.isWithdrowedByNominator;
        isFullWithdrawal = fullWithdrawal;
    }

    function transferOrApproveRewardToAddress(address target, uint amount, bool isWithdrowedByNominator, bool isApprove, bool isFullWithdrawal) internal {
        receivedRewards[target].push(AmountWithTime(amount, block.timestamp, isWithdrowedByNominator, isFullWithdrawal));
        if (isApprove) {
            tokenContract.approve(target, amount);
        } else {
            tokenContract.transfer(target, amount);
        }
        emit ReceiveReward(target, amount, isWithdrowedByNominator);
    }

    function receiveResidue(address target, uint item, address receiver) public onlyOwner {
        (uint amount, uint timestamp, bool isWithdrowedByNominator, bool isFullWithdrawal) = getRequestAmountWithError(target, item);
        require(isWithdrowedByNominator, "reward is not received by user");
        require(contractTokenBalance() >= amount, "not enough balance");
        delete requestedRewards[target][item];
        bool isApprove = true;
        transferOrApproveRewardToAddress(receiver, amount, false, isApprove, isFullWithdrawal);
    }

    function receiveReward(uint item) public {
        address target = msg.sender;
        (uint fullAmount, uint timestamp, bool isWithdrowedByNominator, bool isFullWithdrawal) = getRequestAmountWithError(target, item);

        require(!isWithdrowedByNominator, "reward already received");

        uint amount = fullAmount;
        uint residue = 0;
        if (!isFullWithdrawal) {
            amount = calculateShortAmount(fullAmount);
            residue = fullAmount.sub(amount);
        }
        require(contractTokenBalance() >= amount, "not enough balance");

        AmountWithTime storage request = requestedRewards[target][item];

        if (!isFullWithdrawal) {
            request.isWithdrowedByNominator = true;
            request.amount = residue;
            request.isFullWithdrawal = true;
            request.timestamp = block.timestamp;
        } else {
            delete requestedRewards[target][item];
        }
        bool isApprove = false;
        transferOrApproveRewardToAddress(target, amount, true, isApprove, isFullWithdrawal);
    }

    function transferAllTokensToOwner() public onlyOwner returns(bool) {
        tokenContract.transfer(owner(), contractTokenBalance());
        return true;
    }

    function leafFromAddressAndAmount(address _a, uint256 _n) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(_a, _n));
    }

    function checkProof(bytes32[] memory proof, bytes32 hash) internal view returns (bool) {
        bytes32 el;
        bytes32 h = hash;

        for (uint i = 0; i <= proof.length - 1; i += 1) {
            el = proof[i];

            if (h <= el) {
                h = keccak256(abi.encodePacked(h, el));
            } else {
                h = keccak256(abi.encodePacked(el, h));
            }
        }

        return h == merkleRoot;
    }

    function requestTokensByMerkleProof(bytes32[] memory _proof, uint256 _amount, bool _isFullWithdrawal) public isCancelable returns(bool) {
        require(lastRewardRequestTime[msg.sender] < merkleRootLastUpdateTime, "already withdrawn in this period");
        require(_amount > 0, "amount should be not zero");
        if (!_isFullWithdrawal) {
            require(calculateShortAmount(_amount) > 0, "amount too low"); 
        }
        require(checkProof(_proof, leafFromAddressAndAmount(msg.sender, _amount)), "proof is not correct");
        return requestReward(_amount, _isFullWithdrawal);
    }
}
