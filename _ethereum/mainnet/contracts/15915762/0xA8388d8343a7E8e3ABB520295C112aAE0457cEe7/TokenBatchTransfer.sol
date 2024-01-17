pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./TransferHelper.sol";
import "./IERC20.sol";

contract TokenBatchTransfer {

    using TransferHelper for address;
    using TransferHelper for IERC20;
    using SafeMath for uint256;

    event BatchTransfer(address  token, uint256 total);
    event TokenWithdrawn(address token, address operator, address to, uint256 total);
    event TokenSent(address from, address to, uint256 value);
    
    address public owner;
    uint256 public txFee = 0 ether;

    function initialize() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

    function setTxFee(uint256 _fee) onlyOwner public {
        txFee = _fee;
    }

    function withdrawETH(address _to) external onlyOwner {
        require(_to != address(0), "invalid amount");

        uint256 _balance = address(this).balance;
        address(_to).safeTransferETH(_balance);
        
        emit TokenWithdrawn(0x0000000000000000000000000000000000000000, msg.sender, _to, _balance);
    }

    function withdrawToken(address _tokenAddress, address _to) external onlyOwner {
        require(_to != address(0), "invalid amount");

        IERC20 token = IERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(_to, balance);

        emit TokenWithdrawn(_tokenAddress, msg.sender, _to, balance);
    }

    function ethSend(address[] memory _to, uint256[] memory _value) internal {
        uint256 remainingValue = msg.value;
        require(_to.length == _value.length, "invalid array");
        require(_to.length <= 255, "invalid array");

        for (uint8 i = 0; i < _to.length; i++) {
            remainingValue = remainingValue.sub(_value[i]);
            address(_to[i]).safeTransferETH(_value[i]);
            emit TokenSent(msg.sender, _to[i], _value[i]);
        }
        require(remainingValue >= txFee, "invalid amount");

        emit BatchTransfer(0x0000000000000000000000000000000000000000, msg.value);
    }

    function tokenSend(address _tokenAddress, address[] memory _to, uint256[] memory _value) internal {
        uint sendValue = msg.value;
        require(sendValue >= txFee, "invalid amount");

        uint256 sendAmount = 0;
        require(_to.length == _value.length, "invalid array");
        require(_to.length <= 255, "invalid array");

        IERC20 token = IERC20(_tokenAddress);
        for (uint8 i = 0; i < _to.length; i++) {
            sendAmount = sendAmount.add(_value[i]);
            token.safeTransferFrom(msg.sender, _to[i], _value[i]);
            emit TokenSent(msg.sender, _to[i], _value[i]);
        }
        emit BatchTransfer(_tokenAddress, sendAmount);
    }

    function batchTransfer(address[] memory _to, uint256[] memory _value) payable public {
        ethSend(_to, _value);
    }

    function batchTransferToken(address _tokenAddress, address[] memory _to, uint256[] memory _value) payable public {
        tokenSend(_tokenAddress, _to, _value);
    }

}