// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
pragma experimental ABIEncoderV2;

import "./ERC20.sol";
import "./ERC721.sol";
import "./Owned.sol";
import "./Base64.sol";
import "./Strings.sol";
import "./IconRenderer.sol";
import "./Sanitize.sol";

contract IconFactory is ERC721, Owned {
    using Sanitize for string;
    using Strings for uint256;

    error TokenOwnerOnly();
    error AlreadyExists(uint256);
    error DoesNotExist();

    // Private vars

    string private externalBaseURL = "https://uint256.art/";
    mapping(uint256 => string) private titles;
    mapping(uint256 => string) private descriptions;
    mapping(uint256 => string) private styles;
    string private defaultTitle = "Untitled Icon";
    string private defaultDescription = "A one-of-a-kind 16x16 icon";

    // Public fields

    /// @notice the renderer
    IIconRenderer public renderer;

    constructor(
        string memory name,
        string memory symbol,
        IIconRenderer _renderer
    ) ERC721(name, symbol) Owned(msg.sender) {
        renderer = _renderer;
    }

    ////////////////////////////////////////////////////////////////
    //                        GETTERS
    ////////////////////////////////////////////////////////////////

    function tokenURI(uint256 tokenID)
        public
        view
        override
        onlyMinted(tokenID)
        returns (string memory)
    {
        return
            string.concat(
                "data:application/json;base64,",
                Base64.encode(bytes(_metadata(tokenID)))
            );
    }

    function metadata(uint256 tokenID)
        external
        view
        onlyMinted(tokenID)
        returns (string memory)
    {
        return _metadata(tokenID);
    }

    function _metadata(uint256 tokenID)
        internal
        view
        returns (string memory json)
    {
        bool customTitle = bytes(titles[tokenID]).length != 0;
        bool customDescription = bytes(descriptions[tokenID]).length != 0;
        bool customCSS = bytes(styles[tokenID]).length != 0;

        string memory attributes = string.concat(
            customTitle ? '{"value": "Custom Title"}' : "",
            customTitle && (customDescription || customCSS) ? "," : "",
            customDescription ? '{"value": "Custom Description"}' : "",
            customDescription && customCSS ? "," : "",
            customCSS ? '{"value": "Custom CSS"}' : ""
        );

        json = string.concat(
            "{",
            '"image": "',
            renderer.imageURL(tokenID, styleOf(tokenID)),
            '","name":"',
            titleOf(tokenID),
            '","description":"',
            descriptionOf(tokenID),
            '","css":"',
            styleOf(tokenID),
            '","external_url":"',
            externalURL(tokenID),
            '","attributes":[',
            attributes,
            "]}"
        );
    }

    function titleOf(uint256 tokenID)
        public
        view
        onlyMinted(tokenID)
        returns (string memory)
    {
        string memory t = titles[tokenID];
        if (bytes(t).length == 0) {
            return defaultTitle;
        } else {
            return t.sanitizeForJSON(34);
        }
    }

    function descriptionOf(uint256 tokenID)
        public
        view
        onlyMinted(tokenID)
        returns (string memory)
    {
        string memory d = descriptions[tokenID];
        if (bytes(d).length == 0) {
            return defaultDescription;
        } else {
            return d.sanitizeForJSON(34);
        }
    }

    function styleOf(uint256 tokenID)
        public
        view
        onlyMinted(tokenID)
        returns (string memory)
    {
        return styles[tokenID].sanitizeForJSON(34);
    }

    function externalURL(uint256 tokenID)
        public
        view
        onlyMinted(tokenID)
        returns (string memory)
    {
        return string.concat(externalBaseURL, tokenID.toHexString());
    }

    ////////////////////////////////////////////////////////////////
    //                        PUBLIC WRITES
    ////////////////////////////////////////////////////////////////

    /// @notice Mint a batch of tokens.
    /// @param ids an array of token art/IDs.
    /// @param _titles array of titles. Empty strings will be skipped.
    /// @param _styles array of styles. Empty strings will be skipped.
    function mint(
        uint256[] calldata ids,
        string[] calldata _titles,
        string[] calldata _styles
    ) external virtual {
        address to = msg.sender;
        uint256 idsLength = ids.length;
        uint256 id;

        for (uint256 i = 0; i < idsLength; ) {
            id = ids[i];

            if (_ownerOf[id] != address(0)) {
                revert AlreadyExists(id);
            }
            _ownerOf[id] = to;

            if (i < _titles.length && bytes(_titles[i]).length != 0) {
                titles[id] = _titles[i];
            }

            if (i < _styles.length && bytes(_styles[i]).length != 0) {
                styles[id] = _styles[i];
            }
            unchecked {
                ++i;
            }
            emit Transfer(address(0), to, id);
        }

        unchecked {
            _balanceOf[to] += idsLength;
        }
    }

    function burn(uint256 tokenID) external tokenOwnerOnly(tokenID) {
        _burn(tokenID);
    }

    ////////////////////////////////////////////////////////////////
    //                        CREATOR
    ////////////////////////////////////////////////////////////////

    /// @notice Creator can optionally set the title of the token
    /// @param tokenID the ID of the token
    /// @param title the title of this token
    function setTitle(uint256 tokenID, string calldata title)
        external
        tokenOwnerOnly(tokenID)
    {
        titles[tokenID] = title;
    }

    /// @notice Creator can optionally set the description of the token
    /// @param tokenID the ID of the token
    /// @param description the description of this token
    function setDescription(uint256 tokenID, string calldata description)
        external
        tokenOwnerOnly(tokenID)
    {
        descriptions[tokenID] = description;
    }

    /// @notice Creator can set the CSS for the svg
    /// @param tokenID the ID of the token
    /// @param style the CSS style. Double quotes will be removed.
    function setStyle(uint256 tokenID, string calldata style)
        external
        tokenOwnerOnly(tokenID)
    {
        styles[tokenID] = style;
    }

    ////////////////////////////////////////////////////////////////
    //                        OWNER OPS
    ////////////////////////////////////////////////////////////////

    function setName(string memory _name) external onlyOwner {
        name = _name;
    }

    function setSymbol(string memory _symbol) external onlyOwner {
        symbol = _symbol;
    }

    function setDefaultTitle(string memory title) external onlyOwner {
        defaultTitle = title;
    }

    function setDefaultDescription(string memory description)
        external
        onlyOwner
    {
        defaultDescription = description;
    }

    function setRenderer(IIconRenderer _renderer) external onlyOwner {
        renderer = _renderer;
    }

    function setExternalBaseURL(string memory _url) external onlyOwner {
        externalBaseURL = _url;
    }

    function release(address payable payee) external onlyOwner {
        (bool success, ) = payable(payee).call{value: address(this).balance}(
            ""
        );
        require(success);
    }

    function releaseERC20(ERC20 token, address payee) external onlyOwner {
        token.transfer(payee, token.balanceOf(address(this)));
    }

    ////////////////////////////////////////////////////////////////
    //                        MODIFIERS
    ////////////////////////////////////////////////////////////////

    modifier onlyMinted(uint256 tokenID) {
        if (_ownerOf[tokenID] == address(0)) {
            revert DoesNotExist();
        }
        _;
    }

    modifier tokenOwnerOnly(uint256 tokenID) {
        if (_ownerOf[tokenID] != msg.sender) {
            revert TokenOwnerOnly();
        }
        _;
    }
}
