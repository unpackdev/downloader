// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.11;

import "./IERC721.sol";
import "./ERC165.sol";

interface IWasteland {
    function stakedTokens(address) external view returns (uint256);
}

/**
 * @title WastelandMirage
 * @author bagelface.eth
 * @notice Mock ERC721 for preserving Collab.Land support in staking ecosystem
 */
contract WastelandMirage is ERC165 {
    IERC721 internal immutable WLCC;
    IWasteland internal immutable WSTLND;

    constructor(address wlcc, address wstlnd) {
        WLCC = IERC721(wlcc);
        WSTLND = IWasteland(wstlnd);
    }

    /**
     * @notice Get the combined balance of owner's staked and unstaked WLCC balance
     * @param owner Address of owner to return balance for
     * @return uint256 Combined WLCC balance of owner
     */
    function balanceOf(address owner) public view returns (uint256) {
        return WLCC.balanceOf(owner) + WSTLND.stakedTokens(owner);
    }

    /**
     * @inheritdoc ERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId || super.supportsInterface(interfaceId);
    }
}