// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC20Permit {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(
        bytes memory returndata,
        string memory errorMessage
    ) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                oldAllowance + value
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    oldAllowance - value
                )
            );
        }
    }

    function forceApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        bytes memory approvalCall = abi.encodeWithSelector(
            token.approve.selector,
            spender,
            value
        );

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(token.approve.selector, spender, 0)
            );
            _callOptionalReturn(token, approvalCall);
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(
            nonceAfter == nonceBefore + 1,
            "SafeERC20: permit did not succeed"
        );
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        require(
            returndata.length == 0 || abi.decode(returndata, (bool)),
            "SafeERC20: ERC20 operation did not succeed"
        );
    }

    function _callOptionalReturnBool(
        IERC20 token,
        bytes memory data
    ) private returns (bool) {
        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success &&
            (returndata.length == 0 || abi.decode(returndata, (bool))) &&
            Address.isContract(address(token));
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract Controller is Ownable {
    event ControllerAdded(address controller);
    event ControllerRemoved(address controller);
    mapping(address => bool) controllers;
    uint8 public controllerCnt = 0;

    modifier onlyController() {
        require(isController(_msgSender()), "no controller rights");
        _;
    }

    function isController(address _controller) public view returns (bool) {
        return _controller == owner() || controllers[_controller];
    }

    function addController(address _controller) public onlyOwner {
        if (controllers[_controller] == false) {
            controllers[_controller] = true;
            controllerCnt++;
        }
        emit ControllerAdded(_controller);
    }

    function removeController(address _controller) public onlyOwner {
        if (controllers[_controller] == true) {
            controllers[_controller] = false;
            controllerCnt--;
        }
        emit ControllerRemoved(_controller);
    }
}

library TransferHelper {
    function safeTransferNative(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: NATIVE_TRANSFER_FAILED");
    }
}

contract MinterProxy is Controller {
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;

    address public immutable NATIVE;

    uint256 MAX_UINT256 =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    mapping(uint256 => bool) public completedOrder;

    address public liquidpool;

    event LogVaultIn(
        address indexed token,
        uint256 indexed orderID,
        address indexed receiver,
        uint256 amount
    );
    event LogVaultOut(
        address indexed token,
        address indexed from,
        uint256 fromChainID,
        uint256 amount,
        string toChain,
        string toAddr
    );

    event LogVaultCall(
        address indexed target,
        uint256 amount,
        bool success,
        bytes reason
    );

    constructor(address _NATIVE, address _liquidpool) {
        require(_NATIVE != address(0), "MP: NATIVE is empty");
        require(_liquidpool != address(0), "MP: Liquidpool is empty");
        NATIVE = _NATIVE;
        liquidpool = _liquidpool;
    }

    receive() external payable {}

    fallback() external payable {}

    function chainID() public view returns (uint) {
        return block.chainid;
    }

    function setLiquidpool(address _liquidpool) external onlyOwner {
        require(_liquidpool != address(0), "MP: Liquidpool is empty");
        liquidpool = _liquidpool;
    }

    function isUUIDCompleted(uint256 uuid) external view returns (bool) {
        return completedOrder[uuid];
    }

    function _registerOrder(uint256 uuid) internal {
        require(!completedOrder[uuid], "MP: already completed");
        completedOrder[uuid] = true;
    }

    function _balanceOf(address receiveToken) internal view returns (uint256) {
        uint256 _balance;
        if (receiveToken == NATIVE) {
            _balance = address(this).balance;
        } else {
            _balance = IERC20(receiveToken).balanceOf(address(liquidpool));
        }
        return _balance;
    }

    function _balanceOfSelf(
        address receiveToken
    ) internal view returns (uint256) {
        uint256 _balance;
        if (receiveToken == NATIVE) {
            _balance = address(this).balance;
        } else {
            _balance = IERC20(receiveToken).balanceOf(address(this));
        }
        return _balance;
    }

    function vaultIn(
        uint256 orderID,
        address tokenAddr,
        address toAddr,
        uint256 amount
    ) external onlyController {
        _registerOrder(orderID);
        require(_balanceOf(tokenAddr) >= amount, "MP: insufficient balance");
        if (tokenAddr == NATIVE) {
            TransferHelper.safeTransferNative(toAddr, amount);
        } else {
            IERC20(tokenAddr).safeTransferFrom(liquidpool, toAddr, amount);
        }
        emit LogVaultIn(tokenAddr, orderID, toAddr, amount);
    }

    function vaultInAndCall(
        uint256 orderID,
        address tokenAddr,
        address toAddr,
        uint256 amount,
        bool isNative,
        address receiver,
        address receiveToken,
        bytes calldata data
    ) external onlyController {
        require(_balanceOf(tokenAddr) >= amount, "MP: insufficient balance");
        require(
            (receiveToken == NATIVE) == isNative,
            "MP: insufficient balance"
        );
        require(data.length > 0, "MP: data empty");
        _registerOrder(orderID);
        bool fromTokenNative = tokenAddr == NATIVE;
        if (!fromTokenNative) {
            IERC20(tokenAddr).safeTransferFrom(
                liquidpool,
                address(this),
                amount
            );
            if (IERC20(tokenAddr).allowance(address(this), toAddr) < amount) {
                IERC20(tokenAddr).approve(toAddr, MAX_UINT256);
            }
        }

        uint256 amountOut = _callAndTransfer(
            toAddr,
            fromTokenNative ? amount : 0,
            isNative,
            receiver,
            receiveToken,
            data
        );

        emit LogVaultIn(receiveToken, orderID, receiver, amountOut);
    }

    function call(
        address _target,
        bytes calldata _data
    ) external payable onlyController {
        (bool success, bytes memory result) = _target.call{value: msg.value}(
            _data
        );
        emit LogVaultCall(_target, msg.value, success, result);
    }

    function _callAndTransfer(
        address contractAddr,
        uint256 fromNativeAmount,
        bool isNative,
        address receiver,
        address receiveToken,
        bytes calldata data
    ) internal returns (uint256) {
        uint256 old_balance = _balanceOfSelf(receiveToken);

        if (fromNativeAmount > 0) {
            // address payable to = payable(contractAddr);
            contractAddr.functionCallWithValue(
                data,
                fromNativeAmount,
                "MP: callAndTransfer failed"
            );
        } else {
            contractAddr.functionCall(data, "MP: callAndTransfer failed");
        }

        uint256 new_balance = _balanceOfSelf(receiveToken);
        require(new_balance > old_balance, "MP: receiver should get assets");
        uint256 amountOut = new_balance - old_balance;

        if (receiver != address(this)) {
            if (isNative) {
                TransferHelper.safeTransferNative(receiver, amountOut);
            } else {
                IERC20(receiveToken).safeTransfer(receiver, amountOut);
            }
        }
        return amountOut;
    }

    function withdrawFee(
        address token,
        uint256 amount
    ) external onlyController {
        if (token == NATIVE) {
            uint256 balance = address(this).balance;
            uint256 tmp = balance > amount ? amount : balance;
            TransferHelper.safeTransferNative(owner(), tmp);
        } else {
            uint256 balance = IERC20(token).balanceOf(address(this));
            uint256 tmp = balance > amount ? amount : balance;
            IERC20(token).safeTransfer(owner(), tmp);
        }
    }
}