// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./HuxleyComics.sol";
import "./IGenesisToken.sol";
import "./IHuxleyComics.sol";

import "./AccessControl.sol";
import "./Pausable.sol";

/**
 * @title HuxleyBurn
 *
 */
contract HuxleyBurn is Pausable, AccessControl {
    // ER721 Huxley Comics Token
    HuxleyComics public huxleyComics;

    // ERC1156 Genesis Token
    IGenesisToken public genesisToken;

    // When set, prevent HuxleyComics redeemed Tokens from being used for a new Genesis Token
    bool public checkNotRedeemed = true;

    // Check if Tokens are from Issue 1. To be used after HuxleyComics Issue 2 is created 
    bool public checkTokensIsFromIssue1 = false;

    event GenesisTokenMinted(
        address _sender,
        uint256 _categoryId,
        uint256 _tokenId1,
        uint256 _tokenId2
    );
    event SetCheckNotRedeemedExecuted(address _sender, bool _newValue);
    event SetCheckTokensIsFromIssue1Executed(address _sender, bool _newValue);

    // Mapping from used tokens ids that cannot be used for new Genesis blocks
    mapping(uint256 => bool) public usedTokens;

    // Constructor - setup HuxleyComics address and genesis token
    constructor(address _huxleyComics, address _genesisToken) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        huxleyComics = HuxleyComics(_huxleyComics);
        genesisToken = IGenesisToken(_genesisToken);

        _pause();
    }

    /**
     * Called to burn 2 tokens and get 1 Genesis Token.
     *
     * User has to own 5 tokens from Issue 1 and the tokens used
     * to generate the Genesis Token cannot be used again to generate another
     * Genesis Token.
     *
     * @dev It checks if tokens are valid, finds the Genesis Token category,
     * burns 2 tokens, and mints 1 Genesis Token.
     *
     * @dev Before burning, user should have called HuxleyComics.setApprovalForAll()
     */
    function getGenesisToken(
        uint256 tokenId1,
        uint256 tokenId2,
        uint256 tokenId3,
        uint256 tokenId4,
        uint256 tokenId5
    ) external whenNotPaused {
        // Check if Tokens from HuxleyComics were redeemed before.
        if (checkNotRedeemed) {
            isTokenNotRedeemed(tokenId1, tokenId2, tokenId3, tokenId4, tokenId5);
        }

        // Check if msg.sender is owner of tokenId3, tokenId4 and tokenId5.
        // After Issue 2 is created, it will check also if they are from Issue 1
        isTokenValid(tokenId1, tokenId2, tokenId3, tokenId4, tokenId5);

        // Mark tokens as used in a Genesis Token block.
        require(!usedTokens[tokenId3], "HB: TokenId3 already used");
        usedTokens[tokenId3] = true;

        require(!usedTokens[tokenId4], "HB: TokenId4 already used");
        usedTokens[tokenId4] = true;

        require(!usedTokens[tokenId5], "HB: TokenId5 already used");
        usedTokens[tokenId5] = true;

        require(!usedTokens[tokenId1], "HB: TokenId1 already used");
        require(!usedTokens[tokenId2], "HB: TokenId2 already used");

        // transfer token so it can be burned - setApprovalForAll was called before
        huxleyComics.transferFrom(msg.sender, address(this), tokenId1);
        huxleyComics.transferFrom(msg.sender, address(this), tokenId2);

        // it can be from 10 different categories
        uint256 categoryId = getTokensCategory(tokenId1, tokenId2);

        // burn 2 tokens
        huxleyComics.burn(tokenId1);
        huxleyComics.burn(tokenId2);

        // mint genesis token
        mintGenesisToken(categoryId);

        emit GenesisTokenMinted(msg.sender, categoryId, tokenId1, tokenId2);
    }

    // check if token was not redeemed in the HuxleyComics token smart contract
    function isTokenNotRedeemed(
        uint256 tokenId1,
        uint256 tokenId2,
        uint256 tokenId3,
        uint256 tokenId4,
        uint256 tokenId5
    ) internal view {
        require(huxleyComics.redemptions(tokenId1) == false, "HB: TokenId1 was redeemed");
        require(huxleyComics.redemptions(tokenId2) == false, "HB: TokenId2 was redeemed");
        require(huxleyComics.redemptions(tokenId3) == false, "HB: TokenId3 was redeemed");
        require(huxleyComics.redemptions(tokenId4) == false, "HB: TokenId4 was redeemed");
        require(huxleyComics.redemptions(tokenId5) == false, "HB: TokenId5 was redeemed");
    }

    // check if token is from same owner, is they were used before,
    // if they are from issue 1
    function isTokenValid(
        uint256 tokenId1,
        uint256 tokenId2,
        uint256 tokenId3,
        uint256 tokenId4,
        uint256 tokenId5
    ) internal view returns (bool) {
        // check if is owner
        // it isn't necessary to check tokenid1 and 2 because since they will
        // be burned, it will fail if msg.sender is not the owner
        require(huxleyComics.ownerOf(tokenId3) == msg.sender, "HB: Not owner tokenId3");
        require(huxleyComics.ownerOf(tokenId4) == msg.sender, "HB: Not owner tokenId4");
        require(huxleyComics.ownerOf(tokenId5) == msg.sender, "HB: Not owner tokenId5");

        //check token id is from issue 1
        if (checkTokensIsFromIssue1) {
            IHuxleyComics.Token memory tokenDetails1 = huxleyComics.getToken(tokenId1);
            IHuxleyComics.Token memory tokenDetails2 = huxleyComics.getToken(tokenId2);
            IHuxleyComics.Token memory tokenDetails3 = huxleyComics.getToken(tokenId3);
            IHuxleyComics.Token memory tokenDetails4 = huxleyComics.getToken(tokenId4);
            IHuxleyComics.Token memory tokenDetails5 = huxleyComics.getToken(tokenId5);

            require(tokenDetails1.issueNumber == 1, "HB: TokenId1 not from Issue 1");
            require(tokenDetails2.issueNumber == 1, "HB: TokenId2 not from Issue 1");
            require(tokenDetails3.issueNumber == 1, "HB: TokenId3 not from Issue 1");
            require(tokenDetails4.issueNumber == 1, "HB: TokenId4 not from Issue 1");
            require(tokenDetails5.issueNumber == 1, "HB: TokenId5 not from Issue 1");
        }

        return true;
    }

    // Mint Genesis token to user if category is from 1 to 10
    function mintGenesisToken(uint256 _categoryId) internal virtual {
        require(_categoryId > 0 && _categoryId <= 10, "HB: Invalid Category");
        genesisToken.mint(msg.sender, _categoryId, "");
    }

    // Returns genesis token category based on 2 serial numbers.
    function getTokensCategory(uint256 tokenId1, uint256 tokenId2)
        internal
        pure
        returns (uint256 categoryId)
    {
        //To find token serial number it is only necessary to subtract 100 - tokenId - 100
        uint256 serialNumber1 = tokenId1 - 100;
        uint256 serialNumber2 = tokenId2 - 100;

        uint256 categoryToken1 = getCategory(serialNumber1);
        uint256 categoryToken2 = getCategory(serialNumber2);

        if (categoryToken1 == categoryToken2) {
            return categoryToken1;
        } else {
            //if tokens are from different category, it is needed to get from a formula
            return getCategoryFromFormula(serialNumber1, serialNumber2);
        }
    }

    // get token category based on the token serial number
    function getCategory(uint256 _serialNumber) internal pure returns (uint256 category) {
        if (_serialNumber <= 1000) {
            return 1;
        } else if (_serialNumber <= 2000) {
            return 2;
        } else if (_serialNumber <= 3000) {
            return 3;
        } else if (_serialNumber <= 4000) {
            return 4;
        } else if (_serialNumber <= 5000) {
            return 5;
        } else if (_serialNumber <= 6000) {
            return 6;
        } else if (_serialNumber <= 7000) {
            return 7;
        } else if (_serialNumber <= 8000) {
            return 8;
        } else if (_serialNumber <= 9000) {
            return 9;
        } else if (_serialNumber <= 10000) {
            return 10;
        } else {
            revert("HB: Invalid category");
        }
    }

    function getCategoryFromFormula(uint256 _serialNumber1, uint256 _serialNumber2)
        internal
        pure
        returns (uint256)
    {
        uint256 result;
        if (_serialNumber1 < _serialNumber2) {
            result = (_serialNumber1 * 10000) / _serialNumber2;
        } else {
            result = (_serialNumber2 * 10000) / _serialNumber1;
        }

        if (result <= 1000) {
            return 1;
        } else if (result <= 2000) {
            return 2;
        } else if (result <= 3000) {
            return 3;
        } else if (result <= 4000) {
            return 4;
        } else if (result <= 5000) {
            return 5;
        } else if (result <= 6000) {
            return 6;
        } else if (result <= 7000) {
            return 7;
        } else if (result <= 8000) {
            return 8;
        } else if (result <= 9000) {
            return 9;
        } else if (result <= 10000) {
            return 10;
        } else {
            revert("HB: Invalid Formula category");
        }
    }

    function setCheckNotRedeemed(bool _check) external onlyRole(DEFAULT_ADMIN_ROLE) {
        checkNotRedeemed = _check;

        emit SetCheckNotRedeemedExecuted(msg.sender, _check);
    }

    function setCheckTokensIsFromIssue1(bool _check) external onlyRole(DEFAULT_ADMIN_ROLE) {
        checkTokensIsFromIssue1 = _check;

        emit SetCheckTokensIsFromIssue1Executed(msg.sender, _check);
    }

    /// @dev Pause payableMint()
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /// @dev Unpause payableMint()
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
}
