// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ITangoFactory.sol";
import "./ITangoRouter.sol";

contract TangoRouter is Ownable, ITangoRouter { 
    using SafeERC20 for IERC20;
    address public secretBridge;
    mapping (address => address) public secretStategies;

    event SecretInvest(address _token, uint256 _amount);
    event SecretWithdraw(address _token, uint256 _amount);
    function invest(address _token, uint256 _amount) external override {
        address stategy = secretStategies[_token];
        require(stategy != address(0), "Invalid-token");
        require(msg.sender == secretBridge, "Only-secret-can-call");
        IERC20(_token).safeTransferFrom(msg.sender, stategy, _amount);
        ITangoFactory(stategy).secretInvest(msg.sender, _token, _amount);
        emit SecretInvest(_token, _amount);
    }

    function withdraw(address _token, uint256 _amount) external override { 
        address stategy = secretStategies[_token];
        require(stategy != address(0), "Invalid-token");
        require(msg.sender == secretBridge, "Only-secret-can-call");
        ITangoFactory(stategy).secretWithdraw(msg.sender, _amount);
        emit SecretWithdraw(_token, _amount);
    }

    function adminAddStrategies(address _token, address _factory) external onlyOwner() {
        require(secretStategies[_token] == address(0), "Duplicate");
        secretStategies[_token] = _factory;
    }

    function adminRemoveStategies(address _token) external onlyOwner() {
        require(secretStategies[_token] != address(0),"Invalid-token-address");
        delete secretStategies[_token];
    }

    function setSecretAddress(address _secretAddress) external onlyOwner() {
        secretBridge = _secretAddress;
    }
}