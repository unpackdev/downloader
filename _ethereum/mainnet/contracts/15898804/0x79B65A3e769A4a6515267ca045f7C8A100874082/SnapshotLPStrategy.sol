// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "./IFraxFarm.sol";

/** 
@notice To enable this strategy:
- Deploy this contract with DeployStakedLPVotes.s.sol script
- Obtain the address and insert it into the script below at `<Snapshot_LP_Strategy_Contract_Address>` 
- Copy the script (including the first & last curly brackets).
- At snapshot.org, go to the space you want to enable this strategy for, and click on "Settings" -> "Strategie(s)" -> "Add Strategy"
- Find the strategy named `contract-call` and overwrite what is in there with this (with the address updated)
- Click `Add`
- Now when a new Snapshot is created, it will include this strategy & give users the ability to vote even though they're staked in LPs

The script for Snapshot strategy using "contract-call" strategy:

{
  "address": "<Snapshot_LP_Strategy_Contract_Address",
  "symbol": "FraxfarmStkPitchFxsFraxFraxswapLP",
  "decimals": 18,
  "methodABI": {
    "inputs": [
      {
        "internalType": "address",
        "name": "account",
        "type": "address"
      }
    ],
    "name": "getVotes",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  }
}

*/

/// @title SnapshotLPStrategy
/// @notice Get's a user's number of pitchFXS from a staked position of LP on a FraxFarm.
/// @author Pitch Foundation

contract SnapshotLPStrategy {
    /// @notice The pitch deployer address.
    address public constant OWNER = address(0x092308e1DCDeCA61bF1153Dd92E15eD08E164982);
    /// @notice The pitchFXS-FRAX LP token address.
    address public pitchFxsFraxswapPair;
    /// @notice The FraxFarm staking contract address.
    address public pitchFxsFraxFarm;

    constructor() {
        pitchFxsFraxswapPair = address(0x0a92aC70B5A187fB509947916a8F63DD31600F80);
        pitchFxsFraxFarm = address(0x24C66Ba25ca2A53bB97B452B9F45DD075b07Cf55);
    }

    /// @notice Updates the addresses of the pitchFXS-FRAX LP token and the FraxFarm staking contract.
    /// @dev Callable only by PitchDeployer (owner).
    /// @param _pitchFxsFraxswapPair The address of the pitchFXS-FRAX LP token.
    /// @param _pitchFxsFraxFarm The address of the FraxFarm staking contract.
    function setAddresses(address _pitchFxsFraxswapPair, address _pitchFxsFraxFarm) external {
        if (msg.sender != OWNER) revert("!OWNER");

        pitchFxsFraxswapPair = _pitchFxsFraxswapPair;
        pitchFxsFraxFarm = _pitchFxsFraxFarm;
    }

    /// @notice Returns `account` balance of pitchFXS in the LP pair in WEI.
    /// @param account The address of the account to look up balance of.
    /// @return votes The balance of pitchFXS in the LP pair in WEI.
    function getVotes(address account) external view returns (uint256 votes) {
        // Get the user's total locked stakes liquidity (number of LP tokens)
        uint256 liquidity = IFraxFarm(pitchFxsFraxFarm).lockedLiquidityOf(account);

        // Get the current number of FRAX per LP token
        uint256 fraxPerLp = IFraxFarm(pitchFxsFraxFarm).fraxPerLPToken();

        // Get the current reserves from fraxswap pair
        (uint112 token0Reserve, uint112 token2Reserve, ) = IFraxswap(pitchFxsFraxswapPair).getReserves();

        // convert to uint256 for calculations
        uint256 token0Amt = uint256(token0Reserve);
        uint256 token1Amt = uint256(token2Reserve);

        // votes in wei
        votes = ((liquidity * fraxPerLp) * ((1e18 * token0Amt) / token1Amt)) / 1e36; // or if we want it in ether: ((liquidity * fraxPerLp / 1e18);
    }
}
