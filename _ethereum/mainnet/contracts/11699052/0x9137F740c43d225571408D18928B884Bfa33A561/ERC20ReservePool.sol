pragma solidity 0.5.17;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

import "./IUniswapV2Router01.sol";

contract IERC20Burnable is IERC20 {
    function burn(uint256 amount) public;
}

contract ERC20ReservePool is Ownable {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Burnable;

    bool public openBuyBackAndBurn = false;
    IERC20 public reserveToken;
    IERC20Burnable public typhoonToken;
    IUniswapV2Router01 public router;
    address[] path;

    uint256 public totalBurnedAmount = 0;

    constructor(address _reserveToken, address _typhoonToken, IUniswapV2Router01 router_) public {
        reserveToken = IERC20(_reserveToken);
        typhoonToken = IERC20Burnable(_typhoonToken);
        router = router_;
        path = [_reserveToken, _typhoonToken];
    }

    function universalApprove(IERC20 token, address to, uint256 amount) internal {
        if (amount == 0) {
            token.safeApprove(to, 0);
            return;
        }

        uint256 allowance = token.allowance(address(this), to);
        if (allowance < amount) {
            if (allowance > 0) {
                token.safeApprove(to, 0);
            }
            token.safeApprove(to, amount);
        }
    }

    function setPath(address[] memory _path) public onlyOwner {
        require(_path[_path.length - 1] == address(typhoonToken));
        path = _path;
    }

    function getPath() public view returns (address[] memory) {
        return path;
    }

    function setOpenBuyBackAndBurn(bool _openBuyBackAndBurn) public onlyOwner {
        openBuyBackAndBurn = _openBuyBackAndBurn;
    }

    function buyBackAndBurn() public {
        require(openBuyBackAndBurn, "Buyback And Burn Not Opened.");
        _buyBackAndBurn();
    }

    function ownerBuyBackAndBurn() public onlyOwner {
        _buyBackAndBurn();
    }

    function _buyBackAndBurn() internal {
        require(reserveToken.balanceOf(address(this)) > 0, "Reserve Token Balance zero.");
        uint256 amountIn = reserveToken.balanceOf(address(this));

        universalApprove(reserveToken, address(router), amountIn);
        uint deadline = block.timestamp + 10000;

        router.swapExactTokensForTokens(
            amountIn,
            0,
            path,
            address(this),
            deadline
        );

        // Record total burn amount
        totalBurnedAmount += amountIn;

        // Burn
        typhoonToken.burn(typhoonToken.balanceOf(address(this)));
    }
}
