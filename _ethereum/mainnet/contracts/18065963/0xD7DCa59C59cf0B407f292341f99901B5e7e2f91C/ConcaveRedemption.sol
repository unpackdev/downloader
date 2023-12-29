// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC721.sol";
import "./Multicallable.sol";
import "./SafeTransferLib.sol";
import "./FixedPointMathLib.sol";

abstract contract IStaking is ERC721 {
    function viewPositionRewards(uint256 tokenId)
        external
        view
        virtual
        returns (
            uint256 amountDeposited,
            uint256 baseRewards,
            uint256 excessRewards,
            uint256 totalRewards
        );
}

/// @title ConcaveRedemption
/// @dev A contract that allows redeeming CNV or Staked CNV for USDC at a fixed rate.
contract ConcaveRedemption is Ownable, Multicallable {
    /// -----------------------------------------------------------------------
    /// Dependencies
    /// -----------------------------------------------------------------------

    using SafeTransferLib for address;

    using FixedPointMathLib for uint256;

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /// @dev Emitted when a redemption occurs.
    event Redeem(address indexed redeemer, uint256 cnvIn, uint256 usdcOut);

    /// @dev Emitted when a staked token redemption occurs.
    event Redeem(
        address indexed redeemer,
        uint256 tokenId,
        uint256 cnvIn,
        uint256 usdcOut
    );

    /// -----------------------------------------------------------------------
    /// Immutable Storage
    /// -----------------------------------------------------------------------

    /// @notice The ERC721 representing staked `CNV`, which can be sold at a fixed-rate for `USDC`.
    IStaking public immutable lsdCNV;

    /// @notice The ERC20 token (18 decimals) that can be sold at a fixed-rate for `USDC`.
    address public immutable CNV;

    /// @notice The ERC20 token (6 decimals) that can be purchased at a fixed-rate with `CNV` or equivalent.
    address public immutable USDC;

    /// @notice The exchange rate of `USDC/CNV` (6-decimal precision).
    uint256 public immutable rate;

    constructor(
        address _owner,
        address _lsdCNV,
        address _CNV,
        address _USDC,
        uint256 _rate
    ) {
        _initializeOwner(_owner);

        lsdCNV = IStaking(_lsdCNV);

        CNV = _CNV;

        USDC = _USDC;

        rate = _rate;
    }

    /// -----------------------------------------------------------------------
    /// CNV Redemption
    /// -----------------------------------------------------------------------

    /// @notice Redeem CNV tokens for USDC tokens.
    /// @param cnvIn The amount of CNV tokens to redeem.
    /// @param to The address to send the redeemed USDC tokens to.
    /// @param deadline The deadline for the permit, if required.
    /// @param v The `v` value of the CNV permit signature.
    /// @param r The `r` value of the CNV permit signature.
    /// @param s The `s` value of the CNV permit signature.
    /// @return usdcOut The amount of USDC tokens obtained after redemption.
    function redeem(
        uint256 cnvIn,
        address to,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 usdcOut) {
        ERC20(CNV).permit(msg.sender, address(this), cnvIn, deadline, v, r, s);

        return redeem(cnvIn, to);
    }

    /// @notice Redeem CNV tokens for USDC tokens.
    /// @param cnvIn The amount of CNV tokens to redeem.
    /// @param to The address to send the redeemed USDC tokens to.
    /// @return usdcOut The amount of USDC tokens obtained after redemption.
    function redeem(uint256 cnvIn, address to)
        public
        returns (uint256 usdcOut)
    {
        CNV.safeTransferFrom(msg.sender, address(this), cnvIn);

        USDC.safeTransfer(to, usdcOut = cnvIn.mulWad(rate));

        emit Redeem(msg.sender, cnvIn, usdcOut);
    }

    /// -----------------------------------------------------------------------
    /// Staked CNV Redemption
    /// -----------------------------------------------------------------------

    /// @notice Redeem staked CNV tokens for USDC tokens.
    /// @param tokenId The ID of the staked token.
    /// @param to The address to send the redeemed USDC tokens to.
    /// @return usdcOut The amount of USDC tokens obtained after redemption.
    function redeemStaked(uint256 tokenId, address to)
        public
        virtual
        returns (uint256 usdcOut)
    {
        (uint256 amountDeposited,,, uint256 totalRewards) =
            lsdCNV.viewPositionRewards(tokenId);

        lsdCNV.transferFrom(msg.sender, address(this), tokenId);

        uint256 cnvIn = amountDeposited.rawAdd(totalRewards);

        USDC.safeTransfer(to, usdcOut = cnvIn.mulWad(rate));

        emit Redeem(msg.sender, tokenId, cnvIn, usdcOut);
    }

    /// -----------------------------------------------------------------------
    /// Management
    /// -----------------------------------------------------------------------

    /// @notice Pull USDC tokens from the contract.
    /// @param to The address to send the pulled USDC tokens to.
    function pull(address to) external virtual onlyOwner {
        USDC.safeTransferAll(to);
    }
}
