/**

              !GJ                                                                                                   
            :YGB&B~                                                                                                 
          .?GGPB#&&P:                                                                                               
         !PGGGGB&##&#J                                                                                              
       ^5GGGPP5PBB###&#!                             :PG~    .GG!           7GG.                              ?G5   
     .JGGGGPJ??J55PB&#&&G:                           ~@@J    ^@@5           G@@:                              #@@.  
    7GGPPPPJ???J555P####&&5.          .7G&&&#P!    !B&@@&BB^ ^@@G!B&&&B?.   G@@~?#&&&#P~       :YB&&&#Y:    PB@@@#BG
  ^Y5YJJJ??????J555555PPGBBB7        Y@@B7~~?#@@7  ~G#@@&PG: ^@@@@PJJG@@@7  G@@@@P7!?P@@&!   .#@@5!^!5@@#.  5G@@@BGP
 ~J????????????Y55555555PGPGBJ      5@@Y......P@@7   ~@@J    ^@@#     .@@@  G@@#       B@@! .@@@^.....^@@@    B@@   
  :7???7???????YP555555Y5PGP!       &@@&#&&&&##&&5   ~@@J    ^@@5      #@@  G@@?       ~@@P ^@@@#&&&&&##&&:   #@@.  
    ^??7~~~~!77!55J?77?JPP7.        J@@G.    .?7^    ~@@J    ^@@5      #@@  G@@@^     :&@@:  &@@!     ~?!.    #@@.  
     .!??777?7^~!J5555PPY:           7&@@#PP#@@&~    !@@Y    ^@@5      &@@  G@@&@&GPB&@@G.    P@@&GPG&@@G.    #@@.  
       :7????!!7JJ5PPP5^               ^JGBBP?:      .YY^    .YY~      7YJ  ~JJ.:JGBGY~.       .!5BBB5!.      7YJ   
         ^?????JPP5PP7                                                                                              
           ~???JPPPJ.                                                                                               
            .!?JPY^                                                                                                 
              ^J7                                                                                                   

Website: https://www.ethbet.poker/
Telegram: https://t.me/ethbetpoker
Twitter: https://twitter.com/ethbetpoker
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./ERC20.sol";
import "./Ownable.sol";

/// @title EthBet Coin Token Contract
contract EBCToken is ERC20, Ownable {
    /// @notice The address of the Uniswap router contract
    address public router;
    /// @notice The address mapping of the pairs and their status
    mapping(address => bool) private pairs;
    /// @notice Boolean to check if trading is live
    bool public tradingLive;
    /// @notice Address allowed to provide liquididty for the EthBet Coin
    address public liquidityProvider;

    /// @notice Event emitted when the trading status is changed
    event TradingSet(bool status);
    /// @notice Event emitted when the liquididty provider is set
    event LiquidityProviderSet(address liquidityProvider);

    constructor(address _router) ERC20("EthBet Coin", "EBC") Ownable() {
        router = _router;
        _mint(msg.sender, 77_777_777 ether);
    }

    /// @notice Set the trading status
    /// @dev Callable only by owner
    /// @dev Emits the TradingSet event
    /// @param _status The new status of the trading, true for enabled, false for disabled
    function setTrading(bool _status) external onlyOwner {
        require(_status != tradingLive, "EBC: trading already set");
        tradingLive = _status;
        emit TradingSet(_status);
    }

    /// @notice Set Liquidity Provider
    /// @dev Callable only by owner
    /// @dev Emits the LiquidityProviderSet event
    /// @param _liquidityProvider Address allowed to add liquidity for EBC pairs (ex: Presale contract with autoliquidity)
    function setLiquidityProvider(address _liquidityProvider) external onlyOwner {
        liquidityProvider = _liquidityProvider;
        emit LiquidityProviderSet(_liquidityProvider);
    }

    /// @notice Adds the pairs to the mapping with their status
    /// @dev Callable only by owner
    /// @dev Callable only when trading is disabled
    /// @dev The length of both the arrays must be the same
    /// @param _pairs The array of pairs to be added
    /// @param _status The array of status to be added
    function setPairs(
        address[] calldata _pairs,
        bool[] calldata _status
    ) external onlyOwner {
        require(!tradingLive, "EBC: trading already enabled");
        require(_pairs.length == _status.length, "EBC: invalid parameters");
        for (uint256 i = 0; i < _pairs.length; i++) {
            pairs[_pairs[i]] = _status[i];
        }
    }

    /// @notice Overrides the transfer function to check if trading is disabled and only allow the owner to add liquidity to the whitelisted pairs
    /// @dev Emits the Transfer event
    /// @param from The address to transfer from
    /// @param to The address to transfer to
    /// @param amount The amount to be transferred
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "EBC: transfer from the zero address");
        require(to != address(0), "EBC: transfer to the zero address");

        // If trading is disabled:
        // - Only owner can add liquidity
        // - Only owner can remove liquidity
        if (!tradingLive) {
            // If liquidity is being removed:
            if (pairs[from]) {
                // Allow router/owner to take the liquidity
                // Note: for wETH liquidity removal tokens are transfered to router first
                require(to == router || to == owner(), "EBC: trading disabled");
            }
            // If liquidity is being added:
            else if (pairs[to]) {
                // Allow only owner/liquidityProvider
                require(from == owner() || from == liquidityProvider, "EBC: trading disabled");
            }
            // If liquidity is being transfered from router (liquidity withdrawal):
            // Note: for wETH liquidity removal tokens are transfered to router first then to the user
            else if (from == router) {
                // Allow only owner
                require(to == owner(), "EBC: trading disabled");
            }
        }

        super._transfer(from, to, amount);
    }
}
