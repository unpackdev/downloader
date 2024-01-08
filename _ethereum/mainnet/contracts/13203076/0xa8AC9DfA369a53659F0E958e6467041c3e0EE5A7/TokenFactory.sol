// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import "./ITokenFactory.sol";
import "./ERC1155ERC721Metadata.sol";
import "./ERC1155ERC721WithAdapter.sol";
import "./BaseRelayRecipient.sol";

contract TokenFactory is
    ITokenFactory,
    ERC1155ERC721Metadata,
    ERC1155ERC721WithAdapter,
    BaseRelayRecipient
{
    constructor (address _trustedForwarder) {
        trustedForwarder = _trustedForwarder;
    }

    ///////////////////////////////////    EVENTS    //////////////////////////////////////////
    /// @dev Emitted when `_tokenId` token is minted with Mapping token.
    /// @dev Showing `_tokenId` and `_tokenMapId`
    event TokenMapId(uint256 indexed _tokenId, uint256 indexed _tokenMapId);

    /// @notice Query if a contract implements an interface
    /// @param _interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `_interfaceId`,
    ///  `false` otherwise
    function supportsInterface(bytes4 _interfaceId)
        public
        pure
        override(ERC1155ERC721Metadata, ERC1155ERC721)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

    /// @notice Queries accumulated holding time for a given owner and token
    /// @dev It throws if it's not a need-time token. The way how holding time is
    ///  calculated is by suming up (token amount) * (holding time in second)
    /// @param _owner Address to be queried
    /// @param _tokenId Token ID of the token to be queried
    /// @return Holding time
    function holdingTimeOf(
        address _owner,
        uint256 _tokenId
    )
        external
        view
        override
        returns (uint256)
    {
        require(_tokenId & NEED_TIME > 0, "Doesn't support this token");
        
        return _holdingTime[_owner][_tokenId] + _calcHoldingTime(_owner, _tokenId);
    }

    /// @notice Queries accumulated holding time for a given owner and recording token
    /// @dev It throws if it's not a need-time token. The way how holding time is
    ///  calculated is by suming up (token amount) * (holding time in second)
    /// @dev It returns zero if it doesn't have a corresponding recording token
    /// @param _owner Address to be queried
    /// @param _tokenId Token ID of the token to be queried
    /// @return Holding time
    function recordingHoldingTimeOf(
        address _owner,
        uint256 _tokenId
    )
        external
        view
        override
        returns (uint256)
    {
        return _recordingHoldingTime[_owner][_tokenId] + _calcRecordingHoldingTime(_owner, _tokenId);
    }

    /// @notice Create a token without setting uri
    /// @dev It emits `NewAdapter` if `_erc20` is true
    /// @param _supply The amount of token to create
    /// @param _receiver Address that receives minted token
    /// @param _settingOperator Address that can perform setTimeInterval
    ///  and set ERC20 Attribute
    /// @param _needTime Set to `true` if need to query holding time for token
    /// @param _erc20 Set to `true` to create a erc20 adapter for token
    /// @return Token ID
    function createToken(
        uint256 _supply,
        address _receiver,
        address _settingOperator,
        bool _needTime,
        bool _erc20
    )
        public 
        override
        returns (uint256)
    {
        uint256 tokenId = _mint(_supply, _receiver, _settingOperator, _needTime, "");
        if (_erc20)
            _createAdapter(tokenId);
        return tokenId;
    }
    
    /// @notice Create a token with uri
    /// @param _supply The amount of token to create
    /// @param _receiver Address that receives minted token
    /// @param _settingOperator Address that can perform setTimeInterval
    ///  and set ERC20 Attribute
    /// @param _needTime Set to `true` if need to query holding time for token
    /// @param _uri URI that points to token metadata
    /// @param _erc20 Set to `true` to create a erc20 adapter for token
    /// @return Token ID
    function createToken(
        uint256 _supply,
        address _receiver,
        address _settingOperator,
        bool _needTime,
        string calldata _uri,
        bool _erc20
    )
        external
        override
        returns (uint256)
    {
        uint256 tokenId = createToken(_supply, _receiver, _settingOperator, _needTime, _erc20);
        _setTokenURI(tokenId, _uri);
        return tokenId;
    }

    /// @notice Create both normal token and recording token without setting uri
    /// @dev Recording token shares the same token ID with normal token
    /// @param _supply The amount of token to create
    /// @param _supplyOfRecording The amount of recording token to create
    /// @param _receiver Address that receives minted token
    /// @param _settingOperator Address that can perform setTimeInterval
    ///  and set ERC20 Attribute
    /// @param _needTime Set to `true` if need to query holding time for token
    /// @param _recordingOperator Address that can manage recording token
    /// @param _erc20 Set to `true` to create a erc20 adapter for token
    /// @return Token ID
    function createTokenWithRecording(
        uint256 _supply,
        uint256 _supplyOfRecording,
        address _receiver,
        address _settingOperator,
        bool _needTime,
        address _recordingOperator,
        bool _erc20
    )
        public
        override
        returns (uint256)
    {
        uint256 tokenId = createToken(_supply, _receiver, _settingOperator, _needTime, _erc20);
        _mintCopy(tokenId, _supplyOfRecording, _recordingOperator);
        return tokenId;
    }

    /// @notice Create both normal token and recording token with uri
    /// @dev Recording token shares the same token ID with normal token
    /// @param _supply The amount of token to create
    /// @param _supplyOfRecording The amount of recording token to create
    /// @param _receiver Address that receives minted token
    /// @param _settingOperator Address that can perform setTimeInterval
    ///  and set ERC20 Attribute
    /// @param _needTime Set to `true` if need to query holding time for token
    /// @param _recordingOperator Address that can manage recording token
    /// @param _uri URI that points to token metadata
    /// @param _erc20 Set to `true` to create a erc20 adapter for token
    /// @param _mapNft The amount of mapping token to create
    /// @return Token ID
    function createTokenWithRecording(
        uint256 _supply,
        uint256 _supplyOfRecording,
        address _receiver,
        address _settingOperator,
        bool _needTime,
        address _recordingOperator,
        string calldata _uri,
        bool _erc20,
        bool _mapNft
    )
        external
        override
        returns (uint256)
    {
        uint256 tokenId = createToken(_supply, _receiver, _settingOperator, _needTime, _erc20);
        if (_mapNft) {
            uint256 tokenMapId = createToken(1, _receiver, _settingOperator, false, false);
            _setTokenURI(tokenMapId, _uri);
            emit TokenMapId(tokenId, tokenMapId);
        }
        _mintCopy(tokenId, _supplyOfRecording, _recordingOperator);
        _setTokenURI(tokenId, _uri);
        return 0;
    }
    
    /// @notice Set starting time and ending time for token holding time calculation
    /// @dev Starting time must be greater than time at the moment
    /// @dev To save gas cost, here use uint128 to store time
    /// @param _startTime Starting time in unix time format
    /// @param _endTime Ending time in unix time format
    function setTimeInterval(
        uint256 _tokenId,
        uint128 _startTime,
        uint128 _endTime
    )
        external
        override
    {
        require(_msgSender() == _settingOperators[_tokenId], "Not authorized");
        require(_startTime >= block.timestamp, "Time smaller than now");
        require(_endTime > _startTime, "End greater than start");
        require(_timeInterval[_tokenId] == 0, "Already set");

        _setTime(_tokenId, _startTime, _endTime);
    }
    
    /// @notice Set erc20 token attribute
    /// @dev Throws if `msg.sender` is not authorized setting operator
    /// @param _tokenId Corresponding token ID with erc20 adapter
    /// @param _name Name of the token
    /// @param _symbol Symbol of the token
    /// @param _decimals Number of decimals to use
    function setERC20Attribute(
        uint256 _tokenId,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    )
        external
        override
    {
        require(_msgSender() == _settingOperators[_tokenId], "Not authorized");
        require(_adapters[_tokenId] != address(0), "No adapter found");

        _setERC20Attribute(_tokenId, _name, _symbol, _decimals);
    }

    function _transferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _value
    )
        internal
        override(ERC1155ERC721, ERC1155ERC721WithAdapter)
    {
        super._transferFrom(_from, _to, _tokenId, _value);
    }

    function versionRecipient()
        external
        override
        virtual
        view
        returns (string memory)
    {
        return "2.1.0";
    }

    function _msgSender()
        internal
        override(Context, BaseRelayRecipient)
        view
        returns (address payable)
    {
        return BaseRelayRecipient._msgSender();
    }
    
    function _msgData()
        internal
        override(Context, BaseRelayRecipient)
        view
        returns (bytes memory)
    {
        return BaseRelayRecipient._msgData();
    }
}
