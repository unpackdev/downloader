// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./IRootChainManager.sol";
import "./IL1_Bridge.sol";
import "./errors.sol";

/// @author rimatik
/// @title HydraBridge middleware
contract HydraBridge is Ownable, Pausable {
  using SafeERC20 for IERC20;

    /// Address of polygon bridge root chain manager contract
    address public _polygonRootChainManager;


    /// Address of polygon bridge erc20Predicate contract
    address public _erc20Predicate;


    /// Address of hop bridge contract
    address public _hopBridgeEth;

    /// Address of hop bridge contract
    address public _hopBridgeErc20;


    event MoveCompleted(address, uint256);

    constructor(address polygonRootChainManager, address erc20Predicate, address hopBridgeEth, address hopBridgeErc20) {
        _polygonRootChainManager = polygonRootChainManager;
        _erc20Predicate =  erc20Predicate;
        _hopBridgeEth = hopBridgeEth;
        _hopBridgeErc20 = hopBridgeErc20;
    }

    /// Send funds to polygon bridge
    /// @param recipient address for receiving tokens
    /// @param rootToken address of token to bridge
    /// @param amount of tokens to bridge
    /// @dev transfer tokens to HydraBridge contract and bridge them to polygon
    function sendToPolygon(address recipient, address rootToken, uint256 amount) external whenNotPaused{
        _checkBeforeTransfer(amount, recipient);
         _transferERC20(amount, rootToken, _erc20Predicate, recipient);
        bytes memory depositData = bytes(abi.encode(amount));
        IRootChainManager(_polygonRootChainManager).depositFor(recipient,rootToken,depositData);
        emit MoveCompleted(recipient,amount);
    }

    /// Send eth to polygon bridge
    /// @param recipient address for receiving tokens
     function sendEthToPolygon(address recipient) payable external whenNotPaused {
       _checkBeforeTransfer(msg.value, recipient);
        IRootChainManager(_polygonRootChainManager).depositEtherFor{value: msg.value}(recipient);
        emit MoveCompleted(recipient,msg.value);
    }

    /// Send funds to polygon bridge through hop protocol
    /// @param rootToken address of token to bridge
    /// @param recipient address for receiving tokens
    /// @param chainId number of chain to transfer
    /// @param amount of tokens to bridge
    /// @param amountOutMin minimum tokens received
    /// @param deadline for transfer
    /// @param relayer address of relayer
    /// @param relayerFee fee tha relayer gets
    /// @dev transfer tokens to HydraBridge contract and bridge them to polygon through hop
    function sendToL2Hop(address rootToken, address recipient, uint256 chainId,uint256 amount,uint256 amountOutMin,uint256 deadline,address relayer,uint256 relayerFee) external whenNotPaused {
        _checkBeforeTransfer(amount, recipient);
       _transferERC20(amount, rootToken, _hopBridgeErc20, recipient);
        IL1_Bridge(_hopBridgeErc20).sendToL2(chainId,recipient,amount,amountOutMin,deadline,relayer,relayerFee);
        emit MoveCompleted(recipient,amount);
    }

    /// Send eth to polygon bridge through hop protocol
    /// @param recipient address for receiving tokens
    /// @param chainId number of chain to transfer
    /// @param amountOutMin minimum tokens received
    /// @param deadline for transfer
    /// @param relayer address of relayer
    /// @param relayerFee fee tha relayer gets
    function sendEthToL2Hop(address recipient, uint256 chainId,uint256 amountOutMin,uint256 deadline,address relayer,uint256 relayerFee) payable external whenNotPaused {
        _checkBeforeTransfer(msg.value, recipient);

        IL1_Bridge(_hopBridgeEth).sendToL2{value:msg.value}(chainId,recipient,msg.value,amountOutMin,deadline,relayer,relayerFee);
        emit MoveCompleted(recipient,msg.value);
    }

    /// Check for amount and receiving address before transfer
    /// @param amount to transfer
    /// @param to address to transfer
    function _checkBeforeTransfer(uint256 amount, address to) internal pure {
        require(amount > 0, HydraBridgeErrors.INVALID_AMT);
        require(to != address(0), HydraBridgeErrors.ADDRESS_0_PROVIDED);
    }

    /// Check for amount and receiving address before transfer
    /// @param amount to transfer
    /// @param rootToken address of token to transfer
    /// @param allowanceTarget address for increasing allowance
    /// @param from address from where transfer is made
    function _transferERC20(uint256 amount, address rootToken, address allowanceTarget, address from) internal {
        IERC20(rootToken).safeIncreaseAllowance(allowanceTarget,amount);
        IERC20(rootToken).transferFrom(from,address(this),amount);
    }

    /// Set polygon root chain manager
    /// @param polygonRootChainManager address of root chain manager
    function setRootManager(address polygonRootChainManager) external onlyOwner{
        _polygonRootChainManager = polygonRootChainManager;
    }

    /// Set hop bridge l1 eth address address
    /// @param hopBridgeEth address
    function setHopBridgeEth(address hopBridgeEth) external onlyOwner{
        _hopBridgeEth = hopBridgeEth;
    }

    /// Set hop bridge l1 erc20 address address
    /// @param hopBridgeErc20 address
    function setHopBridgeErc20(address hopBridgeErc20) external onlyOwner{
        _hopBridgeErc20 = hopBridgeErc20;
    }

    /// Set erc20 predicate
    /// @param erc20Predicate address
    function setErc20Predicate(address erc20Predicate) external onlyOwner{
        _erc20Predicate = erc20Predicate;
    }

    /// Disable contract
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// Enable contract
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /// Rescue funds in case they are stuck in contract
    /// @param token to transfer
    /// @param userAddress address of receiver
    /// @param amount to transfer
    function rescueFunds(
        address token,
        address userAddress,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).safeTransfer(userAddress, amount);
    }
}
