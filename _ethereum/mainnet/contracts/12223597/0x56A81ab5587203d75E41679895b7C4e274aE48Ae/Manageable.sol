pragma solidity ^0.6.2;

import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract Manageable is Ownable, Pausable {
    using SafeERC20 for IERC20;

    mapping(address => bool) public _operators;

    modifier onlyOperator() {
        require(_operators[msg.sender], "!operator");
        _;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function addOperator(address _operator) public onlyOwner {
        _operators[_operator] = true;
    }

    function removeOperator(address _operator) public onlyOwner {
        _operators[_operator] = false;
    }

    function fetchBalance(address _tokenAddress, address _receiverAddress) public onlyOwner {
        if (_receiverAddress == address(0)) {
            _receiverAddress = owner();
        }
        if (_tokenAddress == address(0)) {
            require(payable(_receiverAddress).send(address(this).balance));
            return;
        }
        IERC20(_tokenAddress).safeTransfer(_receiverAddress, IERC20(_tokenAddress).balanceOf(address(this)));
    }
}
