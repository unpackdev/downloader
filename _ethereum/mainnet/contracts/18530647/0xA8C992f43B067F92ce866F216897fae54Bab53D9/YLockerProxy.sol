// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import "./SafeERC20.sol";

interface ILocker {
    function safeExecute(
        address payable _to,
        uint256 _value,
        bytes calldata _data
    ) external returns (bool success, bytes memory result);

    function governance() external view returns (address);
}

contract YLockerProxy {
    using SafeERC20 for IERC20;

    event TokenCollectorUpdated(address indexed collector, bool indexed approved);

    address public constant escrow = 0x3f78544364c3eCcDCe4d9C89a630AEa26122829d;
    address public constant ylocker = 0x90be6DFEa8C80c184C442a36e17cB2439AAE25a7;
    mapping(address => bool) tokenCollector;

    // Sweep tokens
    function collectTokensFromLocker(address _token, uint _amount, address _recipient) external returns (uint) {
        require(
            tokenCollector[msg.sender] ||
            msg.sender == ILocker(ylocker).governance()
            , "!authorized"
        );
        bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", _recipient, _amount);
        ILocker(ylocker).safeExecute(payable(_token), 0, data);
        return _amount;
    }

    //give an address access to sweep tokens
    function approveTokenCollector(address _collector, bool _approved) external {
        require(msg.sender == ILocker(ylocker).governance(), "!authorized");
        tokenCollector[_collector] = _approved;
        emit TokenCollectorUpdated(_collector, _approved);
    }
}