pragma solidity ^0.8.0;

import "./Address.sol";
import "./IERC20.sol";
/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.11;

contract split {

    address private constant metavateAddress = 0x8DFdD0FF4661abd44B06b1204C6334eACc8575af;
    address private constant artistAddress1 = 0x6553FD0Ed4f4Bd4B87aed74E95DcC049f5F11A78;
    address private constant artistAddress2 = 0xc7204Fd6A370e9f577e8f9533Fc687f3108A70B2;
    address private constant artistAddress3 = 0xb211499e20c19063f99249B14239a77e0A44408b;
    address private wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 public metavateReceived = 0 ether;
    uint256 private constant metavateCap = 19.998 ether;
    
    modifier onlyTeam {
        require(msg.sender == metavateAddress || msg.sender == artistAddress1 || msg.sender == artistAddress2 || msg.sender == artistAddress3, "Not team" );
        _;
    }

    function withdrawETH() public onlyTeam{
        uint256 initialBalance = address(this).balance;

        require(initialBalance > 0, "Empty balance");
        if (metavateReceived >= metavateCap) { //if metavate already got their cut
            uint256 third = address(this).balance / 3;
            payable(artistAddress1).transfer(third);
            payable(artistAddress2).transfer(third);
            payable(artistAddress3).transfer(third);
        } else if(metavateReceived + (initialBalance * 15 / 100) > metavateCap) { // if this withdraw would put metavate over their cut
            payable(metavateAddress).transfer(metavateCap - metavateReceived); 
            metavateReceived = metavateCap;
            uint256 third = address(this).balance / 3;
            payable(artistAddress1).transfer(third);
            payable(artistAddress2).transfer(third);
            payable(artistAddress3).transfer(third);
        } else {
            payable(metavateAddress).transfer(initialBalance * 15 / 100);
            metavateReceived = metavateReceived + initialBalance * 15 / 100;
            uint256 third = address(this).balance / 3;
            payable(artistAddress1).transfer(third);
            payable(artistAddress2).transfer(third);
            payable(artistAddress3).transfer(third);
        }
    }

    function withdrawWETH() public onlyTeam{
        IERC20 weth = IERC20(wethAddress);
        uint256 initialBalance = weth.balanceOf(address(this));
        require(initialBalance > 0, "Empty balance");
        if (metavateReceived >= metavateCap) { 
            uint256 third = initialBalance / 3;
            weth.transfer(artistAddress1, third);
            weth.transfer(artistAddress2, third);
            weth.transfer(artistAddress3, third);
        } else if(metavateReceived + (initialBalance * 15 / 100) > metavateCap) { 
            payable(metavateAddress).transfer(metavateCap - metavateReceived); 
            metavateReceived = metavateCap;
            uint256 third = weth.balanceOf(address(this)) / 3;
            weth.transfer(artistAddress1, third);
            weth.transfer(artistAddress2, third);
            weth.transfer(artistAddress3, third);
        } else {
            weth.transfer(metavateAddress, initialBalance * 15 / 100);
            metavateReceived = metavateReceived + initialBalance * 15 / 100;
            uint256 third = weth.balanceOf(address(this)) / 3;
            weth.transfer(artistAddress1, third);
            weth.transfer(artistAddress2, third);
            weth.transfer(artistAddress3, third);
        }
    }


    function balanceETH() external view returns(uint256){
        return address(this).balance;
    }

    function balanceWETH() external view returns(uint256){
        return IERC20(wethAddress).balanceOf(address(this));
    }


    fallback() external payable {}
    receive() external payable {}

    }