// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import "./Initializable.sol";
import "./Math.sol";

import "./InterestParameters.sol";

/**
 * @title BondGranter
 * @dev This contract contains functions related to the emission or withdrawal of the bonds
 * @author Ethichub
 */
abstract contract BondGranter is Initializable, InterestParameters {
    struct Bond {
        uint256 mintingDate;
        uint256 maturity;
        uint256 principal;
        uint256 interest;
        bool redeemed;
        string imageCID;
    }

    mapping(uint256 => Bond) public bonds;

    event BondIssued(address buyer, uint256 tokenId, uint256 mintingDate, uint256 maturity, uint256 principal, uint256 interest, string imageCID);
    event BondRedeemed(address redeemer, uint256 tokenId, uint256 redeemDate, uint256 maturity, uint256 withdrawn, uint256 interest, string imageCID);

    error PrincipalIsLesserOrEqualZero();
    error CanNotRedeemYet();
    error AlreadyRedeemed();

    function __BondGranter_init(
        uint256[] calldata _interests,
        uint256[] calldata _maturities
    )
    internal initializer {
        __InterestParameters_init(_interests, _maturities);
    }

    /**
     * @dev Assigns a bond with its parameters
     * @param tokenId uint256
     * @param maturity uint256 seconds
     * @param principal uint256 in wei
     * @param imageCID string
     *
     * Requirements:
     *
     * - Principal amount can not be 0
     * - Maturity must be greater than the first element of the set of interests
     */
    function _issueBond(uint256 tokenId, uint256 maturity, uint256 principal, string memory imageCID) internal virtual {
        if (principal <= 0) revert PrincipalIsLesserOrEqualZero();
        if (maturity < maturities[0]) revert MaturityInputMustBeGreaterThanFirstMaturity();
        uint256 interest = super.getInterestForMaturity(maturity);
        bonds[tokenId] = Bond(block.timestamp, maturity, principal, interest, false, imageCID);
        emit BondIssued(msg.sender, tokenId, block.timestamp, maturity, principal, interest, imageCID);
    }

    /**
     * @dev Checks eligilibility to redeem the bond and returns its value
     * @param tokenId uint256
     */
    function _redeemBond(uint256 tokenId) internal virtual returns (uint256) {
        Bond memory bond = bonds[tokenId];
        if ((bond.maturity + bond.mintingDate) >= block.timestamp) revert CanNotRedeemYet();
        if (bond.redeemed) revert AlreadyRedeemed();
        bonds[tokenId].redeemed = true;
        uint256 bondValue = _bondValue(bond.principal, bond.interest, bond.maturity);
        emit BondRedeemed(msg.sender, tokenId, block.timestamp, bond.maturity, bondValue, bond.interest, bond.imageCID);
        return bondValue;
    }

    /**
     * @dev Returns the actual value of the bond with its interest
     * @param principal uint256
     * @param interest uint256
     * @param timeElapsed uint256
     */
    function _bondValue(uint256 principal, uint256 interest, uint256 timeElapsed) internal view virtual returns (uint256) {
        return principal + Math.mulDiv(principal, interest * timeElapsed, 100 ether);
    }

    uint256[49] private __gap;

}