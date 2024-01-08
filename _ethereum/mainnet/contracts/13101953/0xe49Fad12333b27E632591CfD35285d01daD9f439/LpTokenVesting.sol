//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/*
This contract receives XRUNE from the Thorstarter grants multisig and some
project tokens, then, when ready, an owner calls the `lock` method and both
tokens are paired in an AMM and the LP tokens are locked in this contract.
Over time, each party can claim their vested tokens. Each party is owed an
equal share of the initial amount of LP tokens. If a pool already exist, we
attempt to swap some amount of tokens to bring the price in line with the target
price.
*/

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router.sol";
import "./IUniswapV2Factory.sol";

contract LpTokenVesting {
    using SafeERC20 for IERC20;

    struct Party {
      uint claimedAmount;
      mapping(address => bool) owners;
    }

    IERC20 public token0;
    IERC20 public token1;
    IUniswapV2Router public sushiRouter;
    uint public vestingCliff;
    uint public vestingLength;

    uint public partyCount;
    mapping(uint => Party) public parties;
    mapping(address => bool) public owners;
    uint public initialLpShareAmount;
    uint public vestingStart;

    event Claimed(uint party, uint amount);
    event Locked(uint time, uint amount, uint balance0, uint balance1);

    constructor(address _token0, address _token1, address _sushiRouter, uint _vestingCliff, uint _vestingLength, address[] memory _owners) {
        (_token0, _token1) = _token0 < _token1 ? (_token0, _token1) : (_token1, _token0);
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
        sushiRouter = IUniswapV2Router(_sushiRouter);
        vestingCliff = _vestingCliff;
        vestingLength = _vestingLength;
        partyCount = _owners.length;
        for (uint i = 0; i < _owners.length; i++) {
            Party storage p = parties[i];
            p.owners[_owners[i]] = true;
            owners[_owners[i]] = true;
        }
    }

    modifier onlyOwner {
        require(owners[msg.sender], "not an owner");
        _;
    }

    function toggleOwner(uint party, address owner) public {
        Party storage p = parties[party];
        require(p.owners[msg.sender], "not an owner of this party");
        p.owners[owner] = !p.owners[owner];
        owners[owner] = p.owners[owner];
    }

    function partyClaimedAmount(uint party) public view returns (uint) {
        return parties[party].claimedAmount;
    }

    function partyOwner(uint party, address owner) public view returns (bool) {
        return parties[party].owners[owner];
    }

    function pair() public view returns (address) {
        return IUniswapV2Factory(sushiRouter.factory()).getPair(address(token0), address(token1));
    }
    
    function claimable(uint party) public view returns (uint) {
        if (vestingStart == 0 || party >= partyCount) {
            return 0;
        }
        Party storage p = parties[party];
        uint percentVested = (block.timestamp - _min(block.timestamp, vestingStart + vestingCliff)) * 1e6 / vestingLength;
        if (percentVested > 1e6) {
            percentVested = 1e6;
        }
        return ((initialLpShareAmount * percentVested) / 1e6 / partyCount) - p.claimedAmount;
    }
    
    function claim(uint party) public returns (uint) {
        Party storage p = parties[party];
        require(p.owners[msg.sender], "not an owner of this party");
        uint amount = claimable(party);
        if (amount > 0) {
            p.claimedAmount += amount;
            IERC20(pair()).safeTransfer(msg.sender, amount);
            emit Claimed(party, amount);
        }
        return amount;
    }

    function lock() public onlyOwner {
        require(vestingStart == 0, "vesting already started");

        uint token0Balance = token0.balanceOf(address(this));
        uint token1Balance = token1.balanceOf(address(this));
        address pairAddress = pair();

        // If there's already a pair, we'll need to do a swap in order get the price in the right place
        if (pairAddress != address(0)) {
            IUniswapV2Pair pool = IUniswapV2Pair(pairAddress);
            uint targetPrice = (token0Balance * 1e6) / token1Balance;
            (uint112 reserve0, uint112 reserve1,) = pool.getReserves();
            uint currentPrice = (reserve0 * 1e6) / reserve1;
            uint difference = (currentPrice * 1e6) / targetPrice;
            if (difference < 995000) {
                // Current price is smaller than target (>0.5%), swap token1 for token0
                // We divide the amount of reserve1 to send that would balance the price
                // in two because an ammout of reserve0 is going to come out
                address[] memory path = new address[](2);
                path[0] = address(token0);
                path[1] = address(token1);
                // Multiply amount by 0.6 because swapping 100% of the difference would remove the
                // the equivalent amount from the opposite reserves (we're aiming for half that impact)
                uint amount = (reserve0 * (1e6 - difference) * 60) / 1e6 / 100;
                token0.safeApprove(address(sushiRouter), amount);
                sushiRouter.swapExactTokensForTokens(amount, 0, path, address(this), type(uint).max);
            }
            if (difference > 10050000) {
                // Current price is greater than target (>0.5%), swap token0 for token1
                address[] memory path = new address[](2);
                path[0] = address(token1);
                path[1] = address(token0);
                uint amount = (reserve1 * (difference - 1e6)) / 1e6 / 2;
                token1.safeApprove(address(sushiRouter), amount);
                sushiRouter.swapExactTokensForTokens(amount, 0, path, address(this), type(uint).max);
            }

            (reserve0, reserve1,) = pool.getReserves();
        }

        // Update balances in case we did a swap to adjust price
        token0Balance = token0.balanceOf(address(this));
        token1Balance = token1.balanceOf(address(this));
        token0.safeApprove(address(sushiRouter), token0Balance);
        token1.safeApprove(address(sushiRouter), token1Balance);
        sushiRouter.addLiquidity(
            address(token0), address(token1),
            token0Balance, token1Balance,
            (token0Balance * 9850) / 10000, (token1Balance * 9850) / 10000,
            address(this), type(uint).max
        );

        pairAddress = pair();
        initialLpShareAmount = IERC20(pairAddress).balanceOf(address(this));
        vestingStart = block.timestamp;
        emit Locked(vestingStart, initialLpShareAmount, token0Balance, token1Balance);
    }

    function withdraw(address token, uint amount) public onlyOwner {
       require(token == address(token0) || token == address(token1), "can only withdraw token{0,1}");
       IERC20(token).safeTransfer(msg.sender, amount);
    }

    function _min(uint a, uint b) private pure returns (uint) {
        return a < b ? a : b;
    }
}
