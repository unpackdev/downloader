// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface Token {
    function transfer(address _to, uint256 _value) external view returns (bool);
    function balanceOf(address _owner) external view returns (uint256);
}
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}
library TransferHelper {
    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "STF");
    }
    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "ST");
    }
    function safeApprove(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SA");
    }
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

contract BatchTransferPublic {
    address public owner; // 创建者

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // 批量转账ERC20代币
    function batchTransferErc20(
        address[] memory _to,
        address _token,
        uint256 amount
    ) external payable {
        require(_to.length != 0, "To address null");
        uint256 val = amount / _to.length;
        uint256 remaining = amount % _to.length;

        for (uint256 j = 0; j < _to.length; ++j) {
            address payable to = payable(_to[j]);

            require(to != address(0), "Invalid address"); // 地址有效性检查
            
            uint256 amountToSend = j == _to.length - 1 ? val + remaining : val;
            TransferHelper.safeTransferFrom(_token, msg.sender, to, amountToSend);
            emit TransferErc20(_token, to, amountToSend); // 触发事件
        }
    }

    // 批量转账ETH
    function batchTransferETH(address[] memory _to) external payable {
        require(_to.length != 0, "To address null");
        // 将重复的计算移到循环外部，以减少Gas消耗。
        uint256 val = msg.value / _to.length;
        uint256 remainingETH = msg.value % _to.length;

        for (uint256 j = 0; j < _to.length; ++j) {
            address payable to = payable(_to[j]);

            require(to != address(0), "Invalid address"); // 地址有效性检查

            uint256 amountToSend = j == _to.length - 1 ? val + remainingETH : val;
            TransferHelper.safeTransferETH(to, amountToSend);
            emit TransferEth(to, amountToSend); // 触发事件
        }
    }

    // 主币转出（转出地址）
    function baseBack() external payable onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    // 合约转出（转出代币）
    function tokenBack(address _token) external onlyOwner {
        require(_token != address(0x0), "Token address null");
        uint256 amount = Token(_token).balanceOf(address(this));
        address payable to = payable(owner);
        TransferHelper.safeTransfer(_token, address(to), amount);
    }

    // 添加事件日志，记录ERC20代币和ETH的转账操作，以增强合约的透明度。
    event TransferErc20(address indexed token, address indexed to, uint256 value);
    event TransferEth(address indexed to, uint256 value);
}