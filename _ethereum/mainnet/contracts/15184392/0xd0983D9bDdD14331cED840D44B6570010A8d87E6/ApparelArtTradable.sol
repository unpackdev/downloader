// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./ERC1155MintBurn.sol";

contract ApparelArtTradable is 
    ERC1155,
    ERC1155MintBurn,
    Ownable
{
    using SafeMath for uint256;
    event Minted(
        uint256 tokenId,
        address beneficiary,
        uint256 supply,
        string tokenUri,
        address minter
    );
    event UpdatePlatformFee(
        uint256 platformFee
    );
    event UpdateFeeRecipient(
        address payable feeRecipient
    );
    uint256 private _currentTokenID = 0;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    mapping(uint256 => address) public creators;
    mapping(uint256 => uint256) public tokenSupply;

    // Contract name
    string public name;
    // Contract symbol
    string public symbol;
    // Platform fee
    uint256 public platformFee;
    // Platform fee receipient
    address payable public feeReceipient;
    // Apparel Marketplace contract
    address marketplace;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _platformFee,
        address payable _feeReceipient,
        address _marketplace
    ) public {
        name = _name;
        symbol = _symbol;
        platformFee = _platformFee;
        feeReceipient = _feeReceipient;
        marketplace = _marketplace;
    }

    function uri(uint256 _id) public view returns (string memory) {
        require(_exists(_id), "ERC721Tradable#uri: NONEXISTENT_TOKEN");
        return _tokenURIs[_id];
    }

    /**
     * @dev Returns the total quantity for a token ID
     * @param _id uint256 ID of the token to query
     * @return amount of token in existence
     */
    function totalSupply(uint256 _id) public view returns (uint256) {
        return tokenSupply[_id];
    }

    /**
     * @dev Creates a new token type and assigns _supply to an address
     * @param _to owner address of the new token
     * @param _supply Optional amount to supply the first owner
     * @param _uri Optional URI for this token type
     */
    function mint(
        address _to,
        uint256 _supply,
        string calldata _uri
    ) external payable {
        require(msg.value >= platformFee, "Insufficient funds to mint.");

        uint256 _id = _getNextTokenID();
        _incrementTokenTypeId();

        creators[_id] = msg.sender;
        _setTokenURI(_id, _uri);

        if (bytes(_uri).length > 0) {
            emit URI(_uri, _id);
        }

        _mint(_to, _id, _supply, bytes(""));
        tokenSupply[_id] = _supply;

        // Send fee to fee recipient
        (bool success, ) = feeReceipient.call{value: msg.value}("");
        require(success, "Transfer failed");
        emit Minted(_id, _to, _supply, _uri, _msgSender());
    }

    function getCurrentTokenID() public view returns (uint256) {
        return _currentTokenID;
    }

    /**
     * Override isApprovedForAll to whitelist Apparel contracts to enable gas-less listings.
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool isOperator)
    {
        // Whitelist Apparel marketplace for easy trading.
        if (marketplace == _operator) {
            return true;
        }

        return ERC1155.isApprovedForAll(_owner, _operator);
    }

    /**
     * @dev Returns whether the specified token exists by checking to see if it has a creator
     * @param _id uint256 ID of the token to query the existence of
     * @return bool whether the token exists
     */
    function _exists(uint256 _id) public view returns (bool) {
        return creators[_id] != address(0);
    }

    /**
     * @dev calculates the next token ID based on value of _currentTokenID
     * @return uint256 for the next token ID
     */
    function _getNextTokenID() private view returns (uint256) {
        return _currentTokenID.add(1);
    }

    /**
     * @dev increments the value of _currentTokenID
     */
    function _incrementTokenTypeId() private {
        _currentTokenID++;
    }

    /**
     * @dev Internal function to set the token URI for a given token.
     * Reverts if the token ID does not exist.
     * @param _id uint256 ID of the token to set its URI
     * @param _uri string URI to assign
     */
    function _setTokenURI(uint256 _id, string memory _uri) internal {
        require(_exists(_id), "_setTokenURI: Token should exist");
        _tokenURIs[_id] = _uri;
    }
}
