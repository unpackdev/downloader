// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./ERC20Presaleable.sol";
import "./ERC20Vestable.sol";
import "./ERC20Burnable.sol";
import "./IUniswapV2Router02.sol";
import "./IERC20.sol";

contract ApeToken is ERC20Burnable, ERC20Vestable, ERC20Presaleable {
    IUniswapV2Router02 private router;
    uint256 public constant MAX_INT = uint256(-1);
    uint256 public stakingPoolDateAdd;
    address public stakingPoolPending;

    address
        public constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    event LiquidityAdded(
        uint256 amountToken,
        uint256 amountEth,
        uint256 liquidity
    );

    event DeveloperAddedPendingPool(address pendingPool);
    event DeveloperAddedPool(address pool);

    constructor(
        address payable secondDeveloper,
        address[] memory stakingPools,
        address marketing,
        uint256 presaleCap,
        address[] memory supporters,
        uint256[] memory supporterRewards
    )
        public
        ERC20("Ape.cash V2", "APEv2")
        RoleAware(msg.sender, stakingPools)
        ERC20Presaleable(presaleCap)
    {
        
        // number of tokens is vested over 3 months, see ERC20Vestable
        _addBeneficiary(msg.sender, 105000, 10 days, true);
        _addBeneficiary(secondDeveloper, 45000, 10 days, true);
        _addBeneficiary(marketing, 50000, 10 days, true);
        
        router = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);

        for (uint256 index = 0; index < supporters.length; index++) {
            _mint(supporters[index], supporterRewards[index]);
        }
    }

    // developer can add staking pools. as these can mint, function is timelocked for 24 hours
    function addStakingPoolConfirm() public onlyDeveloper {
        require(now >= stakingPoolDateAdd.add(24 hours));
        grantRole(STAKING_POOL_ROLE, stakingPoolPending);
        grantRole(WHITELIST_ROLE, stakingPoolPending);
        emit DeveloperAddedPool(stakingPoolPending);
    }

    function addStakingPoolInitial(address stakingPool) public onlyDeveloper {
        stakingPoolDateAdd = now;
        stakingPoolPending = stakingPool;
        emit DeveloperAddedPendingPool(stakingPool);
    }

    // allow contracts with role ape staking pool to mint rewards for users
    function mint(address to, uint256 amount)
        public
        onlyStakingPool
        nonReentrant
    {
        if (totalSupply() <= maximumSupply) {
            _mint(to, amount);
        }
    }

    function listOnUniswap() public onlyDeveloper {
        // mint 1800 APE per held ETH to list on Uniswap
        setTradeable();
        timeListed = now;
        addWhitelist(UNISWAP_ROUTER_ADDRESS);

        addWhitelist(uniswapEthPair);
        uint256 ethBalance = address(this).balance;
        uint256 apeBalance = ethBalance.mul(uniswapApePerEth);

        _mint(address(this), apeBalance);

        _approve(address(this), address(router), apeBalance);

        (uint256 amountToken, uint256 amountEth, uint256 liquidity) = router
            .addLiquidityETH{value: ethBalance}(
            address(this),
            apeBalance,
            apeBalance,
            ethBalance,
            address(0),
            block.timestamp + uint256(5).mul(1 minutes)
        );

        revokeRole(WHITELIST_ROLE, uniswapEthPair);
        revokeRole(WHITELIST_ROLE, UNISWAP_ROUTER_ADDRESS);

        addWhitelistFrom(uniswapEthPair);
        stopPresale();

        uniswapPairImpl = IUniswapV2Pair(uniswapEthPair);
        emit LiquidityAdded(amountToken, amountEth, liquidity);
    }

    function empty() public nonReentrant onlyDeveloper {
        _developer.transfer(address(this).balance);
    }

    function transfer(address recipient, uint256 amount)
        public
        override(ERC20Burnable, ERC20)
        returns (bool)
    {
        return ERC20Burnable.transfer(recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override(ERC20Burnable, ERC20) returns (bool) {
        return ERC20Burnable.transferFrom(sender, recipient, amount);
    }

}
