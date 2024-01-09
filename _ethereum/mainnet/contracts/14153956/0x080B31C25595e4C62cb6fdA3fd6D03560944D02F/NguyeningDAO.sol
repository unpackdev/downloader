// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

//OpenZEPP
import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./IERC20.sol";

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint256) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint256) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key)
        public
        view
        returns (int256)
    {
        if (!map.inserted[key]) {
            return -1;
        }
        return int256(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint256 index)
        public
        view
        returns (address)
    {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint256) {
        return map.keys.length;
    }

    function set(
        Map storage map,
        address key,
        uint256 val
    ) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

contract NodeManager is Ownable {
    // Declare all necessary variables
    using IterableMapping for IterableMapping.Map;
    uint256 public setupFee = 0.01 ether; // ONE-TIME ETH-USD FEE TO SETUP NODE
    uint256 public nodeFee = 100 * (10**18); // COST TO SETUP EACH NODE IN $WIN TOKENS
    uint256 public nodeReward = 1 * (10**18); // MAXIMUM REWARDS FOR NODE PER DAY
    uint256 public burnCount; // Keep track of total tokens burned
    uint256 public nodeLimit = 100; // Node Limit Per account
    uint256 public minAgeReduction = 8 hours;
    uint256 public totalNodes;
    uint256 public burnAmount = 20; // Tokent amount to be burned per node creation
    address public gateKeeper;
    address public token;

    struct RewardModel {
        uint256 rewardRate;
        uint256 lastUpdated;
    }

    struct NodeModel {
        uint256 creationTime;
        uint256 lastClaimTime;
        uint256 nodeLevel;
        uint256 rewards;
    }

    IterableMapping.Map private nodeOwners;
    mapping(address => NodeModel[]) private userNodes;
    RewardModel public rewardManager;

    constructor(address _gate, address _token) {
        token = _token;
        gateKeeper = _gate;
        rewardManager.rewardRate = nodeReward;
        rewardManager.lastUpdated = block.timestamp;
    }

    modifier onlyController() {
        require(
            msg.sender == token ||
                msg.sender == gateKeeper ||
                msg.sender == owner(),
            "ERROR: You are not authorized."
        );
        _;
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function setRewardRate(uint256 _amount) external onlyController{
        require(_amount > 0 && _amount <= nodeReward, "Set Reward ERROR: Amount is not within boundaries.");
        rewardManager.rewardRate = _amount;
        rewardManager.lastUpdated = block.timestamp;
    }

    function totalRewards(address _account, uint256 _timeStamp)
        external
        view
        returns (uint256)
    {
        //REQUIRE TO BE A NODE OWNER
        require(
            nodeOwners.get(_account) > 0,
            "NODE ERROR: USER DO NOT OWN ANY NODES."
        );

        uint256 rewardCount;

        NodeModel[] memory nodes = userNodes[_account];

        for (uint256 i = 0; i < nodes.length; i++) {
            //NEED GET TOTAL AMOUNT OF REWARDS
            rewardCount += getRewardWithDecay(nodes[i], _timeStamp);
            rewardCount += nodes[i].rewards;
        }

        return rewardCount;
    }

    function claimAll(address _account, uint256 _timeStamp)
        external
        onlyController
    {
        //Need to add requirement to the GateKeeper
        NodeModel[] storage nodes = userNodes[_account];
        for (uint256 i = 0; i < nodes.length; i++) {
            //Update node last claim time
            nodes[i].lastClaimTime = _timeStamp;
            nodes[i].rewards = 0;
        }
        //Last claim updated for all nodes, now rewards will be sent via main contract.
        //Rewards will be send from distribution pool which could be the token contract itself.
    }

    function updatePendingRewards(address _account, uint256 _amount) external onlyController{
        userNodes[_account][0].rewards += _amount;
    }

    function createNode(
        uint256 _amount,
        address _account,
        uint256 _level
    ) external onlyController {
        for (uint256 i = 0; i < _amount; i++) {
            userNodes[_account].push(
                NodeModel({
                    creationTime: block.timestamp,
                    lastClaimTime: block.timestamp,
                    nodeLevel: _level,
                    rewards: 0
                })
            );
        }
        totalNodes = totalNodes + _amount;
        nodeOwners.set(_account, userNodes[_account].length);
    }

    function levelUp(address _account, uint256 _index, uint256 _level) external onlyController{
        NodeModel[] storage nodes = userNodes[_account];
        nodes[_index].rewards = nodes[_index].rewards + getRewardWithDecay(nodes[_index], block.timestamp);
        uint256 currentLevel = nodes[_index].nodeLevel;
        nodes[_index].nodeLevel = currentLevel + _level;
        currentLevel++;
        nodes[_index].lastClaimTime = block.timestamp;
        totalNodes = totalNodes + _level;
        uint256 creationTime = nodes[_index].creationTime;
        uint256 newCreationTime;
        for(uint256 i = 0; i < _level; i++){
            uint256 addAge = (block.timestamp - creationTime)/(currentLevel + i);
            if(addAge < minAgeReduction)
                newCreationTime += minAgeReduction;
            else
                newCreationTime += addAge;
        }

        if(creationTime + newCreationTime >= block.timestamp)
            nodes[_index].creationTime = block.timestamp;
        else
            nodes[_index].creationTime += newCreationTime;
    }

    function getAllUserNodes(address _account) external view returns(string memory){
        require(nodeOwners.get(_account) > 0, "GET NODE ERROR: USER DO NOT OWN ANY NODES.");
        NodeModel[] memory nodes = userNodes[_account];
        string memory separator = "#";
        string memory insep = ",";
        string memory data; 
        {data = string(abi.encodePacked(uint2str(0), insep, uint2str(nodes[0].creationTime), insep, uint2str(nodes[0].lastClaimTime)));}
        {data = string(abi.encodePacked(data, insep, uint2str(nodes[0].nodeLevel), insep, uint2str(nodes[0].rewards)));}
        for (uint256 i = 1; i < nodes.length; i++) {
            {data = string(abi.encodePacked(data, separator, uint2str(i), insep, uint2str(nodes[i].creationTime))); }
            {data = string(abi.encodePacked(data, insep, uint2str(nodes[i].lastClaimTime), insep, uint2str(nodes[i].nodeLevel), insep, uint2str(nodes[i].rewards))); }
        }
        return data;
    }

    function getRangeUserNodes(address _account, uint256 _start, uint256 _end) external view returns(string memory){
        require(nodeOwners.get(_account) > 0, "GET NODE ERROR: USER DO NOT OWN ANY NODES.");
        NodeModel[] memory nodes = userNodes[_account];
        uint256 nodesCount = nodes.length;
        require(_end <= nodesCount && _start <= nodesCount && _start < _end, "Get Node ERROR: Need start or end to be within range.");
        string memory separator = "#";
        string memory insep = ",";
        string memory data; 
        {data = string(abi.encodePacked(uint2str(_start), insep, uint2str(nodes[_start].creationTime), insep, uint2str(nodes[_start].lastClaimTime))); }
        {data = string(abi.encodePacked(data, insep, uint2str(nodes[_start].nodeLevel), insep, uint2str(nodes[_start].rewards)));}
        
        for (uint256 i = _start+1; i <= _end; i++) {
            {data = string(abi.encodePacked(data, separator, uint2str(i), insep, uint2str(nodes[i].creationTime)));}
            {data = string(abi.encodePacked(data, insep, uint2str(nodes[i].lastClaimTime), insep, uint2str(nodes[i].nodeLevel), insep, uint2str(nodes[i].rewards)));}
        }
        return data;
    }

    function getNodeByIndex(address _account, uint256 _index) external view returns(string memory){
        require(nodeOwners.get(_account) > 0, "GET NODE ERROR: USER DO NOT OWN ANY NODES.");
        NodeModel[] memory nodes = userNodes[_account];
        require(_index < nodes.length, "Get Node ERROR: Index is not within range.");
        string memory insep = ",";
        return string(abi.encodePacked(uint2str(_index), insep, uint2str(nodes[_index].creationTime), insep, uint2str(nodes[_index].lastClaimTime), insep, uint2str(nodes[_index].nodeLevel), insep, uint2str(nodes[_index].rewards)));
    }

    function getRewardWithDecay(NodeModel memory node, uint256 _timeStamp) private view returns (uint256) {
        uint256 rewardCount;
        uint256 decay;

        if(_timeStamp >= node.creationTime + 540 days){
            decay = (((_timeStamp - node.lastClaimTime) * ((rewardManager.rewardRate * node.nodeLevel) / 1 days)) / 10) * 9;
        }
        else if(_timeStamp >= node.creationTime + 360 days){
            decay = (((_timeStamp - node.lastClaimTime) * ((rewardManager.rewardRate * node.nodeLevel) / 1 days)) / 4) * 3;
        } else if(_timeStamp >= node.creationTime + 180 days){
            decay = ((_timeStamp - node.lastClaimTime) * ((rewardManager.rewardRate * node.nodeLevel) / 1 days)) / 2;
        } else if(_timeStamp >= node.creationTime + 90 days){
            decay = ((_timeStamp - node.lastClaimTime) * ((rewardManager.rewardRate * node.nodeLevel) / 1 days)) / 4;
        } else {
            decay = 0;
        }
        rewardCount = (_timeStamp - node.lastClaimTime) * ((rewardManager.rewardRate * node.nodeLevel) / 1 days) - decay;

        return rewardCount;
    }

    function getRewardsByIndex(address _account, uint256 _timeStamp, uint256 _index) external view returns (uint256){
        require(nodeOwners.get(_account) > 0, "GET NODE ERROR: USER DO NOT OWN ANY NODES.");
        NodeModel[] memory nodes = userNodes[_account];
        require(_index < nodes.length, "Get Node ERROR: Index is not within range.");
        return getRewardWithDecay(nodes[_index], _timeStamp) + nodes[_index].rewards;
    }

    function getNodeNumberOf(address _account) external view returns (uint256) {
        return nodeOwners.get(_account);
    }

    function getLastRewardRateUpdate() external view returns (uint256){
        return rewardManager.lastUpdated;
    }

    function setSetupFee(uint256 _amount) external onlyController {
        setupFee = _amount;
    }

    function setNodeFee(uint256 _amount) external onlyController {
        nodeFee = _amount;
    }

    function setReward(uint256 _amount) external onlyController {
        nodeReward = _amount;
    }

    function setBurnAmount(uint256 _amount) external onlyController {
        burnAmount = _amount;
    }

    function setNodeLimit(uint256 _amount) external onlyController {
        nodeLimit = _amount;
    }

    function setGateKeeper(address _account) external onlyController {
        gateKeeper = _account;
    }

    function setToken(address _account) external onlyController {
        token = _account;
    }

    function updateBurnCount(uint256 _amount) external onlyController {
        burnCount += _amount;
    }

    function setBurnCount(uint256 _amount) external onlyController {
        burnCount = _amount;
    }

    function setMinAgeReduction(uint256 _amount) external onlyController {
        minAgeReduction = _amount;
    }

    function getRewardRate() external view onlyController returns(uint256){
        return rewardManager.rewardRate;
    }
}

contract NguyeningDAO is Ownable, ERC20, ERC20Burnable {
    NodeManager public nodeManager;
    address public distributionPool;
    uint256 public rewardTimer = 1 days;
    bool isPaused;
    mapping(address => bool) private blackList;

    constructor(address _distributionPool) ERC20("NguyeningDAO", "WIN") {
        _mint(msg.sender, 10000000 * (10**18));
        distributionPool = _distributionPool;
        isPaused = false;
    }

    modifier contractPaused() {
        require(isPaused == false);
        _;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override contractPaused {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!blackList[from] && !blackList[to], "Blacklisted address");

        super._transfer(from, to, amount);
    }

    function claimAllRewards() public contractPaused {
        address account = msg.sender;
        uint256 time = block.timestamp;
        require(
            nodeManager.getNodeNumberOf(account) > 0,
            "CLAIM ERROR: YOU DONT HAVE ANY NODES."
        );
        require(
            account != address(0),
            "CLAIM ERROR: ADDRESS CANNOT BE A ZERO ADDRESS."
        );
        require(!blackList[account], "CLAIM ERROR: BLACKLISTED ADDRESS.");
        uint256 rewardAmount = nodeManager.totalRewards(account, time);
        require(rewardAmount > 0, "CLAIM ERROR: NOT ENOUGH REWARDS.");
        require(
            balanceOf(distributionPool) >= rewardAmount,
            "CLAIM ERROR: POOL DOES NOT HAVE ENOUGH REWARDS. WAIT TILL REPLENISH."
        );
        nodeManager.claimAll(account, time);
        _transfer(distributionPool, account, rewardAmount);
        updateRewardRate();
    }

    function makeNodes(uint256 _amount, uint256 _level) public payable contractPaused {
        address account = msg.sender;
        require(
            nodeManager.getNodeNumberOf(account) + _amount <=
                nodeManager.nodeLimit(),
            "NODE CREATION: YOU WILL EXCEEDED THE NODE LIMIT."
        );
        require(
            account != address(0),
            "NODE CREATION: ADDRESS CANNOT BE A ZERO ADDRESS."
        );
        require(_level > 0, "NODE CREATION: LEVEL MUST BE GREATER THAN ZERO.");
        require(!blackList[account], "NODE CREATION: BLACKLISTED ADDRESS.");
        uint256 nodePrice = nodeManager.nodeFee() *
            _amount *
            _level;
        uint256 setupFee = nodeManager.setupFee() *
            _amount *
            _level;
        require(msg.value >= setupFee, "NODE CREATION: User did not send enough ETH.");
        require(
            balanceOf(account) >= nodePrice,
            "NODE CREATION: Not enough tokens to create node(s)."
        );
        super._transfer(account, distributionPool, nodePrice);
        nodeManager.createNode(_amount, account, _level);
        uint256 burnAmount = (nodeManager.burnAmount() * (10**18)) * _amount * _level;
        if (burnAmount >= 0 && balanceOf(distributionPool) > burnAmount) {
            super._burn(distributionPool, burnAmount);
            nodeManager.updateBurnCount(nodeManager.burnAmount() * _amount * _level);
        }
        updateRewardRate();
    }

    function levelUpNode(uint256 _index, uint256 _level) public payable contractPaused {
        address account = msg.sender;
        uint256 myNodes = nodeManager.getNodeNumberOf(account);
        require(
            myNodes > 0,
            "LEVEL UP ERROR: YOU DONT HAVE ANY NODES."
        );
        require((_index+1) <= myNodes, "LEVEL UP ERROR: THIS NODE INDEX DOES NOT EXIST.");
        require(
            account != address(0),
            "LEVEL UP ERROR: ADDRESS CANNOT BE A ZERO ADDRESS."
        );
        require(_level > 0, "LEVEL UP ERROR: LEVEL MUST BE GREATER THAN ZERO.");
        require(!blackList[account], "CLAIM ERROR: BLACKLISTED ADDRESS.");
        uint256 nodePrice = nodeManager.nodeFee() * _level;
        uint256 setupFee = nodeManager.setupFee() * _level;
        require(msg.value >= setupFee, "LEVEL UP ERROR: User did not send enough ETH.");
        require(
            balanceOf(account) >= nodePrice,
            "LEVEL UP ERROR: Not enough tokens to create node(s)."
        );
        super._transfer(account, distributionPool, nodePrice);
        nodeManager.levelUp(account, _index, _level);
        uint256 burnAmount = (nodeManager.burnAmount() * (10**18)) * _level;
        if (burnAmount >= 0 && balanceOf(distributionPool) > burnAmount) {
            super._burn(distributionPool, burnAmount);
            nodeManager.updateBurnCount(nodeManager.burnAmount() * _level);
        }
        updateRewardRate();
    }

    function compoundRewardsToLevel(uint256 _index) public payable contractPaused {
        address account = msg.sender;
        uint256 myNodes = nodeManager.getNodeNumberOf(account);
        require(
             myNodes > 0,
            "COMPOUND ERROR: YOU DONT HAVE ANY NODES."
        );
        require(
            account != address(0),
            "COMPOUND ERROR: ADDRESS CANNOT BE A ZERO ADDRESS."
        );
        require(!blackList[account], "COMPOUND ERROR: BLACKLISTED ADDRESS.");
        uint256 totalReward = nodeManager.totalRewards(account,block.timestamp);
        uint256 level =  totalReward / nodeManager.nodeFee();
        require(
            level > 0,
            "COMPOUND ERROR: NOT ENOUGH REWARDS TO COMPUND TO LEVEL"
        );
        require((_index+1) <= myNodes, "COMPOUND ERROR: THIS NODE INDEX DOES NOT EXIST.");
        uint256 setupFee = nodeManager.setupFee() * level;
        require(msg.value >= setupFee, "COMPOUNED ERROR: DID NOT SEND ENOUGH ETH FOR SETUP FEE.");
        nodeManager.claimAll(account, block.timestamp);
        nodeManager.levelUp(account, _index, level);
        nodeManager.updatePendingRewards(account, totalReward % nodeManager.nodeFee());
        uint256 burnAmount = (nodeManager.burnAmount() * (10**18)) *
            level;
        if (burnAmount >= 0 && balanceOf(distributionPool) > burnAmount) {
            super._burn(distributionPool, burnAmount);
            nodeManager.updateBurnCount(
                nodeManager.burnAmount() * level
            );
        }
        updateRewardRate();
    }

    function compoundRewards(uint256 _level) public payable contractPaused{
        address account = msg.sender;
        require(
            nodeManager.getNodeNumberOf(account) > 0,
            "COMPOUND ERROR: YOU DONT HAVE ANY NODES."
        );
        require(_level > 0, "COMPOUND ERROR: THE LEVEL MUST BE GREATER THAN ZERO.");
        require(
            account != address(0),
            "COMPOUND ERROR: ADDRESS CANNOT BE A ZERO ADDRESS."
        );
        require(!blackList[account], "COMPOUND ERROR: BLACKLISTED ADDRESS.");
        uint256 totalReward = nodeManager.totalRewards(account, block.timestamp);
        uint256 amountOfNodes =  totalReward / (nodeManager.nodeFee() * _level);
        require(
            amountOfNodes > 0,
            "COMPOUND ERROR: NOT ENOUGH REWARDS TO COMPUND TO NODE"
        );
        require(
            nodeManager.getNodeNumberOf(account) + amountOfNodes <=
                nodeManager.nodeLimit(),
            "COMPOUND ERROR: YOU WILL EXCEEDED THE NODE LIMIT."
        );
        uint256 setupFee = nodeManager.setupFee() * amountOfNodes * _level;
        require(msg.value >= setupFee, "COMPOUNED ERROR: DID NOT SEND ENOUGH ETH FOR SETUP FEE.");
        nodeManager.claimAll(account, block.timestamp);
        nodeManager.createNode(amountOfNodes, account, _level);
        nodeManager.updatePendingRewards(account, totalReward % nodeManager.nodeFee());
        uint256 burnAmount = (nodeManager.burnAmount() * (10**18)) *
            amountOfNodes * _level;
        if (burnAmount >= 0 && balanceOf(distributionPool) > burnAmount) {
            super._burn(distributionPool, burnAmount);
            nodeManager.updateBurnCount(
                nodeManager.burnAmount() * amountOfNodes * _level
            );
        }
        updateRewardRate();
    }

    function getNodeRewards(address _account) public view contractPaused returns (uint256) {
        return nodeManager.totalRewards(_account, block.timestamp);
    }

    function updateRewardRate() private {
        uint256 lastUpdated = nodeManager.getLastRewardRateUpdate();
        if(block.timestamp >= (lastUpdated + rewardTimer)){
            uint256 poolBalance = balanceOf(distributionPool);
            uint256 nodeReward = nodeManager.nodeReward();
            uint256 totalDailyRewards = getTotalNodeCount() * nodeReward;
            uint256 newReward;
            if(poolBalance/totalDailyRewards >= 75){
                newReward = nodeReward;
            } else if(poolBalance/totalDailyRewards >= 60){
                newReward = (nodeReward / 10) * 8;
            } else if(poolBalance/totalDailyRewards >= 40){
                newReward = (nodeReward / 10) * 6;
            } else if(poolBalance/totalDailyRewards >= 25){
                newReward = (nodeReward / 10) * 4;
            } else {
                newReward = (nodeReward / 10) * 2;
            }
            nodeManager.setRewardRate(newReward);
        }
    }

    function getNodeCount(address _account) public view contractPaused returns (uint256) {
        return nodeManager.getNodeNumberOf(_account);
    }

    function getTotalNodeCount() public view contractPaused returns (uint256) {
        return nodeManager.totalNodes();
    }

    function getNodeSetupFee() public view contractPaused returns (uint256) {
        return nodeManager.setupFee();
    }

    function getNodeFee() public view contractPaused returns (uint256) {
        return nodeManager.nodeFee();
    }

    function getRewardAmountPerNode() public view contractPaused returns (uint256) {
        return nodeManager.getRewardRate();
    }

    function getBurnAmount() public view contractPaused returns (uint256) {
        return nodeManager.burnAmount();
    }

    function getAllUserNodes(address _account) public view contractPaused returns(string memory){
        return nodeManager.getAllUserNodes(_account);
    }

    function getNodeByIndex(address _account, uint256 _index) public view contractPaused returns(string memory){
        return nodeManager.getNodeByIndex(_account, _index);
    }

    function getRangeUserNodes(address _account, uint256 _start, uint256 _end) public view contractPaused returns(string memory){
        return nodeManager.getRangeUserNodes(_account, _start, _end);
    }

    function getRewardByIndex(address _account, uint256 _index) public view contractPaused returns(uint256){
        return nodeManager.getRewardsByIndex(_account, block.timestamp, _index);
    }

    function getBurnCount() public view contractPaused returns(uint256){
        return nodeManager.burnCount();
    }

    function getNodeLimit() public view contractPaused returns(uint256){
        return nodeManager.nodeLimit();
    }

    function getBalanceOfDistPool() public view contractPaused returns(uint256){
        return balanceOf(distributionPool);
    }

    function getBaseReward() public view contractPaused returns(uint256){
        return nodeManager.nodeReward();
    }

    function getMinAgeReduction() public view contractPaused returns(uint256 age){
        return nodeManager.minAgeReduction();
    }

    //Owner Functions
    function pauseContract(bool _pause) public onlyOwner {
        isPaused = _pause;
    }

    function setRewardRate(uint256 _amount) public onlyOwner{
        nodeManager.setRewardRate(_amount);
    }

    function setDistributionPool(address _contract) public onlyOwner {
        distributionPool = _contract;
    }

    function setNodeManager(address _contract) external onlyOwner {
        nodeManager = NodeManager(_contract);
    }

    function claimETH() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
    function setSetupFee(uint256 _amount) public onlyOwner {
        nodeManager.setSetupFee(_amount);
    }

    function setNodeFee(uint256 _amount) public onlyOwner {
        nodeManager.setNodeFee(_amount);
    }

    function setBaseReward(uint256 _amount) public onlyOwner {
        nodeManager.setReward(_amount);
    }

    function setBurnAmount(uint256 _amount) public onlyOwner {
        nodeManager.setBurnAmount(_amount);
    }

    function setNodeLimit(uint256 _amount) public onlyOwner {
        nodeManager.setNodeLimit(_amount);
    }

    function setGateKeeper(address _account) public onlyOwner {
        nodeManager.setGateKeeper(_account);
    }

    function setToken(address _account) public onlyOwner {
        nodeManager.setToken(_account);
    }

    function setBurnCount(uint256 _amount) public onlyOwner {
        nodeManager.setBurnCount(_amount);
    }

    function setRewardTimer(uint256 _amount) public onlyOwner {
        rewardTimer = _amount;
    }

    function ageReduction(uint256 _amount) public onlyOwner {
        nodeManager.setMinAgeReduction(_amount);
    }
}
