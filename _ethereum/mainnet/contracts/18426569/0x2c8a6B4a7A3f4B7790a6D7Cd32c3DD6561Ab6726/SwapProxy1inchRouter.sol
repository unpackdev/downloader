// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "IERC20.sol";
import "SafeERC20.sol";
import "Operator.sol";
import "Address.sol";

contract SwapProxy1inchRouter is Operator {

    using SafeERC20 for IERC20;

    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address payable srcReceiver;
        address payable dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
    }

    address public CRV = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address public CVX = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address public STBT = 0x530824DA86689C9C17CdC2871Ff29B058345b44a;
    address public DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    address[] public receiveTokenList;

    event VaultUpdated(address indexed _vault);
    event ExecuteFailed(uint256 indexed time, address fromTokenAddress, address toTokenAddress, uint256 amount, bytes data);
    event ExecuteSucceeded(uint256 indexed time, address fromTokenAddress, address toTokenAddress, uint256 amount, bytes data);
    event ReceiveTokenListUpdated(uint256 indexed at, address[] newReceiveTokenList);

    receive() external payable {}
    
    function checkReceiveTokenList(address token) public view returns (bool) {
        uint length = receiveTokenList.length;
        for (uint i = 0; i < length; i++) {
            if (token == receiveTokenList[i])
                return true;
        }
        return false;
    }

    function getAllReceiveTokenList() public view returns (address[] memory) {
        return receiveTokenList;
    }

    function executeWithData(
        address externalRouter, 
        address fromTokenAddress, 
        address toTokenAddress, 
        uint256 amount, 
        address receiver, 
        bytes calldata data, 
        bool restriction
    ) external payable {
        (, SwapDescription memory desc, , ) = abi.decode(data[4:], (address, SwapDescription, bytes, bytes));
        require(fromTokenAddress == address(desc.srcToken), "from token address mismatch");
        require(toTokenAddress == address(desc.dstToken), "to token address mismatch");
        require(receiver == address(desc.dstReceiver), "receiver address mismatch");
        require(amount == desc.amount, "token amount mismatch");
        if (restriction == true) {
            require(checkReceiveTokenList(toTokenAddress) == true, "token address beyond the token list");
        }
        IERC20(desc.srcToken).safeTransferFrom(msg.sender, address(this), desc.amount);
        IERC20(desc.srcToken).safeApprove(externalRouter, 0);
        IERC20(desc.srcToken).safeApprove(externalRouter, desc.amount);

        (bool success, bytes memory _data) = address(externalRouter).call(data);
        if (success) {
            emit ExecuteSucceeded(block.number, fromTokenAddress, toTokenAddress, amount, _data);
        } else {
            emit ExecuteFailed(block.number, fromTokenAddress, toTokenAddress, amount, _data);
            revert();
        }   
    }

    function updateReceiveTokenList(address[] memory newReceiveTokenList) public onlyOperator {
        delete receiveTokenList;
        uint256 length = newReceiveTokenList.length;
        for (uint256 pid = 0; pid < length; pid++) {
            receiveTokenList.push(newReceiveTokenList[pid]);
        }
        emit ReceiveTokenListUpdated(block.number, newReceiveTokenList);
    }

    function governanceWithdrawFunds(address _token, uint256 amount, address to) external onlyOperator {
        require(to != address(0), "to address can not be zero address");
        IERC20(_token).safeTransfer(to, amount);
    }

    function governanceWithdrawFundsETH(uint256 amount, address to) external onlyOperator {
        require(to != address(0), "to address can not be zero address");
        Address.sendValue(payable(to), amount);
    }
}
