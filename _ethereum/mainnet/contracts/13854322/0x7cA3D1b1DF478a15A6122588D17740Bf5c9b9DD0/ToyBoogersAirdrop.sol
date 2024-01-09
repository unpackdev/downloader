// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10 <=0.9.0;
import "./IERC1155.sol";
import "./Context.sol";
import "./ReentrancyGuard.sol";

contract ToyBoogersAirdrop is Context, ReentrancyGuard {
    /// @notice Toy Boogers ERC1155 NFT Airdrop Contract
    IERC1155 public token;

    event AirdropDeployed();
    event AirdropFinished(uint256 tokenId, address[] recipients);

    constructor(IERC1155 _token) {
        require(address(_token) != address(0), "Invalid NFT");
        token = _token;
        emit AirdropDeployed();
    }

    /**
     * @dev Owner of token can airdrop tokens to recipients
     * @param _tokenId id of the token
     * @param _recipients addresses of recipients
     */
    function airdrop(uint256 _tokenId, address[] memory _recipients)
        external
        nonReentrant
    {
        require(token.balanceOf(_msgSender(), _tokenId) >= _recipients.length,"Not enough tokens to drop");
        require(token.isApprovedForAll(_msgSender(), address(this)),"Owner is not approved");
        require(_recipients.length >= 0,"Recipients must be greater than 0");
        require(_recipients.length <= 1000,"Recipients should be smaller than 1000");
        for (uint256 i = 0; i < _recipients.length; i++) {
            token.safeTransferFrom(
                _msgSender(),
                _recipients[i],
                _tokenId,
                1,
                ""
            );
        }
        emit AirdropFinished(_tokenId, _recipients);
    }
}
