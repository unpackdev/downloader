// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./EnumerableSet.sol";
import "./AccessControl.sol";
import "./Pausable.sol";
import "./MessageSenderApp.sol";
import "./MessageReceiverApp.sol";
import "./IWETH.sol";
import "./FullMath.sol";

contract SwapBase is MessageSenderApp, MessageReceiverApp, AccessControl, Pausable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet internal supportedDEXes;

    // Collected fee amount for Rubic and integrators
    // token -> amount of collected fees
    mapping(address => uint256) public collectedFee;
    // integrator -> token -> amount of collected fees
    mapping(address => mapping(address => uint256)) public integratorCollectedFee;

    // integrator -> percent for integrators
    mapping(address => uint256) public integratorFee;
    // integrator -> percent for Rubic
    mapping(address => uint256) public platformShare;

    // Crypto fee amount blockchainId -> fee amount
    mapping(uint64 => uint256) public dstCryptoFee;

    /** Shows tx status with transfer id
     *  Null, - tx hasnt arrived yet
     *  Succeeded, - tx successfully executed on dst chain
     *  Failed, - tx failed on src chain, transfer transit token back to EOA
     *  Fallback - tx failed on dst chain, transfer transit token back to EOA
     */
    mapping(bytes32 => SwapStatus) public txStatusById;

    // minimal amount of bridged token
    mapping(address => uint256) public minSwapAmount;
    // maximum amount of bridged token
    mapping(address => uint256) public maxSwapAmount;

    // platform Rubic fee
    uint256 public feeRubic;

    // erc20 wrap of gas token of this chain, eg. WETH
    address public nativeWrap;

    uint64 public nonce;

    // Role of the manager
    bytes32 public constant MANAGER = keccak256('MANAGER');
    // Role of the executor
    bytes32 public constant EXECUTOR = keccak256('EXECUTOR');

    /// @dev This modifier prevents using manager functions
    modifier onlyManager() {
        require(hasRole(MANAGER, msg.sender), 'Caller is not a manager');
        _;
    }

    /// @dev This modifier prevents using executor functions
    modifier onlyExecutor(address _executor) {
        require(hasRole(EXECUTOR, _executor), 'Caller is not an executor');
        _;
    }

    modifier onlyEOA() {
        require(msg.sender == tx.origin, 'Not EOA');
        _;
    }

    // ============== struct for V2 like dexes ==============

    struct SwapInfoV2 {
        address dex; // the DEX to use for the swap
        // if this array has only one element, it means no need to swap
        address[] path;
        // the following fields are only needed if path.length > 1
        uint256 deadline; // deadline for the swap
        uint256 amountOutMinimum; // minimum receive amount for the swap
    }

    // ============== struct for V3 like dexes ==============

    struct SwapInfoV3 {
        address dex; // the DEX to use for the swap
        bytes path;
        uint256 deadline;
        uint256 amountOutMinimum;
    }

    // ============== struct for inch swap ==============

    struct SwapInfoInch {
        address dex;
        // path is tokenIn, tokenOut
        address[] path;
        bytes data;
        uint256 amountOutMinimum;
    }

    // ============== struct dstSwap ==============
    // This is needed to make v2 -> SGN -> v3 swaps and etc.

    struct SwapInfoDest {
        address dex; // dex address
        address integrator;
        SwapVersion version; // identifies swap type
        address[] path; // path address for v2 and inch
        bytes pathV3; // path address for v3
        uint256 deadline; // for v2 and v3
        uint256 amountOutMinimum;
    }

    struct SwapRequestDest {
        SwapInfoDest swap;
        address receiver; // EOA
        uint64 nonce;
        uint64 dstChainId;
    }

    enum SwapVersion {
        v2,
        v3,
        bridge
    }

    enum SwapStatus {
        Null,
        Succeeded,
        Failed,
        Fallback
    }

    // returns address of first token for V3
    function _getFirstBytes20(bytes memory input) internal pure returns (bytes20 result) {
        assembly {
            result := mload(add(input, 32))
        }
    }

    // returns address of tokenOut for V3
    function _getLastBytes20(bytes memory input) internal pure returns (bytes20 result) {
        uint256 offset = input.length + 12;
        assembly {
            result := mload(add(input, offset))
        }
    }

    function _computeSwapRequestId(
        address _sender,
        uint64 _srcChainId,
        uint64 _dstChainId,
        bytes memory _message
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_sender, _srcChainId, _dstChainId, _message));
    }

    // ============== fee logic ==============

    function _calculateCryptoFee(uint256 _fee, uint64 _dstChainId) internal view returns (uint256 updatedFee) {
        require(_fee >= dstCryptoFee[_dstChainId], 'too few crypto fee');
        uint256 _updatedFee = _fee - dstCryptoFee[_dstChainId];
        return (_updatedFee);
    }

    function _calculatePlatformFee(
        address _integrator,
        address _token,
        uint256 _amountWithFee
    ) internal returns (uint256 amountWithoutFee) {
        uint256 _integratorPercent = integratorFee[_integrator];

        // integrator fee is supposed not to be zero
        if (_integratorPercent > 0) {
            uint256 _platformPercent = platformShare[_integrator];

            uint256 _integratorAndPlatformFee = FullMath.mulDiv(_amountWithFee, _integratorPercent, 1e6);

            uint256 _platformFee = FullMath.mulDiv(_integratorAndPlatformFee, _platformPercent, 1e6);

            integratorCollectedFee[_integrator][_token] += _integratorAndPlatformFee - _platformFee;
            collectedFee[_token] += _platformFee;

            amountWithoutFee = _amountWithFee - _integratorAndPlatformFee;
        } else {
            amountWithoutFee = FullMath.mulDiv(_amountWithFee, 1e6 - feeRubic, 1e6);

            collectedFee[_token] += _amountWithFee - amountWithoutFee;
        }
    }

    function smartApprove(
        IERC20 tokenIn,
        uint256 amount,
        address to
    ) internal {
        uint256 _allowance = tokenIn.allowance(address(this), to);
        if (_allowance < amount) {
            if (_allowance == 0) {
                tokenIn.safeApprove(to, type(uint256).max);
            } else {
                try tokenIn.approve(to, type(uint256).max) returns (bool res) {
                    require(res == true, 'approve failed');
                } catch {
                    tokenIn.safeApprove(to, 0);
                    tokenIn.safeApprove(to, type(uint256).max);
                }
            }
        }
    }

    // This is needed to receive ETH when calling `IWETH.withdraw`
    fallback() external payable {}
}
