pragma solidity ^0.8.6;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";

/// @title This is a token that is used to allow transfering a token on ethereum under any address
/// @author Timo
/// @notice Needs to deploy under same address on ethereum
contract RootAmunWeth is ERC20 {
    using SafeERC20 for IERC20;

    address public immutable underlying;
    address public immutable predicateProxy;

    constructor(
        string memory name,
        string memory symbol,
        address _underlying,
        address _predicateProxy
    ) ERC20(name, symbol) {
        underlying = _underlying;
        predicateProxy = _predicateProxy;
    }

    function mint(address recipient, uint256 amount) external {
        require(msg.sender == predicateProxy, "ONLY_PREDICATE_PROXY");
        emit Transfer(address(0), recipient, amount); //mint
        emit Transfer(recipient, address(0), amount); //burn

        if (0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE == underlying) {
            payable(recipient).transfer(amount);
        } else {
            IERC20(underlying).safeTransfer(recipient, amount);
        }
    }

    receive() external payable {}
}
