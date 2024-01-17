pragma solidity 0.8.13;

import "./IUniswapV2Router02.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

contract DexForwarder is Initializable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IUniswapV2Router02 public router;
    address public trustedForwarder;

    function initialize(IUniswapV2Router02 _router, address _trustedForwarder) external initializer {
        __Ownable_init();
        router = _router;
        trustedForwarder = _trustedForwarder;
    }

    function swapExactTokensForTokens(
        //exactIn
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts) {
        IERC20Upgradeable sourceToken = IERC20Upgradeable(path[0]);
        sourceToken.safeTransferFrom(_msgSender(), address(this), amountIn);

        if (sourceToken.allowance(address(this), address(router)) < amountIn) {
            sourceToken.approve(address(router), type(uint256).max);
        }

        amounts = router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            to,
            deadline
        );
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts) {
        IERC20Upgradeable sourceToken = IERC20Upgradeable(path[0]);
        sourceToken.safeTransferFrom(_msgSender(), address(this), amountInMax);

        if (sourceToken.allowance(address(this), address(router)) < amountInMax) {
            sourceToken.safeApprove(address(router), type(uint256).max);
        }

        amounts = router.swapTokensForExactTokens(
            amountOut,
            amountInMax,
            path,
            to,
            deadline
        );

        //exactOut can use amounts less than amountInMax. So transfer the excess funds back
        uint256 excess = sourceToken.balanceOf(address(this));
        if(excess > 0) {
            sourceToken.safeTransfer(_msgSender(), excess);
        }
    }

    function setRouter(IUniswapV2Router02 _router) external onlyOwner {
        router = _router;
    }

    function isTrustedForwarder(address forwarder) public view returns(bool) {
        return forwarder == trustedForwarder;
    }

    function setTrustedForwarder(address forwarder) public onlyOwner {
        trustedForwarder = forwarder;
    }

    function _msgSender() internal override view returns (address ret) {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            return msg.sender;
        }
    }

    function versionRecipient() external pure returns (string memory) {
        return "1";
    }
}
