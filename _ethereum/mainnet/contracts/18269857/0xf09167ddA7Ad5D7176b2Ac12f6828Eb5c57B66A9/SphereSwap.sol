// File: sphere/implementations/addressesImpl.sol


pragma solidity ^0.8.7;

interface ISphereAddresses {
    function getSphereAddress(string memory _label) external view returns(address);
    function owner() external view returns (address);
}

abstract contract SphereAddressesImpl {
    ISphereAddresses sphereAddresses;

    constructor(address addresses_) {
        sphereAddresses = ISphereAddresses(addresses_);
    }

    function owner() public view returns (address) {
        return sphereAddresses.owner();
    }

    function getSphereAddress(string memory _label) public view returns (address) {
        return sphereAddresses.getSphereAddress(_label);
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyTeam() {
        require(msg.sender == getSphereAddress("team"), "Ownable: caller is not team");
        _;
    }
}
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: @openzeppelin/contracts/interfaces/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;


// File: sphere/sphereSwap.sol


pragma solidity ^0.8.7;



library TransferHelper {
    
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

abstract contract Signatures {

    struct SwapParams {
        address fromToken;
        address toToken;
        address fromAddress;
        address toAddress;
        uint256 amount;
        address aggregator;
        bytes callData;
        bytes sig;
        uint256 sigExpiration;
    }
     
   function verifySignature(SwapParams memory params) internal view returns(address) {
        require(block.timestamp < params.sigExpiration, "Signature has expired");
        bytes32 message = keccak256(abi.encode(params.fromToken, params.toToken, params.fromAddress, params.toAddress, params.amount, params.aggregator, params.callData, params.sigExpiration));
        return recoverSigner(message, params.sig);
   }

   function recoverSigner(bytes32 message, bytes memory sig)
       public
       pure
       returns (address)
     {
       uint8 v;
       bytes32 r;
       bytes32 s;
       (v, r, s) = splitSignature(sig);
       return ecrecover(message, v, r, s);
   }

   function splitSignature(bytes memory sig)
       internal
       pure
       returns (uint8, bytes32, bytes32)
     {
       require(sig.length == 65);

       bytes32 r;
       bytes32 s;
       uint8 v;

       assembly {
           r := mload(add(sig, 32))
           s := mload(add(sig, 64))
           v := byte(0, mload(add(sig, 96)))
       }
 
       return (v, r, s);
   }
}

contract SphereSwap is Signatures, SphereAddressesImpl {

    constructor(address addresses_) SphereAddressesImpl(addresses_) {}

    uint256 public protocolFees = 100;
    uint constant maxAllowance = 2**256 - 1;
    bool public isActive = true;
    address public ethAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function swap(SwapParams[] memory params) public payable  {
        require(isActive, "Contract is not active");
        _verifyValidity(params);
        _receiveTokens(params);
        _settleFees(params);
        _swapTokens(params);
    }

    function _verifyValidity(SwapParams[] memory params) internal view {
        for(uint256 i = 0; i < params.length; i++) {
            require(verifySignature(params[i]) == getSphereAddress("signer"), "Signature not valid");
        }
    }

    function _receiveTokens(SwapParams[] memory params) internal {
        _checkReceiveAmounts(params);
        for(uint256 i = 0; i < params.length; i++) {
            if(params[i].fromToken != ethAddress) {
                TransferHelper.safeTransferFrom(params[i].fromToken, params[i].fromAddress, address(this), params[i].amount);
            }
        }
    }

    function _checkReceiveAmounts(SwapParams[] memory params) internal {
        uint256 totalEth = 0;
        
        for(uint256 i = 0; i < params.length; i++) {
            if(params[i].fromToken == ethAddress) {
                totalEth = totalEth + params[i].amount;
            } else {
                require(IERC20(params[i].fromToken).balanceOf(params[i].fromAddress) >= params[i].amount, "Erc20 caller balance is not correct");
                require(IERC20(params[i].fromToken).allowance(params[i].fromAddress, address(this)) >= params[i].amount, "Erc20 amount is not approved");
            }
        }
        require(msg.value >= totalEth, "Eth amount sent is not correct");
    }

    function _swapTokens(SwapParams[] memory params) internal {
        _checkSwapApprovals(params);

        for(uint256 i = 0; i < params.length; i++) {
            if(params[i].fromToken == ethAddress) {
                (bool success,) = params[i].aggregator.call{value: _amountWithoutFees(params[i].amount)}(params[i].callData);
                require(success, "Swap failed to execute on aggregator");
            } else {
                (bool success,) = params[i].aggregator.call{value: 0}(params[i].callData);
                require(success, "Swap failed to execute on aggregator");
            }
        }
    }

    function _checkSwapApprovals(SwapParams[] memory params) internal {
        uint256 totalEth = 0;

        for(uint256 i = 0; i < params.length; i++) {
            if(params[i].fromToken == ethAddress) {
                totalEth = totalEth + _amountWithoutFees(params[i].amount);
            } else {
                require(IERC20(params[i].fromToken).balanceOf(address(this)) >= _amountWithoutFees(params[i].amount), "Erc20 contract balance is not correct");
                if(IERC20(params[i].fromToken).allowance(address(this), params[i].aggregator) < _amountWithoutFees(params[i].amount)) {
                    _setErc20Allowance(params[i].fromToken, params[i].aggregator);
                }
            }
        }

        require(address(this).balance >= totalEth, "Eth contract balance is not correct");
    }

    function _setErc20Allowance(address tokenAddress, address contractAddress) internal {
        TransferHelper.safeApprove(tokenAddress, contractAddress, maxAllowance);
    }

    function _settleFees(SwapParams[] memory params) internal {
        uint256 totalEth = 0;

        for(uint256 i = 0; i < params.length; i++) {
            if(params[i].fromToken == ethAddress) {
                totalEth = totalEth + _feesAmount(params[i].amount);
            } else {
                TransferHelper.safeTransfer(params[i].fromToken, getSphereAddress("feesWallet"), _feesAmount(params[i].amount));
            }
        }

        TransferHelper.safeTransferETH(getSphereAddress("feesWallet"), totalEth);
    }

    function _amountWithoutFees(uint256 amount) internal view returns (uint256) {
        return amount - ((amount * protocolFees) / 10000);
    }

    function _feesAmount(uint256 amount) internal view returns (uint256) {
        return (amount * protocolFees) / 10000;
    }

    function withdraw(address to, uint256 amount) public onlyOwner {
        require(amount <= address(this).balance);
        payable(to).transfer(amount);
    }

    function withdrawErc20(address token, address to, uint256 amount) public onlyOwner {
        require(IERC20(token).balanceOf(address(this)) >= amount, "Value greater than balance.");
        TransferHelper.safeTransfer(token, to, amount);
    }

    function setProtocolFees(uint256 amount) public onlyTeam {
        protocolFees = amount;
    }

    function switchActive() public onlyTeam {
        isActive = !isActive;
    }

    receive() external payable {}
    fallback() external payable {}
}