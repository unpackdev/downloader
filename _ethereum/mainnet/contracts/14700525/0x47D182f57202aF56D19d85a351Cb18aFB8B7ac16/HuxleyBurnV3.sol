// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./HuxleyComics.sol";
import "./IGenesisToken.sol";

import "./AccessControl.sol";
import "./Pausable.sol";

/**
 * @title HuxleyBurn V3
 *
 */
contract HuxleyBurnV3 is Pausable, AccessControl {
    /// @dev ER721 Huxley Comics Token
    HuxleyComics public huxleyComics;

    /// @dev ERC1156 Genesis Token
    IGenesisToken public genesisToken;

    event GenesisTokenMinted(
        address _sender,
        uint256 _categoryId,
        uint256 _tokenId1,
        uint256 _tokenId2,
        uint256 _tokenId3,
        uint256 _tokenId4,
        uint256 _tokenId5
    );

    /// @dev Constructor - setup HuxleyComics address and genesis token
    constructor(address _huxleyComics, address _genesisToken) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        huxleyComics = HuxleyComics(_huxleyComics);
        genesisToken = IGenesisToken(_genesisToken);

        _pause();
    }

    /**
     * Called to burn 5 tokens and get 1 Genesis Token.
     *
     * User has to own 5 tokens. 1 from Issue 1, 2 from Issue 2 and 2 from Issue 3.
     *
     * @dev It checks if tokens are valid, finds the Genesis Token category,
     * burns 5 tokens, and mints 1 Genesis Token. Before burning, user should
     * have called HuxleyComics.setApprovalForAll()
     *
     * @param tokenId1 Token Id from Issue 1
     * @param tokenId2 Token Id from Issue 2
     * @param tokenId3 Token Id from Issue 2
     * @param tokenId4 Token Id from Issue 3
     * @param tokenId5 Token Id from Issue 3
     */
    function getGenesisToken(
        uint256 tokenId1,
        uint256 tokenId2,
        uint256 tokenId3,
        uint256 tokenId4,
        uint256 tokenId5
    ) external whenNotPaused {
        // Check if msg.sender is owner of tokenId3, tokenId4 and tokenId5.
        isTokenValid(tokenId1, tokenId2, tokenId3, tokenId4, tokenId5);

        // transfer token so it can be burned - setApprovalForAll was called before
        huxleyComics.transferFrom(msg.sender, address(this), tokenId1);
        huxleyComics.transferFrom(msg.sender, address(this), tokenId2);
        huxleyComics.transferFrom(msg.sender, address(this), tokenId3);
        huxleyComics.transferFrom(msg.sender, address(this), tokenId4);
        huxleyComics.transferFrom(msg.sender, address(this), tokenId5);

        // it can be from 10 different categories - 1 to 10
        uint256 categoryId = getTokensCategory(tokenId1, tokenId2, tokenId3, tokenId4, tokenId5);

        // burn 5 tokens
        huxleyComics.burn(tokenId1);
        huxleyComics.burn(tokenId2);
        huxleyComics.burn(tokenId3);
        huxleyComics.burn(tokenId4);
        huxleyComics.burn(tokenId5);

        // mint genesis token
        mintGenesisToken(categoryId);

        emit GenesisTokenMinted(
            msg.sender,
            categoryId,
            tokenId1,
            tokenId2,
            tokenId3,
            tokenId4,
            tokenId5
        );
    }

    /**
     * @dev Check if tokens are from Issue 1, 2 and 3 and if they are a First edition.
     * Since it is known the Token id range, it can be used to verify token Issues
     * @param tokenId1 Token Id from Issue 1
     * @param tokenId2 Token Id from Issue 2
     * @param tokenId3 Token Id from Issue 2
     * @param tokenId4 Token Id from Issue 3
     * @param tokenId5 Token Id from Issue 3
     */
    function isTokenValid(
        uint256 tokenId1,
        uint256 tokenId2,
        uint256 tokenId3,
        uint256 tokenId4,
        uint256 tokenId5
    ) internal pure returns (bool) {
        require(tokenId1 > 101 && tokenId1 <= 10100, "HB: TokenId1 not from Issue 1");
        require(tokenId2 >= 10211 && tokenId2 <= 20210, "HB: TokenId2 not from Issue 2");
        require(tokenId3 >= 10211 && tokenId3 <= 20210, "HB: TokenId3 not from Issue 2");
        require(tokenId4 >= 20321 && tokenId4 <= 30320, "HB: TokenId4 not from Issue 3");
        require(tokenId5 >= 20321 && tokenId5 <= 30320, "HB: TokenId5 not from Issue 3");

        return true;
    }

    /// @dev Mint Genesis token to user. Category is from 1 to 10
    /// @param _categoryId It is from 1 to 10
    function mintGenesisToken(uint256 _categoryId) internal virtual {
        require(_categoryId > 0 && _categoryId <= 10, "HB: Invalid Category");
        genesisToken.mint(msg.sender, _categoryId, "");
    }

    /**
     * @dev Returns genesis token category based on 5 token ids.
     * @param tokenId1 Token Id from Issue 1
     * @param tokenId2 Token Id from Issue 2
     * @param tokenId3 Token Id from Issue 2
     * @param tokenId4 Token Id from Issue 3
     * @param tokenId5 Token Id from Issue 3
     */
    function getTokensCategory(
        uint256 tokenId1,
        uint256 tokenId2,
        uint256 tokenId3,
        uint256 tokenId4,
        uint256 tokenId5
    ) internal pure returns (uint256 categoryId) {
        //To find token serial number it is only necessary to subtract 100 - tokenId - 100
        uint256 lastDigit1 = tokenId1 % 10;
        uint256 lastDigit2 = tokenId2 % 10;
        uint256 lastDigit3 = tokenId3 % 10;
        uint256 lastDigit4 = tokenId4 % 10;
        uint256 lastDigit5 = tokenId5 % 10;

        uint256 sum = lastDigit1 + lastDigit2 + lastDigit3 + lastDigit4 + lastDigit5;
        uint256 lastDigitSum = sum % 10;
        categoryId = lastDigitSum + 1;

        if (categoryId > 10) {
            categoryId = 10;
        }
    }

    /// @dev Pause getGenesisToken(). Only DEFAULT_ADMIN_ROLE can call it.
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /// @dev Unpause getGenesisToken(). Only DEFAULT_ADMIN_ROLE can call it.
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
}
