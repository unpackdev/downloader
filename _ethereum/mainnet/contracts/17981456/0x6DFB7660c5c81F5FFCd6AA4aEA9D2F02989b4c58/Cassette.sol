// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./IONFT1155.sol";
import "./IONFT1155Core.sol";
import "./ONFT1155Core.sol";
import "./ERC1155.sol";
import "./IERC165.sol";

import "./ICassette.sol";

error Cassette_ExceedsMaxPage();
error Cassette_FunctionLocked();
error Cassette_IncorrectValue();
error Cassette_InvalidConfiguration();
error Cassette_InvalidSendData();
error Cassette_MintClosed();
error Cassette_NotAllowed();
error Cassette_ValueOutOfRange();
error Cassette_WithdrawFailed();

/**
                        .             :++-
                       *##-          +####*          -##+
                       *####-      :%######%.      -%###*
                       *######:   =##########=   .######*
                       *#######*-#############*-*#######*
                       *################################*
                       *################################*
                       *################################*
                       *################################*
                       *################################*
                       :*******************************+.

                .:.
               *###%*=:
              .##########+-.
              +###############=:
              %##################%+
             =######################
             -######################++++++++++++++++++=-:
              =###########################################*:
               =#############################################.
  +####%#*+=-:. -#############################################:
  %############################################################=
  %##############################################################
  %##############################################################%=----::.
  %#######################################################################%:
  %##########################################+:    :+%#######################:
  *########################################*          *#######################
   -%######################################            %######################
     -%###################################%            #######################
       =###################################-          :#######################
     ....+##################################*.      .+########################
  +###########################################%*++*%##########################
  %#########################################################################*.
  %#######################################################################+
  ########################################################################-
  *#######################################################################-
  .######################################################################%.
     :+#################################################################-
         :=#####################################################:.....
             :--:.:##############################################+
   ::             +###############################################%-
  ####%+-.        %##################################################.
  %#######%*-.   :###################################################%
  %###########%*=*####################################################=
  %####################################################################
  %####################################################################+
  %#####################################################################.
  %#####################################################################%
  %######################################################################-
  .+*********************************************************************.
 * @title KAIJU ORIGINS: The Journals of Stod - Cassette
 * @notice See https://origins.kaijukingz.io/ for more details.
 * @author Augminted Labs, LLC
 */
