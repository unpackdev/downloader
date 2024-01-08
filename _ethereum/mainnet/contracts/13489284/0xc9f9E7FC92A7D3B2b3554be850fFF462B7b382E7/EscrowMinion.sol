// Based on https://github.com/HausDAO/MinionSummoner/blob/main/MinionFactory.sol
import "./Address.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.5;

interface IERC721 {
    // brief interface for minion erc721 token txs
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface IERC1155 {
    // brief interface for minion erc1155 token txs
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

interface IERC721Receiver {
    // Safely receive ERC721 tokens
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC1155PartialReceiver {
    // Safely receive ERC1155 tokens
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    // ERC1155 batch receive not implemented in this escrow contract
}

interface IMOLOCH {
    // brief interface for moloch dao v2

    function depositToken() external view returns (address);

    function tokenWhitelist(address token) external view returns (bool);

    function getProposalFlags(uint256 proposalId)
        external
        view
        returns (bool[6] memory);

    function members(address user)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            bool,
            uint256,
            uint256
        );

    function userTokenBalances(address user, address token)
        external
        view
        returns (uint256);

    function cancelProposal(uint256 proposalId) external;

    function submitProposal(
        address applicant,
        uint256 sharesRequested,
        uint256 lootRequested,
        uint256 tributeOffered,
        address tributeToken,
        uint256 paymentRequested,
        address paymentToken,
        string calldata details
    ) external returns (uint256);

    function withdrawBalance(address token, uint256 amount) external;
}

/// @title EscrowMinion - Token escrow for ERC20, ERC721, ERC1155 tokens tied to Moloch DAO proposals
/// @dev Ties arbitrary token escrow to a Moloch DAO proposal
///  Can be used to tribute tokens in exchange for shares, loot, or DAO funds
///
///  Any number and combinations of tokens can be escrowed
///  If any tokens become untransferable, the rest of the tokens in escrow can be released individually
///
///  If proposal passes, tokens become withdrawable to destination - usually a Gnosis Safe or Minion
///  If proposal fails, or cancelled before sponsorship, token become withdrawable to applicant
///
///  If any tokens become untransferable, the rest of the tokens in escrow can be released individually
///
/// @author Isaac Patka, Dekan Brown
contract EscrowMinion is
    IERC721Receiver,
    ReentrancyGuard,
    IERC1155PartialReceiver
{
    using Address for address; /*Address library provides isContract function*/
    using SafeERC20 for IERC20; /*SafeERC20 automatically checks optional return*/

    // Track token tribute type to use so we know what transfer interface to use
    enum TributeType {
        ERC20,
        ERC721,
        ERC1155
    }

    // Track the balance and withdrawl state for each token
    struct EscrowBalance {
        uint256[3] typesTokenIdsAmounts; /*Tribute type | ID (for 721, 1155) | Amount (for 20, 1155)*/
        address tokenAddress; /* Address of tribute token */
        bool executed; /* Track if this specific token has been withdrawn*/
    }

    // Store destination vault and proposer for each proposal
    struct TributeEscrowAction {
        address vaultAddress; /*Destination for escrow tokens - must be token receiver*/
        address proposer; /*Applicant address*/
    }

    mapping(address => mapping(uint256 => TributeEscrowAction)) public actions; /*moloch => proposalId => Action*/
    mapping(address => mapping(uint256 => mapping(uint256 => EscrowBalance)))
        public escrowBalances; /* moloch => proposal => token index => balance */
        
    /* 
    * Moloch proposal ID
    * Applicant addr
    * Moloch addr
    * escrow token addr
    * escrow token types
    * escrow token IDs (721, 1155)
    * amounts (20, 1155)
    * destination for escrow
    */
    event ProposeAction(
        uint256 proposalId,
        address proposer,
        address moloch,
        address[] tokens,
        uint256[] types,
        uint256[] tokenIds,
        uint256[] amounts,
        address destinationVault
    ); 
    event ExecuteAction(uint256 proposalId, address executor, address moloch);
    event ActionCanceled(uint256 proposalId, address moloch);

    // internal tracking for destinations to ensure escrow can't get stuck
    // Track if already checked so we don't do it multiple times per proposal
    mapping(TributeType => uint256) internal destinationChecked_;
    uint256 internal constant NOTCHECKED_ = 1;
    uint256 internal constant CHECKED_ = 2;

    /// @dev Construtor sets the status of the destination checkers
    constructor() {
        // Follow a similar pattern to reentency guard from OZ
        destinationChecked_[TributeType.ERC721] = NOTCHECKED_;
        destinationChecked_[TributeType.ERC1155] = NOTCHECKED_;
    }

    // Reset the destination checkers for the next proposal
    modifier safeDestination() {
        _;
        destinationChecked_[TributeType.ERC721] = NOTCHECKED_;
        destinationChecked_[TributeType.ERC1155] = NOTCHECKED_;
    }

    // Safely receive ERC721s
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    // Safely receive ERC1155s
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    /**
     * @dev internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param _operator address representing the entity calling the function
     * @param _from address representing the previous owner of the given token ID
     * @param _to target address that will receive the tokens
     * @param _tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address _operator,
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) internal returns (bool) {
        if (!_to.isContract()) {
            return true;
        }
        bytes memory _returndata = _to.functionCall(
            abi.encodeWithSelector(
                IERC721Receiver(_to).onERC721Received.selector,
                _operator,
                _from,
                _tokenId,
                _data
            ),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
        bytes4 _retval = abi.decode(_returndata, (bytes4));
        return (_retval == IERC721Receiver(_to).onERC721Received.selector);
    }

    /**
     * @dev internal function to invoke {IERC1155-onERC1155Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param _operator address representing the entity calling the function
     * @param _from address representing the previous owner of the given token ID
     * @param _to target address that will receive the tokens
     * @param _id uint256 ID of the token to be transferred
     * @param _amount uint256 amount of token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC1155Received(
        address _operator,
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) internal returns (bool) {
        if (!_to.isContract()) {
            return true;
        }
        bytes memory _returndata = _to.functionCall(
            abi.encodeWithSelector(
                IERC1155PartialReceiver(_to).onERC1155Received.selector,
                _operator,
                _from,
                _id,
                _amount,
                _data
            ),
            "ERC1155: transfer to non ERC1155Receiver implementer"
        );
        bytes4 _retval = abi.decode(_returndata, (bytes4));
        return (_retval ==
            IERC1155PartialReceiver(_to).onERC1155Received.selector);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on both vault & applicant
     * Ensures tokens cannot get stuck here due to interface issue
     *
     * @param _vaultAddress Destination for tokens on successful proposal
     * @param _applicantAddress Destination for tokens on failed proposal
     */
    function checkERC721Recipients(address _vaultAddress, address _applicantAddress) internal {
        require(
            _checkOnERC721Received(
                address(this),
                address(this),
                _vaultAddress,
                0,
                ""
            ),
            "!ERC721"
        );
        require(
            _checkOnERC721Received(
                address(this),
                address(this),
                _applicantAddress,
                0,
                ""
            ),
            "!ERC721"
        );
        // Mark 721 as checked so we don't check again during this tx
        destinationChecked_[TributeType.ERC721] = CHECKED_;
    }

    /**
     * @dev Internal function to invoke {IERC1155Receiver-onERC1155Received} on both vault & applicant
     * Ensures tokens cannot get stuck here due to interface issue
     *
     * @param _vaultAddress Destination for tokens on successful proposal
     * @param _applicantAddress Destination for tokens on failed proposal
     */
    function checkERC1155Recipients(address _vaultAddress, address _applicantAddress) internal {
        require(
            _checkOnERC1155Received(
                address(this),
                address(this),
                _vaultAddress,
                0,
                0,
                ""
            ),
            "!ERC1155"
        );
        require(
            _checkOnERC1155Received(
                address(this),
                address(this),
                _applicantAddress,
                0,
                0,
                ""
            ),
            "!ERC1155"
        );
        // Mark 1155 as checked so we don't check again during this tx
        destinationChecked_[TributeType.ERC1155] = CHECKED_;
    }

    /**
     * @dev Internal function to move token into or out of escrow depending on type
     * Only valid for 721, 1155, 20
     *
     * @param _tokenAddress Token to escrow
     * @param _typesTokenIdsAmounts Type: 0-20, 1-721, 2-1155 TokenIds: for 721, 1155 Amounts: for 20, 1155
     * @param _from Sender (applicant or this)
     * @param _to Recipient (this or applicant or destination)
     */
    function doTransfer(
        address _tokenAddress,
        uint256[3] memory _typesTokenIdsAmounts,
        address _from,
        address _to
    ) internal {
        // Use 721 interface for 721
        if (_typesTokenIdsAmounts[0] == uint256(TributeType.ERC721)) {
            IERC721 _erc721 = IERC721(_tokenAddress);
            _erc721.safeTransferFrom(_from, _to, _typesTokenIdsAmounts[1]);
        // Use 20 interface for 20
        } else if (_typesTokenIdsAmounts[0] == uint256(TributeType.ERC20)) {
            // Fail if attempt to send 0 tokens
            require(_typesTokenIdsAmounts[2] != 0, "!amount");
            IERC20 _erc20 = IERC20(_tokenAddress);
            if (_from == address(this)) {
                _erc20.safeTransfer(_to, _typesTokenIdsAmounts[2]);
            } else {
                _erc20.safeTransferFrom(_from, _to, _typesTokenIdsAmounts[2]);
            }
            // use 1155 interface for 1155
        } else if (_typesTokenIdsAmounts[0] == uint256(TributeType.ERC1155)) {
            // Fail if attempt to send 0 tokens
            require(_typesTokenIdsAmounts[2] != 0, "!amount");
            IERC1155 _erc1155 = IERC1155(_tokenAddress);
            _erc1155.safeTransferFrom(
                _from,
                _to,
                _typesTokenIdsAmounts[1],
                _typesTokenIdsAmounts[2],
                ""
            );
        } else {
            revert("Invalid type");
        }
    }

    /**
     * @dev Internal function to move token into escrow on proposal
     *
     * @param _molochAddress Moloch to read proposal data from
     * @param _tokenAddresses Addresses of tokens to escrow
     * @param _typesTokenIdsAmounts ERC20, 721, or 1155 | id for 721, 1155 | amount for 20, 1155
     * @param _vaultAddress Addresses of destination of proposal successful
     * @param _proposalId ID of Moloch proposal for this escrow
     */
    function processTributeProposal(
        address _molochAddress,
        address[] memory _tokenAddresses,
        uint256[3][] memory _typesTokenIdsAmounts,
        address _vaultAddress,
        uint256 _proposalId
    ) internal {
        
        // Initiate arrays to flatten 2d array for event
        uint256[] memory _types = new uint256[](_tokenAddresses.length);
        uint256[] memory _tokenIds = new uint256[](_tokenAddresses.length);
        uint256[] memory _amounts = new uint256[](_tokenAddresses.length);

        // Store proposal metadata
        actions[_molochAddress][_proposalId] = TributeEscrowAction({
            vaultAddress: _vaultAddress,
            proposer: msg.sender
        });
        
        // Store escrow data, check destinations, and do transfers
        for (uint256 _index = 0; _index < _tokenAddresses.length; _index++) {
            // Store withdrawable balances
            escrowBalances[_molochAddress][_proposalId][_index] = EscrowBalance({
                typesTokenIdsAmounts: _typesTokenIdsAmounts[_index],
                tokenAddress: _tokenAddresses[_index],
                executed: false
            });

            if (destinationChecked_[TributeType.ERC721] == NOTCHECKED_)
                checkERC721Recipients(_vaultAddress, msg.sender);
            if (destinationChecked_[TributeType.ERC1155] == NOTCHECKED_)
                checkERC1155Recipients(_vaultAddress, msg.sender);

            // Move tokens into escrow
            doTransfer(
                _tokenAddresses[_index],
                _typesTokenIdsAmounts[_index],
                msg.sender,
                address(this)
            );

            // Store in memory so they can be emitted in an event
            _types[_index] = _typesTokenIdsAmounts[_index][0];
            _tokenIds[_index] = _typesTokenIdsAmounts[_index][1];
            _amounts[_index] = _typesTokenIdsAmounts[_index][2];
        }
        emit ProposeAction(
            _proposalId,
            msg.sender,
            _molochAddress,
            _tokenAddresses,
            _types,
            _tokenIds,
            _amounts,
            _vaultAddress
        );
    }

    //  -- Proposal Functions --
    /**
     * @notice Creates a proposal and moves NFT into escrow
     * @param _molochAddress Address of DAO
     * @param _tokenAddresses Token contract address
     * @param _typesTokenIdsAmounts Token id.
     * @param _vaultAddress Address of DAO's NFT vault
     * @param _requestSharesLootFunds Amount of shares requested
     // add funding request token
     * @param _details Info about proposal
     */
    function proposeTribute(
        address _molochAddress,
        address[] calldata _tokenAddresses,
        uint256[3][] calldata _typesTokenIdsAmounts,
        address _vaultAddress,
        uint256[3] calldata _requestSharesLootFunds, // also request loot or treasury funds
        string calldata _details
    ) external nonReentrant safeDestination returns (uint256) {
        IMOLOCH _thisMoloch = IMOLOCH(_molochAddress); /*Initiate interface to relevant moloch*/
        address _thisMolochDepositToken = _thisMoloch.depositToken(); /*Get deposit token for proposals*/

        require(_vaultAddress != address(0), "invalid vaultAddress"); /*Cannot set destination to 0*/

        require(
            _typesTokenIdsAmounts.length == _tokenAddresses.length,
            "!same-length"
        );

        // Submit proposal to moloch for loot, shares, or funds in the deposit token
        uint256 _proposalId = _thisMoloch.submitProposal(
            msg.sender,
            _requestSharesLootFunds[0],
            _requestSharesLootFunds[1],
            0, // No ERC20 tribute directly to Moloch
            _thisMolochDepositToken,
            _requestSharesLootFunds[2],
            _thisMolochDepositToken,
            _details
        );

        processTributeProposal(
            _molochAddress,
            _tokenAddresses,
            _typesTokenIdsAmounts,
            _vaultAddress,
            _proposalId
        );

        return _proposalId;
    }

    /**
     * @notice Internal function to move tokens to destination ones it can be processed or has been cancelled
     * @param _molochAddress Address of DAO
     * @param _tokenIndices Indices in proposed tokens array - have to specify this so frozen tokens cant make the whole payload stuck
     * @param _destination Address of DAO's NFT vault or Applicant if failed/ cancelled
     * @param _proposalId Moloch proposal ID
     */
    function processWithdrawls(
        address _molochAddress,
        uint256[] calldata _tokenIndices, // only withdraw indices in this list
        address _destination,
        uint256 _proposalId
    ) internal {
        for (uint256 _index = 0; _index < _tokenIndices.length; _index++) {
            // Retrieve withdrawable balances
            EscrowBalance storage _escrowBalance = escrowBalances[_molochAddress][
                _proposalId
            ][_tokenIndices[_index]];
            // Ensure this token has not been withdrawn
            require(!_escrowBalance.executed, "executed");
            require(_escrowBalance.tokenAddress != address(0), "!token");
            _escrowBalance.executed = true;

            // Move tokens to 
            doTransfer(
                _escrowBalance.tokenAddress,
                _escrowBalance.typesTokenIdsAmounts,
                address(this),
                _destination
            );
        }
    }

    /**
     * @notice External function to move tokens to destination ones it can be processed or has been cancelled
     * @param _proposalId Moloch proposal ID
     * @param _molochAddress Address of DAO
     * @param _tokenIndices Indices in proposed tokens array - have to specify this so frozen tokens cant make the whole payload stuck
     */
    function withdrawToDestination(
        uint256 _proposalId,
        address _molochAddress,
        uint256[] calldata _tokenIndices
    ) external nonReentrant {
        IMOLOCH _thisMoloch = IMOLOCH(_molochAddress);
        bool[6] memory _flags = _thisMoloch.getProposalFlags(_proposalId);

        require(
            _flags[1] || _flags[3],
            "proposal not processed and not cancelled"
        );

        TributeEscrowAction memory _action = actions[_molochAddress][_proposalId];
        address _destination;
        // if passed, send NFT to vault
        if (_flags[2]) {
            _destination = _action.vaultAddress;
            // if failed or cancelled, send back to proposer
        } else {
            _destination = _action.proposer;
        }

        processWithdrawls(_molochAddress, _tokenIndices, _destination, _proposalId);

        emit ExecuteAction(_proposalId, msg.sender, _molochAddress);
    }

    /**
     * @notice External function to cancel proposal by applicant if not sponsored 
     * @param _proposalId Moloch proposal ID
     * @param _molochAddress Address of DAO
     */
    function cancelAction(uint256 _proposalId, address _molochAddress)
        external
        nonReentrant
    {
        IMOLOCH _thisMoloch = IMOLOCH(_molochAddress);
        TributeEscrowAction memory _action = actions[_molochAddress][_proposalId];

        require(msg.sender == _action.proposer, "not proposer");
        _thisMoloch.cancelProposal(_proposalId); /*reverts if not cancelable*/

        emit ActionCanceled(_proposalId, _molochAddress);
    }
}
