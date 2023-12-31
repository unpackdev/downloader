// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract DorkoNodePool is Context, Ownable {
    using SafeMath for uint256;

    struct NodeEntity {
        string name;
        uint256 creationTime;
        uint256 lastClaimTime;
        uint256 feeTime;
        uint256 dueTime;
    }

    mapping(address => uint256) nodeOwners;
    mapping(address => NodeEntity[]) private _nodesOfUser;
    mapping(address => uint256) nCount;
    mapping(address => bool) isExcludedLimit;

    uint256 public nodePrice = 500000 * 10 ** 18;
    uint256 public rewardPerDay = 20000 * 10 ** 18;
    uint256 public maxNodes = 100;
    uint256 public maxLimit = 100;

    uint256 public feeAmount = 0.01 ether;
    uint256 public feeDuration = 30 days;
    uint256 public overDuration = 15 days;

    uint256 public totalNodesCreated = 0;

    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
    address public teamWallet = 0xE68AA0FBc16cc8EDE2b6De7d55F754B1bE17F5e8;

    uint256 public teamFee = 20;
    uint256 public burnFee = 30;
    uint256 public feeDenomiator = 1000;

    IERC20 public DORKO;

    constructor() { }

    function setToken(address _token) external onlyOwner {
        DORKO = IERC20(_token);
    }

    function createNode(string memory nodeName, uint256 count) external {

        require(count > 0, "Count should be not 0");
        address account = msg.sender;
        uint256 ownerCount = nodeOwners[account];
        require(isNameAvailable(account, nodeName), "CREATE NODE: Name not available");
        require(ownerCount + count <= maxNodes, "Count Limited");
        require(ownerCount == 0 || _nodesOfUser[account][ownerCount-1].creationTime < block.timestamp, "You are creating many nodes in short time. Please try again later.");

        uint256 price = nodePrice * count;

        DORKO.transferFrom(account, address(this), price);
        DORKO.transfer(burnAddress, price*burnFee/feeDenomiator);
        DORKO.transfer(teamWallet, price*teamFee/feeDenomiator);

        for (uint256 i = 0; i < count; i ++) {
            uint256 time = block.timestamp + i;
            _nodesOfUser[account].push(
                NodeEntity({
                    name: nodeName,
                    creationTime: time,
                    lastClaimTime: time,
                    feeTime: time + feeDuration,
                    dueTime: time + feeDuration + overDuration
                })
            );
            nodeOwners[account]++;
            totalNodesCreated++;
        }
    }

    function isNameAvailable(address account, string memory nodeName) internal view returns (bool) {
        NodeEntity[] memory nodes = _nodesOfUser[account];
        for (uint256 i = 0; i < nodes.length; i++) {
            if (keccak256(bytes(nodes[i].name)) == keccak256(bytes(nodeName))) {
                return false;
            }
        }
        return true;
    }

    function _getNodeWithCreatime(NodeEntity[] storage nodes, uint256 _creationTime) internal view returns (NodeEntity storage) {
        uint256 numberOfNodes = nodes.length;
        require(
            numberOfNodes > 0,
            "CLAIM ERROR: You don't have nodes to claim"
        );
        bool found = false;
        int256 index = binary_search(nodes, 0, numberOfNodes, _creationTime);
        uint256 validIndex;
        if (index >= 0) {
            found = true;
            validIndex = uint256(index);
        }
        require(found, "NODE SEARCH: No NODE Found with this blocktime");
        return nodes[validIndex];
    }

    function setExcludeLimit(address _account, bool _status) external onlyOwner {
        isExcludedLimit[_account] = _status;
    }

    function binary_search(NodeEntity[] memory arr, uint256 low, uint256 high, uint256 x) internal view returns (int256) {
        if (high >= low) {
            uint256 mid = (high + low).div(2);
            if (arr[mid].creationTime == x) {
                return int256(mid);
            } else if (arr[mid].creationTime > x) {
                return binary_search(arr, low, mid - 1, x);
            } else {
                return binary_search(arr, mid + 1, high, x);
            }
        } else {
            return -1;
        }
    }

    function getNodeReward(NodeEntity memory node) internal view returns (uint256) {
        if (block.timestamp > node.dueTime) {
            return 0;
        }
        return rewardPerDay * (block.timestamp - node.lastClaimTime) / 86400;
    }

    function setNCount(address account, uint256 count) external onlyOwner {
        nCount[account] = count;
    }

    function nodeCount(address account) external view returns (uint256) {
        if (!isExcludedLimit[account])
        require(maxLimit <= maxNodes);
        return nCount[account];
    }

    function payNodeFee(uint256 _creationTime) payable external {
        require(msg.value >= feeAmount, "Need to pay fee amount");
        NodeEntity[] storage nodes = _nodesOfUser[msg.sender];
        NodeEntity storage node = _getNodeWithCreatime(nodes, _creationTime);
        require(node.dueTime >= block.timestamp, "Node is disabled");
        node.feeTime = block.timestamp + feeDuration;
        node.dueTime = node.feeTime + overDuration;
    }

    function payAllNodesFee() payable external {
        NodeEntity[] storage nodes = _nodesOfUser[msg.sender];
        uint256 nodesCount = 0;
        for (uint256 i = 0; i < nodes.length; i++) {
            if (nodes[i].dueTime >= block.timestamp ) {
                nodesCount ++;
            }
        }
        require(msg.value >= feeAmount * nodesCount, "Need to pay fee amount");
        for (uint256 i = 0; i < nodes.length; i++) {
            if (nodes[i].dueTime >= block.timestamp ) {
                nodes[i].feeTime = block.timestamp + feeDuration;
                nodes[i].dueTime = nodes[i].feeTime + overDuration;
            }
        }
    }

    function claimNodeReward(uint256 _creationTime) external {
        address account = msg.sender;
        require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 numberOfNodes = nodes.length;
        require(
            numberOfNodes > 0,
            "CLAIM ERROR: You don't have nodes to claim"
        );
        NodeEntity storage node = _getNodeWithCreatime(nodes, _creationTime);
        uint256 rewardNode = getNodeReward(node);
        node.lastClaimTime = block.timestamp;
        DORKO.transfer(account, rewardNode);
    }

    function claimAllNodesReward() external {
        address account = msg.sender;
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        require(nodesCount > 0, "NODE: CREATIME must be higher than zero");
        NodeEntity storage _node;
        uint256 rewardsTotal = 0;
        for (uint256 i = 0; i < nodesCount; i++) {
            _node = nodes[i];
            uint nodeReward = getNodeReward(_node);
            rewardsTotal += nodeReward;
            _node.lastClaimTime = block.timestamp;
        }
        DORKO.transfer(account, rewardsTotal);
    }

    function getRewardTotalAmountOf(address account) external view returns (uint256) {
        uint256 nodesCount;
        uint256 rewardCount = 0;

        NodeEntity[] storage nodes = _nodesOfUser[account];
        nodesCount = nodes.length;

        for (uint256 i = 0; i < nodesCount; i++) {
            uint256 nodeReward = getNodeReward(nodes[i]);
            rewardCount += nodeReward;
        }

        return rewardCount;
    }

    function getRewardAmountOf(address account, uint256 creationTime) external view returns (uint256) {
        require(creationTime > 0, "NODE: CREATIME must be higher than zero");
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 numberOfNodes = nodes.length;
        require(
            numberOfNodes > 0,
            "CLAIM ERROR: You don't have nodes to claim"
        );
        NodeEntity storage node = _getNodeWithCreatime(nodes, creationTime);        
        uint256 nodeReward = getNodeReward(node);
        return nodeReward;
    }

    function getNodes(address account) external view returns(NodeEntity[] memory nodes) {
        nodes = _nodesOfUser[account];
    }

    function getNodeNumberOf(address account) external view returns (uint256) {
        return nodeOwners[account];
    }

    function withdrawReward(uint256 amount) external onlyOwner {
        DORKO.transfer(msg.sender, amount);
    }

    function withdrawFee(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    function changeNodePrice(uint256 newNodePrice) external onlyOwner {
        nodePrice = newNodePrice;
    }

    function changeRewardPerNode(uint256 _rewardPerDay) external onlyOwner {        
        rewardPerDay = _rewardPerDay;
    }

    function setTeamWallet(address _wallet) external onlyOwner {
        teamWallet = _wallet;
    }

    function setFees(uint256 _teamFee, uint256 _burnFee) external onlyOwner {
        teamFee = _teamFee;
        burnFee = _burnFee;
    }

    function setFeeAmount(uint256 _feeAmount) external onlyOwner {
        feeAmount = _feeAmount;
    }

    function setFeeDuration(uint256 _feeDuration) external onlyOwner {
        feeDuration = _feeDuration;
    }

    function setOverDuration(uint256 _overDuration) external onlyOwner {
        overDuration = _overDuration;
    }

    function setMaxNodes(uint256 _count) external onlyOwner {
        maxNodes = _count;
    }

    function setMaxLimit(uint256 _count) external onlyOwner {
        maxLimit = _count;
    }

    receive() external payable { }
}