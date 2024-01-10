pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface ICurveCvxCrvStableSwap {
  function add_liquidity(
      uint256[2] calldata _amounts,
      uint256 _min_mint_amount,
      address _receiver
  ) external returns(uint256);

  function calc_token_amount(
      uint256[2] calldata _amounts,
      bool _is_deposit
  ) external view returns(uint256);
}

// @external
// @nonreentrant('lock')
// def add_liquidity(
//     _amounts: uint256[N_COINS],
//     _min_mint_amount: uint256,
//     _receiver: address = msg.sender
// ) -> uint256:
//     """
//     @notice Deposit coins into the pool
//     @param _amounts List of amounts of coins to deposit
//     @param _min_mint_amount Minimum amount of LP tokens to mint from the deposit
//     @param _receiver Address that owns the minted LP tokens
//     @return Amount of LP tokens received by depositing
//     """

// @view
// @external
// def calc_token_amount(_amounts: uint256[N_COINS], _is_deposit: bool) -> uint256:
//     """
//     @notice Calculate addition or reduction in token supply from a deposit or withdrawal
//     @dev This calculation accounts for slippage, but not fees.
//          Needed to prevent front-running, not for precise calculations!
//     @param _amounts Amount of each coin being deposited
//     @param _is_deposit set True for deposits, False for withdrawals
//     @return Expected amount of LP tokens received
//     """
