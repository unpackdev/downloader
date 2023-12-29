// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./IStoneVault.sol";
import "./IStone.sol";

import "./ReentrancyGuard.sol";

contract DepositBridge is ReentrancyGuard {
    address public immutable stone;
    address payable public immutable vault;

    uint16 public immutable dstChainId;

    event BridgeTo(
        address indexed srcAddr,
        bytes dstAddr,
        uint256 etherAmount,
        uint256 stoneAmount,
        uint256 gasPaid
    );

    constructor(address _stone, address payable _vault, uint16 _dstChainId) {
        stone = _stone;
        vault = _vault;

        dstChainId = _dstChainId;
    }

    function bridgeTo(
        uint256 _amount,
        bytes calldata _dstAddress,
        uint256 _gasPaidForCrossChain
    ) public payable returns (uint256 stoneMinted) {
        stoneMinted = bridge(
            msg.sender,
            _amount,
            _dstAddress,
            _gasPaidForCrossChain
        );
    }

    function bridge(
        address _srcAddr,
        uint256 _amount,
        bytes calldata _dstAddress,
        uint256 _gasPaidForCrossChain
    ) public payable nonReentrant returns (uint256 stoneMinted) {
        require(msg.value >= _amount + _gasPaidForCrossChain, "wrong amount");

        IStoneVault stoneVault = IStoneVault(vault);
        stoneMinted = stoneVault.deposit{value: _amount}();

        IStone stoneToken = IStone(stone);
        stoneToken.sendFrom{value: _gasPaidForCrossChain}(
            address(this),
            dstChainId,
            _dstAddress,
            stoneMinted,
            payable(_srcAddr),
            address(0),
            bytes("")
        );

        emit BridgeTo(
            _srcAddr,
            _dstAddress,
            _amount,
            stoneMinted,
            _gasPaidForCrossChain
        );
    }

    function estimateSendFee(
        uint256 _amount,
        bytes calldata _dstAddress
    ) public view returns (uint nativeFee, uint zroFee) {
        return
            IStone(stone).estimateSendFee(
                dstChainId,
                _dstAddress,
                _amount,
                false,
                bytes("")
            );
    }

    receive() external payable {
        bytes memory dstAddr = abi.encodePacked(msg.sender);

        (uint nativeFee, ) = this.estimateSendFee(msg.value, dstAddr);

        require(msg.value > nativeFee, "too little");

        uint256 amount = msg.value - nativeFee;

        this.bridge{value: msg.value}(msg.sender, amount, dstAddr, nativeFee);
    }
}
