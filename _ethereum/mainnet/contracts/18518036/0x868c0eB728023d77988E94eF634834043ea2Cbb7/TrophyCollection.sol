// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ERC721A.sol";
import "./ERC721AQueryable.sol";
import "./ERC721ABurnable.sol";
import "./Ownable.sol";
import "./ERC2981.sol";
import "./AccessControl.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

/**
 * @title  Trophy_Collection
 * @author Dadogg80 - VBS Viken Blockchain Solutions AS, @mayjer (Centaurify)
 */
abstract contract TrophyCollection is
    ERC721A,
    ERC721AQueryable,
    ERC721ABurnable,
    Ownable,
    AccessControl,
    ERC2981
{
    using SafeERC20 for IERC20;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    event Minted(address to, uint amount);

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(IERC721A, ERC721A, ERC2981, AccessControl)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public onlyRole(ADMIN_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /// @notice Removes stuck erc20 tokens from contract.
    /// @dev Restricted to onlyRole(ADMIN_ROLE).
    /// @param _token The contract address of the token to remove.
    /// @param _to The to account.
    function removeStuckTokens(
        address _token,
        address _to
    ) external onlyRole(ADMIN_ROLE) {
        uint _amount = balanceOf(address(_token));
        IERC20(_token).safeTransfer(_to, _amount);
    }
}
