// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./SignedWadMath.sol";
import "./PaymentSplitter.sol";
import "./Ownable.sol";
import "./Referrals.sol";
import "./ICARTEL.sol";
import "./IterableNodeTypeMapping.sol";
import "./IUniswapV2Router02.sol";
import "./LogisticVRGDA.sol";

contract CartelManager is PaymentSplitter, LogisticVRGDA, Ownable {

    using IterableNodeTypeMapping for IterableNodeTypeMapping.Map;

    struct NodeEntity {
        string nodeTypeName;       
        uint256 creationTime;
        uint256 lastClaimTime;
    }
	/// @notice burn address used to burn escrowed tokens.
	address public deadAddress = 0x000000000000000000000000000000000000dEaD;
	/// @notice node type mapping.
    IterableNodeTypeMapping.Map private _nodeTypes;
	/// @notice first level node, entry point for all nodes.
	string public constant FIRST_LEVEL_NODE = "Galaxy Fragilis";
	/// @notice map node type for address to node data.
	mapping(string => mapping(address => NodeEntity[])) private _nodeTypeOwner;
	/// @notice map node type for address to node level.
	mapping(string => mapping(address => uint256)) private _nodeTypeOwnerLevelUp;
	/// @notice map node type for address to node pending creation.
	mapping(string => mapping(address => uint256)) private _nodeTypeOwnerCreatedPending;
	/// @notice referral code for promotion.
	mapping(string => address) private _referrals;
	/// @notice safety check, only one referral code can be used per address.
	mapping(address => bool) private _referralsUsed;
	/// @notice referral code for an address, used for front-end display.
	mapping(address => string) public referralByAddress;
	/// @notice nonce used to generate referral code.
	uint256 private _referralsNonce;
	/// @notice rewards for referral.
	uint256 public referralRewards;
	/// @notice $GLY token address.
    address public _tokenAddress;
	/// @notice $esGLY token address.
	address public _escrowedTokenAddress;
	/// @notice uniswap router address.
    IUniswapV2Router02 public _uniswapV2Router;
	/// @notice uniswap pair address.
    address public pairAddress;
	/// @notice creation fee recipient.
	address public creationFeeAddress;
	/// @notice fee for node creation.
	uint256 public nodeCreationFee;
	/// @notice fee for liquidity pool.
    uint256 public liquidityPoolFee;
	/// @notice fee for cashout.
    uint256 public cashoutFee;
	/// @notice fee for level up.
	uint256 public levelUpFee;
	/// @notice reentrancy guard.
    bool private swapping = false;
	/// @notice reentrancy guard.
    bool private swapLiquify = true;
	/// @notice minimum amount token to process swap.
    uint256 public swapTokensAmount;
	/// @notice max amount of nodes that can be airdropped.
	uint256 public maxairdroppedNodes;
	/// @notice amount of nodes that have been airdropped.
	uint256 public airdroppedNodes;
	
	bool public openLevelUp = false;
	bool public openPending = false;
	bool public openReferral = false;
	/// @notice open date for node sale, used to calculate node price by VRGDA.
	uint128 public openDate;

    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
	event AddNewLevel(string nodeTypeName, uint256 nodePrice);
	event CreateNode(address owner, string nodeTypeName, uint256 count);
	event CreateReferralCode(address owner, string code);

	modifier whenIsOpen() {
		require (block.timestamp >= openDate);
		_;
	}

    constructor(
        address token,
		address esToken,
		address _pairAddress,
		address uniV2Router,
        uint256 swapAmount,
		uint128 _openDate,
		address[] memory payees,
        uint256[] memory shares
    ) PaymentSplitter(payees, shares)
		LogisticVRGDA(
		0.20e18, // Price decay percent.
		toWadUnsafe(10000), // Max first level node mintable by VRGDA.
		0.05e18 // Time scale.
 	) {
        _tokenAddress = token;
		_escrowedTokenAddress = esToken;
		pairAddress = _pairAddress;
		_uniswapV2Router = IUniswapV2Router02(uniV2Router);

        require(pairAddress != address(0), "PAIR CANNOT BE ZERO");
		require(uniV2Router != address(0), "ROUTER CANNOT BE ZERO");
        require(swapAmount > 0, "Swap amount incorrect");

        swapTokensAmount = swapAmount;
		openDate = _openDate;

		/// first level node creation 
		_nodeTypes.set(FIRST_LEVEL_NODE, IterableNodeTypeMapping.NodeType({
                nodeTypeName: FIRST_LEVEL_NODE,
				nodeLevel : 1,
				targetPrice : 8333000000000000000000,
                claimTime: 14400,
                rewardAmount: 124995000000000000000,
                claimTaxBeforeTime: 1,
				count: 0,
				max: 10000,
				earlyClaimTax: 10,
				maxLevelUpGlobal: 10000,
				maxLevelUpUser: 50,
				maxCreationPendingGlobal: 10000,
				maxCreationPendingUser: 25
            })
        );
    }

	//// NODE CREATION LOGIC ////

	/**
	 * Only first level node can be created with token, to create other node, users need to level up. 
	 * @param count number of node to create.
	 * @param referralCode referral code for promotion => referrers will obtain $esGXY which they can use to create nodes.
	**/
	function createNodeWithTokens(uint256 count, string memory referralCode) public whenIsOpen {
		uint256 _nodePrice = nodePrice(FIRST_LEVEL_NODE) * count;

		require(ICARTEL(_tokenAddress).balanceOf(msg.sender) >= _nodePrice, "Balance too low for creation.");
		ICARTEL(_tokenAddress).transferFrom(msg.sender, address(this), _nodePrice);

		uint256 contractTokenBalance = ICARTEL(_tokenAddress).balanceOf(address(this));

        bool swapAmountOk = contractTokenBalance >= swapTokensAmount;

		if (openReferral) {
			if(bytes(referralCode).length > 0){
				address referrer = _referrals[referralCode];
				if (referrer != address(0) && referrer != msg.sender) {
					uint256 referrerReward = (_nodePrice * referralRewards) / 100;
					ICARTEL(_escrowedTokenAddress).mintFromCasino(referrer, referrerReward);
				}
			}
		}
        if (swapAmountOk && swapLiquify && !swapping) {
            swapping = true;

            uint256 creationFee = (contractTokenBalance * nodeCreationFee) / 100;

            swapAndSendToFee(creationFeeAddress, creationFee);

            uint256 swapTokens = (contractTokenBalance * liquidityPoolFee) / 100;

            swapAndLiquify(swapTokens);
            swapTokensForEth(ICARTEL(_tokenAddress).balanceOf(address(this)));

            swapping = false;
        }
		_createNodes(msg.sender, FIRST_LEVEL_NODE, count);
	}

	/** 
     * Node creation with $esGXY, at the same price as with $GXY. Only first level node can be created with escrowed token.
	*/
	function createNodeWithEscrowedTokens() public {
		uint256 _nodePrice = nodePrice(FIRST_LEVEL_NODE);
		require(ICARTEL(_escrowedTokenAddress).balanceOf(msg.sender) >= _nodePrice, "Balance too low for creation.");
		ICARTEL(_escrowedTokenAddress).transferFrom(msg.sender, deadAddress, _nodePrice);
		_createNodes(msg.sender, FIRST_LEVEL_NODE, 1);
	}

	/**
	 * Node airdrop for OGs and promotion. Limited by maxairdroppedNodes variable.
	 * @param ogs list of addresses.
	 * @param nodeTypeName list of node type name to create.
	 */
	function createNodesAidrop(address[] calldata ogs, string[] calldata nodeTypeName) external onlyOwner whenIsOpen {
		require(ogs.length == nodeTypeName.length, "Not same size");
		require(airdroppedNodes + ogs.length <= maxairdroppedNodes, "Max aidropped nodes reached");
		for (uint256 i=0;i<ogs.length;i++){
			require(_doesNodeTypeExist(nodeTypeName[i]), "nodeTypeName does not exist");
			_createNodes(ogs[i], nodeTypeName[i], 1);
			airdroppedNodes ++;
		}
	}

	function _createNodes(address account, string memory nodeTypeName, uint256 count) private {
        require(_doesNodeTypeExist(nodeTypeName), "NodeTypeName does not exist");
        require(count > 0, "Count cannot be less than 1.");

		IterableNodeTypeMapping.NodeType storage nt;

		nt = _nodeTypes.get(nodeTypeName);
		nt.count += count;
		require(nt.count <= nt.max, "Max already reached");

        for (uint256 i = 0; i < count; i++) {
			_nodeTypeOwner[nodeTypeName][account].push(
                NodeEntity({
                    nodeTypeName: nodeTypeName,
                    creationTime: block.timestamp,   
                    lastClaimTime: block.timestamp
                })
			);
        }

		emit CreateNode(account, nodeTypeName, count);
    }

	/// NODE LEVEL UP LOGIC ///

	/** 
	* User can now level up a casino with tokens. 
	* The next level node price will depend on the current demand : more level up, more expensive.
	* @param nodeName : name of the node to level up
	**/
	function levelUp(string memory nodeName) public {
		require(openLevelUp, "Node level up not authorized yet");
		require(_doesNodeTypeExist(nodeName), "Node doesnt exist");
		require (_nodeTypeOwner[nodeName][msg.sender].length > 0, "No node to level up");
		
		IterableNodeTypeMapping.NodeType storage nodeToLvlUp = _nodeTypes.get(nodeName);
		IterableNodeTypeMapping.NodeType storage nodeTarget = _nodeTypes.get(getNodeTypeNameAtIndex(nodeToLvlUp.nodeLevel));

		require(_doesNodeTypeExist(nodeTarget.nodeTypeName), "Node doesnt exist");
		require(nodeTarget.maxLevelUpGlobal >= 1, "No one can level up this type of node");

		nodeTarget.maxLevelUpGlobal -= 1;
		_nodeTypeOwnerLevelUp[nodeTarget.nodeTypeName][msg.sender] += 1;

		require(_nodeTypeOwnerLevelUp[nodeTarget.nodeTypeName][msg.sender] <= nodeTarget.maxLevelUpUser, "Level up limit reached for user");
		
		uint256 priceToPay = nodePrice(nodeTarget.nodeTypeName);
		
		require(ICARTEL(_tokenAddress).balanceOf(msg.sender) >= priceToPay, "Balance too low for level up.");

		_nodeTypeOwner[nodeName][msg.sender].pop();
		nodeToLvlUp.count -= 1;
		
		ICARTEL(_tokenAddress).transferFrom(msg.sender, address(this), priceToPay);
		//// only levelUp fee is taken, the rest is burned
		uint256 tax = priceToPay * levelUpFee / 100;

		ICARTEL(_tokenAddress).transferFrom(msg.sender, deadAddress, priceToPay - tax);
		
		_createNodes(msg.sender, nodeTarget.nodeTypeName, 1);
	}

	/**
	 * User can level up their node with pending reward, to avoid paying claim tax. 
	 * @param nodeName node to level up.
	**/
	function levelUpWithPending(string memory nodeName) public whenIsOpen {
		require(openPending, "Buy node with pending reward not authorized yet");
		require(_doesNodeTypeExist(nodeName), "Node doesnt exist");
		require (_nodeTypeOwner[nodeName][msg.sender].length > 0, "No node to level up");
		
		IterableNodeTypeMapping.NodeType storage nodeToLvlUp = _nodeTypes.get(nodeName);
		IterableNodeTypeMapping.NodeType storage nodeTarget = _nodeTypes.get(getNodeTypeNameAtIndex(nodeToLvlUp.nodeLevel));

		require(_doesNodeTypeExist(nodeTarget.nodeTypeName), "Node doesnt exist");
		require(nodeTarget.maxLevelUpGlobal >= 1, "No one can level up this type of node");

		nodeTarget.maxLevelUpGlobal -= 1;
		_nodeTypeOwnerLevelUp[nodeTarget.nodeTypeName][msg.sender] += 1;
		nodeTarget.maxCreationPendingGlobal -= 1;
		_nodeTypeOwnerCreatedPending[nodeTarget.nodeTypeName][msg.sender] += 1;

		require(_nodeTypeOwnerLevelUp[nodeTarget.nodeTypeName][msg.sender] <= nodeTarget.maxLevelUpUser, "Level up limit reached for user");
		require(nodeTarget.maxCreationPendingGlobal >= 0, "Max creation pending reached");
		require(_nodeTypeOwnerCreatedPending[nodeTarget.nodeTypeName][msg.sender] <= nodeTarget.maxCreationPendingUser, "Max creation pending reached for user");

		IterableNodeTypeMapping.NodeType memory nt;
		uint256 priceToPay = nodePrice(nodeTarget.nodeTypeName);
		uint256 rewardAmount;

		for (uint i; i < _nodeTypes.size() && priceToPay > 0; i++) {
			nt = _nodeTypes.getValueAtIndex(i);
			NodeEntity[] storage nes = _nodeTypeOwner[nt.nodeTypeName][msg.sender];

			for (uint j; j < nes.length && priceToPay > 0; j++) {
				rewardAmount = _calculateNodeReward(nes[j]);

				if (priceToPay > rewardAmount){
					nes[j].lastClaimTime = block.timestamp;
					priceToPay -= rewardAmount;
				}
				else {
					priceToPay = 0;
					nes[j].lastClaimTime = block.timestamp - rewardAmount * nt.claimTime / nt.rewardAmount;
				}
			}
			require(priceToPay == 0, "Insufficient Pending");

			_createNodes(msg.sender, nodeTarget.nodeTypeName, 1);
		}
	}

	//// VRGDA PRICE LOGIC ////

	/**
	 * We use a virtual price curve to determine the price of each node.
	 * The price is based on the demand for the node level.
	 * Thanks to paradigm team ❤️
	 * @param levelName : name of the node level
	**/
  	function nodePrice(string memory levelName) public view returns (uint256) {
		require(_doesNodeTypeExist(levelName), "levelName does not exist");

		IterableNodeTypeMapping.NodeType memory nt = _nodeTypes.get(levelName);
    	uint256 timeSinceStart = block.timestamp - openDate;
		uint256 price = getVRGDAPrice(nt.targetPrice, toDaysWadUnsafe(timeSinceStart), nt.count);

		if (nt.nodeLevel != 1) {
			/// we calculate upgrade cost compared to first level node
			IterableNodeTypeMapping.NodeType memory ntFirstLvl = _nodeTypes.get(FIRST_LEVEL_NODE);
			price += getVRGDAPrice(ntFirstLvl.targetPrice, toDaysWadUnsafe(timeSinceStart), ntFirstLvl.count);
		}
		return price;
  	}

	//// NODE REWARDS LOGIC ////

	//// TODO : separated claim, little lvl = big risk, big lvl = little risk


	//// LEVEL 5 node : 

	function claimAll() public {
		address sender = msg.sender;
		IterableNodeTypeMapping.NodeType memory nt;
		uint256 rewardAmount = 0;
		
		for (uint i; i < _nodeTypes.size(); i++) {
			nt = _nodeTypes.getValueAtIndex(i);
			NodeEntity[] storage nes = _nodeTypeOwner[nt.nodeTypeName][sender];
			for (uint j; j < nes.length; j++) {
				rewardAmount += _calculateNodeReward(nes[j]);
				nes[j].lastClaimTime = block.timestamp;
			}
		}
		require(rewardAmount > 0, "Nothing to claim");

		ICARTEL(_tokenAddress).mintFromCasino(address(this), rewardAmount);

		if (swapLiquify) {
			uint256 feeAmount;
            if (cashoutFee > 0) {
                feeAmount = rewardAmount * cashoutFee / 100;
                swapTokensForEth(feeAmount);
            }
            rewardAmount -= feeAmount;
		}

		ICARTEL(_tokenAddress).transfer(sender, rewardAmount);
	}

	function calculateAllClaimableRewards(address user) public view returns (uint256) {
		IterableNodeTypeMapping.NodeType memory nt;
		uint256 rewardAmount = 0;
		
		for (uint256 i=0; i < _nodeTypes.size(); i++) {
			nt = _nodeTypes.getValueAtIndex(i);
			NodeEntity[] storage nes = _nodeTypeOwner[nt.nodeTypeName][user];
			for (uint256 j=0; j < nes.length; j++) {
				rewardAmount += _calculateNodeReward(nes[j]);
			}
		}
		return rewardAmount;
	}

	function _calculateNodeReward(NodeEntity memory node) private view returns(uint256) {
		IterableNodeTypeMapping.NodeType memory nt = _nodeTypes.get(node.nodeTypeName);
		uint256 rewards;
		if (block.timestamp - node.lastClaimTime < nt.claimTime) {
			rewards =  nt.rewardAmount * (block.timestamp - node.lastClaimTime) * (100 - nt.claimTaxBeforeTime) / (nt.claimTime * 100);
		} else {
			rewards = nt.rewardAmount * (block.timestamp - node.lastClaimTime) / nt.claimTime;
		}
		if (nt.rewardAmount * (block.timestamp - node.creationTime) / nt.claimTime < nodePrice(nt.nodeTypeName)) {
			rewards = rewards * (100 - nt.earlyClaimTax) / 100;
		}
		return rewards;
	}

	//// REFERRALS LOGIC ////

    function createReferralCode() public returns (string memory) {
        require(!_referralsUsed[msg.sender], "Referral code already exists for this address");
		require(openReferral, "Referral code creation is not open");

        string memory code = Referrals._generateReferralCode(_referralsNonce);

        while (_referrals[code] != address(0)) {
            _referralsNonce++;
            code = Referrals._generateReferralCode(_referralsNonce);
        }
        _referrals[code] = msg.sender;
        _referralsUsed[msg.sender] = true;
		referralByAddress[msg.sender] = code;
        _referralsNonce++;

		emit CreateReferralCode(msg.sender, code);

		return code;
    }

	//// GETTERS //// 

	function getTotalCreatedNodes() public view returns(uint256) {
		uint256 total = 0;
		for (uint256 i=0; i < _nodeTypes.size(); i++) {
			total += _nodeTypes.getValueAtIndex(i).count;
		}
		return total;
	}

	function getTotalCreatedNodesOf(address who) public view returns(uint256) {
		uint256 total = 0;
		for (uint256 i=0; i < getNodeTypesSize(); i++) {
			string memory name = _nodeTypes.getValueAtIndex(i).nodeTypeName;
			total += getNodeTypeOwnerNumber(name, who);
		}
		return total;
	}

	function getTotalTypeNodes(string memory nodeTypeName) public view returns(uint256) {
		require(_doesNodeTypeExist(nodeTypeName), "nodeTypeName does not exist");
		return _nodeTypes.get(nodeTypeName).count;
	}
	
	function getNodeTypesSize() public view returns(uint256) {
		return _nodeTypes.size();
	}
	
	function getNodeTypeNameAtIndex(uint256 i) public view returns(string memory) {
        return _nodeTypes.getValueAtIndex(i).nodeTypeName;
	}
	
	function getNodeTypeOwnerNumber(string memory nodeTypeName, address _owner) public view returns(uint256) {
		if (!_doesNodeTypeExist(nodeTypeName)) {
			return 0;
		}
		return _nodeTypeOwner[nodeTypeName][_owner].length;
	}

	function getAllTypeOwnerNumber(address _owner) public view returns(uint256[] memory) {
		uint256[] memory all = new uint256[](_nodeTypes.size());
		for (uint i; i < _nodeTypes.size(); i++) {
			all[i] = getNodeTypeOwnerNumber(_nodeTypes.getValueAtIndex(i).nodeTypeName, _owner);
		}
		return all;
	}

	//// UTILS ////

	function addNewLevel(
		string memory levelName, 
		uint256[] memory values,
		int256 _targetPrice
	) external onlyOwner {
		require(bytes(levelName).length > 0, "addNodeType: Empty name");
        require(!_doesNodeTypeExist(levelName), "addNodeType: same nodeTypeName exists.");

        _nodeTypes.set(levelName, IterableNodeTypeMapping.NodeType({
                nodeTypeName: levelName, 
				nodeLevel : values[0],
				targetPrice : _targetPrice,
                claimTime: values[1],
                rewardAmount: values[2],
                claimTaxBeforeTime: values[3],
				count: 0,
				max: values[4],
				earlyClaimTax: values[5],
				maxLevelUpGlobal: values[6],
				maxLevelUpUser: values[7],
				maxCreationPendingGlobal: values[8],
				maxCreationPendingUser: values[9]
            })
        );
		emit AddNewLevel(levelName, values[0]);
    }

	function changeNodeType(
		string memory nodeTypeName, 
		uint256[] memory values,
		int256 _targetPrice
	) external onlyOwner {
        require(_doesNodeTypeExist(nodeTypeName), "changeNodeType: nodeTypeName does not exist");

        IterableNodeTypeMapping.NodeType storage nt = _nodeTypes.get(nodeTypeName);

		nt.targetPrice = _targetPrice;
		nt.nodeLevel = values[0];
		nt.claimTime = values[1];
		nt.rewardAmount = values[2];
		nt.claimTaxBeforeTime = values[3];
		nt.max = values[4];
		nt.earlyClaimTax = values[5];
		nt.maxLevelUpGlobal = values[6];
		nt.maxLevelUpUser = values[7];
		nt.maxCreationPendingGlobal = values[8];
		nt.maxCreationPendingUser = values[9];
    }
	
	function _doesNodeTypeExist(string memory nodeTypeName) private view returns (bool) {
        return _nodeTypes.getIndexOfKey(nodeTypeName) >= 0;
    }

    function updateSwapTokensAmount(uint256 newVal) external onlyOwner {
        swapTokensAmount = newVal;
    }

    function updateLiquidityFee(uint256 value) external onlyOwner {
        liquidityPoolFee = value;
    }

    function updateCreationFee(uint256 value) external onlyOwner {
        nodeCreationFee = value;
    }

    function updateCashoutFee(uint256 value) external onlyOwner {
        cashoutFee = value;
    }

	function updateOpenPending(bool value) external onlyOwner {
		openPending = value;
	}
	
	function updateOpenLevelUp(bool value) external onlyOwner {
        openLevelUp = value;
    }

	function updateLevelUpFee(uint256 value) external onlyOwner {
		levelUpFee = value;
	}

	function updateOpenReferral(bool value) external onlyOwner {
		openReferral = value;
	}

	function updateReferralRewards(uint256 value) external onlyOwner {
		referralRewards = value;
	}

	function updateCreationFeeAddr(address newAddr) external onlyOwner {
		creationFeeAddress = newAddr;
	}

	//// SWAP ////

	function swapAndSendToFee(address destination, uint256 tokens) private {
        uint256 initialETHBalance = address(this).balance;
        swapTokensForEth(tokens);
        uint256 newBalance = (address(this).balance) - initialETHBalance;
		payable(destination).transfer(newBalance);
    }

    function swapAndLiquify(uint256 tokens) private {
        uint256 half = tokens / 2;
        uint256 otherHalf = tokens - half;

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(half);

        uint256 newBalance = address(this).balance - initialBalance;

        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = _tokenAddress;
        path[1] = _uniswapV2Router.WETH();

        IERC20(_tokenAddress).approve(address(_uniswapV2Router), tokenAmount);

        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }


    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        IERC20(_tokenAddress).approve(address(_uniswapV2Router), tokenAmount);

        _uniswapV2Router.addLiquidityETH{value: ethAmount}(
            _tokenAddress,                  // token address
            tokenAmount,                    // amountTokenDesired
            0, // slippage is unavoidable   // amountTokenMin
            0, // slippage is unavoidable   // amountAVAXMin
            owner(),                    	// to address
            block.timestamp                 // deadline
        );
    }

}