// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./SafeERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IWETH.sol";
import "./TransferHelper.sol";
import "./ITopic.sol";

contract Topic is ITopic, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    mapping(uint256 => uint) private locked;
    mapping(uint256 => uint) public status;

    address constant private DEAD = 0x000000000000000000000000000000000000dEaD;
    address public immutable WETH;
    uint256 public fees;
    address public operatorAddress;

    mapping(uint256 => uint256) public parentIds;
    mapping(uint256 => uint256) public childCount;
    mapping(uint256 => string) public name;
    mapping(uint256 => uint256) public start;
    mapping(uint256 => uint256) public totalSupply;
    mapping(uint256 => uint256) private _liquidityPower;
    mapping(uint256 => uint256) private _liquidity;
    mapping(uint256 => mapping(address => uint256)) public balanceOf;
    mapping(uint256 => uint256) public holders;

    uint256 constant private BASE_PRICE = 1E15;
    uint256 constant private X = 1E6;

    constructor(address _WETH){
        WETH = _WETH;
        operatorAddress = msg.sender;
    }

    function decimals() override virtual public view returns (uint8) {
        return 18;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    modifier lock(uint256 id) {
        require(locked[id] == 0, 'LOCKED');
        locked[id] = 1;
        _;
        locked[id] = 0;
    }

    modifier created(uint256 id){
        require(status[id] > 0, 'Not created');
        _;
    }


    modifier started(uint256 id){
        if (parentIds[id] > 0) {
            require(block.timestamp >= start[id] && block.timestamp >= start[parentIds[id]], 'Not started');
        } else {
            require(block.timestamp >= start[id], 'Not started');
        }
        _;
    }

    modifier onlyOperator(){
        require(msg.sender == operatorAddress, 'caller is not the operator');
        _;
    }

    function setOperatorAddress(address newAddress) onlyOwner public {
        require(newAddress != DEAD, 'Error newAddress');
        operatorAddress = newAddress;
    }

    function withdrawFee(uint256 amount) onlyOwner public {
        require(amount <= fees, 'Insufficient');
        fees -= amount;
        IWETH(WETH).withdraw(amount);
        TransferHelper.safeTransferETH(msg.sender, amount);
    }

    function withdraw() onlyOwner public {
        uint256 amount = IERC20(WETH).balanceOf(address(this));
        IWETH(WETH).withdraw(amount);
        TransferHelper.safeTransferETH(msg.sender, amount);
    }

    function getBaseData(uint256 id) public view returns (uint _status,
        uint256 _activeSupply,
        uint256 _holders,
        uint256 _price,
        uint256 liquidityPower,
        uint256 liquidity,
        uint256 burned,
        uint256 hold){
        if (status[id] == 0) {
            _status = 0; // Not created
            _holders = 0;
            _price = 0;
        } else {
            _holders = holders[id];
            if (block.timestamp < start[id]) {
                _status = 1; // Not start
                if (parentIds[id] == 0) _price = 1E15;
                else _price = 1E18;
            } else {
                if (parentIds[id] == 0) _price = topicPrice(id);
                else _price = opinionPrice(id);
                _status = 2; // Trading
            }
        }
        (liquidityPower, liquidity) = getLiquidity(id);
        if (parentIds[id] == 0) _activeSupply = totalSupply[id] - liquidityPower - balanceOf[id][DEAD];
        else _activeSupply = totalSupply[id] - liquidity - balanceOf[id][DEAD];
        burned = balanceOf[id][DEAD];
        hold = balanceOf[id][address(this)];
    }

    function createTopic(uint256 _id,
        uint256 _start,
        string memory _name,
        uint256 _totalSupply) public onlyOperator {
        require(status[_id] == 0, 'Created');
        require(_id > 0, '_id zero');
        require(_totalSupply >= 20, '_totalSupply low');
        _liquidityPower[_id] = totalSupply[_id] = _totalSupply;
        _liquidity[_id] = _totalSupply * BASE_PRICE / 1E18;
        balanceOf[_id][address(this)] = totalSupply[_id];
        emit Transfer(_id, DEAD, address(this), totalSupply[_id]);
        holders[_id] += 1;
        childCount[0] += 1;
        parentIds[_id] = 0;
        status[_id] = 1;
        start[_id] = _start;
        name[_id] = _name;
        emit SetTopic(_id, _name, _start, totalSupply[_id]);
    }

    function createOpinion(uint256 _id,
        uint256 _start,
        string memory _name,
        uint256 _topic) public onlyOperator {
        require(status[_id] == 0, 'Created');
        require(_id > 0, '_id zero');
        require(_id != _topic, '_id == _topic');
        require(status[_topic] > 0, '_topic Not created');
        require(parentIds[_topic] == 0, '_topic error');
        require(start[_topic] <= _start, '_start < topic start');
        _liquidityPower[_id] = _liquidity[_id] = totalSupply[_id] = totalSupply[_topic] * 5E4 / X;
        balanceOf[_id][address(this)] = totalSupply[_id];
        emit Transfer(_id, DEAD, address(this), totalSupply[_id]);
        holders[_id] += 1;
        childCount[_topic] += 1;
        parentIds[_id] = _topic;
        status[_id] = 1;
        start[_id] = _start;
        name[_id] = _name;
        emit SetOpinion(_id, _name, _start, totalSupply[_id], _topic);
    }

    function setStartTime(uint256 _id, uint256 _start) created(_id) public onlyOperator {
        require(block.timestamp < start[_id], 'Trading');
        start[_id] = _start;
        if (parentIds[_id] == 0) emit SetTopic(_id, name[_id], _start, totalSupply[_id]);
        else emit SetOpinion(_id, name[_id], _start, totalSupply[_id], parentIds[_id]);
    }

    function setName(uint256 _id, string memory _name) created(_id) public onlyOperator {
        name[_id] = _name;
        if (parentIds[_id] == 0) emit SetTopic(_id, _name, start[_id], totalSupply[_id]);
        else emit SetOpinion(_id, _name, start[_id], totalSupply[_id], parentIds[_id]);
    }

    function getLiquidity(uint256 id) override virtual public view returns (uint256 liquidityPower, uint256 liquidity){
        liquidityPower = _liquidityPower[id];
        liquidity = _liquidity[id];
    }

    function topicPrice(uint256 id) override virtual public view returns (uint256){
        require(parentIds[id] == 0, 'Opinion');
        return _liquidity[id].mul(1E18).div(_liquidityPower[id]);
    }

    function opinionPrice(uint256 id) override virtual public view returns (uint256){
        require(parentIds[id] > 0, 'Topic');
        return _liquidityPower[id].mul(1E18).div(_liquidity[id]);
    }

    function buyTopicPower(uint256 id, uint256 cost) override virtual public view returns (uint256){
        (uint256 amount,uint256 price,uint256 fee,uint256 burned,uint256 k) = _buyTopicPower(id, cost);
        return amount;
    }

    function _buyTopicPower(uint256 id, uint256 cost) created(id) started(id) internal virtual view returns (uint256 amount, uint256 price, uint256 fee, uint256 burned, uint256 k){
        require(parentIds[id] == 0, 'Opinion');
        require(_liquidityPower[id] > 0, 'Insufficient liquidity');
        require(cost >= 1E12 && cost < 1E26, 'Overflow');
        k = _liquidityPower[id] * _liquidity[id];
        uint256 a1 = 2E4;
        uint256 a2 = 63E4;
        uint256 time = block.timestamp - start[id];
        time = time / 30;
        if (time < 60) a2 -= (time * 1E4);
        else a2 = 3E4;
        fee = cost * a1 / X;
        amount = _liquidityPower[id] - k / (_liquidity[id] + (cost - fee));
        price = (cost - fee) * 1E18 / amount;
        burned = amount * a2 / X;
        amount = amount * (X - a2) / X;
        require(amount > 0 && amount < _liquidityPower[id], 'Insufficient liquidity');
    }

    function sellTopicGain(uint256 id, uint256 amount) override virtual public view returns (uint256){
        (uint256 gain,uint256 price,uint256 fee,uint256 burned,uint256 k) = _sellTopicGain(id, amount);
        return gain;
    }

    function _sellTopicGain(uint256 id, uint256 amount) created(id) started(id) internal virtual view returns (uint256 gain, uint256 price, uint256 fee, uint256 burned, uint256 k){
        require(block.timestamp >= start[id], 'Not started');
        require(parentIds[id] == 0, 'Opinion');
        require(amount > 0 && _liquidity[id] > 0, 'Insufficient liquidity');
        uint256 b1 = 2E4;
        uint256 b2 = 3E4;
        k = _liquidityPower[id] * _liquidity[id];
        burned = amount * b2 / X;
        gain = _liquidity[id] - k / (_liquidityPower[id] + (amount - burned));
        fee = gain * b1 / X;
        gain = gain * (X - b1) / X;
        price = gain * 1E18 / amount;
        require(gain < _liquidity[id], 'Insufficient liquidity');
    }

    function buyPower(uint256 id, uint256 amountOutMin) override virtual external payable {
        IWETH(WETH).deposit{value: msg.value}();
        _buyPower(id, msg.sender, amountOutMin, msg.value);
    }

    function _buyPower(uint256 id, address to, uint256 amountOutMin, uint256 cost) lock(id) internal virtual returns (uint256) {
        (uint256 amount,uint256 price,uint256 fee,uint256 burned,uint256 k) = _buyTopicPower(id, cost);
        require(amount >= amountOutMin, 'LT amountOutMin');
        _transfer(id, address(this), to, amount);
        _liquidityPower[id] -= (amount + burned);
        if (burned > 0) _burn(id, address(this), burned, k);
        _liquidity[id] += (cost - fee);
        fees += fee;
        emit BuyPower(to, id, price, cost, amount, burned, fee);
        return amount;
    }

    function sellPower(uint256 id, uint256 amount, uint256 amountOutMin) override virtual external {
        _sellPower(id, msg.sender, amount, amountOutMin, false);
    }

    function _sellPower(uint256 id, address to, uint256 amount, uint256 amountOutMin, bool isSellFee) lock(id) internal virtual returns (uint256){
        (uint256 gain,uint256 price,uint256 fee,uint256 burned,uint256 k) = _sellTopicGain(id, amount);
        require(gain >= amountOutMin, 'Insufficient output amount');
        _transfer(id, to, address(this), amount);
        if (burned > 0) _burn(id, address(this), burned, k);
        _liquidityPower[id] += (amount - burned);
        _liquidity[id] -= (gain + fee);
        fees += fee;
        if (isSellFee) fees += gain;
        else {
            require(gain <= IERC20(WETH).balanceOf(address(this)), 'Insufficient ETH');
            IWETH(WETH).withdraw(gain);
            TransferHelper.safeTransferETH(to, gain);
        }
        emit SellPower(to, id, price, gain, amount, burned, fee);
        return gain;
    }

    function buyOpinionVote(uint256 id, uint256 cost) override virtual public view returns (uint256){
        (uint256 amount,uint256 price,uint256 fee,uint256 burned,uint256 k) = _buyOpinionVote(id, cost);
        return amount;
    }

    function _buyOpinionVote(uint256 id, uint256 cost) created(id) started(id) internal view returns (uint256 amount, uint256 price, uint256 fee, uint256 burned, uint256 k){
        require(parentIds[id] > 0, 'Topic');
        require(cost >= 1E12, 'The minimum cost is 0.000001');
        require(_liquidity[id] > 0, 'Insufficient liquidity');
        uint256 a1 = 2E4;
        uint256 a2 = 63E4;
        k = _liquidity[id] * _liquidityPower[id];
        fee = cost * a1 / X;
        amount = _liquidity[id] - k / (_liquidityPower[id] + (cost - fee));
        price = (cost - fee) * 1E18 / amount;
        uint256 time = block.timestamp - start[id];
        time = time / 30;
        if (time < 60) a2 -= (time * 1E4);
        else a2 = 3E4;
        burned = amount * a2 / X;
        amount = amount * (X - a2) / X;
        require(amount > 0 && amount < _liquidity[id], 'Insufficient liquidity');
    }

    function sellOpinionGain(uint256 id, uint256 amount) override virtual public view returns (uint256){
        (uint256 gain,uint256 price,uint256 fee,uint256 burned,uint256 k) = _sellOpinionGain(id, amount);
        return gain;
    }

    function _sellOpinionGain(uint256 id, uint256 amount) created(id) started(id) internal view returns (uint256 gain, uint256 price, uint256 fee, uint256 burned, uint256 k){
        require(parentIds[id] > 0, 'Topic');
        require(amount >= 1E12, 'The minimum amount is 0.000001');
        require(_liquidityPower[id] > 0, 'Insufficient liquidity');
        uint256 b1 = 2E4;
        uint256 b2 = 3E4;
        k = _liquidityPower[id] * _liquidity[id];
        burned = amount * b2 / X;
        gain = _liquidityPower[id] - k / (_liquidity[id] + (amount - burned));
        fee = gain * b1 / X;
        gain = gain * (X - b1) / X;
        price = gain * 1E18 / amount;
        require(gain < _liquidityPower[id], 'Insufficient liquidity');
    }

    function buyVote(uint256 id, uint256 amountOutMin, uint256 cost) override virtual external {
        _buyVote(id, msg.sender, amountOutMin, cost);
    }

    function _buyVote(uint256 id, address to, uint256 amountOutMin, uint256 cost) lock(id) internal virtual {
        (uint256 amount,uint256 price,uint256 fee,uint256 burned,uint256 k) = _buyOpinionVote(id, cost);
        require(amount >= amountOutMin, 'Insufficient amount');
        uint256 parentId = parentIds[id];
        _transfer(parentId, to, address(this), cost - fee);
        _transfer(parentId, to, owner(), fee);
        _liquidity[id] -= (amount + burned);
        if (burned > 0) _burn(id, address(this), burned, k);
        _transfer(id, address(this), to, amount);
        _liquidityPower[id] += (cost - fee);
        _sellPower(parentId, owner(), fee, 0, true);
        uint256 ethPrice = (price * topicPrice(parentId)) / 1E18;
        emit BuyVote(to, id, ethPrice, price, cost, amount, burned, fee);
    }

    function sellVote(uint256 id, uint256 amount, uint256 amountOutMin) override virtual external {
        _sellVote(id, msg.sender, amount, amountOutMin);
    }

    function _sellVote(uint256 id, address to, uint256 amount, uint256 amountOutMin) lock(id) internal virtual returns (uint256) {
        (uint256 gain,uint256 price,uint256 fee,uint256 burned,uint256 k) = _sellOpinionGain(id, amount);
        require(gain >= amountOutMin, 'Insufficient output amount');
        _transfer(id, to, address(this), amount);
        if (burned > 0) _burn(id, address(this), burned, k);
        _liquidityPower[id] -= (gain + fee);
        _liquidity[id] += (amount - burned);
        uint256 parentId = parentIds[id];
        _transfer(parentId, address(this), owner(), fee);
        _sellPower(parentId, owner(), fee, 0, true);
        _transfer(parentId, address(this), to, gain);
        emit SellVote(to, id, (price * topicPrice(parentId)) / 1E18, price, gain, amount, burned, fee);
        return gain;
    }


    function buyVoteInETH(uint256 id, uint256 amountOutMin) override virtual external payable {
        IWETH(WETH).deposit{value: msg.value}();
        uint256 power = _buyPower(parentIds[id], msg.sender, 0, msg.value);
        _buyVote(id, msg.sender, amountOutMin, power);
    }

    function sellVote2ETH(uint256 id, uint256 amount, uint256 amountOutMin) override virtual external {
        uint256 power = _sellVote(id, msg.sender, amount, 0);
        _sellPower(parentIds[id], msg.sender, power, amountOutMin, false);
    }

    function _transfer(
        uint256 id,
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        if (to == DEAD) {
            uint256 k = _liquidityPower[id] * _liquidity[id];
            _burn(id, from, amount, k);
        } else {
            require(balanceOf[id][from] >= amount, 'Insufficient');
            balanceOf[id][from] -= amount;
            if (balanceOf[id][from] == 0 && holders[id] >= 1) holders[id] -= 1;
            if (balanceOf[id][to] == 0) holders[id] += 1;
            balanceOf[id][to] += amount;
            emit Transfer(id, from, to, amount);
        }
    }

    function transfer(
        uint256 id,
        address to,
        uint256 amount
    ) created(id) public override {
        _transfer(id, msg.sender, to, amount);
    }

    function burn(
        uint256 id,
        uint256 amount
    ) created(id) public override {
        uint256 k = _liquidityPower[id] * _liquidity[id];
        _burn(id, msg.sender, amount, k);
    }

    function _burn(uint256 id, address from, uint256 amount, uint256 k) internal virtual {
        require(balanceOf[id][from] >= amount, 'Insufficient');
        balanceOf[id][from] -= amount;
        if (balanceOf[id][from] == 0 && holders[id] >= 1) holders[id] -= 1;
        if (balanceOf[id][DEAD] == 0) holders[id] += 1;
        balanceOf[id][DEAD] += amount;
        uint256 getEth = 0;
        if (parentIds[id] == 0) {
            getEth = k / (totalSupply[id] - balanceOf[id][DEAD]) - k / (totalSupply[id] - balanceOf[id][DEAD] + amount);
        } else {
            uint256 getPower = k / (totalSupply[id] - balanceOf[id][DEAD]) - k / (totalSupply[id] - balanceOf[id][DEAD] + amount);
            uint256 parentId = parentIds[id];
            k = _liquidityPower[parentId] * _liquidity[parentId];
            _burn(parentId, address(this), getPower, k);
        }
        fees += getEth;
        emit Transfer(id, from, DEAD, amount);
        emit Burn(id, from, amount);
    }
}