contract Cassette is ONFT1155Core, ERC1155, IONFT1155, ICassette {
    uint16 public constant FUNCTION_TYPE_BURN = uint16(uint256(keccak256("BURN")));

    uint256 public immutable MAX_PAGE;
    uint256 public immutable TOTAL_CHAINS;
    uint256 public immutable TOKEN_OFFSET;

    address public replicator;
    uint256 public currentMaxPage;
    uint256 public price;
    uint256 public totalMinted;
    bool public mintEnabled;

    mapping(bytes4 => bool) public functionLocked;

    constructor(
        string memory _uri,
        address _endpoint,
        uint256 _maxPage,
        uint256 _totalChains,
        uint256 _tokenOffset,
        uint256 _price
    )
        ERC1155(_uri)
        ONFT1155Core(_endpoint)
    {
        if (_tokenOffset >= _totalChains) revert Cassette_InvalidConfiguration();

        MAX_PAGE = _maxPage;
        TOTAL_CHAINS = _totalChains;
        TOKEN_OFFSET = _tokenOffset;
        price = _price;
    }

    /**
     * @notice Modifier applied to functions that will be disabled when they're no longer needed
     */
    modifier lockable() {
        if (functionLocked[msg.sig]) revert Cassette_FunctionLocked();
        _;
    }

    /**
     * @inheritdoc ERC1155
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ONFT1155Core, ERC1155, IERC165)
        returns (bool)
    {
        return interfaceId == type(IONFT1155).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @notice Emulates ERC721 "name" function
     * @return string Contract name
     */
    function name() public pure returns (string memory) {
        return "KAIJU ORIGINS: The Journals of Stod - Cassette";
    }

    /**
     * @notice Emulates ERC721 "symbol" function
     * @return string Token symbol
     */
    function symbol() public pure returns (string memory) {
        return "CASSETTE";
    }

    /**
     * @notice Calculate page number of a specified token ID
     * @param _tokenId Token ID to return the page number of
     * @return uint256 A token's corresponding page number
     */
    function page(uint256 _tokenId) public view returns (uint256) {
        if (_tokenId > MAX_PAGE * TOTAL_CHAINS) revert Cassette_ValueOutOfRange();

        return _tokenId == 0 ? 0 : (_tokenId + TOTAL_CHAINS - 1) / TOTAL_CHAINS;
    }

    /**
     * @notice Calculate token ID of a specified page
     * @dev This will vary depending on which chain this contract is deployed to
     * @param _page Page to return the token ID of
     * @return uint256 A page's corresponding token ID
     */
    function tokenId(uint256 _page) public view returns (uint256) {
        if (_page > MAX_PAGE) revert Cassette_ValueOutOfRange();

        return _page == 0 ? 0 : ((_page - 1) * TOTAL_CHAINS) + TOKEN_OFFSET + 1;
    }

    /**
     * @notice Return an array of token balances for a specified address
     * @param _account Address to return the token balances of
     * @return uint256[] Balances for every valid token ID
     */
    function balancesOf(address _account) public view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](TOTAL_CHAINS * MAX_PAGE + 1);

        for (uint256 i; i < balances.length;) {
            balances[i] = balanceOf(_account, i);
            unchecked { ++i; }
        }

        return balances;
    }

    /**
     * @notice Set the address of the replicator contract
     * @param _replicator Address of the replicator contract
     */
    function setReplicator(address _replicator) public payable lockable onlyOwner {
        replicator = _replicator;
    }

    /**
     * @notice Set the price of a single cassette
     * @param _price Price of a single cassette
     */
    function setPrice(uint256 _price) public payable lockable onlyOwner {
        price = _price;
    }

    /**
     * @notice Set the metadata URI for the contract
     * @param _uri Metadata URI for the contract
     */
    function setURI(string calldata _uri) public payable lockable onlyOwner {
        _setURI(_uri);
    }

    /**
     * @notice Set the current maximum page
     * @param _currentMaxPage Current maximum page
     */
    function setCurrentMaxPage(uint256 _currentMaxPage) public payable lockable onlyOwner {
        if (_currentMaxPage > MAX_PAGE) revert Cassette_ExceedsMaxPage();

        currentMaxPage = _currentMaxPage;
    }

    /**
     * @notice Set the current state of cassette minting
     * @param _mintEnabled Current mint state
     */
    function setMintEnabled(bool _mintEnabled) public payable lockable onlyOwner {
        mintEnabled = _mintEnabled;
    }

    /**
     * @notice Airdrop a specified amount of blank cassettes to a specified list of receivers
     * @param _receivers List of receivers of the airdrop
     * @param _amounts List of amounts to airdrop
     */
    function airdrop(address[] calldata _receivers, uint256[] calldata _amounts) public payable lockable onlyOwner {
        if (_receivers.length != _amounts.length) revert Cassette_ValueOutOfRange();

        for (uint i; i < _receivers.length;) {
            _mint(_receivers[i], 0, _amounts[i]);
            unchecked { ++i; }
        }
    }

    /**
     * @notice Send all ETH transferred to the contract to a specified receiver
     * @param _receiver Address to receive all the ETH in the contract
     */
    function withdraw(address _receiver) public payable onlyOwner {
        (bool success, ) = _receiver.call{value: address(this).balance}("");
        if (!success) revert Cassette_WithdrawFailed();
    }

    /**
     * @notice Mint a specified number of a specific page using a replicator
     * @param _to Address receiving the pages
     * @param _page Page to mint
     * @param _amount Amount of pages to mint
     */
    function replicatorMint(address _to, uint256 _page, uint256 _amount) public payable {
        if (msg.sender != replicator) revert Cassette_NotAllowed();

        _mint(_to, _page, _amount);
    }

    /**
     * @notice Mint a specified number of blank cassettes
     * @param _amount Amount of blank cassettes to mint
     */
    function mint(uint256 _amount) public payable {
        if (!mintEnabled) revert Cassette_MintClosed();
        if (_amount * price != msg.value) revert Cassette_IncorrectValue();

        _mint(msg.sender, 0, _amount);
    }

    /**
     * @notice Internal function for minting cassettes
     * @param _to Address receiving the cassettes
     * @param _page Page to mint
     * @param _amount Amount of cassettes to mint
     */
    function _mint(address _to, uint256 _page, uint256 _amount) internal {
        if (_page > MAX_PAGE) revert Cassette_ExceedsMaxPage();

        _mint(_to, tokenId(_page), _amount, "");

        unchecked { totalMinted += _amount; }
    }

    /**
     * @notice Burn a token to receive the next page in the series
     * @param _tokenId Token to burn
     * @param _amount Amount of tokens to burn
     */
    function burn(uint256 _tokenId, uint256 _amount) public payable {
        uint256 _page = page(_tokenId);

        if (_page + 1 > currentMaxPage) revert Cassette_ExceedsMaxPage();

        _burn(msg.sender, _tokenId, _amount);
        _mint(msg.sender, _page + 1, _amount);
    }

    /**
     * @notice Burn a batch of tokens to receive the next page in the series
     * @param _tokenIds Tokens to burn
     * @param _amounts Amounts of tokens to burn
     */
    function burnBatch(
        uint256[] memory _tokenIds,
        uint256[] memory _amounts
    )
        public
        payable
    {
        for (uint256 i; i < _tokenIds.length;) {
            uint256 _page = page(_tokenIds[i]);

            if (_page + 1 > currentMaxPage) revert Cassette_ExceedsMaxPage();

            _burn(msg.sender, _tokenIds[i], _amounts[i]);
            _mint(msg.sender, _page + 1, _amounts[i]);

            unchecked { ++i; }
        }
    }

    /**
     * @notice Burn a token on the current chain to receive the next page in the series on a destination chain
     * @dev For more details see https://layerzero.gitbook.io/docs/evm-guides/master
     * @param _from Address to burn a token from
     * @param _dstChainId Destination chain's LayerZero ID
     * @param _toAddress Address to receive the next page in the series
     * @param _tokenId Token to burn
     * @param _amount Amount of tokens to burn
     * @param _refundAddress Address to send refund to if transaction is cheaper than expected
     * @param _zroPaymentAddress Address of $ZRO token holder that will pay for the transaction
     * @param _adapterParams Parameters for custom functionality
     */
    function burnFrom(
        address _from,
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint256 _tokenId,
        uint256 _amount,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    )
        public
        payable
    {
        if (page(_tokenId) + 1 > currentMaxPage) revert Cassette_ExceedsMaxPage();

        _sendBatch(
            FUNCTION_TYPE_BURN,
            _from,
            _dstChainId,
            _toAddress,
            _toSingletonArray(_tokenId),
            _toSingletonArray(_amount),
            _refundAddress,
            _zroPaymentAddress,
            _adapterParams
        );
    }

    /**
     * @notice Burn a batch of tokens on the current chain to receive the next pages in the series on a destination chain
     * @dev For more details see https://layerzero.gitbook.io/docs/evm-guides/master
     * @param _from Address to burn tokens from
     * @param _dstChainId Destination chain's LayerZero ID
     * @param _toAddress Address to receive the next pages in the series
     * @param _tokenIds Tokens to burn
     * @param _amounts Amounts of tokens to burn
     * @param _refundAddress Address to send refund to if transaction is cheaper than expected
     * @param _zroPaymentAddress Address of $ZRO token holder that will pay for the transaction
     * @param _adapterParams Parameters for custom functionality
     */
    function burnBatchFrom(
        address _from,
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    )
        public
        payable
    {
        for (uint256 i; i < _tokenIds.length;) {
            if (page(_tokenIds[i]) + 1 > currentMaxPage) revert Cassette_ExceedsMaxPage();
            unchecked { ++i; }
        }

        _sendBatch(
            FUNCTION_TYPE_BURN,
            _from,
            _dstChainId,
            _toAddress,
            _tokenIds,
            _amounts,
            _refundAddress,
            _zroPaymentAddress,
            _adapterParams
        );
    }

    /**
     * @notice Estimate the cost of sending a token to a destination chain
     * @param _dstChainId Destination chain's LayerZero ID
     * @param _toAddress Address to receive the token
     * @param _tokenId Token to send
     * @param _amount Amount of tokens to send
     * @param _useZro Flag indicating whether to use $ZRO for payment
     * @param _adapterParams Parameters for custom functionality
     */
    function estimateSendFee(
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint256 _tokenId,
        uint256 _amount,
        bool _useZro,
        bytes memory _adapterParams
    )
        public
        view
        override(ONFT1155Core, IONFT1155Core)
        returns (uint256 nativeFee, uint256 zroFee)
    {
        return estimateBatchFee(
            FUNCTION_TYPE_SEND,
            _dstChainId,
            _toAddress,
            _toSingletonArray(_tokenId),
            _toSingletonArray(_amount),
            _useZro,
            _adapterParams
        );
    }

    /*
     * @notice Estimate the cost of sending a batch of tokens to a destination chain
     * @param _dstChainId Destination chain's LayerZero ID
     * @param _toAddress Address to receive the tokens
     * @param _tokenId Tokens to send
     * @param _amount Amounts of tokens to send
     * @param _useZro Flag indicating whether to use $ZRO for payment
     * @param _adapterParams Parameters for custom functionality
     */
    function estimateSendBatchFee(
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts,
        bool _useZro,
        bytes memory _adapterParams
    )
        public
        view
        override(ONFT1155Core, IONFT1155Core)
        returns (uint256 nativeFee, uint256 zroFee)
    {
        return estimateBatchFee(
            FUNCTION_TYPE_SEND_BATCH,
            _dstChainId,
            _toAddress,
            _tokenIds,
            _amounts,
            _useZro,
            _adapterParams
        );
    }

    /*
     * @notice Estimate the cost of performing a specified cross-chain function on a token
     * @param _functionType Cross-chain function to perform
     * @param _dstChainId Destination chain's LayerZero ID
     * @param _toAddress Address to receive the tokens
     * @param _tokenId Tokens to send
     * @param _amount Amounts of tokens to send
     * @param _useZro Flag indicating whether to use $ZRO for payment
     * @param _adapterParams Parameters for custom functionality
     */
    function estimateFee(
        uint16 _functionType,
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint256 _tokenId,
        uint256 _amount,
        bool _useZro,
        bytes memory _adapterParams
    ) public view returns (uint256 nativeFee, uint256 zroFee) {
        return estimateBatchFee(
            _functionType,
            _dstChainId,
            _toAddress,
            _toSingletonArray(_tokenId),
            _toSingletonArray(_amount),
            _useZro,
            _adapterParams
        );
    }

    /*
     * @notice Estimate the cost of performing a specified cross-chain function on a batch of tokens
     * @param _functionType Cross-chain function to perform
     * @param _dstChainId Destination chain's LayerZero ID
     * @param _toAddress Address to receive the tokens
     * @param _tokenIds Tokens to burn
     * @param _amounts Amounts of tokens to burn
     * @param _useZro Flag indicating whether to use $ZRO for payment
     * @param _adapterParams Parameters for custom functionality
     */
    function estimateBatchFee(
        uint16 _functionType,
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts,
        bool _useZro,
        bytes memory _adapterParams
    ) public view returns (uint256 nativeFee, uint256 zroFee) {
        bytes memory payload = abi.encode(_functionType, _toAddress, _tokenIds, _amounts);
        return lzEndpoint.estimateFees(_dstChainId, address(this), payload, _useZro, _adapterParams);
    }

    /**
     * @notice Override `ONFT1155Core` function to debit a batch of tokens from the current chain
     * @dev For more details see https://layerzero.gitbook.io/docs/evm-guides/master
     * @param _from Address to debit tokens from
     * @param _tokenIds Tokens to debit
     * @param _amounts Amounts of tokens to debit
     */
    function _debitFrom(
        address _from,
        uint16, // _dstChainId
        bytes memory, // _toAddress
        uint256[] memory _tokenIds,
        uint256[] memory _amounts
    )
        internal
        override
    {
        if (msg.sender != _from && !isApprovedForAll(_from, msg.sender)) revert Cassette_NotAllowed();

        _burnBatch(_from, _tokenIds, _amounts);
    }

    /**
     * @notice Override `ONFT1155Core` function to credit a batch of tokens on the current chain
     * @dev For more details see https://layerzero.gitbook.io/docs/evm-guides/master
     * @param _toAddress Address to credit tokens to
     * @param _tokenIds Tokens to credit
     * @param _amounts Amounts of tokens to credit
     */
    function _creditTo(
        uint16, // _srcChainId
        address _toAddress,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts
    )
        internal
        override
    {
        _mintBatch(_toAddress, _tokenIds, _amounts, "");
    }

    /**
     * @notice Override `ONFT1155Core` function to send a batch of tokens from the current chain to a destination chain
     * @dev For more details see https://layerzero.gitbook.io/docs/evm-guides/master
     * @param _from Address to send tokens from
     * @param _dstChainId Destination chain's LayerZero ID
     * @param _toAddress Address to receive the tokens
     * @param _tokenIds Tokens to send
     * @param _amounts Amounts of tokens to send
     * @param _refundAddress Address to send refund to if transaction is cheaper than expected
     * @param _zroPaymentAddress Address of $ZRO token holder that will pay for the transaction
     * @param _adapterParams Parameters for custom functionality
     */
    function _sendBatch(
        address _from,
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    )
        internal
        override
    {
        _sendBatch(
            _tokenIds.length == 1 ? FUNCTION_TYPE_SEND : FUNCTION_TYPE_SEND_BATCH,
            _from,
            _dstChainId,
            _toAddress,
            _tokenIds,
            _amounts,
            _refundAddress,
            _zroPaymentAddress,
            _adapterParams
        );
    }

    /**
     * @notice Send a batch of tokens from the current chain to a destination chain with a specified operation
     * @dev For more details see https://layerzero.gitbook.io/docs/evm-guides/master
     * @param _functionType Function to perform on the destination chain
     * @param _from Address to send tokens from
     * @param _dstChainId Destination chain's LayerZero ID
     * @param _toAddress Address to receive the tokens
     * @param _tokenIds Tokens to send
     * @param _amounts Amounts of tokens to send
     * @param _refundAddress Address to send refund to if transaction is cheaper than expected
     * @param _zroPaymentAddress Address of $ZRO token holder that will pay for the transaction
     * @param _adapterParams Parameters for custom functionality
     */
    function _sendBatch(
        uint16 _functionType,
        address _from,
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    )
        internal
    {
        if (_tokenIds.length == 0 || _tokenIds.length != _amounts.length)
            revert Cassette_InvalidSendData();

        if (_functionType == FUNCTION_TYPE_SEND || _functionType == FUNCTION_TYPE_SEND_BATCH) {
            for (uint256 i; i < _tokenIds.length;) {
                if (_tokenIds[i] != 0) revert Cassette_InvalidSendData();
                unchecked { ++i; }
            }
        }

        _debitFrom(_from, _dstChainId, _toAddress, _tokenIds, _amounts);

        bytes memory payload = abi.encode(_functionType, _toAddress, _tokenIds, _amounts);

        _checkGasLimit(_dstChainId, _functionType, _adapterParams, NO_EXTRA_GAS);
        _lzSend(_dstChainId, payload, _refundAddress, _zroPaymentAddress, _adapterParams, msg.value);

        if (_tokenIds.length == 1) {
            emit SendToChain(_dstChainId, _from, _toAddress, _tokenIds[0], _amounts[0]);
        } else if (_tokenIds.length > 1) {
            emit SendBatchToChain(_dstChainId, _from, _toAddress, _tokenIds, _amounts);
        }
    }

    /**
     * @notice Override `ONFT1155Core` function that processes a payload from a source chain
     * @dev For more details see https://layerzero.gitbook.io/docs/evm-guides/master
     * @param _srcChainId Source chain's LayerZero ID
     * @param _srcAddress Address that sent the payload from the source chain
     * @param _payload Payload to process
     */
    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64, // _nonce
        bytes memory _payload
    )
        internal
        override
    {
        (
            uint16 functionType,
            bytes memory toAddressBytes,
            uint256[] memory tokenIds,
            uint256[] memory amounts
        ) = abi.decode(_payload, (uint16, bytes, uint256[], uint256[]));
        address toAddress;
        assembly {
            toAddress := mload(add(toAddressBytes, 20))
        }

        uint256[] memory _tokenIds = functionType == FUNCTION_TYPE_BURN
            ? _bumpTokenIds(tokenIds)
            : tokenIds;

        _creditTo(_srcChainId, toAddress, _tokenIds, amounts);

        if (tokenIds.length == 1) {
            emit ReceiveFromChain(_srcChainId, _srcAddress, toAddress, _tokenIds[0], amounts[0]);
        } else if (tokenIds.length > 1) {
            emit ReceiveBatchFromChain(_srcChainId, _srcAddress, toAddress, _tokenIds, amounts);
        }
    }

    /**
     * @notice Bump token IDs to those corresponding to the next page in the series
     * @param _tokenIds Tokens to bump to the next page
     * @return uint256[] Tokens corresponding to the next page in the series
     */
    function _bumpTokenIds(uint256[] memory _tokenIds) internal view returns (uint256[] memory) {
        for (uint256 i; i < _tokenIds.length;) {
            unchecked {
                _tokenIds[i] = tokenId(page(_tokenIds[i]) + 1);
                ++i;
            }
        }

        return _tokenIds;
    }
}