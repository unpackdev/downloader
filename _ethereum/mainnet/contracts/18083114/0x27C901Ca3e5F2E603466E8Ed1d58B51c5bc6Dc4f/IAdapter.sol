pragma solidity 0.7.5;
pragma abicoder v2;

import "./IERC20.sol";
import "./Utils.sol";

interface IAdapter {

    /**
    * @dev Certain adapters needs to be initialized.
    * This method will be called from Augustus
    */
    function initialize(bytes calldata data) external;

    /**
   * @dev The function which performs the swap on an exchange.
   * @param fromToken Address of the source token
   * @param toToken Address of the destination token
   * @param fromAmount Amount of source tokens to be swapped
   * @param networkFee Network fee to be used in this router
   * @param route Route to be followed
   */
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 networkFee,
        Utils.Route[] calldata route
    )
        external
        payable;
}