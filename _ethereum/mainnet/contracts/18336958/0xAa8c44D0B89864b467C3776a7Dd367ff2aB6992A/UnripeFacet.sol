/*
 * SPDX-License-Identifier: MIT
 */

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./MerkleProof.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./IBean.sol";
import "./LibDiamond.sol";
import "./LibUnripe.sol";
import "./LibTransfer.sol";
import "./C.sol";
import "./ReentrancyGuard.sol";

/// @author ZrowGz, Publius
/// @title VestingFacet
/// @notice Manage the logic of the vesting process for the Barnraised Funds

contract UnripeFacet is ReentrancyGuard {
    using SafeERC20 for IERC20;
    using LibTransfer for IERC20;
    using SafeMath for uint256;

    uint256 constant DECIMALS = 1e6;

    event AddUnripeToken(
        address indexed unripeToken,
        address indexed underlyingToken,
        bytes32 merkleRoot
    );

    event ChangeUnderlying(address indexed token, int256 underlying);

    event SwitchUnderlyingToken(address indexed token, address indexed underlyingToken);

    event Chop(
        address indexed account,
        address indexed token,
        uint256 amount,
        uint256 underlying
    );

    event Pick(
        address indexed account,
        address indexed token,
        uint256 amount
    );

    function chop(
        address unripeToken,
        uint256 amount,
        LibTransfer.From fromMode,
        LibTransfer.To toMode
    ) external payable nonReentrant returns (uint256 underlyingAmount) {
        uint256 unripeSupply = IERC20(unripeToken).totalSupply();

        amount = LibTransfer.burnToken(IBean(unripeToken), amount, msg.sender, fromMode);

        underlyingAmount = _getPenalizedUnderlying(unripeToken, amount, unripeSupply);

        require(underlyingAmount > 0, "Chop: no underlying");

        LibUnripe.decrementUnderlying(unripeToken, underlyingAmount);

        address underlyingToken = s.u[unripeToken].underlyingToken;

        IERC20(underlyingToken).sendToken(underlyingAmount, msg.sender, toMode);

        emit Chop(msg.sender, unripeToken, amount, underlyingAmount);
    }

    function pick(
        address token,
        uint256 amount,
        bytes32[] memory proof,
        LibTransfer.To mode
    ) external payable nonReentrant {
        bytes32 root = s.u[token].merkleRoot;
        require(root != bytes32(0), "UnripeClaim: invalid token");
        require(
            !picked(msg.sender, token),
            "UnripeClaim: already picked"
        );

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        require(
            MerkleProof.verify(proof, root, leaf),
            "UnripeClaim: invalid proof"
        );
        s.unripeClaimed[token][msg.sender] = true;

        LibTransfer.sendToken(IERC20(token), amount, msg.sender, mode);

        emit Pick(msg.sender, token, amount);
    }

    function picked(address account, address token)
        public
        view
        returns (bool)
    {
        return s.unripeClaimed[token][account];
    }

    function getUnderlying(address unripeToken, uint256 amount)
        public
        view
        returns (uint256 redeem)
    {
        return _getUnderlying(unripeToken, amount, IERC20(unripeToken).totalSupply());
    }

    function _getUnderlying(address unripeToken, uint256 amount, uint256 supply)
        private
        view
        returns (uint256 redeem)
    {
        redeem = s.u[unripeToken].balanceOfUnderlying.mul(amount).div(
            supply
        );
    }

    function getPenalty(address unripeToken)
        external
        view
        returns (uint256 penalty)
    {
        return getPenalizedUnderlying(unripeToken, DECIMALS);
    }

    function getPenalizedUnderlying(address unripeToken, uint256 amount)
        public
        view
        returns (uint256 redeem)
    {
        return _getPenalizedUnderlying(unripeToken, amount, IERC20(unripeToken).totalSupply());
    }

    function _getPenalizedUnderlying(address unripeToken, uint256 amount, uint256 supply)
        public
        view
        returns (uint256 redeem)
    {
        require(isUnripe(unripeToken), "not vesting");
        uint256 sharesBeingRedeemed = getRecapPaidPercentAmount(amount);
        redeem = _getUnderlying(unripeToken, sharesBeingRedeemed, supply);
    }

    function isUnripe(address unripeToken) public view returns (bool unripe) {
        unripe = s.u[unripeToken].underlyingToken != address(0);
    }

    function balanceOfUnderlying(address unripeToken, address account)
        external
        view
        returns (uint256 underlying)
    {
        return
            getUnderlying(unripeToken, IERC20(unripeToken).balanceOf(account));
    }

    function balanceOfPenalizedUnderlying(address unripeToken, address account)
        external
        view
        returns (uint256 underlying)
    {
        return
            getPenalizedUnderlying(
                unripeToken,
                IERC20(unripeToken).balanceOf(account)
            );
    }

    function getRecapFundedPercent(address unripeToken)
        public
        view
        returns (uint256 percent)
    {
        if (unripeToken == C.UNRIPE_BEAN) {
            return LibUnripe.percentBeansRecapped();
        } else if (unripeToken == C.UNRIPE_LP) {
            return LibUnripe.percentLPRecapped();
        }
        revert("not vesting");
    }

    function getPercentPenalty(address unripeToken)
        external
        view
        returns (uint256 penalty)
    {
        return getRecapPaidPercentAmount(getRecapFundedPercent(unripeToken));
    }

    function getRecapPaidPercent() external view returns (uint256 penalty) {
        penalty = getRecapPaidPercentAmount(DECIMALS);
    }

    function getRecapPaidPercentAmount(uint256 amount)
        private
        view
        returns (uint256 penalty)
    {
        return s.fertilizedIndex.mul(amount).div(s.unfertilizedIndex);
    }

    function getUnderlyingPerUnripeToken(address unripeToken)
        external
        view
        returns (uint256 underlyingPerToken)
    {
        underlyingPerToken = s
            .u[unripeToken]
            .balanceOfUnderlying
            .mul(DECIMALS)
            .div(IERC20(unripeToken).totalSupply());
    }

    function getTotalUnderlying(address unripeToken)
        external
        view
        returns (uint256 underlying)
    {
        return s.u[unripeToken].balanceOfUnderlying;
    }

    function addUnripeToken(
        address unripeToken,
        address underlyingToken,
        bytes32 root
    ) external payable nonReentrant {
        LibDiamond.enforceIsOwnerOrContract();
        s.u[unripeToken].underlyingToken = underlyingToken;
        s.u[unripeToken].merkleRoot = root;
        emit AddUnripeToken(unripeToken, underlyingToken, root);
    }

    function getUnderlyingToken(address unripeToken)
        external
        view
        returns (address underlyingToken)
    {
        return s.u[unripeToken].underlyingToken;
    }

    /////////////// UNDERLYING TOKEN MIGRATION //////////////////

    /**
     * @notice Adds underlying tokens to an Unripe Token.
     * @param unripeToken The Unripe Token to add underlying tokens to.
     * @param amount The amount of underlying tokens to add.
     * @dev Used to migrate the underlying token of an Unripe Token to a new token.
     * Only callable by the contract owner.
     */
    function addMigratedUnderlying(address unripeToken, uint256 amount) external payable nonReentrant {
        LibDiamond.enforceIsContractOwner();
        IERC20(s.u[unripeToken].underlyingToken).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        LibUnripe.incrementUnderlying(unripeToken, amount);
    }

    /**
     * @notice Switches the Underlying Token of an Unripe Token.
     * @param unripeToken The Unripe Token to switch the underlying token of.
     * @param newUnderlyingToken The new underlying token to switch to.
     * @dev `s.u[unripeToken].balanceOfUnderlying` must be 0.
     */
    function switchUnderlyingToken(address unripeToken, address newUnderlyingToken) external payable {
        LibDiamond.enforceIsContractOwner();
        require(s.u[unripeToken].balanceOfUnderlying == 0, "Unripe: Underlying balance > 0");
        LibUnripe.switchUnderlyingToken(unripeToken, newUnderlyingToken);
    }
}
