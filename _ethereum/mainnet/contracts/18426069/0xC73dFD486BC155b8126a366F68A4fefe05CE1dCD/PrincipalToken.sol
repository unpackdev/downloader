// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.21;

import "./IDelegateToken.sol";

import "./ERC721.sol";
import "./IERC2981.sol";
import "./MarketMetadata.sol";

/// @notice A simple NFT that doesn't store any user data, being tightly linked to the stateful Delegate Token.
/// @notice The holder of the PT is eligible to reclaim the escrowed NFT when the DT expires or is burned.
contract PrincipalToken is ERC721("Principal Token", "PT"), IERC2981 {
    IDelegateToken public immutable delegateToken;

    error DelegateTokenZero();
    error CallerNotDelegateToken();
    error NotApproved(address spender, uint256 id);

    constructor(address _delegateToken) {
        if (_delegateToken == address(0)) revert DelegateTokenZero();
        delegateToken = IDelegateToken(_delegateToken);
    }

    function _checkDelegateTokenCaller() internal view {
        if (msg.sender == address(delegateToken)) return;
        revert CallerNotDelegateToken();
    }

    /// @notice Mints a PT if and only if the DT contract calls and has authorized
    function mint(address to, uint256 id) external {
        _checkDelegateTokenCaller();
        _mint(to, id);
        delegateToken.mintAuthorizedCallback();
    }

    /// @notice Burns a PT if the DT contract authorizes and the spender isApprovedOrOwner and DT owner authorizes
    function burn(address spender, uint256 id) external {
        _checkDelegateTokenCaller();
        if (_isApprovedOrOwner(spender, id)) {
            _burn(id);
            delegateToken.burnAuthorizedCallback();
            return;
        }
        revert NotApproved(spender, id);
    }

    function isApprovedOrOwner(address account, uint256 id) external view returns (bool) {
        return _isApprovedOrOwner(account, id);
    }

    /// @inheritdoc IERC2981
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        (receiver, royaltyAmount) = MarketMetadata(delegateToken.marketMetadata()).royaltyInfo(tokenId, salePrice);
    }

    function contractURI() external view returns (string memory) {
        return MarketMetadata(delegateToken.marketMetadata()).principalTokenContractURI();
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        _requireMinted(id);
        return MarketMetadata(delegateToken.marketMetadata()).principalTokenURI(id, delegateToken.getDelegateTokenInfo(id));
    }
}
