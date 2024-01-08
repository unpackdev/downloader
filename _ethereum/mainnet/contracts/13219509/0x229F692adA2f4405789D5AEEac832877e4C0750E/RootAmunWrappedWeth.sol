pragma solidity ^0.8.6;

import "./IBridgeToken.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";

/// @title This is a token that is used to allow transfering a token on ethereum under any address
/// @author Timo
/// @notice Needs to deploy under same address on ethereum
contract RootAmunWrappedWeth is ERC20 {
    using SafeERC20 for IERC20;

    IBridgeToken public immutable underlying;
    address public immutable predicateProxy;

    constructor(
        string memory name,
        string memory symbol,
        address _underlying,
        address _predicateProxy
    ) ERC20(name, symbol) {
        underlying = IBridgeToken(_underlying);
        predicateProxy = _predicateProxy;
    }

    /**
     * @notice called when underlying is redeemed on root chain
     * @dev Should be callable only on root chain
     * @param amount redeem amount
     */
    function redeemWeth(uint256 amount) external {
        _burn(msg.sender, amount);
        if (0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE == address(underlying)) {
            payable(msg.sender).transfer(amount);
        } else {
            IERC20(address(underlying)).safeTransfer(msg.sender, amount);
        }
    }

    function mint(address recipient, uint256 amount) external {
        require(msg.sender == predicateProxy, "ONLY_PREDICATE_PROXY");
        _mint(recipient, amount);
    }

    receive() external payable {}
}
