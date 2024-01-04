pragma solidity >=0.6.0 <0.7.0;

import "./IERC20.sol";
import "./AccessControl.sol";

import "./ERC721.sol";
import "./IAllowList.sol";
import "./IBondToken.sol";
import "./IDDP.sol";
import "./IEURxb.sol";
import "./Initializable.sol";

import "./TokenAccessRoles.sol";


contract DDP is IDDP, AccessControl, Initializable {
    /// bond address
    address private _bond;
    address private _eurxb;
    address private _allowList;

    uint256 _claimPeriod = 30 days;

    constructor(address admin) public {
        // admin role for setClaimPeriod only
        _setupRole(TokenAccessRoles.admin(), admin);
    }

    /**
     * @dev configures DDP to use BondToken, EURxb contract and AllowList addresses
     * @param bond BondToken contract address
     * @param eurxb EURxb contract address
     * @param allowList AllowList address
     */
    function configure(address bond, address eurxb, address allowList) external initializer {
        _bond = bond;
        _eurxb = eurxb;
        _allowList = allowList;
    }

    function setClaimPeriod(uint256 period) external override {
        require(
            hasRole(TokenAccessRoles.admin(), _msgSender()),
            "user is not admin");
        _claimPeriod = period;
    }

    function deposit(
        uint256 tokenId,
        uint256 value,
        uint256 maturity,
        address to) external override
    {
        // only bond is allowed to deposit
        require(_msgSender() == _bond,
            "caller is not allowed to deposit");

        // mint EURxb tokens: amount of EURxb FT tokens = value of Bond NFT token.
        IEURxb(_eurxb).mint(to, value);
        IEURxb(_eurxb).addNewMaturity(value, maturity);
    }

    /**
     *  repays bond token, any user can call it
     */
    function withdraw(uint256 tokenId) external {
        // check if token exists
        require(
            IBondToken(_bond).hasToken(tokenId),
            "bond token id does not exist");

        address user = _msgSender();

        // get token properties
        ( uint256 value, /* uint256 interest */, uint256 maturity ) = IBondToken(_bond)
            .getTokenInfo(tokenId);

        address owner = IERC721(_bond).ownerOf(tokenId);
        bool isOwner = owner == user;

        if (!isOwner) {
            require (
                IAllowList(_allowList).isAllowedAccount(user),
                "user is not allowed");
            require(
                block.timestamp > maturity + _claimPeriod,
                "claim period is not finished yet");
        }

        // check if enough money to repay
        require(IERC20(_eurxb).balanceOf(user) >= value,
            "not enough EURxb to withdraw");

        // burn EURxb
        IEURxb(_eurxb).burn(user, value);
        if (maturity > block.timestamp) {
            // only if maturity has not arrived yet
            IEURxb(_eurxb).removeMaturity(value, maturity);
        }

        if (!isOwner) {
            // if not owner, need to transfer ownership first
            IBondToken(_bond).safeTransferFrom(owner, user, tokenId);
        }

        // burn token
        IBondToken(_bond).burn(tokenId);
    }

    function getClaimPeriod() external view returns (uint256) {
        return _claimPeriod;
    }
}
