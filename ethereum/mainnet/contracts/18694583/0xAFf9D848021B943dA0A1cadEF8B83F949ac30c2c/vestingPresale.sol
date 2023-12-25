// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./MerkleProof.sol";
import "./IPresale.sol";


contract vestingPresale is Ownable {
    using SafeERC20 for IERC20;

	struct User {
		uint amountIn;
		uint amountOut;
		uint vesting_time;
		uint claimed;
	}

	IERC20 public immutable TOKEN;
    uint public immutable FIRSTCLAIMAG;
	uint public immutable FIRSTCLAIMOG;
    IPresale public immutable PRESALE;

	mapping(address => User) public users;
	mapping(address => uint) public firstOut;

	bytes32 public OGROOT;

	uint public totalTokens;
	uint public state;
	uint public START_CLAIM_TIME;


	constructor(IPresale _presale, IERC20 _token, uint _firstClaimAG, uint _firstClaimOG, address _multisig) {
		TOKEN = _token;
        FIRSTCLAIMAG = _firstClaimAG;
		FIRSTCLAIMOG = _firstClaimOG;
        PRESALE = _presale;
		transferOwnership(_multisig);
	}

	function changeOGRoot(bytes32 _ogRoot) public onlyOwner() {
		OGROOT = _ogRoot;
	}


	function setTotalTokens(uint amount) external onlyOwner {
		require(START_CLAIM_TIME == 0, "claim started");
		TOKEN.safeTransferFrom(_msgSender(), address(this), amount);
		totalTokens += amount;
	}

	function startClaim(bytes32 _ogRoot, uint additionalTime) external onlyOwner {
		require(START_CLAIM_TIME == 0, "claim started");
		require(additionalTime <= 1 days, "too long");
		OGROOT = _ogRoot;
		START_CLAIM_TIME = block.timestamp + additionalTime;
		Address.sendValue(payable(owner()), address(this).balance);
		delete state;
	}

	function claim(bytes32[] calldata proof) external {
		uint startClaimTimeCached = START_CLAIM_TIME;
		require(startClaimTimeCached > 0, "cannot claim yet");
        if (users[msg.sender].vesting_time == 0) {
            _setUser(proof);
        } 
		uint claimable = pendingOf(_msgSender());
		require(claimable > 0, "nothing to claim");
		users[_msgSender()].claimed += claimable;
		TOKEN.safeTransfer(_msgSender(), claimable);
	}

	function pendingOf(address who) public view returns (uint) {
        uint startClaimTimeCached = START_CLAIM_TIME;
        if (startClaimTimeCached == 0 || startClaimTimeCached > block.timestamp)
            return 0;
        User storage user = users[who];
        uint amount = firstOut[who];
        uint userFinal = user.amountOut - firstOut[who];
        uint max = user.amountOut;
        amount += (userFinal * (block.timestamp - startClaimTimeCached)) /
            user.vesting_time;
        if (amount > max) amount = max;

        return amount - user.claimed;
    }

    function _setUser(bytes32[] calldata proof) private {
        (uint amountIn, uint amountOut, uint vesting_time, uint claimed) = PRESALE.users(msg.sender);
        users[msg.sender] = User(amountIn, amountOut, vesting_time, claimed);
		require(users[msg.sender].vesting_time > 0, "FORBIDDEN");
		bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
		if (MerkleProof.verify(proof, OGROOT, leaf)){
			firstOut[msg.sender] = users[msg.sender].amountOut * FIRSTCLAIMOG / 100;
		}
        else {
			require(users[msg.sender].amountIn >= 1 * 10**18, "FORBIDDEN");
			firstOut[msg.sender] = users[msg.sender].amountOut * FIRSTCLAIMAG / 100;
		}
            
    }

    
}