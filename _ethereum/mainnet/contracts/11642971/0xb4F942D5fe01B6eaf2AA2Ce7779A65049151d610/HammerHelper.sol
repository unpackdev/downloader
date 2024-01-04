pragma solidity ^0.5.17;

import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./SafeERC20.sol";
// import "./ERC20Detailed.sol";
// import "./Ownable.sol";

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

interface IBPool {
    function joinswapExternAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut
    ) external payable returns (uint256 poolAmountOut);

    function isBound(address t) external view returns (bool);

    function getFinalTokens() external view returns (address[] memory tokens);

    function totalSupply() external view returns (uint256);

    function getDenormalizedWeight(address token)
        external
        view
        returns (uint256);

    function getTotalDenormalizedWeight() external view returns (uint256);

    function getSwapFee() external view returns (uint256);

    function calcPoolOutGivenSingleIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 tokenAmountIn,
        uint256 swapFee
    ) external pure returns (uint256 poolAmountOut);

    function getBalance(address token) external view returns (uint256);
}

interface IVault {
    function token() external view returns (address);

    function underlying() external view returns (address);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function controller() external view returns (address);

    function governance() external view returns (address);

    function getPricePerFullShare() external view returns (uint256);

    function deposit(uint256) external;

    function depositAll() external;

    function withdraw(uint256) external;

    function withdrawAll() external;
}

contract HammerHelper {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public constant WRAP_ETH_ADDRESS = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    
    function depositEthToBalancer(address balAndWethPoolAddress, uint256 minBptOut) payable external {
        require(msg.value > 0, "ERR: No ETH sent");
        uint256 bptAmount = supplyEthToBalancer(balAndWethPoolAddress, msg.value, minBptOut);
        IERC20(balAndWethPoolAddress).safeTransfer(msg.sender, bptAmount);
    }
    
    function depositEthToHammer(address balAndWethPoolAddress, address hammerAddress, uint256 minBptOut) payable external {
        require(msg.value > 0, "ERR: No ETH sent");
        uint256 bptAmount = supplyEthToBalancer(balAndWethPoolAddress, msg.value, minBptOut);
        uint256 hbptAmount = supplyBptToHammer(balAndWethPoolAddress, hammerAddress, bptAmount);
        IERC20(balAndWethPoolAddress).safeTransfer(msg.sender, hbptAmount);
    }
    
    function supplyEthToBalancer(address balAndWethPoolAddress, uint256 amount, uint256 minBptOut) private returns (uint256) {
        IWETH(WRAP_ETH_ADDRESS).deposit.value(amount)();
        IERC20(WRAP_ETH_ADDRESS).safeApprove(
            balAndWethPoolAddress,
            0
        );
        IERC20(WRAP_ETH_ADDRESS).safeApprove(
            balAndWethPoolAddress,
            amount
        );
        uint256 bptAmount = IBPool(balAndWethPoolAddress).joinswapExternAmountIn(WRAP_ETH_ADDRESS, amount, minBptOut);
        return bptAmount;
    }
    
    function supplyBptToHammer(address balAndWethPoolAddress, address hammerAddress, uint256 amount) private returns (uint256){
        IERC20(balAndWethPoolAddress).safeApprove(hammerAddress, 0);
        IERC20(balAndWethPoolAddress).safeApprove(hammerAddress, amount);

        uint256 before = IERC20(hammerAddress).balanceOf(address(this));
        IVault(hammerAddress).deposit(amount);
        uint256 afterDeposit = IERC20(hammerAddress).balanceOf(address(this));
        uint256 diff = afterDeposit.sub(before);

        return diff;
    }

}