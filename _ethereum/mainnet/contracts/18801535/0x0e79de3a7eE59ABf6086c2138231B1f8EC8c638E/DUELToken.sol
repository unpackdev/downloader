// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC20.sol";
import "./IUniswapV2Router.sol";

interface IVesting {
    function allocateDUEL(address, uint256) external;

    function allocateDUEL(address, uint256, uint256) external;

    function claimDUEL() external;
}

interface IStaking {
    function stakeFor(
        address wallet,
        uint256 amount,
        uint32 periodDays
    ) external;
}

/// @title Main ERC-20 DUEL Token with vesting contract connection and convertRain() functionality
/// @author Haider
/// @notice Contract is ownable for the period of vesting, ownership to renounced later
contract DUELToken is ERC20, Ownable {
    address private _rainToken;
    address private _wethToken;
    address private _usdtToken;
    address private _dynamicVestingContract;
    address private _stakingContract;
    uint256 private _markedUpRainValueUnit;
    uint256 public _deploymentTime;
    IUniswapV2Router _uniswapRouter;

    constructor(
        address rainToken,
        address wethToken,
        address usdtToken,
        IUniswapV2Router uniswapRouter
    ) Ownable(msg.sender) ERC20("DUEL Token", "DUEL") {
        _rainToken = rainToken;
        _wethToken = wethToken;
        _usdtToken = usdtToken;
        _uniswapRouter = uniswapRouter;
        _markedUpRainValueUnit = 1 * 10 ** 4;

        _deploymentTime = block.timestamp;
        _mint(owner(), 10000000000 * 10 ** 18); // 10bil total supply
    }

    function setVestingContract(address dynamicVesting) external onlyOwner {
        _dynamicVestingContract = dynamicVesting;
    }

    function setStakingContract(address newStaker) external onlyOwner {
        _stakingContract = newStaker;
    }

    function setRainMarkup(uint256 newRate) external onlyOwner {
        _markedUpRainValueUnit = newRate;
    }

    function getRainValue() public view returns (uint256) {
        address[] memory route = new address[](3);
        route[0] = address(_rainToken);
        route[1] = address(_wethToken);
        route[2] = address(_usdtToken);
        uint256[] memory amounts = _uniswapRouter.getAmountsOut(
            1 * 10 ** 18,
            route
        );
        return amounts[2];
    }

    function _convertInternal(
        uint256 rainAmount
    ) internal returns (uint256 baseDuelAmount, uint256 bonusDuelAmount) {
        IERC20(_rainToken).transferFrom(
            _msgSender(),
            0x000000000000000000000000000000000000dEaD,
            rainAmount
        );

        // [6 decimals] Fetch market price of RAIN in USD
        uint256 rainValueUnit = getRainValue();

        // [6 decimals] Calculate user's provided RAIN token's USD worth
        // Dividing by 10**18 is eliminating rainAmount's decimal offset
        uint256 rainValueUSD = (rainAmount * rainValueUnit) / 10 ** 18;

        uint markedUpRainValueUnit = 100000; // $0.01

        // It is the rain value that is decaying not the bonus
        if (block.timestamp >= _deploymentTime + 60 days) {
            markedUpRainValueUnit = 60000; // $0.006
        } else if (block.timestamp >= _deploymentTime + 30 days) {
            markedUpRainValueUnit = 80000; // $0.008
        }

        // [6 decimals] Calculate rewarded RAIN value in USD (including bonus)
        uint256 markedUpRainValueUSD = (block.timestamp >= _deploymentTime + 180 days)? rainValueUSD : (rainAmount * _markedUpRainValueUnit) / 10 ** 18;

        // [6 decimals] Set parameters for duel value at $0.0045
        uint256 duelValueUnit = 4500;
        uint256 duelValueBase = 10 ** 6;

        // [18 decimals] Calculate duel amount to reward in total (base + bonus)
        baseDuelAmount =
            ((markedUpRainValueUSD * duelValueBase) / duelValueUnit) *
            10 ** 12;

        // By default, we assume that there is no bonus, i.e. rainValueUSD > markedUpRainValueUSD
        // In this case, user will get all the baseDuelAmount after 30 days
        bonusDuelAmount = 0;

        // Check if bonus is applicable
        if (markedUpRainValueUSD > rainValueUSD) {
            // [6 decimals] Calculate the bonus value USD
            uint256 difference = markedUpRainValueUSD - rainValueUSD;

            // [18 decimals] Set the bonus duel amount for 90-days lockup
            bonusDuelAmount =
                ((difference * duelValueBase) / duelValueUnit) *
                10 ** 12;

            // [18 decimals] Set the 1:1 duel amount for 30-days lockup
            baseDuelAmount -= bonusDuelAmount;
        }
    }

    function convertRain(uint256 rainAmount) external {
        (uint256 baseDuelAmount, uint256 bonusDuelAmount) = _convertInternal(
            rainAmount
        );
        IVesting(_dynamicVestingContract).allocateDUEL(
            _msgSender(),
            baseDuelAmount,
            bonusDuelAmount
        );
    }

    function swapAndStake(uint256 rainAmount, uint32 stakePeriodDays) external {
        require(stakePeriodDays >= 3 * 30, "Minimum stake duration is 3 months");

        (uint256 baseDuelAmount, uint256 bonusDuelAmount) = _convertInternal(
            rainAmount
        );
        IStaking(_stakingContract).stakeFor(
            _msgSender(),
            baseDuelAmount + bonusDuelAmount,
            stakePeriodDays * 1 days
        );
    }
}
