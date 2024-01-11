// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IWETH.sol";
import "./IThorchainRouter.sol";

contract BaseProxyContract is PausableUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    address payable constant NULL_ADDRESS = payable(0x0000000000000000000000000000000000000000);
    uint constant MAX_FEE_PERCENT_x_10000 = 300;
    uint constant MAX_AFFILIATE_PERCENT_x_10000 = 300;

    using SafeMath for uint;

    //keccak256("exchange.rango.baseproxycontract")
    bytes32 internal constant BASE_PROXY_CONTRACT_NAMESPACE = hex"c23df90b6466cfd0cbf4f6a578f167d2f60ed56371b4746a3c5973c8543f4fd9";

    struct BaseProxyStorage {
        address payable feeContractAddress;
        address nativeWrappedAddress;
        mapping (address => bool) whitelistContracts;
    }

    event FeeReward(address token, address wallet, uint amount);
    event AffiliateReward(address token, address wallet, uint amount);
    event CallResult(address target, bool success, bytes returnData);
    event DexOutput(address _token, uint amount);
    event SendToken(address _token, uint256 _amount, address _receiver, bool _nativeOut, bool _withdraw);

    struct Call { address payable target; bytes callData; }
    struct Result { bool success; bytes returnData; }
    struct SwapRequest {
        address fromToken;
        address toToken;
        uint amountIn;
        uint feeIn;
        uint affiliateIn;
        address payable affiliatorAddress;
    }

    function addWhitelist(address _factory) external onlyOwner {
        BaseProxyStorage storage baseProxyStorage = getBaseProxyContractStorage();
        baseProxyStorage.whitelistContracts[_factory] = true;
    }

    function removeWhitelist(address _factory) external onlyOwner {
        BaseProxyStorage storage baseProxyStorage = getBaseProxyContractStorage();
        require(baseProxyStorage.whitelistContracts[_factory], 'Factory not found');
        delete baseProxyStorage.whitelistContracts[_factory];
    }

    function updateFeeContractAddress(address payable _address) external onlyOwner {
        BaseProxyStorage storage baseProxyStorage = getBaseProxyContractStorage();
        baseProxyStorage.feeContractAddress = _address;
    }

    function refund(address _tokenAddress, uint256 _amount) external onlyOwner {
        IERC20 ercToken = IERC20(_tokenAddress);
        uint balance = ercToken.balanceOf(address(this));
        require(balance >= _amount, 'Insufficient balance');

        SafeERC20.safeTransfer(IERC20(_tokenAddress), msg.sender, _amount);
    }

    function refundNative(uint256 _amount) external onlyOwner {
        uint balance = address(this).balance;
        require(balance >= _amount, 'Insufficient balance');

        _sendToken(NULL_ADDRESS, _amount, msg.sender, true, false);
    }

    function onChainSwaps(
        SwapRequest memory request,
        Call[] calldata calls,
        bool nativeOut
    ) external payable whenNotPaused nonReentrant returns (bytes[] memory) {
        (bytes[] memory result, uint outputAmount) = onChainSwapsInternal(request, calls);

        _sendToken(request.toToken, outputAmount, msg.sender, nativeOut, false);
        return result;
    }

    function onChainSwapsInternal(SwapRequest memory request, Call[] calldata calls) internal returns (bytes[] memory, uint) {

        IERC20 ercToken = IERC20(request.toToken);
        uint balanceBefore = request.toToken == NULL_ADDRESS
            ? address(this).balance
            : ercToken.balanceOf(address(this));

        bytes[] memory result = callSwapsAndFees(request, calls);

        uint balanceAfter = request.toToken == NULL_ADDRESS
            ? address(this).balance
            : ercToken.balanceOf(address(this));

        uint secondaryBalance;
        if (calls.length > 0) {
            require(balanceAfter - balanceBefore > 0, "No balance found after swaps");

            secondaryBalance = balanceAfter - balanceBefore;
            emit DexOutput(request.toToken, secondaryBalance);
        } else {
            secondaryBalance = balanceAfter > balanceBefore ? balanceAfter - balanceBefore : request.amountIn;
        }

        return (result, secondaryBalance);
    }

    function callSwapsAndFees(SwapRequest memory request, Call[] calldata calls) private returns (bytes[] memory) {
        bool isSourceNative = request.fromToken == NULL_ADDRESS;
        BaseProxyStorage storage baseProxyStorage = getBaseProxyContractStorage();
        
        // validate
        require(baseProxyStorage.feeContractAddress != NULL_ADDRESS, "Fee contract address not set");

        for(uint256 i = 0; i < calls.length; i++) {
            require(baseProxyStorage.whitelistContracts[calls[i].target], "Contact not whitelisted");
        }

        // Get all the money from user
        uint totalInputAmount = request.feeIn + request.affiliateIn + request.amountIn;
        if (isSourceNative)
            require(msg.value >= totalInputAmount, "Not enough ETH provided to contract");

        // Check max fee/affiliate is respected
        uint maxFee = totalInputAmount * MAX_FEE_PERCENT_x_10000 / 10000;
        uint maxAffiliate = totalInputAmount * MAX_AFFILIATE_PERCENT_x_10000 / 10000;
        require(request.feeIn <= maxFee, 'Requested fee exceeded max threshold');
        require(request.affiliateIn <= maxAffiliate, 'Requested affiliate reward exceeded max threshold');

        // Transfer from wallet to contract
        if (!isSourceNative) {
            for(uint256 i = 0; i < calls.length; i++) {
                approve(request.fromToken, calls[i].target, totalInputAmount);
            }
            SafeERC20.safeTransferFrom(IERC20(request.fromToken), msg.sender, address(this), totalInputAmount);
        }

        // Get Platform fee
        if (request.feeIn > 0) {
            _sendToken(request.fromToken, request.feeIn, baseProxyStorage.feeContractAddress, isSourceNative, false);
            emit FeeReward(request.fromToken, baseProxyStorage.feeContractAddress, request.feeIn);
        }

        // Get affiliator fee
        if (request.affiliateIn > 0) {
            require(request.affiliatorAddress != NULL_ADDRESS, "Invalid affiliatorAddress");
            _sendToken(request.fromToken, request.affiliateIn, request.affiliatorAddress, isSourceNative, false);
            emit AffiliateReward(request.fromToken, request.affiliatorAddress, request.affiliateIn);
        }

        bytes[] memory returnData = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = isSourceNative
                ? calls[i].target.call{value: request.amountIn}(calls[i].callData)
                : calls[i].target.call(calls[i].callData);

            emit CallResult(calls[i].target, success, ret);
            require(success, string(abi.encodePacked("Call failed, index:", i)));
            returnData[i] = ret;
        }

        return returnData;
    }

    function approve(address token, address to, uint value) internal {
        SafeERC20.safeApprove(IERC20(token), to, 0);
        SafeERC20.safeIncreaseAllowance(IERC20(token), to, value);
    }

    function _sendToken(
        address _token,
        uint256 _amount,
        address _receiver,
        bool _nativeOut,
        bool _withdraw
    ) internal {
        BaseProxyStorage storage baseProxyStorage = getBaseProxyContractStorage();
        emit SendToken(_token, _amount, _receiver, _nativeOut, _withdraw);

        if (_nativeOut) {
            if (_withdraw) {
                require(_token == baseProxyStorage.nativeWrappedAddress, "token mismatch");
                IWETH(baseProxyStorage.nativeWrappedAddress).withdraw(_amount);
            }
            _sendNative(_receiver, _amount);
        } else {
            SafeERC20.safeTransfer(IERC20(_token), _receiver, _amount);
        }
    }

    function _sendNative(address _receiver, uint _amount) internal {
        (bool sent, ) = _receiver.call{value: _amount}("");
        require(sent, "failed to send native");
    }


    function getBaseProxyContractStorage() internal pure returns (BaseProxyStorage storage s) {
        bytes32 namespace = BASE_PROXY_CONTRACT_NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := namespace
        }
    }
}
