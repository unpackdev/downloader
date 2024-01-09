// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./IElvantisFeeReceiver.sol";
import "./IDEXRouter.sol";

// This contract will only be used for Elvantis Token
contract ElvantisFeeReceiver is Ownable, IElvantisFeeReceiver {
    IERC20 public elvantis;
    IDEXRouter public router;
    address public feeRecipient;

    bool public swapEnabled = true;
    uint256 public swapThreshold = 1 ether;
    
    event FeeRecipientUpdated(address indexed feeRecipient);
    event RouterUpdated(address indexed router);
    event SwapUpdated(bool indexed enabled);
    event SwapThresholdUpdated(uint256 indexed threshold);

    modifier onlyElvantis {
        require(msg.sender == address(elvantis), "ElvantisFeeReceiver: Only Elvantis!");
        _;
    }

    constructor(address _elvantis, address _router, address _owner) {
        require(_elvantis != address(0) && _router != address(0) && _owner != address(0), "ElvantisFeeReceiver: zero address");

        elvantis = IERC20(_elvantis);
        router = IDEXRouter(_router);
        transferOwnership(_owner);
    }

    function onFeeReceived(address token, uint256 amount) external override onlyElvantis {
        if(token != address(0)) {
            address recipient = swapEnabled ? address(this) : feeRecipient;
            elvantis.transferFrom(address(elvantis), recipient, amount);
            _swapTokensForETH();
        }
    }

    function _swapTokensForETH() private {
        uint256 amount = elvantis.balanceOf(address(this));
        if(amount > swapThreshold) {
            address[] memory path = new address[](2);
            path[0] = address(elvantis);
            path[1] = router.WETH();

            elvantis.approve(address(router), amount);
            
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amount,
                0,
                path,
                feeRecipient,
                block.timestamp
            );
        }
    }
    
    function setFeeRecipient(address _feeRecipient) onlyOwner external {
        require(_feeRecipient != address(0), "ElvantisFeeReceiver: _feeRecipient is a zero address");
        feeRecipient = _feeRecipient;
        emit FeeRecipientUpdated(_feeRecipient);
    }

    function setRouter(IDEXRouter _router) onlyOwner external {
        require(address(_router) != address(0), "ElvantisFeeReceiver: _router is a zero address");
        router = _router;
        emit RouterUpdated(address(_router));
    }

    function setSwapEnabled(bool _enabled) onlyOwner external {
        swapEnabled = _enabled;
        emit SwapUpdated(_enabled);
    }

    function setSwapThreshold(uint256 _threshold) onlyOwner external {
        swapThreshold = _threshold;
        emit SwapThresholdUpdated(_threshold);
    }

    function drainAccidentallySentTokens(IERC20 token, address recipient, uint256 amount) onlyOwner external {
        token.transfer(recipient, amount);
    }
}