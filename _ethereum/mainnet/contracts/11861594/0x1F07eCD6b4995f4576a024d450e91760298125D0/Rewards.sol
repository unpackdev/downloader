// SPDX-License-Identifier: Unlicense

pragma solidity ^0.7.6;

import "./IERC20.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

/**
 * @title Rewards is for holding all value (Tokens and Ether) in the Game System 
 * @notice All functions are only callable by the creator, which is the Game contract,
 * with a notable exception being the payable Ether fallback function, because the Uniswap Router
 * will be sending Ether here
 * @dev This contract needs to exist, and be its own instance, because a Uniswap Pair will not
 * swap tokens _to_ the contract which is one of it's own tokens. For this reason, we need to initiate
 * swaps from a different address; hence, this contract exists.
 */
contract Rewards {
    /**
     * @notice contract address of the main Game token contract
     */
    address public game;

    /**
     * @notice Addresses of the Uniswap and Router
     */
    IUniswapV2Router02 public immutable uniswapV2Router;

    // used for a safety check in the payable receive function
    // once the game is over, no more Ether can be deposited from anyone except Uniswap router
    uint256 private _endTime;

    constructor(address _game, IUniswapV2Router02 router, uint256 endTime) {
        game = _game;
        uniswapV2Router = router;
        _endTime = endTime;
    }

    /**
     * @notice reverts if the msg.sender is not the Game contract address
     */
    modifier onlyGame() {
        require(msg.sender == game, "Rewards::onlyGame: msg.sender must be the Game contract");
        _;
    }

    /**
     * @notice Accept an amount of Tokens, some Ether, and add them to liquidity on the Token-ETH pair.
     * The tokens must have already been transfered to this contract. The Ether is payable, so attached to the function call.
     * Only callable by the Game address.
     * @param tokenAmount a number of tokens to be added as liquidity
     * @return amountToken the amount of tokens which were successfully added to liquidity; will be <= the input `tokenAmount`
     * @return amountETH the amount of Ether which were successfully added to liquidity; will be <= the input msg.value
     * @return liquidity the number of Token-ETH LP tokens which were created and transfered to this contract
     * @dev any remaining Tokens or Ether which weren't added to liquidity, are refunded to this contract
     */
    function addLiquidityETH(uint256 tokenAmount) onlyGame public payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity) {
        // there are no limits on the expected amount of liquidity which are added, simply send all of the input Tokens and Ether
        (amountToken, amountETH, liquidity) = uniswapV2Router.addLiquidityETH{ value: msg.value }(game, tokenAmount, 0, 0, address(this), block.timestamp);
    }

    /**
     * @notice Accept a Pair address, and an amount of liquidity tokens, and removes that liquidity from the Token-ETH pair
     * Only callable by the Game address.
     * @param pair address of the Uniswap Pair that we're removing liquidity from (in practice, will always be the Token-ETH pair address)
     * @param liquidityBalance the amount of LP tokens to remove from liquidity
     * @dev The pair address is needed to approve token transfer for the Uniswap router, since this contract holds the LP tokens
     * @dev This contract is the recipient of removed Tokens and Ether
     */
    function removeLiquidityETH(IUniswapV2Pair pair, uint256 liquidityBalance) onlyGame public {
        // approve the Uniswap router to be able to transfer LP tokens of this contract
        pair.approve(address(uniswapV2Router), liquidityBalance);

        // no limits on the min amounts of Tokens or ETH which are removed
        uniswapV2Router.removeLiquidityETH(game, liquidityBalance, 0, 0, address(this), block.timestamp);
    }

    /**
     * @notice Accepts payable Ether, and swaps all of it for Tokens
     * Only callable by the Game address.
     * @return amount the amount of Tokens which were acquired from the swap
     * @dev This contract is the recipient of acquired Tokens
     */
    function swapExactETHForTokens(uint256 amountOutMin) onlyGame public payable returns (uint256 amount) {
        // build the WETH -> Token path
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = game;

        // no limits on the amount of Tokens which are received
        uint256[] memory amounts = uniswapV2Router.swapExactETHForTokens{ value: msg.value }(amountOutMin, path, address(this), block.timestamp);
        amount = amounts[1];
    }

    /**
     * @notice Accepts an amount of Tokens, and swaps all of them for Ether
     * Only callable by the Game address.
     * @param amountToken the number of tokens to swap for Ether
     * @dev This contract is the recipient of acquired Ether
     */
    function swapExactTokensForETH(uint256 amountToken) onlyGame public {
        // build the Token -> WETH path
        address[] memory path = new address[](2);
        path[0] = game;
        path[1] = uniswapV2Router.WETH();

        uint256 amountsOut = uniswapV2Router.getAmountsOut(amountToken, path)[1];

        // Don't call swap if there's no ETHs to receive
        if (amountsOut == 0) {
            return;
        }

        // no limits on the amount of Ether which are received
        uniswapV2Router.swapExactTokensForETH(amountToken, 0, path, address(this), block.timestamp);
    }

    /**
     * @notice Accepts and address and an Ether value, and transfers that much Ether to the address
     * Only callable by the Game address.
     * @param to payable address that the Ether should be sent to
     * @param amount the amount of Ether to send
     * @dev the Ether needs to already belong to this contract, it's not passed through this function
     */
    function sendEther(address payable to, uint256 amount) onlyGame public {
        to.transfer(amount);
    }

    /**
     * @notice Sends all balance of a given token to the game contract - used to recover locked non-game related tokens
     * Only callable by the Game address.
     * @param token an address of the token contract
     */
    function recoverToken(address token) onlyGame external {
        uint256 myBalance = IERC20(token).balanceOf(address(this));
        if (myBalance > 0) {
            IERC20(token).transfer(game, myBalance);
        }
    }

    /**
     * @notice The fallback function for this contract to accept Ether
     */
    receive() external payable {
        // if the msg.sender is the Uniswap Router address, always accept the Ether
        if (msg.sender != address(uniswapV2Router)) {
            // Otherwise, only accept Ether from anyone else during the actual gameplay
            require(_endTime > block.timestamp, "Rewards::receive: game is over! no more depositing into the rewards contract");
        }
    }
}
