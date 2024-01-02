// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// Standard IERC20 interface
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/// Second part of the router interface of uniswap and forks
interface IUniswapV2Router02 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

/// Interface for the pairs of uniswap and forks
interface IPair {
    function burn(address to) external returns (uint amount0, uint amount1);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns(address);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
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

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

/// Transfer Helper to ensure the correct transfer of the tokens or ETH
library SafeTransfer {
    using Address for address;
    /** Safe Transfer asset from one wallet with approval of the wallet
    * @param erc20: the contract address of the erc20 token
    * @param from: the wallet to take from
    * @param amount: the amount to take from the wallet
    **/
    function _pullUnderlying(IERC20 erc20, address from, uint amount) internal
    {
        safeTransferFrom(erc20,from,address(this),amount);
    }

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

    /** Safe Transfer asset to one wallet from within the contract
    * @param erc20: the contract address of the erc20 token
    * @param to: the wallet to send to
    * @param amount: the amount to send from the contract
    **/
    function _pushUnderlying(IERC20 erc20, address to, uint amount) internal
    {
        safeTransfer(erc20,to,amount);
    }

    /** Safe Transfer ETH to one wallet from within the contract
    * @param to: the wallet to send to
    * @param value: the amount to send from the contract
    **/
    function safeTransferETH(address to, uint256 value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    uint256 private _status2;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "reentry");
        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

contract LPLoanRepayment is ReentrancyGuard{
    mapping(address => bool) public agreed;
    address public constant LP = 0x60EF1e0Bf9218Cdc1769a43c4B0B111ed38BB418;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant FEG = 0xbededDf2eF49E87037c4fb2cA34d1FF3D3992A11;
    address private _FEGlocation;
    address public constant withdrawalAddress = 0x992274f2Ce632f5fABBdf02ce0039f127AD10Ae0;
    address public constant admin = 0xd29335830FFEaC24E2BA30b5b6B7e0Ef5Ead1902;
    uint256 public rate = 10; //10 = 10% rate of release.
    uint256 public interval = 14 days; // every 14 days rate is released.
    uint256 public WETHout;
    uint256 public FEGout;
    uint256 public startTime;
    uint256 public lastRoundTime;
    uint256 public round; // times interval has passed
    uint256 public addedLP;
    uint256 public claimedLP;
    uint256 public lastClaimedLP;
    uint256 public goal = 100000000000000000000; // 100 ETH
    uint256 public minETH;
    uint256 public withdrawAmount;
    bool public goalReached;
    bool public enabled;
    event AddLP(uint256 amount, uint256 time);
    event Withdraw(uint256 ETHOut, uint256 ClaimedLP);
    event SetAgree(address user, bool _bool);

    modifier update() {    
        if(round == 0) {
            round = 1;
            startTime = block.timestamp;
            lastRoundTime = block.timestamp;
        }  
        if(block.timestamp > startTime + (round * interval)) {
            round += 1;
            lastRoundTime = block.timestamp;
        }
        _;
    }

    function FEGlocation() public view returns(address) {
        address fl = _FEGlocation == address(0) ? admin : _FEGlocation;
        return fl;
    }

    function setFEGlocation(address addy) external {
        require(msg.sender == admin, "admin");
        _FEGlocation = addy; // allow for FEG to be sent to a bonding contract if added
    }

    function addLP(uint256 amount) external nonReentrant update{
        require(msg.sender == admin, "admin");
        require(!goalReached, "over");
        SafeTransfer.safeTransferFrom(IERC20(LP), admin, address(this), amount);
        addedLP += amount;
        emit AddLP(amount, block.timestamp);
    }

    // configured to read new rounds not yet registered with update
    function balanceOpen() public view returns(uint256 amount) {  
        uint256 r = round;
        uint256 i = interval;
        uint256 st = startTime;
        if(block.timestamp > st + (round * i)) {
        for(uint256 e = 0; e < 10 - round; e++) {
            if(block.timestamp > st + (r * i)) {
            r += 1;
            }
            if(block.timestamp <= st + (r * i)) {
            break;
            }
        }
        }
        uint256 d = ((addedLP * rate / 100) * r) >= addedLP ? addedLP : ((addedLP * rate / 100) * r);
        amount = goalReached ? 0 : d - claimedLP;
    }

    function LPValue() external view returns(uint256 native) {
        uint256 a = IERC20(WETH).balanceOf(LP);
        uint256 b = IERC20(LP).totalSupply();
        uint256 c = IERC20(LP).balanceOf(address(this));
        native = a * c / b;
    }

    function setAgreed(bool _bool) external nonReentrant update {
        require(msg.sender == admin || msg.sender == withdrawalAddress, "not permitted");
        if(msg.sender == admin) {
            agreed[admin] = _bool;
            emit SetAgree(msg.sender, _bool);
        }
        if(msg.sender == withdrawalAddress) {
            agreed[withdrawalAddress] = _bool;
            emit SetAgree(msg.sender, _bool);
        }
    }

    // enable withdrawal before withdraw so that we can set minETH out automatically at 95% of claimable amount
    function enableWithdrawal(uint256 amount) external {
        require(msg.sender == withdrawalAddress, "not permitted");
        require(amount <= 100 && amount > 0, "0/100");
        uint256 bal = balanceOpen();
        require(bal > 0, "no bal");
        (uint112 reserve0, uint112 reserve1,) = IPair(LP).getReserves();
        uint256 reserve = WETH == IPair(LP).token0() ? reserve0 : reserve1;
        withdrawAmount = bal * amount / 100 >= addedLP * rate / 100 ? addedLP * rate / 100 : bal * amount / 100;
        minETH = (reserve * withdrawAmount / IERC20(LP).totalSupply()) * 95 / 100; // require 95% of amount out minimum
        enabled = true;
    }

    function withdraw() external nonReentrant update {
        require(msg.sender == withdrawalAddress, "not permitted");
        require(enabled && minETH > 0 && withdrawAmount > 0, "enable withdraw first");
        uint256 bal = balanceOpen();
        require(bal > 0, "no bal");
        require(bal >= withdrawAmount, "over");
        require(!goalReached, "reached goal");
        require(block.timestamp > lastClaimedLP + 1 days, "1 Day cool down"); // if withdrawal address did not take full 10% allow them to take more after 1 days past
        SafeTransfer.safeTransfer(IERC20(LP), LP, withdrawAmount);
        IPair(LP).burn(address(this));
        claimedLP += withdrawAmount;
        uint256 fb = IERC20(FEG).balanceOf(address(this));
        SafeTransfer.safeTransfer(IERC20(FEG), FEGlocation(), fb); // send FEG to FEGlocation if enabled
        FEGout += fb;
        uint256 eb = IERC20(WETH).balanceOf(address(this));
        require(eb >= minETH, "min ETH not met");
        bool reach = WETHout + eb > goal ? true : false;
        uint256 ethOut = reach ? goal - WETHout : eb;        
        WETHout = reach ? goal : WETHout + ethOut;
        SafeTransfer.safeTransfer(IERC20(WETH), withdrawalAddress, ethOut);
        lastClaimedLP = block.timestamp;
        if(reach) {
            goalReached = true;
            SafeTransfer.safeTransfer(IERC20(WETH), admin, IERC20(WETH).balanceOf(address(this)));
            SafeTransfer.safeTransfer(IERC20(LP), admin, IERC20(LP).balanceOf(address(this)));
        }
        emit Withdraw(ethOut, withdrawAmount);
        withdrawAmount = 0;
        minETH = 0;
        enabled = false;
    }

    function saveTokens(address addy) external nonReentrant{
        require(msg.sender == admin || msg.sender == withdrawalAddress, "not permitted");
        if(!agreed[admin] && !agreed[withdrawalAddress]) {
        require(block.timestamp > startTime + ((100 / rate) * interval) + 1 days, "live"); // 141 days after starttime
        }
        uint256 a = IERC20(WETH).balanceOf(address(this));
        if(a > 0) {
        SafeTransfer.safeTransfer(IERC20(WETH), admin, a);
        }
        uint256 b = IERC20(LP).balanceOf(address(this));
        if(b > 0) {
        SafeTransfer.safeTransfer(IERC20(LP), admin, b);
        }
        uint256 c = IERC20(FEG).balanceOf(address(this));
        if(c > 0) {
        SafeTransfer.safeTransfer(IERC20(FEG), admin, c);
        }
        uint256 d = IERC20(addy).balanceOf(address(this));
        if(d > 0) {
        SafeTransfer.safeTransfer(IERC20(addy), admin, d);
        }
        if(agreed[admin] && agreed[withdrawalAddress]) {
        agreed[admin] = false;
        agreed[withdrawalAddress] = false;
        }
    }
}