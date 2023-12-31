// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;
pragma abicoder v2;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

import "./IStargateRouter.sol";
import "./IStargateReceiver.sol";
import "./IStargateEthVault.sol";
import "./BytesLib.sol";
import "./SafeCall.sol";

interface IStargateBridge {
    function quoteLayerZeroFee(
        uint16 _chainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        IStargateRouter.lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
}

interface IPool {
    function token() external view returns (address);
    function convertRate() external view returns (uint256);
}

interface IStargateFactory {
    function getPool(uint256 _poolId) external view returns (address);
}

contract StargateComposer is IStargateRouter, IStargateReceiver, Ownable, ReentrancyGuard {
    using BytesLib for bytes;
    using SafeCall for address;
    using Address for address;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private dstGasReserve = 40000;
    uint256 private transferOverhead = 20000;

    uint256 private _swapStatus = _NOT_ENTERED;

    IStargateBridge public immutable stargateBridge;
    IStargateRouter public immutable stargateRouter;
    address public immutable factory;
    uint256 public wethPoolId;

    struct PoolInfo {
        address token;
        address poolAddress;
        uint256 convertRate;
    }

    mapping(uint16 => address) public peers;
    mapping(uint256 => address) public stargateEthVaults;
    mapping(uint16 => mapping(bytes => mapping(uint256 => bytes32))) public payloadHashes;
    mapping(uint256 => PoolInfo) public poolIdToInfo; // cache pool info

    modifier nonSwapReentrant() {
        require(_swapStatus != _ENTERED, "Stargate: reentrant call");
        _swapStatus = _ENTERED;
        _;
        _swapStatus = _NOT_ENTERED;
    }

    event CachedSwapSaved(
        uint16 chainId,
        bytes srcAddress,
        uint256 nonce,
        bytes reason
    );

    event ComposedTokenTransferFailed(
        address token,
        address intendedReceiver,
        uint amountLD
    );

    struct SwapAmount {
        uint256 amountLD; // the amount, in Local Decimals, to be swapped
        uint256 minAmountLD; // the minimum amount accepted out on destination
    }

    constructor(address _stargateBridge, address _stargateRouter, address _stargateEthVault, uint256 _wethPoolId) {
        stargateBridge = IStargateBridge(_stargateBridge);
        stargateRouter = IStargateRouter(_stargateRouter);
        wethPoolId = _wethPoolId;
        setStargateEthVaults(_wethPoolId, _stargateEthVault);

        (bool success, bytes memory data) = _stargateRouter.staticcall(abi.encodeWithSignature("factory()"));
        require(success, "Stargate: invalid factory address");
        factory = abi.decode(data, (address));
    }

    function addLiquidity(
        uint256 _poolId,
        uint256 _amountLD,
        address _to
    ) external override {
        PoolInfo memory poolInfo = _getPoolInfo(_poolId);

        // remove dust
        if (poolInfo.convertRate > 1) _amountLD = _amountLD.div(poolInfo.convertRate).mul(poolInfo.convertRate);

        // transfer tokens into this contract
        IERC20(poolInfo.token).safeTransferFrom(msg.sender, address(this), _amountLD);

        stargateRouter.addLiquidity(_poolId, _amountLD, _to);
    }

    function redeemRemote(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        uint256 _minAmountLD,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external override payable nonReentrant {
        IERC20 lpToken = IERC20(_getPoolInfo(_srcPoolId).poolAddress);
        // transfer lp tokens into this contract
        lpToken.safeTransferFrom(msg.sender, address(this), _amountLP);

        stargateRouter.redeemRemote{value: msg.value}(
            _dstChainId,
            _srcPoolId,
            _dstPoolId,
            _refundAddress,
            _amountLP,
            _minAmountLD,
            _to,
            _lzTxParams
        );
    }

    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external override payable nonReentrant {
        IERC20 lpToken = IERC20(_getPoolInfo(_srcPoolId).poolAddress);
        // transfer lp tokens into this contract
        lpToken.safeTransferFrom(msg.sender, address(this), _amountLP);

        stargateRouter.redeemLocal{value: msg.value}(
            _dstChainId,
            _srcPoolId,
            _dstPoolId,
            _refundAddress,
            _amountLP,
            _to,
            _lzTxParams
        );
    }

    function instantRedeemLocal(
        uint16 _srcPoolId,
        uint256 _amountLP,
        address _to
    ) external override nonReentrant returns (uint256 amountSD) {
        IERC20 lpToken = IERC20(_getPoolInfo(_srcPoolId).poolAddress);

        // should always be zero as this contract doesnt hold tokens
        uint balanceBefore = lpToken.balanceOf(address(this));

        // transfer lp tokens into this contract
        lpToken.safeTransferFrom(msg.sender, address(this), _amountLP);

        // redeem the tokens on behalf of user
        amountSD = stargateRouter.instantRedeemLocal(_srcPoolId, _amountLP, _to);

        // any extra lpTokens send back to the original msg.sender
        uint balanceAfter = lpToken.balanceOf(address(this));
        uint diff = balanceAfter - balanceBefore;
        if (diff > 0) lpToken.safeTransfer(msg.sender, diff);
    }

    function sendCredits(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress
    ) external payable override nonReentrant {
        stargateRouter.sendCredits{value: msg.value}(_dstChainId, _srcPoolId, _dstPoolId, _refundAddress);
    }

    function quoteLayerZeroFee(
        uint16 _chainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        IStargateRouter.lzTxObj memory _lzTxParams
    ) external view override returns(uint256, uint256) {
        bytes memory newPayload = _buildPayload(_toAddress, _transferAndCallPayload);

        // overhead for calling composer's sgReceive()
        _lzTxParams.dstGasForCall += dstGasReserve + transferOverhead;

        return stargateBridge.quoteLayerZeroFee(_chainId, _functionType, _toAddress, newPayload, _lzTxParams);
    }

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        IStargateRouter.lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external override payable nonSwapReentrant {
        bytes memory newPayload = _buildPayload(_to, _payload);
        bytes memory peer = _getPeer(_dstChainId);

        if(isEthPool(_srcPoolId)) {
            require(msg.value > _amountLD, "Stargate: msg.value must be > _swapAmount.amountLD");
            IStargateEthVault(stargateEthVaults[_srcPoolId]).deposit{value: _amountLD}();
            IStargateEthVault(stargateEthVaults[_srcPoolId]).approve(address(stargateRouter), _amountLD);
        } else {
            PoolInfo memory poolInfo = _getPoolInfo(_srcPoolId);
            // remove dust
            if (poolInfo.convertRate > 1) _amountLD = _amountLD.div(poolInfo.convertRate).mul(poolInfo.convertRate);
            // transfer token to this contract
            IERC20(poolInfo.token).safeTransferFrom(msg.sender, address(this), _amountLD);
        }

        // overhead for calling composer's sgReceive()
        _lzTxParams.dstGasForCall += dstGasReserve + transferOverhead;

        stargateRouter.swap{value: isEthPool(_srcPoolId) ? msg.value - _amountLD : msg.value}(
            _dstChainId,
            _srcPoolId,
            _dstPoolId,
            _refundAddress,
            _amountLD,
            _minAmountLD,
            _lzTxParams,
            peer, // swap the to address with the peer address
            newPayload
        );
    }

    // @notice compose stargate to swap ETH on the source to ETH on the destination and arbitrary call
    function swapETHAndCall(
        uint16 _dstChainId, // destination Stargate chainId
        address payable _refundAddress, // refund additional messageFee to this address
        bytes calldata _to, // the receiver of the destination ETH
        SwapAmount memory _swapAmount, // the amount and the minimum swap amount
        IStargateRouter.lzTxObj memory _lzTxParams, // the LZ tx params
        bytes calldata _payload // the payload to send to the destination
    ) external payable nonSwapReentrant {
        bytes memory newPayload = _buildPayload(_to, _payload);
        bytes memory peer = _getPeer(_dstChainId);

        {
            require(msg.value > _swapAmount.amountLD, "Stargate: msg.value must be > _swapAmount.amountLD");
            require(stargateEthVaults[wethPoolId] != address(0), "Stargate: Pool does not exist");
            IStargateEthVault(stargateEthVaults[wethPoolId]).deposit{value: _swapAmount.amountLD}();
            IStargateEthVault(stargateEthVaults[wethPoolId]).approve(address(stargateRouter), _swapAmount.amountLD);
        }

        // overhead for calling composer's sgReceive()
        _lzTxParams.dstGasForCall += dstGasReserve + transferOverhead;

        stargateRouter.swap{value: (msg.value - _swapAmount.amountLD)}(
            _dstChainId, // destination Stargate chainId
            wethPoolId, // WETH Stargate poolId on source
            wethPoolId, // WETH Stargate poolId on destination
            _refundAddress, // message refund address if overpaid
            _swapAmount.amountLD, // the amount in Local Decimals to swap()
            _swapAmount.minAmountLD, // the minimum amount swap()er would allow to get out (ie: slippage)
            _lzTxParams, // the LZ tx params
            peer, // address on destination to send to
            newPayload // payload to send to the destination
        );
    }

    function _buildPayload(
        bytes calldata _to,
        bytes calldata _payload
    ) internal view returns (bytes memory) {
        require(_to.length == 20, "Stargate: invalid to address");
        require(_payload.length > 0, "Stargate: payload is empty");

        // new payload = to(20) + sender(20) + payload
        // encoding the sender allows the receiver to know who called the Stargate
        return abi.encodePacked(_to, msg.sender, _payload);
    }

    function _getPeer(uint16 _dstChainId) internal view returns(bytes memory) {
        address peerAddr = peers[_dstChainId];
        require(peerAddr != address(0), "Stargate: peer not found");
        return abi.encodePacked(peerAddr);
    }

    function addLiquidityETH() external payable {
        require(msg.value > 0, "Stargate: msg.value is 0");

        // wrap the ETH into WETH
        uint256 amountLD = msg.value;
        require(stargateEthVaults[wethPoolId] != address(0), "Stargate: Pool does not exist");
        IStargateEthVault(stargateEthVaults[wethPoolId]).deposit{value: amountLD}();
        IStargateEthVault(stargateEthVaults[wethPoolId]).approve(address(stargateRouter), amountLD);

        // addLiquidity using the WETH that was just wrapped,
        // and mint the LP token to the msg.sender
        stargateRouter.addLiquidity(wethPoolId, amountLD, msg.sender);
    }

    function sgReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint256 _nonce,
        address _token,
        uint256 _amountLD,
        bytes memory _payload
    ) external override {
        require(msg.sender == address(stargateRouter), "Stargate: only router");
        // will just ignore the payload in some invalid configuration
        if (_payload.length <= 40) return; // 20 + 20 + payload

        address intendedReceiver = _payload.toAddress(0);

        try IERC20(_token).transfer(intendedReceiver, _amountLD) {
            if (!intendedReceiver.isContract()) return; // ignore

            bytes memory callData = abi.encodeWithSelector(
                IStargateReceiver.sgReceive.selector,
                _srcChainId,
                abi.encodePacked(_payload.toAddress(20)), // use the caller as the srcAddress (the msg.sender caller the StargateComposer at the source)
                _nonce,
                _token,
                _amountLD,
                _payload.slice(40, _payload.length - 40)
            );

            // no point in requires, because it will revert regardless
            uint256 externalGas = gasleft() - dstGasReserve;

            (bool success, bytes memory reason) = intendedReceiver.safeCall(externalGas, 0, 150, callData); // only return 150 bytes of data

            if (!success) {
                payloadHashes[_srcChainId][_srcAddress][_nonce] = keccak256(abi.encodePacked(intendedReceiver, callData));
                emit CachedSwapSaved(_srcChainId, _srcAddress, _nonce, reason);
            }

        } catch {
            // do nothing, token swap failed and can't be delivered, tokens are held inside this contract
            emit ComposedTokenTransferFailed(_token, intendedReceiver, _amountLD);
        }
    }

    function clearCachedSwap(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        address _receiver,
        bytes calldata _sgReceiveCallData
    ) external nonReentrant {
        bytes32 hash = keccak256(abi.encodePacked(_receiver, _sgReceiveCallData));
        require(payloadHashes[_srcChainId][_srcAddress][_nonce] == hash, "Stargate: invalid hash");
        delete payloadHashes[_srcChainId][_srcAddress][_nonce];

        (bool success, bytes memory reason) = _receiver.safeCall(gasleft(), 0, 150, _sgReceiveCallData);
        if (!success) {
            assembly {
                revert(add(32, reason), mload(reason))
            }
        }
    }

    function setDstGasReserve(uint256 _dstGasReserve) onlyOwner external {
        dstGasReserve = _dstGasReserve;
    }

    function setTransferOverhead(uint256 _transferOverhead) onlyOwner external {
        transferOverhead = _transferOverhead;
    }

    function setStargateEthVaults(uint256 _poolId, address _stargateEthVault) onlyOwner public {
        stargateEthVaults[_poolId] = _stargateEthVault;
    }

    function setWethPoolId(uint256 _wethPoolId) onlyOwner external {
        wethPoolId = _wethPoolId;
    }

    function setPeer(uint16 _chainId, address _peer) onlyOwner external {
        require(peers[_chainId] == address(0), "Stargate: peer already set");
        peers[_chainId] = _peer;
    }

    function recoverToken(address _token, address _to, uint256 _amount) external onlyOwner {
        IERC20(_token).safeTransfer(_to, _amount);
    }

    function isSending() external view returns (bool) {
        return _swapStatus == _ENTERED;
    }

    function isEthPool(uint256 _srcPoolId) internal view returns (bool) {
        return stargateEthVaults[_srcPoolId] != address(0);
    }

    function getPoolInfo(uint256 _poolId) external returns (PoolInfo memory poolInfo) {
        return _getPoolInfo(_poolId);
    }

    function _getPoolInfo(uint256 _poolId) internal returns (PoolInfo memory poolInfo) {
        // return early if its already been called
        if (poolIdToInfo[_poolId].poolAddress != address(0)) {
            return poolIdToInfo[_poolId];
        }

        address pool = IStargateFactory(factory).getPool(_poolId);
        require(address(pool) != address(0), "Stargate: pool does not exist");
        IERC20(pool).safeApprove(address(stargateRouter), type(uint256).max);

        address token = IPool(pool).token();
        require(address(token) != address(0), "Stargate: token does not exist");
        IERC20(token).safeApprove(address(stargateRouter), type(uint256).max);

        uint256 convertRate = IPool(pool).convertRate();

        poolInfo = PoolInfo({token: token, poolAddress: pool, convertRate: convertRate});
        poolIdToInfo[_poolId] = poolInfo;
    }
}
