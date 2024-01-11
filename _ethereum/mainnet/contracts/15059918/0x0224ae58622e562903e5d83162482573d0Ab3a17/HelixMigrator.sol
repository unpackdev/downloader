// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Pausable.sol";
import "./Ownable.sol";

import "./IHelixMigrator.sol";
import "./IHelixV2Router02.sol";
import "./IExternalRouter.sol";

contract HelixMigrator is Pausable, Ownable {
    using SafeERC20 for IERC20;

    IHelixV2Router02 public router;

    constructor(address _router) {
        require(_router != address(0), "Migrator: zero address");
        router = IHelixV2Router02(_router);
    }

    event MigrateLiquidity(
        address indexed sender,             // Migrate liquidity function caller
        address indexed tokenA,             // First token migrated
        address indexed tokenB,             // Second token migrated
        address externalRouter,             // External DEX's router
        uint256 exLiquidity,                // Liquidity in external DEX
        uint256 exBalanceTokenA,            // Token A balance in external DEX
        uint256 exBalanceTokenB,            // Token B balance in external DEX
        uint256 liquidity,                  // Liquidity moved to DEX
        uint256 balanceTokenA,              // Token A balance moved to DEX
        uint256 balanceTokenB               // Token B balance moved to DEX
    );

    /// Migrate _lpToken composed of _tokenA and _tokenB from _externalRouter to router
    function migrateLiquidity(
        address _tokenA, 
        address _tokenB, 
        address _lpToken, 
        address _externalRouter
    ) 
        external 
        whenNotPaused
    {
        IERC20 lpToken = IERC20(_lpToken);
        // Transfer the caller's external liquidity balance to this contract
        uint256 exLiquidity = lpToken.balanceOf(msg.sender);
        require(exLiquidity > 0, "Migrator: no balance to migrate");
        require(
            exLiquidity <= lpToken.allowance(msg.sender, address(this)),
            "Migrator: insufficient allowance"
        );
        lpToken.safeTransferFrom(msg.sender, address(this), exLiquidity);
        lpToken.safeApprove(_externalRouter, exLiquidity);

        // Remove the token balances from the external exchange
        (uint256 exBalanceTokenA, uint256 exBalanceTokenB) = IExternalRouter(_externalRouter).removeLiquidity(
            _tokenA,            // address of tokenA
            _tokenB,            // address of tokenB
            exLiquidity,        // amount of liquidity to remove
            0,                  // minimum amount of A
            0,                  // minimum amount of B
            address(this),      // recipient of underlying assets
            block.timestamp     // deadline until tx revert
        );

        // Approve this router to spend up to the external token balances
        IERC20(_tokenA).safeApprove(address(router), exBalanceTokenA);
        IERC20(_tokenB).safeApprove(address(router), exBalanceTokenB);

        // Move the external token balances to this exchange
        // Note: addLiquidity handles adding token pair to factory
        (uint256 balanceTokenA, uint256 balanceTokenB, uint256 liquidity) = router.addLiquidity(
            _tokenA,            // address of token A
            _tokenB,            // address of token B
            exBalanceTokenA,    // desired amount of A
            exBalanceTokenB,    // desired amount of B
            0,                  // minimum amount of A
            0,                  // minimum amount of B
            msg.sender,         // liquidity tokens recipient
            block.timestamp     // deadline until tx revert
        ); 

        // Log relevant migration details
        emit MigrateLiquidity(
            msg.sender,
            _tokenA,
            _tokenB,
            _externalRouter,
            exLiquidity,
            exBalanceTokenA,
            exBalanceTokenB,
            liquidity,
            balanceTokenA,
            balanceTokenB
        );
    }

    /// Called by the owner to set the router address
    function setRouter(address _router) external onlyOwner {
        require(_router != address(0), "Migrator: zero address");
        router = IHelixV2Router02(_router);
    }

    /// Called by the owner to pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    /// Called by the owner to unpause the contract
    function unpause() external onlyOwner {
        _unpause(); 
    }
}
