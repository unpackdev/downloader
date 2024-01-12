pragma solidity 0.6.6;

import "./IERC20Upgradeable.sol";

interface IMintableERC20 is IERC20Upgradeable {
    /**
     * @notice called by predicate contract to mint tokens while withdrawing
     * @dev Should be callable only by MintableERC20Predicate
     * Make sure minting is done only by this function
     * @param user user address for whom token is being minted
     * @param amount amount of token being minted
     */
    function mint(address user, uint256 amount) external;
}
