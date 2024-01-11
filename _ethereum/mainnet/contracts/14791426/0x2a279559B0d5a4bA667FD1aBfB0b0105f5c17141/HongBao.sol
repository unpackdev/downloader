// SPDX-License-Identifier: MIT
// Creator: Xing @nelsonie

pragma solidity ^0.8.6;

import "./IERC20.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";


contract HongBao is Ownable {
    uint64 private constant EXPIRE_DAY = 1 days;

    struct RedEnvelopInfo {
        // Red Envelop information
        address creator;
        address tokenAddr;
        bytes32 merkelRoot;
        uint256 remainMoney;
        uint16 remainCount;
        uint64 expireTime;
        mapping (address => bool) isOpened;
    }
    mapping(uint64 => RedEnvelopInfo) public redEnvelopInfos;

    // Protocal Fee
    uint16 public protocalRatio = 824;
    mapping(address => uint256) public teamProfit;

    constructor() {
    }

    event Create(uint64 indexed envelopId, address indexed creator, uint256 indexed protocalFee, uint256 money);
    event Open(uint64 indexed envelopId, address indexed opener, uint256 money);
    event Drawback(uint64 indexed envelopId, address indexed creator, uint256 money);

    function create(uint64 envelopId, address tokenAddr, uint256 money, uint16 count, bytes32 merkelRoot) external payable {
        require(msg.sender == tx.origin, "Contract not allowed");
        require(redEnvelopInfos[envelopId].creator == address(0), "Duplicate ID");
        require(count > 0, "Invalid count");
        uint256 protocalFee = money / 100000 * protocalRatio;
        require(money - protocalFee >= count, "Invalid money");
        if (tokenAddr != address(0)) {
            require(IERC20(tokenAddr).allowance(msg.sender, address(this)) >= money, "Check Token allowance");
            require(IERC20(tokenAddr).transferFrom(msg.sender, address(this), money), "Transfer Token failed");
        } else {
            require(money == msg.value, "Insufficient ETH");
        }

        teamProfit[tokenAddr] += protocalFee;

        RedEnvelopInfo storage p = redEnvelopInfos[envelopId];
        p.creator = msg.sender;
        p.tokenAddr = tokenAddr;
        p.merkelRoot = merkelRoot;
        p.remainMoney = money - protocalFee;
        p.remainCount = count;
        p.expireTime = uint64(block.timestamp) + EXPIRE_DAY;
        emit Create(envelopId, msg.sender, protocalFee, money);
    }

    function open(uint64 envelopId, bytes32[] calldata proof) external {
        require(msg.sender == tx.origin, "Contract not allowed");
        require(checkOpenAvailability(envelopId, msg.sender, proof) == 0, "You are not allowed");

        uint256 amount = _calculateRandomAmount(redEnvelopInfos[envelopId].remainMoney, redEnvelopInfos[envelopId].remainCount, msg.sender);

        redEnvelopInfos[envelopId].remainMoney -= amount;
        redEnvelopInfos[envelopId].remainCount -= 1;
        redEnvelopInfos[envelopId].isOpened[msg.sender] = true;

        _send(redEnvelopInfos[envelopId].tokenAddr, payable(msg.sender), amount);
        emit Open(envelopId, msg.sender, amount);
    }

    function drawback(uint64 envelopId) external {
        require(msg.sender == tx.origin, "Contract not allowed");
        require(msg.sender == redEnvelopInfos[envelopId].creator, "Not creator");
        require(block.timestamp > redEnvelopInfos[envelopId].expireTime, "Not expired");
        require(redEnvelopInfos[envelopId].remainMoney > 0, "No money left");

        uint256 amount = redEnvelopInfos[envelopId].remainMoney;
        redEnvelopInfos[envelopId].remainMoney = 0;
        redEnvelopInfos[envelopId].remainCount = 0;

        _send(redEnvelopInfos[envelopId].tokenAddr, payable(msg.sender), amount);
        emit Drawback(envelopId, msg.sender, amount);
    }

    function info(uint64 envelopId) external view returns (address, address, bytes32, uint256, uint16, uint64) {
        RedEnvelopInfo storage redEnvelopInfo = redEnvelopInfos[envelopId];
        return (
        redEnvelopInfo.creator,
        redEnvelopInfo.tokenAddr,
        redEnvelopInfo.merkelRoot,
        redEnvelopInfo.remainMoney,
        redEnvelopInfo.remainCount,
        redEnvelopInfo.expireTime);
    }

    function checkOpenAvailability(uint64 envelopId, address sender, bytes32[] calldata proof) public view returns (uint) {
        if (redEnvelopInfos[envelopId].creator == address(0)) {
            return 1;
        }

        if (redEnvelopInfos[envelopId].remainCount == 0) {
            return 2;
        }

        if (redEnvelopInfos[envelopId].isOpened[sender]) {
            return 3;
        }

        if (redEnvelopInfos[envelopId].merkelRoot != "") {
            if (!MerkleProof.verify(proof, redEnvelopInfos[envelopId].merkelRoot, keccak256(abi.encodePacked(sender)))) {
                return 4;
            }
        }

        return 0;
    }

    function _random(uint256 remainMoney, uint remainCount, address sender) private view returns (uint256) {
       return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.number, sender))) % (remainMoney / remainCount * 2) + 1;
    }

    function _calculateRandomAmount(uint256 remainMoney, uint remainCount, address sender) private view returns (uint256) {
        uint256 amount = 0;
        if (remainCount == 1) {
            amount = remainMoney;
        } else if (remainCount == remainMoney) {
            amount = 1;
        } else if (remainCount < remainMoney) {
            amount = _random(remainMoney, remainCount, sender);
        }
        return amount;
    }

    function _send(address tokenAddr, address payable to, uint256 amount) private {
        if (tokenAddr == address(0)) {
            require(to.send(amount), "Transfer ETH failed");
        } else {
            require(IERC20(tokenAddr).transfer(to, amount), "Transfer Token failed");
        }
    }

    // WIN TOGETHER
    /**
        Withdraw protocal fee to a Crepto Team public wallet address
        Crepto Team will convert all profit token to ETH, then transfer ETH to Crepass contract 0x759e689ec7dd42097e40d1f5df558b130a7544a9

        Support set the withdraw address to Crepass contract directly and renounce the ownership in future
     */
    address public creptoPassAddress = 0xdACFF5227793a31e98845DC5a9910D383e59f85D;

    function withdraw(address tokenAddr) external {
        require(creptoPassAddress != address(0), "Set address");
        uint256 profit = teamProfit[tokenAddr];
        require(profit > 0, "Make more profit");

        teamProfit[tokenAddr] = 0;

        _send(tokenAddr, payable(creptoPassAddress), profit);
    }

    function setCreptoPassAddress(address _creptoPassAddress) external onlyOwner {
        creptoPassAddress = _creptoPassAddress;
    }

    /**
        Protocal Fee can be lower in future and can't exceed 0.824%
     */
    function setProtocalRatio(uint16 _protocalRatio) external onlyOwner {
        require(_protocalRatio <= 824, "Exceed 824");
        protocalRatio = _protocalRatio;
    }
}