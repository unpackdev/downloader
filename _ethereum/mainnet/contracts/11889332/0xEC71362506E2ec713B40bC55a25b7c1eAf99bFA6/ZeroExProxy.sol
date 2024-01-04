pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./IZeroEx.sol";
import "./LibBytesV06.sol";
import "./LibProxyRichErrors.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

/// @dev A generic proxy contract which extracts a fee before delegation
contract ZeroExProxy is Ownable {
    using LibBytesV06 for bytes;
    using SafeERC20 for IERC20;

    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    IZeroEx public zeroEx;
    address payable public beneficiary;

    event BeneficiaryChanged(address newBeneficiary);

    /// @dev Construct this contract and specify a fee beneficiary
    constructor(IZeroEx _zeroEx, address payable _beneficiary) public {
        zeroEx = _zeroEx;
        beneficiary = _beneficiary;
    }

    function setBeneficiary(address payable _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
        emit BeneficiaryChanged(_beneficiary);
    }

    /// @dev Forwards calls to the specified implementation contract and extract a fee based on provided arguments
    function swap(bytes calldata _msgData, address _feeToken, address _inputToken, address _outputToken, uint256 _fee) external payable returns (bytes memory) {
        payFees(_feeToken, _fee);
        bytes4 _signature = _msgData.readBytes4(0);
        address _target = zeroEx.getFunctionImplementation(_signature);
        if (_target == address(0)) {
            _revertWithData(LibProxyRichErrors.NotImplementedError(_signature));
        }
        bool _success = false;
        bytes memory _resultData;
        if (_inputToken == ETH_ADDRESS && _feeToken == ETH_ADDRESS && _fee > 0) {
            require(msg.value > _fee);
            (_success, _resultData) = this.externalDelegate{value: msg.value - _fee}(_target, _msgData);
            if (_success) {
                uint256 _tokenBalance = IERC20(_outputToken).balanceOf(address(this));
                if (_tokenBalance > 0) {
                    IERC20(_outputToken).safeTransfer(msg.sender, _tokenBalance);
                }
            }
        } else {
            (_success, _resultData) = _target.delegatecall(_msgData);
        }
        if (!_success) {
            _revertWithData(_resultData);
        }
        _returnWithData(_resultData);
    }

    function externalDelegate(address _target, bytes calldata _msgData) external payable returns (bool, bytes memory) {
        return _target.delegatecall(_msgData);
    }

    /// @dev Fallback for just receiving ether.
    receive() external payable {}

    function payFees(address _token, uint256 _amount) private {
        if (_token == ETH_ADDRESS) {
            return _sendETH(beneficiary, _amount);
        }
        return _sendERC20(IERC20(_token), msg.sender, beneficiary, _amount);
    }

    function _sendETH(address payable _toAddress, uint256 _amount) private {
        if (_amount > 0) {
            (bool _success,) = _toAddress.call{ value: _amount }("");
            require(_success, "Unable to send ETH");
        }
    }

    function _sendERC20(IERC20 _token, address _fromAddress, address _toAddress, uint256 _amount) private {
        if (_amount > 0) {
            _token.safeTransferFrom(_fromAddress, _toAddress, _amount);
        }
    }

    /// @dev Revert with arbitrary bytes.
    /// @param data Revert data.
    function _revertWithData(bytes memory data) private pure {
        assembly { revert(add(data, 32), mload(data)) }
    }

    /// @dev Return with arbitrary bytes.
    /// @param data Return data.
    function _returnWithData(bytes memory data) private pure {
        assembly { return(add(data, 32), mload(data)) }
    }
}