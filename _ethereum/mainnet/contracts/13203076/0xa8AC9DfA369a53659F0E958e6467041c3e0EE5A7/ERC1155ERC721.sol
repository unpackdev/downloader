// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import "./IERC1155.sol";
import "./IERC1155TokenReceiver.sol";
import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC20Adapter.sol";
import "./Context.sol";
import "./Address.sol";

/// @title A ERC1155 and ERC721 Implmentation
contract ERC1155ERC721 is IERC165, IERC1155, IERC721, Context {
    using Address for address;
    
    mapping(uint256 => uint256) internal _totalSupply;
    mapping(address => mapping(uint256 => uint256)) internal _ftBalances;
    mapping(address => uint256) internal _nftBalances;
    mapping(uint256 => address) internal _nftOwners;
    mapping(uint256 => address) internal _nftOperators;
    mapping(address => mapping(uint256 => uint256)) internal _recordingBalances;
    mapping(uint256 => address) internal _recordingOperators;
    mapping(address => mapping(address => bool)) internal _operatorApproval;
    mapping(uint256 => address) internal _settingOperators;
    mapping(uint256 => uint256) internal _timeInterval;
    mapping(address => mapping(uint256 => uint256)) internal _lastUpdateAt;
    mapping(address => mapping(uint256 => uint256)) internal _holdingTime;
    mapping(address => mapping(uint256  => uint256)) internal _recordingLastUpdateAt;
    mapping(address => mapping(uint256  => uint256)) internal _recordingHoldingTime;
    
    // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    bytes4 constant private ERC1155_ACCEPTED = 0xf23a6e61;
    // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
    bytes4 constant private ERC1155_BATCH_ACCEPTED = 0xbc197c81;
    bytes4 constant private ERC721_ACCEPTED = 0x150b7a02;
    bytes4 constant private INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;
    bytes4 constant private INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;
    bytes4 constant private INTERFACE_SIGNATURE_ERC1155Receiver = 0x4e2312e0;
    bytes4 constant private INTERFACE_SIGNATURE_ERC721 = 0x80ac58cd;

    uint256 private constant IS_NFT = 1 << 255;
    uint256 internal constant NEED_TIME = 1 << 254;
    uint256 private idNonce;
    
    
    /// @dev Emitted when `_tokenId` token is transferred from `_from` to `_to`.
    /// @dev Not included in ERC721 interface because it causes a conflict between ERC1155 and ERC721
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev Emitted when `_owner` enables `_approved` to manage the `_tokenId` token.
    /// @dev Not included in ERC721 interface because it causes a conflict between ERC1155 and ERC721
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    
    /// @dev Emitted when `_value` amount of `_tokenId` recording token is transferred from
    /// `_from` to `_to` by `_operator`.
    event RecordingTransferSingle(address _operator, address indexed _from, address indexed _to, uint256 indexed _tokenId, uint256 _value);
    
    /// @dev Emitted when `_tokenId`'s interval of token holding time range is being set
    event TimeInterval(uint256 indexed _tokenId, uint256 _startTime, uint256 _endTime);

    modifier AuthorizedTransfer(
        address _operator,
        address _from,
        uint _tokenId
    ) {
        require(
            _from == _operator ||
            _nftOperators[_tokenId] == _operator ||
            _operatorApproval[_from][_operator],
            "Not authorized"
        );
        _;
    }

    /////////////////////////////////////////// Query //////////////////////////////////////////////
    
    /// @notice Returns the setting operator of a token
    /// @param _tokenId Token ID to be queried
    /// @return The setting operator address
    function settingOperatorOf(uint256 _tokenId)
        external
        view
        returns (address)
    {
        return _settingOperators[_tokenId];
    }

    /// @notice Returns the recording operator of a token
    /// @param _tokenId Token ID to be queried
    /// @return The recording operator address
    function recordingOperatorOf(uint256 _tokenId)
        external
        view
        returns (address)
    {
        return _recordingOperators[_tokenId];
    }

    /// @notice Returns the starting time and ending time of token holding
    /// time calculation
    /// @param _tokenId Token ID to be queried
    /// @return The starting time in unix time
    /// @return The ending time in unix time
    function timeIntervalOf(uint256 _tokenId)
        external
        view
        returns (uint256, uint256)
    {
        uint256 startTime = uint256(uint128(_timeInterval[_tokenId]));
        uint256 endTime = uint256(_timeInterval[_tokenId] >> 128);
        return (startTime, endTime);
    }

    /////////////////////////////////////////// ERC165 //////////////////////////////////////////////
    
    /// @notice Query if a contract implements an interface
    /// @param _interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `_interfaceId`,
    ///  `false` otherwise
    function supportsInterface(
        bytes4 _interfaceId
    )
        public
        pure
        virtual
        override
        returns (bool)
    {
        if (_interfaceId == INTERFACE_SIGNATURE_ERC165 ||
            _interfaceId == INTERFACE_SIGNATURE_ERC1155 || 
            _interfaceId == INTERFACE_SIGNATURE_ERC721) {
            return true;
        }
        return false;
    }
    
    /////////////////////////////////////////// ERC1155 //////////////////////////////////////////////

    /// @notice Transfers `_value` amount of an `_tokenId` from the `_from` address to the `_to` address specified (with safety call).
    /// @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
    /// MUST revert if `_to` is the zero address.
    /// MUST revert if balance of holder for token `_tokenId` is lower than the `_value` sent.
    /// MUST revert on any other error.
    /// MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
    /// After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
    /// @param _from    Source address
    /// @param _to      Target address
    /// @param _tokenId     ID of the token type
    /// @param _value   Transfer amount
    /// @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _value,
        bytes calldata _data
    ) 
        external
        override
        AuthorizedTransfer(_msgSender(), _from, _tokenId)
    {
        require(_to != address(0x0), "_to must be non-zero.");
        if (_tokenId & IS_NFT > 0) {
            if (_value > 0) {
                require(_value == 1, "NFT amount more than 1");
                safeTransferFrom(_from, _to, _tokenId, _data);
            }
            return;
        }

        if (_tokenId & NEED_TIME > 0) {
           _updateHoldingTime(_from, _tokenId);
           _updateHoldingTime(_to, _tokenId);
        }
        _transferFrom(_from, _to, _tokenId, _value);

        if (_to.isContract()) {
            require(_checkReceivable(_msgSender(), _from, _to, _tokenId, _value, _data, false, false),
                    "Transfer rejected");
        }
    }
    
    /// @notice Transfers `_values` amount(s) of `_tokenIds` from the `_from` address to the `_to` address specified (with safety call).
    /// @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
    /// MUST revert if `_to` is the zero address.
    /// MUST revert if length of `_tokenIds` is not the same as length of `_values`.
    /// MUST revert if any of the balance(s) of the holder(s) for token(s) in `_tokenIds` is lower than the respective amount(s) in `_values` sent to the recipient.
    /// MUST revert on any other error.
    /// MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
    /// Balance changes and events MUST follow the ordering of the arrays (_tokenIds[0]/_values[0] before _tokenIds[1]/_values[1], etc).
    /// After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
    /// @param _from    Source address
    /// @param _to      Target address
    /// @param _tokenIds     IDs of each token type (order and length must match _values array)
    /// @param _values  Transfer amounts per token type (order and length must match _tokenIds array)
    /// @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _tokenIds,
        uint256[] calldata _values,
        bytes calldata _data
    )
        external
        override
    {
        require(_to != address(0x0), "_to must be non-zero.");
        require(_tokenIds.length == _values.length, "Array length must match.");
        bool authorized = _from == _msgSender() || _operatorApproval[_from][_msgSender()];
            
        _batchUpdateHoldingTime(_from, _tokenIds);
        _batchUpdateHoldingTime(_to, _tokenIds);
        _batchTransferFrom(_from, _to, _tokenIds, _values, authorized);
        
        if (_to.isContract()) {
            require(_checkBatchReceivable(_msgSender(), _from, _to, _tokenIds, _values, _data),
                    "BatchTransfer rejected");
        }
    }
    
    
    /// @notice Get the balance of an account's Tokens.
    /// @dev It accept both 
    /// @param _owner  The address of the token holder
    /// @param _tokenId     ID of the Token
    /// @return        The _owner's balance of the Token type requested
    function balanceOf(
        address _owner,
        uint256 _tokenId
    )
        public
        view
        virtual
        override
        returns (uint256) 
    {
        if (_tokenId & IS_NFT > 0) {
            if (_ownerOf(_tokenId) == _owner)
                return 1;
            else
                return 0;
        }
        return _ftBalances[_owner][_tokenId];
    }
    
    /// @notice Get the balance of multiple account/token pairs
    /// @param _owners The addresses of the token holders
    /// @param _tokenIds    ID of the Tokens
    /// @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
    function balanceOfBatch(
        address[] calldata _owners,
        uint256[] calldata _tokenIds
    )
        external
        view
        override
        returns (uint256[] memory)
    {
        require(_owners.length == _tokenIds.length, "Array lengths should match");

        uint256[] memory balances_ = new uint256[](_owners.length);
        for (uint256 i = 0; i < _owners.length; ++i) {
            balances_[i] = balanceOf(_owners[i], _tokenIds[i]);
        }

        return balances_;
    }

    /// @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
    /// @dev MUST emit the ApprovalForAll event on success.
    /// @param _operator  Address to add to the set of authorized operators
    /// @param _approved  True if the operator is approved, false to revoke approval
    function setApprovalForAll(
        address _operator,
        bool _approved
    )
        external
        override(IERC1155, IERC721)
    {
        _operatorApproval[_msgSender()][_operator] = _approved;
        emit ApprovalForAll(_msgSender(), _operator, _approved);
    }
    
    /// @notice Queries the approval status of an operator for a given owner.
    /// @param _owner     The owner of the Tokens
    /// @param _operator  Address of authorized operator
    /// @return           True if the operator is approved, false if not
    function isApprovedForAll(
        address _owner,
        address _operator
    ) 
        external
        view
        override(IERC1155, IERC721)
        returns (bool) 
    {
        return _operatorApproval[_owner][_operator];
    }

    /////////////////////////////////////////// ERC721 //////////////////////////////////////////////

    /// @notice Count all NFTs assigned to an owner
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) 
        external
        view
        override
        returns (uint256) 
    {
        return _nftBalances[_owner];
    }
    

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address or FT token are considered invalid,
    ///  and queries about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId)
        external
        view
        override
        returns (address) 
    {
        address owner = _ownerOf(_tokenId);
        require(owner != address(0), "Not nft or not exist");
        return owner;
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) 
        external
        override
    {
        safeTransferFrom(_from, _to, _tokenId, "");
    }
    
    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param _data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    )
        public
        override
        AuthorizedTransfer(_msgSender(), _from, _tokenId)
    {
        require(_to != address(0), "_to must be non-zero");
        require(_nftOwners[_tokenId] == _from, "Not owner or it's not nft");
        
        if (_tokenId & NEED_TIME > 0) {
           _updateHoldingTime(_from, _tokenId);
           _updateHoldingTime(_to, _tokenId);
        }
        _transferFrom(_from, _to, _tokenId, 1);
        
        if (_to.isContract()) {
            require(_checkReceivable(_msgSender(), _from, _to, _tokenId, 1, _data, true, true),
                    "Transfer rejected");
        }
    }
    
    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) 
        external
        override
        AuthorizedTransfer(_msgSender(), _from, _tokenId)
    {
        require(_to != address(0), "_to must be non-zero");
        require(_nftOwners[_tokenId] == _from, "Not owner or it's not nft");
                
        if (_tokenId & NEED_TIME > 0) {
           _updateHoldingTime(_from, _tokenId);
           _updateHoldingTime(_to, _tokenId);
        }
        _transferFrom(_from, _to, _tokenId, 1);

        if (_to.isContract()) {
            require(_checkReceivable(_msgSender(), _from, _to, _tokenId, 1, "", true, false),
                    "Transfer rejected");
        }
    }
    
    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _to The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(
        address _to,
        uint256 _tokenId
    )
        external
        override 
    {
        address owner = _nftOwners[_tokenId];
        require(owner == _msgSender() || _operatorApproval[owner][_msgSender()],
                "Not authorized or not a nft");
        _nftOperators[_tokenId] = _to;
        emit Approval(owner, _to, _tokenId);
    }
    
    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) 
        external
        view
        override
        returns (address) 
    {
        require(_tokenId & IS_NFT > 0, "Not a nft");
        return _nftOperators[_tokenId];
    }

    /////////////////////////////////////////// Recording //////////////////////////////////////////////
    
    /// @notice Transfer recording token
    /// @dev If `_to` is zeroaddress or `msg.sender` is not recording operator,
    ///  it throwsa.
    /// @param _from Current owner of recording token
    /// @param _to New owner
    /// @param _tokenId The token to transfer
    /// @param _value The amount to transfer
    function recordingTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _value
    ) 
        external
    {
        require(_msgSender() == _recordingOperators[_tokenId], "Not authorized");
        require(_to != address(0), "_to must be non-zero");

       _updateRecordingHoldingTime(_from, _tokenId);
       _updateRecordingHoldingTime(_to, _tokenId);
        _recordingTransferFrom(_from, _to, _tokenId, _value);
    }
    
    /// @notice Count all recording token assigned to an address
    /// @param _owner An address for whom to query the balance
    /// @param _tokenId The token ID to be queried
    function recordingBalanceOf(
        address _owner,
        uint256 _tokenId
    ) 
        public 
        view
        returns (uint256)
    {
        return _recordingBalances[_owner][_tokenId];
    }
    
    /////////////////////////////////////////// Holding Time //////////////////////////////////////////////

    function _updateHoldingTime(
        address _owner,
        uint256 _tokenId
    )
        internal
    {
        require(_tokenId & NEED_TIME > 0, "Doesn't support this token");

        _holdingTime[_owner][_tokenId] += _calcHoldingTime(_owner, _tokenId);
        _lastUpdateAt[_owner][_tokenId] = block.timestamp;
    }

    function _batchUpdateHoldingTime(
        address _owner,
        uint256[] memory _tokenIds
    )
        internal
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if (_tokenIds[i] & NEED_TIME > 0)
               _updateHoldingTime(_owner, _tokenIds[i]);
        }
    }
    
    function _updateRecordingHoldingTime(
        address _owner,
        uint256 _tokenId
    )
        internal
    {
        _recordingHoldingTime[_owner][_tokenId] += _calcRecordingHoldingTime(_owner, _tokenId);
        _recordingLastUpdateAt[_owner][_tokenId] = block.timestamp;
    }

    /////////////////////////////////////////// Internal //////////////////////////////////////////////

    function _calcHoldingTime(
        address _owner,
        uint256 _tokenId
    )
        internal
        view
        returns (uint256)
    {
        uint256 lastTime = _lastUpdateAt[_owner][_tokenId];
        uint256 startTime = uint256(uint128(_timeInterval[_tokenId]));
        uint256 endTime = uint256(_timeInterval[_tokenId] >> 128);
        uint256 balance = balanceOf(_owner, _tokenId);

        if (balance == 0)
            return 0;
        if (startTime == 0 || startTime >= block.timestamp)
            return 0;
        if (lastTime >= endTime)
            return 0;
        if (lastTime < startTime)
            lastTime = startTime;

        if (block.timestamp > endTime)
            return balance * (endTime - lastTime);
        else
            return balance * (block.timestamp - lastTime);
    }

    function _calcRecordingHoldingTime(
        address _owner,
        uint256 _tokenId
    )
        internal
        view
        returns (uint256)
    {
        uint256 lastTime = _recordingLastUpdateAt[_owner][_tokenId];
        uint256 startTime = uint256(uint128(_timeInterval[_tokenId]));
        uint256 endTime = uint256(_timeInterval[_tokenId] >> 128);
        uint256 balance = recordingBalanceOf(_owner, _tokenId);

        if (balance == 0)
            return 0;
        if (startTime == 0 || startTime >= block.timestamp)
            return 0;
        if (lastTime >= endTime)
            return 0;
        if (lastTime < startTime)
            lastTime = startTime;

        if (block.timestamp > endTime)
            return balance * (endTime - lastTime);
        else
            return balance * (block.timestamp - lastTime);
    }

    function _setTime(
        uint256 _tokenId,
        uint128 _startTime,
        uint128 _endTime
    )
        internal
    {
        uint256 timeInterval = _startTime + (uint256(_endTime) << 128);
        _timeInterval[_tokenId] = timeInterval;

        emit TimeInterval(_tokenId, uint256(_startTime), uint256(_endTime));
    }

    function _recordingTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _value
    )
        internal
    {
        _recordingBalances[_from][_tokenId] -= _value;
        _recordingBalances[_to][_tokenId] += _value;
        emit RecordingTransferSingle(_msgSender(), _from, _to, _tokenId, _value);
    }
    
    function _batchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds,
        uint256[] memory _values,
        bool authorized
    ) 
        internal
    {
        uint256 numNFT;
        
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if (_values[i] > 0) {
                if (_tokenIds[i] & IS_NFT > 0) {
                    require(_values[i] == 1, "NFT amount is not 1");
                    require(_nftOwners[_tokenIds[i]] == _from, "_from is not owner");
                    require(_nftOperators[_tokenIds[i]] == _msgSender() || authorized, "Not authorized");
                    numNFT++;
                    _nftOwners[_tokenIds[i]] = _to;
                    _nftOperators[_tokenIds[i]] = address(0);
                    emit Transfer(_from, _to, _tokenIds[i]);
                } else {
                    require(authorized, "Not authorized");
                    _ftBalances[_from][_tokenIds[i]] -= _values[i];
                    _ftBalances[_to][_tokenIds[i]] += _values[i];
                }
            }
        }
        _nftBalances[_from] -= numNFT;
        _nftBalances[_to] += numNFT;

        emit TransferBatch(_msgSender(), _from, _to, _tokenIds, _values);
    }
    
    function _mint(
        uint256 _supply,
        address _receiver,
        address _settingOperator,
        bool _needTime,
        bytes memory _data
    )
        internal
        returns (uint256)
    {
        uint256 tokenId = ++idNonce;
        if (_needTime)
            tokenId |= NEED_TIME;

        if (_supply == 1) {
            tokenId |= IS_NFT;
            _nftBalances[_receiver]++;
            _nftOwners[tokenId] = _receiver;
            emit Transfer(address(0), _receiver, tokenId);
        } else {
            _ftBalances[_receiver][tokenId] += _supply;
        }

        _totalSupply[tokenId] += _supply;
        _settingOperators[tokenId] = _settingOperator;
        
        emit TransferSingle(_msgSender(), address(0), _receiver, tokenId, _supply);
        
        if (_receiver.isContract()) {
            require(_checkReceivable(_msgSender(), address(0), _receiver, tokenId, _supply, _data, false, false),
                    "Transfer rejected");
        }
        return tokenId;
    }
    
    function _mintCopy(
        uint256 _tokenId,
        uint256 _supply,
        address _recordingOperator
    )
        internal
    {
        _recordingBalances[_recordingOperator][_tokenId] += _supply;
        _recordingOperators[_tokenId] = _recordingOperator;
        emit RecordingTransferSingle(_msgSender(), address(0), _recordingOperator, _tokenId, _supply);
    }
    
    function _checkReceivable(
        address _operator,
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _value,
        bytes memory _data,
        bool _erc721erc20,
        bool _erc721safe
    )
        internal
        returns (bool)
    {
        if (_erc721erc20 && !_checkIsERC1155Receiver(_to)) {
            if (_erc721safe)
                return _checkERC721Receivable(_operator, _from, _to, _tokenId, _data);
            else
                return true;
        }
        return _checkERC1155Receivable(_operator, _from, _to, _tokenId, _value, _data);
    }
    
    function _checkERC1155Receivable(
        address _operator,
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _value,
        bytes memory _data
    )
        internal
        returns (bool)
    {
        return (IERC1155TokenReceiver(_to).onERC1155Received(_operator, _from, _tokenId, _value, _data) == ERC1155_ACCEPTED);
    }
    
    function _checkERC721Receivable(
        address _operator,
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    )
        internal
        returns (bool)
    {
        return (IERC721Receiver(_to).onERC721Received(_operator, _from, _tokenId, _data) == ERC721_ACCEPTED);
    }
    
    function _checkIsERC1155Receiver(address _to) 
        internal
        returns (bool)
    {
        (bool success, bytes memory data) = _to.call(
            abi.encodeWithSelector(IERC165.supportsInterface.selector, INTERFACE_SIGNATURE_ERC1155Receiver));
        if (!success)
            return false;
        bool result = abi.decode(data, (bool));
        return result;
    }
    
    function _checkBatchReceivable(
        address _operator,
        address _from,
        address _to,
        uint256[] memory _tokenIds,
        uint256[] memory _values,
        bytes memory _data
    )
        internal
        returns (bool)
    {
        return (IERC1155TokenReceiver(_to).onERC1155BatchReceived(_operator, _from, _tokenIds, _values, _data)
                == ERC1155_BATCH_ACCEPTED);
    }
    
    function _ownerOf(uint256 _tokenId)
        internal
        view
        returns (address)
    {
        return _nftOwners[_tokenId]; 
    }
    
    function _transferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _value
    )
        internal
        virtual
    {
        if (_tokenId & IS_NFT > 0) {
            if (_value > 0) {
                require(_value == 1, "NFT amount more than 1");
                _nftOwners[_tokenId] = _to;
                _nftBalances[_from]--;
                _nftBalances[_to]++;
                _nftOperators[_tokenId] = address(0);
                
                emit Transfer(_from, _to, _tokenId);
            }
        } else {
            if (_value > 0) {
                _ftBalances[_from][_tokenId] -= _value;
                _ftBalances[_to][_tokenId] += _value;
            }
        }
        
        emit TransferSingle(_msgSender(), _from, _to, _tokenId, _value);
    }
}

