// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Prohibition / VenturePunk,LLC
// Written By: Thomas Lipari (thom.eth)
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Base64.sol";

/**
 * @title The WrappedPresent contract
 * @author Thomas Lipari (thom.eth)
 * @notice A contract that represents a random gift in the Santa.fm Gift Exchange
 */
contract WrappedPresent is Ownable, ERC721 {
    using Strings for uint256;

    // Designated Minter Role
    address public minter;
    // URL for the image returned in the token's metadata
    string internal tokenImage;
    // Counter for tokens minted
    uint256 public totalTokensMinted;
    // Counter for tokens burned
    uint256 public totalTokensBurned;
    // Year of the gift exchange
    uint256 public year;
    // URL of the gift exchange dapp ui
    string public url;

    // Mapping of burned tokens by address
    mapping(address burnerAccount => uint256[] burnedTokenIds) public burnedBy;
    // Mapping of of whether or not a token has been burned
    mapping(uint256 tokenId => bool hasBeenBurned) public burned;

    // Error for when an account doesn't own a token when burning
    error OnlyOwnerCanBurnThroughMinter();

    // Event for burning tokens
    event Burn(uint256 tokenId, address account);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _tokenImage,
        string memory _url,
        uint256 _year
    ) Ownable() ERC721(_name, _symbol) {
        tokenImage = _tokenImage;
        url = _url;
        year = _year;
    }

    /*
     * Owner Functions
     */

    /**
     * @notice Function that sets the image to be returned in Token URI
     * @param _tokenImage - The tokenId we're checking
     */
    function setTokenImage(string memory _tokenImage) public onlyOwner {
        tokenImage = _tokenImage;
    }

    /**
     * @notice Function that updates the designated minter
     * @param _minter - The address of the new minter
     */
    function setMinter(address _minter) public onlyOwner {
        minter = _minter;
    }

    /**
     * @notice Function that transfers a tokenId
     * @param from - The sender of the transfer
     * @param to - The receiver of the transfer
     * @param tokenId - TokenID of the token being transferred
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /*
     * Minter Functions
     */

    /**
     * @notice Function that mints an NFT. Can only be called by `minter`
     * @param to - The address that receives the minted NFT
     */
    function simpleMint(address to) public onlyMinter {
        // increment number of tokens minted
        totalTokensMinted += 1;

        // mint the token to the address
        _mint(to, totalTokensMinted);
    }

    /**
     * @notice Function that burns a present
     * @param tokenId - The tokenId to burn
     * @param account - The account that owns the token
     *
     * @dev [WARNING!] Be sure that when using this function, the `account` actually owns `tokenId`
     */
    function burn(uint256 tokenId, address account) public onlyMinter {
        // Since _burn does not check approval for burning, we have to make sure that the
        // designated Minter only passes the correct owner of the token as `account`
        if (ownerOf(tokenId) != account) revert OnlyOwnerCanBurnThroughMinter();

        // burn the token.
        _burn(tokenId);

        // keep track of burnings
        totalTokensBurned += 1;
        burnedBy[account].push(tokenId);
        burned[tokenId] = true;

        // emit our event
        emit Burn(tokenId, account);
    }

    /*
     * URI Functions
     */

    /**
     * @notice Function that returns the Contract URI
     */
    function contractURI() public view returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                '{"name": "Santa.FM NFT Gift Exchange", ',
                                '"description": "Santa.fm Presents are NFTs from the NFT Gift Exchange pool. Add a NFT gift to the pool and receive a NFT Present in return that you open on Christmas morning.", ',
                                '"external_link": "',
                                url,
                                '" }'
                            )
                        )
                    )
                )
            )
        );
    }

    /**
     * @notice Function that returns the URI for a token
     * @param id - Token ID we're referencing
     */
    function tokenURI(uint256 id) public view override returns (string memory) {
        // Fail if token hasn't been minted
        require(id <= totalTokensMinted);

        // Fail if token has been burned
        require(!burned[id]);

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                '{"name": "Wrapped Present #',
                                id.toString(),
                                '", ',
                                '"description": "Wrapped Presents are given to you when you add an NFT to the Gift Dexchange. Use this present to redeem a random gift on Christmas Day!", ',
                                '"image": "',
                                tokenImage,
                                '", "attributes": [{"trait_type": "Gift", "value": "Wrapped Present"}, {"trait_type": "Year", "value": "',
                                year.toString(),
                                '" }]}'
                            )
                        )
                    )
                )
            )
        );
    }

    /*
     * Modifiers
     */

    modifier onlyMinter() {
        require(msg.sender == minter);
        _;
    }
}
