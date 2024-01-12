// Github source: https://github.com/alexanderem49/wildwestnft-smart-contracts
// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./ITokenSupplyData.sol";
import "./ERC721Royalty.sol";
import "./Ownable.sol";

contract NFT is ERC721Royalty, Ownable, ITokenSupplyData {
    using Address for address payable;

    uint16 private constant MAX_SUPPLY = 10005;

    uint16 private totalSupply = 0;
    uint16 private ownerSupply = 0;
    uint16 private userSupply = 0;
    string public baseTokenURI;

    mapping(address => bool) private _isWhitelisted;

    event PermanentURI(string _value, uint256 indexed _id);
    event Minted(uint16 indexed _tokenId, address indexed _buyer);

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI_,
        address fundingWallet_
    ) ERC721(name_, symbol_) {
        baseTokenURI = baseTokenURI_;

        _setDefaultRoyalty(fundingWallet_, 1500);

        for (uint16 i = 10001; i <= 10005; i++) {
            // Mints token id of collection nft.
            _safeMint(msg.sender, i);

            emit Minted(i, msg.sender);
            emit PermanentURI(tokenURI(i), i);
        }

        // Increase the total supply of purchases.
        totalSupply = 5;
    }

    /**
     * @notice Mints NFT by the token id.
     * @param _tokenId The token id of collection nft.
     */
    function mint(uint16 _tokenId) external {
        // Limits of collection nft.
        require(userSupply < 9000, "NFT: mint not available");
        require(_tokenId >= 1 && _tokenId <= MAX_SUPPLY, "NFT: token !exists");
        // Mints token id of collection nft by user.
        _safeMint(msg.sender, _tokenId);
        // Increases the total supply of mints.
        totalSupply++;
        // Increases the user supply of mints.
        userSupply++;

        emit Minted(_tokenId, msg.sender);
        emit PermanentURI(tokenURI(_tokenId), _tokenId);
    }

    /**
     * @notice Mints NFT by the token ids.
     * @param _tokenIds The array of token ids of collection nft.
     */
    function mintBulk(uint16[] calldata _tokenIds) external onlyOwner {
        uint16 length = uint16(_tokenIds.length);

        require(ownerSupply + length <= 1000, "NFT: mint not available");

        for (uint16 i = 0; i < length; i++) {
            uint16 _tokenId = _tokenIds[i];
            require(
                _tokenId >= 1 && _tokenId <= MAX_SUPPLY,
                "NFT: token !exists"
            );

            // Mints token id of collection nft by user.
            _safeMint(msg.sender, _tokenId);

            emit Minted(_tokenId, msg.sender);
            emit PermanentURI(tokenURI(_tokenId), _tokenId);
        }
        // Increases the total supply of mints.
        totalSupply += length;
        // Increases the owner supply of mints.
        ownerSupply += length;
    }

    /**
     * @notice Returns the token uri by id.
     * @param _tokenId The token id of collection.
     * @return tokenURI.
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "ERC721Metadata: token !exists");

        return
            string(
                abi.encodePacked(
                    baseTokenURI,
                    Strings.toString(_tokenId),
                    ".json"
                )
            );
    }

    /**
     * @notice Checks token id on existence.
     * @param _tokenId The token id of collection nft.
     * @return Status if token id is exist or not.
     */
    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    /**
     * @notice Returns maximum amount of tokens available to buy on this contract.
     * @return Max supply of tokens.
     */
    function maxSupply() external pure override returns (uint256) {
        return MAX_SUPPLY;
    }

    /**
     * @notice Returns amount of tokens that are minted and sold.
     * @return Circulating supply of tokens.
     */
    function circulatingSupply() external view override returns (uint256) {
        return totalSupply;
    }
}
