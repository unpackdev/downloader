// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Tokens.sol";
import "./IERC20.sol";

function _getBalance(address token, address user) view returns (uint256) {
    if (token == address(0)) return 0;
    return token == NATIVE_TOKEN ? user.balance : IERC20(token).balanceOf(user);
}

function _simulateAndRevert(
    address _service,
    uint256 _gasleft,
    bytes memory _data
) {
    assembly {
        let success := call(
            gas(),
            _service,
            0,
            add(_data, 0x20),
            mload(_data),
            0,
            0
        )

        mstore(0x00, success) // store success bool in first word
        mstore(0x20, sub(_gasleft, gas())) // store gas after success
        mstore(0x40, returndatasize()) // store length of return data size in third word
        returndatacopy(0x60, 0, returndatasize()) // store actual return data in fourth word and onwards
        revert(0, add(returndatasize(), 0x60))
    }
}

function _revert(
    bool _success,
    bytes memory _returndata,
    uint256 _estimatedGasUsed
) pure {
    bytes memory revertData = bytes.concat(
        abi.encode(_success, _estimatedGasUsed, _returndata.length),
        _returndata
    );
    assembly {
        revert(add(32, revertData), mload(revertData))
    }
}

function _revertWithFee(
    bool _success,
    bytes memory _returndata,
    uint256 _estimatedGasUsed,
    uint256 _observedFee
) pure {
    bytes memory revertData = bytes.concat(
        abi.encode(
            _success,
            _estimatedGasUsed,
            _observedFee,
            _returndata.length
        ),
        _returndata
    );
    assembly {
        revert(add(32, revertData), mload(revertData))
    }
}

function _revertWithFeeAndIsFeeCollector(
    bool _success,
    bool _isFeeCollector,
    bytes memory _returndata,
    uint256 _estimatedGasUsed,
    uint256 _observedFee
) pure {
    bytes memory revertData = bytes.concat(
        abi.encode(
            _success,
            _estimatedGasUsed,
            _observedFee,
            _isFeeCollector,
            _returndata.length
        ),
        _returndata
    );
    assembly {
        revert(add(32, revertData), mload(revertData))
    }
}
