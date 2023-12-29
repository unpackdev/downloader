pragma solidity ^0.6.8;

import "./Ownable.sol";

import "./ZoraAuthorized.sol";
import "./TransferProxy.sol";

import "./IUniswapExchange.sol";
import "./IOriginalDropToken02.sol";

contract OriginalDropWrapper01 is Ownable {

    /* ============ Variables ============ */

    ZoraAuthorized public zoraAuthorized;

    TransferProxy public transferProxy;

    mapping (address => address) public tokenToExchange;

    /* ============ Modifiers ============ */

    modifier onlyAuthorized() {
        require(
            zoraAuthorized.isAuthorized(msg.sender) == true,
            "TradeWrapper: only authorized contract can call"
        );
        _;
    }

    // modifier ensureTokensTransferred(address tokenToCheck) {
    //     // Get the starting balance of the drop
    //     uint256 preBalance = IOriginalDropToken02(tokenToCheck).balanceOf(address(this));

    //     // Execute the function
    //     _;

    //     // Get the balance after all operations have been executed
    //     uint256 postBalance = IOriginalDropToken02(tokenToCheck).balanceOf(address(this));

    //     // Ensure that no tokens are stuck inside and the contract reverts if so
    //     require(
    //         preBalance == postBalance,
    //         "DropWrapper01: tokens were not transferred"
    //     );
    // }

    /* ============ Constructor ============ */

    constructor(
        address _zoraAuthorized,
        address _transferProxy
    )
        public
    {
        zoraAuthorized = ZoraAuthorized(_zoraAuthorized);
        transferProxy = TransferProxy(_transferProxy);
    }

    /* ============ Authorized Functions ============ */

    function setTokenToExchange(
        address dropToken,
        address uniswapExchange
    )
        public
        onlyAuthorized
    {
        tokenToExchange[dropToken] = uniswapExchange;
    }

    /**
     * @dev Use a permit() signature and transfer tokens
     *      Only callable by an authorized user.
     */
    function proxyTransfer(
        address dropToken,
        address transferDestination,
        uint256 transferValue,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        public
        onlyAuthorized
    {

        // Submit the permit signature to the token
        IOriginalDropToken02(dropToken).permit(
            owner,
            spender,
            value,
            deadline,
            v,
            r,
            s
        );

        // Call the transfer function
        transfer(
            dropToken,
            owner,
            transferDestination,
            transferValue
        );

    }

    /**
     * @dev Use a permit() signature and sell tokens for ETH
     *      Only callable by an authorized user.
     */
    function proxySell(
        address dropToken,
        uint256 inputAmount,
        uint256 outputMinimum,
        uint256 uniswapDeadline,
        address outputDestination,
        address owner,
        address destination,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        public
        payable
        onlyAuthorized
    {

        // Submit the permit signature to the token
        IOriginalDropToken02(dropToken).permit(
            owner,
            destination,
            value,
            deadline,
            v,
            r,
            s
        );

        // Call the sell function
        sell(
            dropToken,
            owner,
            inputAmount,
            outputMinimum,
            uniswapDeadline,
            outputDestination
        );
    }

    /**
     * @dev Transfer tokens with a pre-existing approval
     *      Only callable by an authorized user.
     *
     * @param from  Address to transfer tokens from
     * @param to    Address to transfer tokens to
     * @param value Amount of tokens to spend
     */
    function transfer(
        address dropToken,
        address from,
        address to,
        uint256 value
    )
        public
        onlyAuthorized
        // ensureTokensTransferred(dropToken)
    {

        // Call the transfer proxy to transfer tokens
        // This will fail if the transfer proxy doesn't have approval from the user
        transferProxy.transferFrom(
            dropToken,
            from,
            to,
            value
        );

    }

    /**
     * @dev Buy tokens with a pre-existing approval
     *      Only callable by an authorized user.
     *
     * @param dropToken Address of the drop token to buy
     * @param outputMinimum Minimum amount of tokens expected from Uniswap
     * @param uniswapDeadline Deadline before Uniswap won't accept the order
     * @param outputDestination Address to forward tokens to
     */
    function buy(
        address dropToken,
        uint256 outputMinimum,
        uint256 uniswapDeadline,
        address outputDestination
    )
        public
        payable
        onlyAuthorized
        // ensureTokensTransferred(dropToken)
    {

        // Call Uniswap to buy tokens (ethToTokens function)
        IUniswapExchange uniswapExchange = IUniswapExchange(tokenToExchange[dropToken]);

        uniswapExchange.ethToTokenTransferInput.value(msg.value)(
            outputMinimum,
            uniswapDeadline,
            outputDestination
        );

    }

    /**
     * @dev Sell tokens with a pre-existing approval
     *      Only callable by an authorized user.
     *
     * @param dropToken Address of the drop token to sell
     * @param owner Address to move tokens on behalf of
     * @param inputAmount Amounts of tokens to sell
     * @param outputMinimum Minimum amount of ETH expected from Uniswap
     * @param uniswapDeadline Deadline before Uniswap won't accept the order
     * @param outputDestination Address to forward ETH to
     */
    function sell(
        address dropToken,
        address owner,
        uint256 inputAmount,
        uint256 outputMinimum,
        uint256 uniswapDeadline,
        address outputDestination
    )
        public
        onlyAuthorized
        // ensureTokensTransferred(dropToken)
    {
        transfer(
            dropToken,
            owner,
            address(this),
            inputAmount
        );

        IOriginalDropToken02(dropToken).approve(
            tokenToExchange[dropToken],
            inputAmount
        );

        // Call Uniswap to buy tokens (tokensToEth function)
        IUniswapExchange uniswapExchange = IUniswapExchange(tokenToExchange[dropToken]);

        uniswapExchange.tokenToEthTransferInput(
            inputAmount,
            outputMinimum,
            uniswapDeadline,
            outputDestination
        );

    }

}