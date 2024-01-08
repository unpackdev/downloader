// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/***
 *
 *     _           _ _ _              _ _   _              __ _
 *    | |         (_) | |            (_) | | |            / _| |
 *    | |__  _   _ _| | |_  __      ___| |_| |__    _ __ | |_| |_     ___  _ __ __ _
 *    | '_ \| | | | | | __| \ \ /\ / / | __| '_ \  | '_ \|  _| __|   / _ \| '__/ _` |
 *    | |_) | |_| | | | |_   \ V  V /| | |_| | | | | | | | | | |_   | (_) | | | (_| |
 *    |_.__/ \__,_|_|_|\__|   \_/\_/ |_|\__|_| |_| |_| |_|_|  \__| (_)___/|_|  \__, |
 *                                                                              __/ |
 *                                                                             |___/
 */

import "./Ownable.sol";
import "./IERC20.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./Counters.sol";
import "./ERC165.sol";

import "./ERC2981ContractWideRoyalties.sol";

/**
 * @title Built With NFT
 * @notice 100% charity NFT project by Satoshibles and Built With Bitcoin
 * @author Satoshibles Team (Brian Laughlan, Ayyoub Bouzerda, Aaron Hanson, Jarrad Douglas)
 */
contract BuiltWithNFT is ERC721, ERC2981ContractWideRoyalties, Ownable {

    /// The max token supply
    uint256 public constant MAX_SUPPLY = 10000;

    /// The maximum ERC-2981 royalties percentage
    uint256 public constant MAX_ROYALTIES_PCT = 750;

    /// The current state of the sale
    bool public saleIsActive;

    /// The default token price
    uint256 public tokenPrice = 0.06 ether;

    /// The provenance URI
    string public provenanceURI = "Not Yet Set";

    /// When true, the provenanceURI can no longer be changed
    bool public provenanceUriLocked;

    /// The base URI
    string public baseURI = "https://api.builtwithnft.org/token/";

    /// When true, the baseURI can no longer be changed
    bool public baseUriLocked;

    /// Use Counters for token IDs
    using Counters for Counters.Counter;

    /// Token ID counter
    Counters.Counter private _tokenIds;

    /**
     * @notice Emitted when the saleIsActive flag changes
     * @param isActive Indicates whether or not the sale is now active
     */
    event SaleStateChanged(
        bool indexed isActive
    );

    /**
     * @notice Boom... Let's go!
     * @param _royaltiesPercentage Initial royalties percentage for ERC-2981
     */
    constructor(
        uint256 _royaltiesPercentage
    )
        ERC721("Built With NFT", "BWNFT")
    {
        require(
            _royaltiesPercentage <= MAX_ROYALTIES_PCT,
            "Royalties too high"
        );

        _setRoyalties(
            _msgSender(),
            _royaltiesPercentage
        );
    }

    /**
     * @dev Returns the current total supply derived from token count.
     */
    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    /**
     * @notice Mints tokens during sale
     * @param _numberOfTokens Number of tokens to mint
     */
    function mintTokens(
        uint256 _numberOfTokens
    )
        external
        payable
    {
        require(
            saleIsActive == true,
            "Sale must be active"
        );

        require(
            _numberOfTokens >= 1,
            "Need at least 1 token"
        );

        require(
            _numberOfTokens <= 500,
            "Max 500 at a time"
        );

        unchecked {
            require(
                _tokenIds.current() + _numberOfTokens <= MAX_SUPPLY,
                "Not enough tokens left"
            );

            require(
                tokenPrice * _numberOfTokens == msg.value,
                "Ether amount not correct"
            );

            for (uint256 i = 0; i < _numberOfTokens; i++) {
                _tokenIds.increment();
                _safeMint(
                    _msgSender(),
                    _tokenIds.current()
                );
            }
        }
    }

    /**
     * @notice Activates or deactivates the sale
     * @param _isActive Whether to activate or deactivate the sale
     */
    function activateSale(
        bool _isActive
    )
        external
        onlyOwner
    {
        saleIsActive = _isActive;

        emit SaleStateChanged(
            _isActive
        );
    }

    /**
     * @notice Modifies the price in case of major ETH price changes
     * @param _tokenPrice The new default token price
     */
    function updateTokenPrice(
        uint256 _tokenPrice
    )
        external
        onlyOwner
    {
        require(
            saleIsActive == false,
            "Sale is active"
        );

        require(
            _tokenPrice > 0,
            "Price must be nonzero"
        );

        tokenPrice = _tokenPrice;
    }

    /**
     * @notice Sets the provenance URI
     * @param _newProvenanceURI The new provenance URI
     */
    function setProvenanceURI(
        string calldata _newProvenanceURI
    )
        external
        onlyOwner
    {
        require(
            provenanceUriLocked == false,
            "Provenance URI has been locked"
        );

        provenanceURI = _newProvenanceURI;
    }

    /**
     * @notice Prevents further changes to the provenance URI
     */
    function lockProvenanceURI()
        external
        onlyOwner
    {
        provenanceUriLocked = true;
    }

    /**
     * @notice Sets a new base URI
     * @param _newBaseURI The new base URI
     */
    function setBaseURI(
        string calldata _newBaseURI
    )
        external
        onlyOwner
    {
        require(
            baseUriLocked == false,
            "Base URI has been locked"
        );

        baseURI = _newBaseURI;
    }

    /**
     * @notice Prevents further changes to the base URI
     */
    function lockBaseURI()
        external
        onlyOwner
    {
        baseUriLocked = true;
    }

    /**
     * @notice Withdraws sale proceeds
     * @param _amount Amount to withdraw in wei
     */
    function withdraw(
        uint256 _amount
    )
        external
        onlyOwner
    {
        payable(_msgSender()).transfer(
            _amount
        );
    }

    /**
     * @notice Withdraws any ERC20 tokens
     * @dev WARNING: Double check token is legit before calling this
     * @param _token Contract address of token
     * @param _to Address to which to withdraw
     * @param _amount Amount to withdraw
     * @param _hasVerifiedToken Must be true (sanity check)
     */
    function withdrawERC20(
        address _token,
        address _to,
        uint256 _amount,
        bool _hasVerifiedToken
    )
        external
        onlyOwner
    {
        require(
            _hasVerifiedToken == true,
            "Need to verify token"
        );

        IERC20(_token).transfer(
            _to,
            _amount
        );
    }

    /**
     * @notice Withdraws any ERC721 tokens
     * @dev WARNING: Double check token is legit before calling this
     * @param _token Contract address of token
     * @param _to Address to which to withdraw
     * @param _tokenId Token ID to withdraw
     * @param _hasVerifiedToken Must be true (sanity check)
     */
    function withdrawERC721(
        address _token,
        address _to,
        uint256 _tokenId,
        bool _hasVerifiedToken
    )
        external
        onlyOwner
    {
        require(
            _hasVerifiedToken == true,
            "Need to verify token"
        );

        IERC721(_token).safeTransferFrom(
            address(this),
            _to,
            _tokenId
        );
    }

    /**
     * @notice Sets token royalties (ERC-2981)
     * @param _recipient Recipient of the royalties
     * @param _value Royalty percentage (using 2 decimals - 10000 = 100, 0 = 0)
     */
    function setRoyalties(
        address _recipient,
        uint256 _value
    )
        external
        onlyOwner
    {
        require(
            _value <= MAX_ROYALTIES_PCT,
            "Royalties too high"
        );

        _setRoyalties(
            _recipient,
            _value
        );
    }

    /// @inheritdoc	ERC165
    function supportsInterface(
        bytes4 _interfaceId
    )
        public
        view
        override (ERC721, ERC2981Base)
        returns (bool doesSupportInterface)
    {
        doesSupportInterface = super.supportsInterface(_interfaceId);
    }

    /**
     * @dev Base URI for computing tokenURI
     * @return Base URI string
     */
    function _baseURI()
        internal
        view
        override
        returns (string memory)
    {
        return baseURI;
    }
}
