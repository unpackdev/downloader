// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import "./NFT.sol";
import "./CollateralizedBondGranter.sol";
import "./LockedBondGranter.sol";
import "./LiquidityRequester.sol";
import "./PausableUpgradeable.sol";
import "./Base64.sol";
import "./Strings.sol";
import "./DecimalStrings.sol";

/**
 * @title NFTBond
 * @dev Contains functions related to buying and liquidating bonds, and borrowing and returning funds
 * @author Ethichub
 */
abstract contract NFTBond is NFT, CollateralizedBondGranter, LockedBondGranter, LiquidityRequester, PausableUpgradeable {
    using Strings for uint256;
    using DecimalStrings for uint256;

    error NonExistentToken();
    error CooldownCanNotBeActivatedNotOwner();

    function __NFTBond_init(
        string calldata _name,
        string calldata _symbol,
        address _collateralToken,
        address _accessManager,
        uint256[] calldata _interests,
        uint256[] calldata _maturities,
        uint256 _cooldownSeconds
    )
    internal initializer {
        __NFT_init(_name, _symbol, _accessManager);
        __CollateralizedBondGranter_init(_collateralToken, _interests, _maturities);
        __LockedBondGranter_init(_cooldownSeconds, _interests, _maturities);
    }

    /**
     * @dev Returns updated totalBorrowed
     * @param amount uint256 in wei
     */
    function returnLiquidity(uint256 amount) public payable virtual override returns (uint256) {
        _beforeReturnLiquidity();
        super.returnLiquidity(amount);
        _afterReturnLiquidity(amount);
        return totalBorrowed;
    }

    /**
     * @dev Requests totalBorrowed
     * @param destination address of recipient
     * @param amount uint256 in wei
     */
    function requestLiquidity(address destination, uint256 amount) public override whenNotPaused returns (uint256) {
        _beforeRequestLiquidity(destination, amount);
        super.requestLiquidity(destination, amount);
        return totalBorrowed;
    }

    function activateCooldown(uint256 tokenId) public override {
        if (ownerOf(tokenId) != msg.sender) revert CooldownCanNotBeActivatedNotOwner();
        super.activateCooldown(tokenId);
    }

    /**
    * @dev Returns the tokenURI for tokenId token.
    * @param tokenId uint256
    */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (! _exists(tokenId)) revert NonExistentToken();
        Bond memory bond = bonds[tokenId];
        if (bytes(bond.imageCID).length != 0) {
            return _bondTokenURI(tokenId);
        } else {
            return super.tokenURI(tokenId);
        }
    }

    /**
     * @dev Returns assigned tokenId of the bond
     */
    function _buyBond(
        address beneficiary,
        uint256 maturity,
        uint256 principal,
        string memory imageCID
    )
    internal returns (uint256) {
        _beforeBondPurchased(beneficiary, maturity, principal);
        uint256 tokenId = _safeMint(beneficiary, "");
        super._issueBond(tokenId, maturity, principal, imageCID);
        _afterBondPurchased(beneficiary, maturity, principal, tokenId);
        return tokenId;
    }

    /**
     * @dev Issue the bond
     */
    function _issueBond(uint256 tokenId, uint256 maturity, uint256 principal, string memory imageCID) internal virtual override (BondGranter, CollateralizedBondGranter) {}

    /**
     * @dev Returns the amount that corresponds to the bond
     */
    function _redeemBond(uint256 tokenId) internal virtual override (CollateralizedBondGranter, LockedBondGranter) returns (uint256) {
        uint256 amount = super._redeemBond(tokenId);
        address beneficiary = ownerOf(tokenId);
        _afterBondRedeemed(tokenId, amount, beneficiary);
        return amount;
    }

    function _beforeBondPurchased(
        address beneficiary,
        uint256 maturity,
        uint256 principal
    ) internal virtual {}

    function _afterBondPurchased(
        address beneficiary,
        uint256 maturity,
        uint256 principal,
        uint256 tokenId
    ) internal virtual {}

    function _beforeBondRedeemed(uint256 tokenId, uint256 value) internal virtual {}

    function _afterBondRedeemed(uint256 tokenId, uint256 value, address beneficiary) internal virtual {}

    function _beforeRequestLiquidity(address destination, uint256 amount) internal virtual {}

    function _afterRequestLiquidity(address destination) internal virtual {}

    function _beforeReturnLiquidity() internal virtual {}

    function _afterReturnLiquidity(uint256 amount) internal virtual {}

    function _bondTokenURI(uint256 tokenId) private view returns (string memory) {
        Bond memory bond = bonds[tokenId];
        string memory dataJSON = string.concat(
            '{'
                '"name": "', string.concat('Minimice Yield Bond #', tokenId.toString()), '", ',
                '"description": "MiniMice Risk Yield Bond from EthicHub.", ',
                '"image": "ipfs://', bond.imageCID, '", ',
                '"external_url": "https://ethichub.com",',
                '"attributes": [',
                _setAttribute('Principal', string.concat(bond.principal._decimalString(18, false), ' USD')),',',
                _setAttribute('Collateral', string.concat((bond.principal * collateralMultiplier)._decimalString(18, false), ' Ethix')),',',
                _setAttribute('APY', (bond.interest*365 days/1e16)._decimalString(2, true)),',',
                _setAttribute('Maturity', string.concat((bond.maturity*1e2/30 days)._decimalString(2, false), ' Months')),',',
                _setAttribute('Maturity Unix Timestamp', (bond.mintingDate + bond.maturity).toString()),
                ']'
            '}'
        );
        return string.concat("data:application/json;base64,", Base64.encode(bytes(dataJSON)));
    }

    function _setAttribute(string memory _name, string memory _value) private pure returns (string memory) {
        return string.concat('{"trait_type":"', _name,'","value":"', _value,'"}');
    }

    /**
     * ////// [v1.0, v1.1, v1.2] //////
     * 49 __gap
     * 49 (mistakenly deployed with 49 store gaps)
     */
    uint256[49] private __gap; // deployed with 49 store gaps
}