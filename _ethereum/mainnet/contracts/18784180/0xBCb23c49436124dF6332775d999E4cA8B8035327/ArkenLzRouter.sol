// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IOFTV2.sol";
import "./ICommonOFT.sol";
import "./SafeERC20.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";

contract ArkenLzRouter is UUPSUpgradeable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    uint256 public constant FEE_BASIS_POINT = 10000;

    uint256 public feeRate;
    address public feeOwner;

    mapping(address => bool) public supportedOFTs;

    /************************************************************************
     * events
     ************************************************************************/
    event Bridge(
        address indexed oft,
        address indexed from,
        uint16 indexed dstChainId,
        bytes32 toAddress,
        uint256 amount,
        uint256 fee,
        bytes adapterParams
    );

    /************************************************************************
     * public functions
     ************************************************************************/
    function initialize(
        uint256 _feeRate,
        address _feeOwner
    ) external initializer {
        UUPSUpgradeable.__UUPSUpgradeable_init();
        OwnableUpgradeable.__Ownable_init();
        feeRate = _feeRate;
        feeOwner = _feeOwner;
    }

    function setFeeRate(uint256 _feeRate) external onlyOwner {
        require(
            _feeRate < FEE_BASIS_POINT,
            'ArkenLzRouter: feeRate must be less than FEE_BASIS_POINT'
        );
        feeRate = _feeRate;
    }

    function setFeeOwner(address _feeOwner) external onlyOwner {
        feeOwner = _feeOwner;
    }

    function setSupportedOFT(address _oft, bool _supported) external onlyOwner {
        supportedOFTs[_oft] = _supported;
    }

    function bridge(
        address _oft,
        uint16 _dstChainId,
        bytes32 _toAddress,
        uint256 _amount,
        address payable _refundAddress,
        bytes calldata _adapterParams
    ) public payable {
        require(_amount > 0, 'ArkenLzRouter: amount must be greater than zero');
        require(supportedOFTs[_oft], 'ArkenLzRouter: unsupported oft');
        (uint256 nativeLzFee, ) = estimateLzFee(
            _oft,
            _dstChainId,
            _toAddress,
            _amount,
            _adapterParams
        );
        require(msg.value >= nativeLzFee, 'ArkenLzRouter: insufficient fee');
        uint256 fee = estimateBridgeFee(_amount);
        address _underlying = IOFTV2(_oft).token();
        _transferFrom(_underlying, msg.sender, address(this), _amount);
        uint256 _amountAfterFee = _amount - fee;
        _approveToken(_underlying, _oft, _amountAfterFee);
        IOFTV2(_oft).sendFrom{value: msg.value}(
            address(this),
            _dstChainId,
            _toAddress,
            _amountAfterFee,
            ICommonOFT.LzCallParams({
                refundAddress: _refundAddress,
                zroPaymentAddress: address(0),
                adapterParams: _adapterParams
            })
        );
        emit Bridge(
            _oft,
            msg.sender,
            _dstChainId,
            _toAddress,
            _amount,
            fee,
            _adapterParams
        );
    }

    function estimateBridgeFee(
        uint256 _amount
    ) public view returns (uint256 fee) {
        fee = (_amount * feeRate) / FEE_BASIS_POINT;
    }

    function estimateLzFee(
        address _oft,
        uint16 _dstChainId,
        bytes32 _toAddress,
        uint _amount,
        bytes calldata _adapterParams
    ) public view returns (uint256 nativeFee, uint256 zroFee) {
        (nativeFee, zroFee) = ICommonOFT(_oft).estimateSendFee(
            _dstChainId,
            _toAddress,
            _amount,
            false,
            _adapterParams
        );
    }

    function withdrawFee(address _token) external {
        require(msg.sender == feeOwner, 'ArkenLzRouter: only feeOwner');
        IERC20(_token).safeTransfer(
            feeOwner,
            IERC20(_token).balanceOf(address(this))
        );
    }

    /************************************************************************
     * internal functions
     ************************************************************************/

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function _transferFrom(
        address _srcToken,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        IERC20(_srcToken).transferFrom(_from, _to, _amount);
    }

    function _approveToken(
        address _srcToken,
        address _spender,
        uint256 _amount
    ) internal {
        if (IERC20(_srcToken).allowance(address(this), _spender) < _amount) {
            IERC20(_srcToken).approve(_spender, type(uint256).max);
        }
    }
}
