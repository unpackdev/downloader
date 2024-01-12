// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Strings.sol";
import "./Address.sol";

import "./BaseSupport.sol";
import "./BytesLib.sol";
import "./I1inchSupport.sol";

contract OneinchSupport is BaseSupport, I1inchSupport {
    using BytesLib for bytes;
    using SafeMath for uint256;

    struct SwapDescription {
        address srcToken;
        address dstToken;
        address payable srcReceiver;
        address payable dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
        bytes permit;
    }

    uint32 private constant INCH_UNI2_SELECTOR = uint32(0x2e95b6c8);
    uint32 private constant INCH_UNI3_SELECTOR = uint32(0xe449022e);
    uint32 private constant INCH_OTHER_SELECTOR = uint32(0x7c025200);

    address public immutable inchRouter;

    constructor(address _inchRouter) {
        inchRouter = _inchRouter;
    }

    function inchSwap(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _minReturn,
        bytes memory _inData
    ) external payable override returns (uint256 _returns) {
        if (_from != ETH) {
            IERC20(_from).transferFrom(msg.sender, address(this), _amount);
        } else {
            require(msg.value >= _amount, "OneinchSupport: msg.value not enough");
        }
        _returns = inchSwapNoHandle(_from, _amount, _inData);
        require(_returns >= _minReturn, "OneinchSupport: _returns < _minReturn");
        if (_to == ETH) {
            payable(msg.sender).transfer(_returns);
        } else {
            SafeERC20.safeTransfer(IERC20(_to), msg.sender, _returns);
        }
    }

    ///@dev Only used as an implementation
    function inchSwapNoHandle(
        address _from,
        uint256 _amount,
        bytes memory _inData
    ) public payable override returns (uint256) {
        bool success;
        bytes memory data;
        if (_from != ETH) {
            _safeApprove(IERC20(_from), inchRouter, _amount);
            (success, data) = inchRouter.call(_inData);
        } else {
            (success, data) = inchRouter.call{ value: _amount }(_inData);
        }
        string memory reason;
        if (!success) reason = abi.decode(Address.verifyCallResult(success, data, "OneinchSupport: _inchSwap not get error"), (string));
        require(success, reason);
        return abi.decode(data, (uint256));
    }

    function modifyOneinchAmount(bytes memory _data, uint256 _amount) external pure override returns (bytes memory) {
        uint32 _selector = _data.slice(0, 4).toUint32(0);
        bytes memory _input = _data.slice(4, _data.length - 4);
        if (_selector == INCH_UNI2_SELECTOR) {
            return _modifyOneinchUni2Amount(_input, _amount);
        }
        if (_selector == INCH_UNI3_SELECTOR) {
            return _modifyOneinchUni3Amount(_input, _amount);
        }
        if (_selector == INCH_OTHER_SELECTOR) {
            return _modifyOneinchOtherAmount(_input, _amount);
        }
        require(false, string(abi.encodePacked("OneinchSupport: Not yet supported selector: ", Strings.toString(_selector))));
        return _data;
    }

    function _modifyOneinchUni2Amount(bytes memory _data, uint256 _amount) private pure returns (bytes memory) {
        (address _srcToken, uint256 _oldAmount, uint256 _minReturn, bytes32[] memory _pools) = abi.decode(_data, (address, uint256, uint256, bytes32[]));
        if (_amount < _oldAmount) {
            _minReturn = _handMinreturn(_oldAmount, _amount, _minReturn);
        }
        bytes memory _newData = abi.encode(_srcToken, _amount, _minReturn, _pools);
        return abi.encodePacked(INCH_UNI2_SELECTOR, _newData);
    }

    function _modifyOneinchUni3Amount(bytes memory _data, uint256 _amount) private pure returns (bytes memory) {
        (uint256 _oldAmount, uint256 _minReturn, uint256[] memory _pools) = abi.decode(_data, (uint256, uint256, uint256[]));
        if (_amount < _oldAmount) {
            _minReturn = _handMinreturn(_oldAmount, _amount, _minReturn);
        }
        bytes memory _newData = abi.encode(_amount, _minReturn, _pools);
        return abi.encodePacked(INCH_UNI3_SELECTOR, _newData);
    }

    function _modifyOneinchOtherAmount(bytes memory _data, uint256 _amount) private pure returns (bytes memory) {
        (address _caller, SwapDescription memory _desc, bytes memory _originData) = abi.decode(_data, (address, SwapDescription, bytes));
        if (_amount < _desc.amount) {
            _desc.minReturnAmount = _handMinreturn(_desc.amount, _amount, _desc.minReturnAmount);
        }
        _desc.amount = _amount;
        bytes memory _newData = abi.encode(_caller, _desc, _originData);
        return abi.encodePacked(INCH_OTHER_SELECTOR, _newData);
    }

    function _handMinreturn(
        uint256 _oldAmount,
        uint256 _newAmount,
        uint256 _minReturn
    ) private pure returns (uint256) {
        return _minReturn.sub(_oldAmount.sub(_newAmount).mul(_minReturn).div(_oldAmount)).sub(1000);
    }
}
