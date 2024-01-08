pragma solidity ^0.6.12;

import "./Context.sol";
import "./IERC20.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./VRFConsumerBase.sol";

contract Raffle is Ownable, VRFConsumerBase {
    // using SafeMath for uint256;
    using Address for address;

    IERC20 _token; 
    mapping (address => uint256) _balances;
    uint256 unstakeFee = 500; // 5%
    bool halted;
    bool locked;
    address deadAdd = 0x000000000000000000000000000000000000dEaD;
    mapping (uint256 => uint256) randomNums;
    uint256 curRaffle;

    bytes32 private keyHash;
    uint256 private fee;

    event Stake(address indexed account, uint256 timestamp, uint256 value);
    event Unstake(address indexed account, uint256 timestamp, uint256 value);
    event Lock(address indexed account, uint256 timestamp);
    event Unlock(address indexed account, uint256 timestamp);

    constructor(address _tokenAdd) 
        VRFConsumerBase(0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, 0x514910771AF9Ca656af840dff83E8264EcF986CA)
        public {
        _token = IERC20(_tokenAdd);
        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
        fee = 2 * 10 ** 18;
    }

    function stakedBalance(address account) external view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 value) external notHalted {
        require(value > 0, "Raffle: stake value should be greater than 0");
        _token.transferFrom(_msgSender(), address(this), value);

        _balances[_msgSender()] = _balances[_msgSender()].add(value);
        emit Stake(_msgSender(),now,value);
    }

    function unstake(uint256 value) external lockable {
        require(_balances[_msgSender()] >= value, 'Raffle: insufficient staked balance');

        _balances[_msgSender()] = _balances[_msgSender()].sub(value);
        uint256 toBurn = value.mul(unstakeFee).div(10000);
        _token.transfer(deadAdd, toBurn);
        _token.transfer(_msgSender(), value.sub(toBurn));
        emit Unstake(_msgSender(),now,value);
    }

    function lockForRaffle() external onlyOwner() lockable {
        locked = true;
        emit Lock(owner(), now);
    }

    function raffleUnlock() external onlyOwner() {
        require(locked, "Raffle: Stakes are unlocked");
        locked = false;
        emit Unlock(owner(), now);
    }

    function getRandomNumber(uint256 _raffleIter) external returns (bytes32 requestId) {
        require(_msgSender() == owner(), "Raffle: Only Owner");
        require(_raffleIter > curRaffle, "Raffle: Can only get random for the next raffle");
        curRaffle = _raffleIter;
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomNums[curRaffle] = randomness;
    }

    function getRandom(uint256 raffleIter) public view returns (uint256) {
        return randomNums[raffleIter];
    }

    function getPositionRandom(uint56 raffleIter, uint256 position) public view returns (uint256) {
        uint256 positionRandom = uint256(keccak256(abi.encode(randomNums[raffleIter], position)));
        return positionRandom;
    }

    function getPositionWinner(uint256 raffleIter, uint256 position, uint256 totalTickets) public view returns (uint256) {
        uint256 positionRandom = uint256(keccak256(abi.encode(randomNums[raffleIter], position)));
        uint256 winnerTicket = positionRandom % totalTickets;
        return winnerTicket;
    }

    function withdrawLink() external onlyOwner() {
        LINK.transfer(owner(), LINK.balanceOf(address(this)));
    }

    function setUnstakeFee(uint256 _fee) external onlyOwner() {
        unstakeFee = _fee;
    }

    function halt(bool status) external onlyOwner {
        halted = status;
    }

    modifier lockable() {
        require(!locked, "Raffle: Stakes locked for Raffle");
        _;
    }

    modifier notHalted() {
        require(!halted, "Raffle: Deposits are paused");
        _;
    }
}