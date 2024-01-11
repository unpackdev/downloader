// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import "./SafeCast.sol";
import "./Errors.sol";
import "./WadRayMath.sol";
import "./IPool.sol";
import "./IScaledBalanceToken.sol";
import "./MintableIncentivizedERC721.sol";

/**
 * @title ScaledBalanceTokenBase
 *
 * @notice Basic ERC721 implementation of scaled balance token
 **/
abstract contract ScaledBalanceTokenBaseERC721 is
    MintableIncentivizedERC721,
    IScaledBalanceToken
{
    using WadRayMath for uint256;
    using SafeCast for uint256;

    /**
     * @dev Constructor.
     * @param pool The reference to the main Pool contract
     * @param name The name of the token
     * @param symbol The symbol of the token
     */
    constructor(
        IPool pool,
        string memory name,
        string memory symbol
    ) MintableIncentivizedERC721(pool, name, symbol) {
        // Intentionally left blank
    }

    /// @inheritdoc IScaledBalanceToken
    function scaledBalanceOf(address user)
        external
        view
        override
        returns (uint256)
    {
        return balanceOf(user);
    }

    /// @inheritdoc IScaledBalanceToken
    function getScaledUserBalanceAndSupply(address user)
        external
        view
        returns (uint256, uint256)
    {
        return (balanceOf(user), totalSupply());
    }

    /// @inheritdoc IScaledBalanceToken
    function scaledTotalSupply()
        public
        view
        virtual
        override
        returns (uint256)
    {
        return totalSupply();
    }

    /// @inheritdoc IScaledBalanceToken
    function getPreviousIndex(address user)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _userState[user].additionalData;
    }

    function decimals() external view returns (uint8) {
        return 0;
    }
}
