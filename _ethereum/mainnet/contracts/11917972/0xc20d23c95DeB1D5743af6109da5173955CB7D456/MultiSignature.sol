pragma solidity >=0.6.0 <0.7.0;

import "./IDDP.sol";
import "./IAllowList.sol";
import "./ISecurityAssetToken.sol";
import "./OperatorVote.sol";
import "./Initializable.sol";


contract MultiSignature is OperatorVote, Initializable {
    /// KYC address list
    address private _allowList;
    /// DDP contract address
    address private _ddp;
    /// Security Asset token contract address
    address private _sat;

    constructor (
        address[] memory founders,
        uint256 votesThreshold
        ) public OperatorVote(founders, votesThreshold)
    {
    }

    function configure(
        address allowList,
        address ddp,
        address sat
    ) external initializer
    {
        _allowList = allowList;
        _ddp = ddp;
        _sat = sat;
    }

    function allowAccount (address account) external onlyOperator {
        IAllowListChange(_allowList).allowAccount(account);
    }

    function disallowAccount(address account) external onlyOperator {
        IAllowListChange(_allowList).disallowAccount(account);
    }

    function mintSecurityAssetToken(
        address to,
        uint256 value,
        uint256 maturity) external onlyOperator
    {
        ISecurityAssetToken(_sat).mint(to, value, maturity);
    }

    function burnSecurityAssetToken(uint256 tokenId) external onlyOperator {
        ISecurityAssetToken(_sat).burn(tokenId);
    }

    function transferSecurityAssetToken(
        address from,
        address to,
        uint256 tokenId) external onlyOperator
    {
        ISecurityAssetToken(_sat).transferFrom(from, to, tokenId);
    }

    function setClaimPeriod(uint256 claimPeriod) external onlyOperator {
        IDDP(_ddp).setClaimPeriod(claimPeriod);
    }
}
