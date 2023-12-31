// SPDX-License-Identifier: MIT

import "./AxelarExecutable.sol";
import "./IAxelarGasService.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";

pragma solidity ^0.8.7;

contract YelBridger is AxelarExecutable, Ownable, Pausable {
    using SafeERC20 for IERC20;

    address public immutable yel;

    error AlreadyInitialized();

    mapping(address => uint) public balances;
    mapping(string => address) public trustRemoteAddr;

    IAxelarGasService public immutable gasService;

    event Bridged(string dstChain, uint amount, address sender);
    event Withdraw(uint amount, address user);
    event YelBridged(address user, uint amount);

    constructor(address yel_, address gasReceiver_, address gateway_) AxelarExecutable(gateway_) {
        yel = yel_;

        gasService = IAxelarGasService(gasReceiver_);
    }

    function setTrustRemote(address _trustRemoteAddr, string calldata _remoteChain) external onlyOwner {
      if(trustRemoteAddr[_remoteChain] == address(0)) {
        trustRemoteAddr[_remoteChain] = _trustRemoteAddr;
      } else {
        revert AlreadyInitialized();
      }
    }

    function bridgeYel(string memory _destinationChain, string memory _destinationAddress, uint _amount) external payable whenNotPaused {
        IERC20(yel).safeTransferFrom(msg.sender, address(this), _amount);
        bytes memory payload = abi.encode(msg.sender, _amount, _destinationAddress);

        gasService.payNativeGasForContractCall{ value: msg.value }(address(this), _destinationChain, _destinationAddress, payload, msg.sender);
        gateway.callContract(_destinationChain, _destinationAddress, payload);

        emit Bridged(_destinationChain, _amount, msg.sender);
    }

    function withdrawYel(uint _amount) external whenNotPaused {
        uint balance = balances[msg.sender];
        require(balance >= _amount, "Not enough yel");
        uint balanceYel = balanceYelThisChain();
        uint availableToClaim;

        if (balanceYel <= _amount) {
            availableToClaim = balanceYel;
        } else if(balanceYel >= _amount) {
            availableToClaim = _amount;
        }

        balances[msg.sender] = balance - availableToClaim;
        IERC20(yel).safeTransfer(msg.sender, availableToClaim);

        emit Withdraw(availableToClaim, msg.sender);
    }

    function relayToAnotherChain(string memory _destinationChain, string memory _destinationAddress, uint _amount) external payable whenNotPaused {
        uint balance = balances[msg.sender];
        require(balance >= _amount, "Not enough yel");

        balances[msg.sender] = balance - _amount;

        bytes memory payload = abi.encode(msg.sender, _amount, _destinationAddress);

        gasService.payNativeGasForContractCall{ value: msg.value }(address(this), _destinationChain, _destinationAddress, payload, msg.sender);
        gateway.callContract(_destinationChain, _destinationAddress, payload);

        emit Bridged(_destinationChain, _amount, msg.sender);
    }

    function _execute(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) internal override {
        address trustedSender = trustRemoteAddr[sourceChain];
        address decodedSourceAddress;

        assembly {
            let offset := sourceAddress.offset
            let length := sourceAddress.length

            calldatacopy(
                decodedSourceAddress,
                offset,
                length
            )
        }

        require(decodedSourceAddress != trustedSender, 'Not trusted sender');
        (address user, uint256 amount, address destinationAddress) = abi.decode(
            payload,
            (address, uint256, address)
        );

        balances[user] += amount;

        emit YelBridged(user, amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function balanceYelThisChain() public view returns (uint256) {
        return IERC20(yel).balanceOf(address(this));
    }

    function inCaseTokensGetStuck(address _token, uint _amount) external onlyOwner {
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }
}