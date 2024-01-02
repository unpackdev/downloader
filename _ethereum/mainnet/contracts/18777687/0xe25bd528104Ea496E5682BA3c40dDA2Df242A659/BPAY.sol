// SPDX-License-Identifier: MIT

/**
██████╗░██████╗░░█████╗░██╗░░░██╗
██╔══██╗██╔══██╗██╔══██╗╚██╗░██╔╝
██████╦╝██████╔╝███████║░╚████╔╝░
██╔══██╗██╔═══╝░██╔══██║░░╚██╔╝░░
██████╦╝██║░░░░░██║░░██║░░░██║░░░
╚═════╝░╚═╝░░░░░╚═╝░░╚═╝░░░╚═╝░░░
                        ...                       
              ,%@@@@@@@@@@@@@@@@@@@*.             
          *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.         
       ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       
     *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.    
    @@@@@@@@@@@@@@@@@@.......@@@@@@@@@@@@@@@@@#   
  /@@@@@@@@@@@@@@@@@@.........@@@@@@@@@@@@@@@@@@  
 *@@@@@@@@@@@@.......@.......@.......@@@@@@@@@@@@ 
 @@@@@@@@@@@@.........@@@@@@@.........@@@@@@@@@@@,
*@@@@@@@@@@@@@.......@.......@ ......@@@@@@@@@@@@@
(@@@@@@@@@@@@@@@@@@@@.........@@@@@@@@@@@@@@@@@@@@@
,@@@@@@@@@@@@@.......@.......@.......@@@@@@@@@@@@:
 @@@@@@@@@@@@.........@@@@@@@.........@@@@@@@@@@@@
 .@@@@@@@@@@@@.......@.......@.......@@@@@@@@@@@@
  ,@@@@@@@@@@@@@@@@@@.........@@@@@@@@@@@@@@@@@@@  
    @@@@@@@@@@@@@@@@@@.......@@@@@@@@@@@@@@@@@@,   
     ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@     
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*       
          ,&@@@@@@@@@@@@@@@@@@@@@@@@@@@*          
               (@@@@@@@@@@@@@@@@@@@*                               
*/

pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./Ownable.sol";

contract BPAY is ERC20, Ownable {
    // Addresses for different allocations
    address public immutable presaleContract;
    address public immutable marketingAddr;
    address public immutable liquidityAddr;
    address public immutable charityAddr;
    address public immutable devAddr;
    address public immutable communityAddr;
    address public immutable teamAddr;

    // Allocation Percentages (Tokenomics)
    uint256 public constant PRESALE = 45;
    uint256 public constant MARKETING = 15;
    uint256 public constant LIQUIDITY = 10;
    uint256 public constant CHARITY = 10;
    uint256 public constant DEVELOPMENT = 10;
    uint256 public constant COMMUNITY = 5;
    uint256 public constant TEAM = 5;

    uint256 public constant TOTAL_SUPPLY = 31_000_000_000 * (10 ** 18);

    // Amount of tokens per allocation
    uint256 public constant presaleAllocation = (PRESALE * TOTAL_SUPPLY) / 100;
    uint256 public constant marketingAllocation = (MARKETING * TOTAL_SUPPLY) / 100;
    uint256 public constant exchangeAndLiquidityAllocation =
        (LIQUIDITY * TOTAL_SUPPLY) / 100;
    uint256 public constant charityAllocation = (CHARITY * TOTAL_SUPPLY) / 100;
    uint256 public constant developmentAllocation = (DEVELOPMENT * TOTAL_SUPPLY) / 100;
    uint256 public constant communityRewardsAllocation =
        (COMMUNITY * TOTAL_SUPPLY) / 100;
    uint256 public constant teamAllocation = (TEAM * TOTAL_SUPPLY) / 100;

    // Time when the team's tokens are unlocked
    uint256 public immutable teamUnlockTime;

    modifier onlyAfterTeamUnlock() {
        require(
            block.timestamp >= teamUnlockTime,
            "Team tokens are not yet unlocked"
        );
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _presaleAddress,
        address _marketingAddress,
        address _exchangeAndLiquidityAddress,
        address _charityAddress,
        address _developmentAddress,
        address _communityRewardsAddress,
        address _teamAddress
    ) ERC20(_name, _symbol) Ownable(msg.sender) {
        // Assign addresses
        presaleContract = _presaleAddress;
        marketingAddr = _marketingAddress;
        liquidityAddr = _exchangeAndLiquidityAddress;
        charityAddr = _charityAddress;
        devAddr = _developmentAddress;
        communityAddr = _communityRewardsAddress;
        teamAddr = _teamAddress;

        // Mint tokens to specified addresses
        _mint(presaleContract, presaleAllocation);
        _mint(marketingAddr, marketingAllocation);
        _mint(liquidityAddr, exchangeAndLiquidityAllocation);
        _mint(charityAddr, charityAllocation);
        _mint(devAddr, developmentAllocation);
        _mint(communityAddr, communityRewardsAllocation);

        // Set team unlock time
        teamUnlockTime = block.timestamp + 2 * 365 days;
    }

    function releaseTokenToTeam() external onlyAfterTeamUnlock {
        _mint(teamAddr, teamAllocation);
    }

    /**
     * @dev Burn tokens from owners wallet
     * @param _amount Token amount to be burned
     */
    function burn(uint256 _amount) external {
        _burn(_msgSender(), _amount);
    }
}