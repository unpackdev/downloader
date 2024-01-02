// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Owned.sol";
import "./ERC20.sol";
import "./SafeTransferLib.sol";
import "./WETH.sol";
import "./IChad.sol";

import "./IUniswapV2Router.sol";
import "./ISwapRouter.sol";
import "./IQuoter.sol";

contract GFYETF is Owned {
    using SafeTransferLib for ERC20;

    enum UniswapVersion {
        V2,
        V3
    }

    struct IndexComponent {
        address token;
        uint8 weight;
        uint24 fee;
        UniswapVersion version;
    }
    struct TokenAmount {
        address token;
        uint256 amount;
    }

    event IndexComponentUpdated(address indexed token, uint8 weight);
    event TokenPurchased(address indexed token, uint256 amount);
    event TokenRedeemed(address indexed token, uint256 amount);

    IUniswapV2Router public immutable uniswapV2Router;
    ISwapRouter public immutable uniswapV3Router;

    /// @dev enable perfect granularity
    uint256 public constant MAX_BPS = 1_000_000_000 * 1e18;
    uint24 public immutable LOW_FEE = 3_000;
    uint24 public immutable HIGH_FEE = 10_000;

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address public constant GFY = 0x2D9D7c64F6c00e16C28595ec4EbE4065ef3A250b;

    bool public canUpdateWeights = true;
    address public index;
    uint256 public lastPurchase;

    // Current implementation
    mapping(address => IndexComponent) public components;
    mapping(address => bool) public hasToken;
    address[] public tokens;
    address[] public allTokens;

    constructor() Owned(msg.sender) {
        uniswapV2Router = IUniswapV2Router(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV3Router = ISwapRouter(
            0xE592427A0AEce92De3Edee1F18E0157C05861564
        );

        components[GFY] = IndexComponent({
            token: GFY,
            weight: 100,
            fee: 0,
            version: UniswapVersion.V2
        });

        tokens = [GFY];
        allTokens = [GFY];

        hasToken[GFY] = true;

        ERC20(WETH).approve(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,
            type(uint256).max
        );
        ERC20(WETH).approve(
            0xE592427A0AEce92De3Edee1F18E0157C05861564,
            type(uint256).max
        );

        lastPurchase = block.timestamp;
    }

    receive() external payable {}

    function _requireIsOwner() internal view {
        require(msg.sender == owner, "!owner");
    }

    function setToken(address newIndex) external {
        _requireIsOwner();
        index = newIndex;
        ERC20(IChad(index).uniswapV2Pair()).approve(
            address(uniswapV2Router),
            type(uint256).max
        );
    }

    function setCanUpdateWeights(bool _canUpdateWeights) external {
        _requireIsOwner();
        canUpdateWeights = _canUpdateWeights;
    }

    function purchaseTokensForGFY() external {
        _requireIsOwner();
        uint256 wethBalance = ERC20(WETH).balanceOf(address(this));
        uint256 etherBalance = address(this).balance;

        uint256 totalBalance = wethBalance + etherBalance;

        if (totalBalance == 0) {
            return;
        }

        uint256 managementFee = (totalBalance * 2) / 100;
        uint256 purchaseAmount = (totalBalance * 98) / 100;
        uint256 etherToWithdraw = managementFee - etherBalance;

        if (etherToWithdraw > 0) {
            IWETH(payable(WETH)).withdraw(etherToWithdraw);
        }
        (bool success, ) = address(owner).call{value: managementFee}("");
        require(success);

        address token;
        uint256 ethAmount;
        IndexComponent memory component;
        for (uint8 i = 0; i < tokens.length; ) {
            token = tokens[i];
            component = components[token];
            ethAmount = (component.weight * purchaseAmount) / 100;
            if (component.version == UniswapVersion.V2) {
                _purchaseFromV2(token, ethAmount);
            } else {
                _purchaseFromV3(token, ethAmount, component.fee);
            }
            unchecked {
                i++;
            }
        }

        lastPurchase = block.timestamp;
    }

    function isERC20(address tokenAddress) internal returns (bool) {
        bytes memory payload = abi.encodeWithSignature("totalSupply()");
        (bool success, bytes memory result) = tokenAddress.call(payload);
        return success && result.length > 0;
    }

    function updateWeights(IndexComponent[] calldata newComponents) external {
        _requireIsOwner();
        uint8 totalWeight;
        for (uint8 i = 0; i < newComponents.length; ) {
            totalWeight += newComponents[i].weight;
            unchecked {
                i++;
            }
        }
        require(totalWeight == 100, "!valid");
        for (uint i = 0; i < allTokens.length; ) {
            address token = allTokens[i];
            delete components[token];
            emit IndexComponentUpdated(token, 0);
            unchecked {
                i++;
            }
        }
        delete tokens;
        IndexComponent memory currentComponent;
        for (uint i = 0; i < newComponents.length; ) {
            currentComponent = newComponents[i];
            require(isERC20(currentComponent.token), "Not ERC20");
            components[currentComponent.token] = currentComponent;
            tokens.push(currentComponent.token);
            if (!hasToken[currentComponent.token]) {
                hasToken[currentComponent.token] = true;
                allTokens.push(currentComponent.token);
            }
            emit IndexComponentUpdated(
                currentComponent.token,
                currentComponent.weight
            );
            unchecked {
                i++;
            }
        }
    }

    function redeem(uint256 amount) external {
        require(index != address(0));
        require(amount > 0, "!tokens");
        uint256 share = (amount * MAX_BPS) / ERC20(index).totalSupply();

        IChad(index).burn(msg.sender, amount);

        address token;
        uint256 allocation;
        uint256 contractBalance;
        for (uint8 i = 0; i < allTokens.length; ) {
            token = allTokens[i];
            contractBalance = ERC20(token).balanceOf(address(this));
            if (contractBalance > 0) {
                allocation = (contractBalance * share) / MAX_BPS;
                ERC20(token).safeTransfer(msg.sender, allocation);
                emit TokenRedeemed(token, allocation);
            }
            unchecked {
                i++;
            }
        }

        if (lastPurchase != 0 && lastPurchase + 15 days < block.timestamp) {
            // anti-rug vector, if deployed dies or project stagnates the initial LP can be redeemed + all added liquidity
            address liquidityAddress = IChad(index).uniswapV2Pair();
            uint256 liquidityBalance = ERC20(liquidityAddress).balanceOf(
                address(this)
            );
            uint256 liquidityAllocation = (liquidityBalance * share) / MAX_BPS;
            if (liquidityAllocation > 0) {
                uniswapV2Router.removeLiquidity(
                    WETH,
                    index,
                    liquidityAllocation,
                    0,
                    0,
                    address(this),
                    block.timestamp
                );
            }
            uint256 chadRemoved = ERC20(index).balanceOf(address(this));
            IChad(index).burn(address(this), chadRemoved);

            // anti-rug vector, if deployer dies or never updates the index - can redeem for weth
            uint256 wethBalance = ERC20(WETH).balanceOf(address(this));
            uint256 wethAllocation = (wethBalance * share) / MAX_BPS;
            if (wethAllocation > 0) {
                ERC20(WETH).safeTransfer(msg.sender, wethAllocation);
            }
        }
    }

    function sellToken(address token) external {
        _requireIsOwner();

        IndexComponent memory component = components[token];
        uint256 tokenBalance = ERC20(token).balanceOf(address(this));

        if (tokenBalance == 0) {
            return;
        }

        if (component.version == UniswapVersion.V2) {
            _sellToV2(token, tokenBalance);
        } else {
            _sellToV3(token, tokenBalance, component.fee);
        }

        // Update structures
        delete components[token];
        hasToken[token] = false;
        _removeTokenFromArray(token);

        uint8 weightToRemove = component.weight;
        uint8 remainingTokens = uint8(tokens.length);
        if (remainingTokens > 0) {
            uint8 distributeWeight = weightToRemove / remainingTokens;
            for (uint8 i = 0; i < tokens.length; i++) {
                components[tokens[i]].weight += distributeWeight;
            }
        }
    }

    function redemptionAmounts() external view returns (TokenAmount[] memory) {
        TokenAmount[] memory tokenAmounts = new TokenAmount[](allTokens.length);
        for (uint8 i = 0; i < allTokens.length; ) {
            address token = allTokens[i];
            tokenAmounts[i].token = token;
            tokenAmounts[i].amount = ERC20(token).balanceOf(address(this));
            unchecked {
                i++;
            }
        }
        return tokenAmounts;
    }

    function currentTokenCount() external view returns (uint256) {
        return tokens.length;
    }

    function totalTokenCount() external view returns (uint256) {
        return allTokens.length;
    }

    function _removeTokenFromArray(address token) private {
        uint256 indexToRemove;
        bool found = false;
        for (uint256 i = 0; i < allTokens.length; i++) {
            if (allTokens[i] == token) {
                indexToRemove = i;
                found = true;
                break;
            }
        }
        require(found, "Token not found in allTokens");

        if (indexToRemove < allTokens.length - 1) {
            allTokens[indexToRemove] = allTokens[allTokens.length - 1];
        }
        allTokens.pop();
    }

    function _sellToV2(address token, uint256 amount) internal {
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = WETH;
        ERC20(token).approve(address(uniswapV2Router), type(uint256).max);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _sellToV3(address token, uint256 amount, uint24 fee) internal {
        ERC20(token).approve(address(uniswapV3Router), type(uint256).max);
        uniswapV3Router.exactInput(
            ISwapRouter.ExactInputParams({
                path: abi.encodePacked(token, fee, WETH),
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amount,
                amountOutMinimum: 0
            })
        );
    }

    function _purchaseFromV2(address token, uint256 amount) internal {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = token;
        uint256 balanceBefore = ERC20(token).balanceOf(address(this));
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 balanceAfter = ERC20(token).balanceOf(address(this));
        emit TokenPurchased(token, balanceAfter - balanceBefore);
    }

    function _purchaseFromV3(
        address token,
        uint256 amount,
        uint24 fee
    ) internal {
        uint256 balanceBefore = ERC20(token).balanceOf(address(this));
        uniswapV3Router.exactInput(
            ISwapRouter.ExactInputParams({
                path: abi.encodePacked(WETH, fee, token),
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amount,
                amountOutMinimum: 0
            })
        );
        uint256 balanceAfter = ERC20(token).balanceOf(address(this));
        emit TokenPurchased(token, balanceAfter - balanceBefore);
    }
}
