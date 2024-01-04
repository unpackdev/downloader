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
    using SafeMath for uint256;

    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant NULL_ADDRESS = 0x0000000000000000000000000000000000000000;
    uint256 private constant MAX_UINT = 2**256 - 1;

    IZeroEx public zeroEx;
    address payable public beneficiary;
    mapping(bytes4 => address) implementationOverrides;

    event BeneficiaryChanged(address newBeneficiary);
    event ImplementationOverrideSet(bytes4 signature, address implementation);

    /// @dev Construct this contract and specify a fee beneficiary
    constructor(IZeroEx _zeroEx, address payable _beneficiary) public {
        zeroEx = _zeroEx;
        beneficiary = _beneficiary;
    }

    function setBeneficiary(address payable _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
        emit BeneficiaryChanged(_beneficiary);
    }

    function setImplementationOverride(bytes4 _signature, address _implementation) public onlyOwner {
        implementationOverrides[_signature] = _implementation;
        emit ImplementationOverrideSet(_signature, _implementation);
    }

    /// @dev Delegates calls to the specified implementation contract and extracts a fee based on provided arguments
    /// @param _msgData The byte data representing a swap using the original ZeroEx contract. This is either recieved from the 0x API directly or we construct it in order to perform a Uniswap trade
    /// @param _feeToken The ERC20 we wish to extract a user fee from. If this is ETH it should be the standard 0xeee ETH address
    /// @param _fee Fee amount collected and sent to the beneficiary
    function optimalSwap(bytes calldata _msgData, address _feeToken, uint256 _fee) external payable returns (bytes memory) {
        payFees(_feeToken, _fee);
        bytes4 _signature = _msgData.readBytes4(0);
        address _target = getFunctionImplementation(_signature);
        if (_target == address(0)) {
            _revertWithData(LibProxyRichErrors.NotImplementedError(_signature));
        }
        (bool _success, bytes memory _resultData) = _target.delegatecall(_msgData);
        if (!_success) {
            _revertWithData(_resultData);
        }
        _returnWithData(_resultData);
    }

    /// @dev Forwards calls to the zeroEx contract and extracts a fee based on provided arguments
    /// @param _msgData The byte data representing a swap using the original ZeroEx contract. This is either recieved from the 0x API directly or we construct it in order to perform a Uniswap trade
    /// @param _feeToken The ERC20 we wish to extract a user fee from. If this is ETH it should be the standard 0xeee ETH address
    /// @param _inputToken The ERC20 the user is selling. If this is ETH it should be the standard 0xeee ETH address
    /// @param _inputAmount The amount of _inputToken being sold
    /// @param _outputToken The ERC20 the user is buying. If this is ETH it should be the standard 0xeee ETH address
    /// @param _fee Fee amount collected and sent to the beneficiary
    function proxiedSwap(bytes calldata _msgData, address _feeToken, address _inputToken, uint256 _inputAmount, address _outputToken, uint256 _fee) external payable returns (bytes memory) {
        payFees(_feeToken, _fee);
        uint256 _value = 0;
        if (_inputToken == ETH_ADDRESS) {
            _value = msg.value.sub(_fee);
        } else {
            _sendERC20(IERC20(_inputToken), msg.sender, address(this), _inputAmount);
            if (IERC20(_inputToken).allowance(address(this), address(zeroEx)) == 0) {
                IERC20(_inputToken).safeApprove(address(zeroEx), MAX_UINT);
            }
        }
        (bool _success, bytes memory _resultData) = address(zeroEx).call{value: _value}(_msgData);
        if (!_success) {
            _revertWithData(_resultData);
        }
        if (_outputToken == ETH_ADDRESS) {
            if (address(this).balance>0) {
                _sendETH(msg.sender, address(this).balance);
            } else {
                _revertWithData(_resultData);
            }
        } else {
            uint256 _tokenBalance = IERC20(_outputToken).balanceOf(address(this));
            if (_tokenBalance > 0) {
                IERC20(_outputToken).safeTransfer(msg.sender, _tokenBalance);
            } else {
                _revertWithData(_resultData);
            }
        }
        _returnWithData(_resultData);
    }

    function getFunctionImplementation(bytes4 _signature) public returns (address _impl) {
        _impl = implementationOverrides[_signature];
        if (_impl == NULL_ADDRESS) {
            _impl = zeroEx.getFunctionImplementation(_signature);
        }
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