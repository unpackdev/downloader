// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./IERC20.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./Counters.sol";
import "./ERC165.sol";

contract FastPass is ERC721, Ownable {

    /// The max token supply
    uint256 public constant MAX_SUPPLY = 20;

    /// The base URI
    string public baseURI = "https://api.satoshibles.com/token/fast-pass/";

    /// When true, the baseURI can no longer be changed
    bool public baseUriLocked;

    /// Use Counters for token IDs
    using Counters for Counters.Counter;

    /// Token ID counter
    Counters.Counter private _tokenIds;

    /// Boom... Let's go!
    constructor() ERC721("Stacks Bridge: Satoshibles Fast Pass", "SBSFP") {
        for (uint256 i = 0; i < MAX_SUPPLY; i++) {
            _tokenIds.increment();
            _safeMint(
                _msgSender(),
                _tokenIds.current()
            );
        }
    }

    /**
     * @dev Returns the current total supply derived from token count.
     */
    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
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
     * @notice Withdraw balance
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

    /// @inheritdoc	ERC165
    function supportsInterface(
        bytes4 _interfaceId
    )
        public
        view
        override (ERC721)
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
