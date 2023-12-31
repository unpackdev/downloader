//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./NFTEntry.sol";
import "./ERC2771ContextUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./OwnerOperator.sol";


contract LibesEntryV2 is ERC2771ContextUpgradeable, OwnerOperator{
    using Counters for Counters.Counter;
    using ECDSAUpgradeable for bytes32;

    event CreateTournament(uint256 tournamentId, string indexed name);
    event LibesEntry(uint256 entryId, uint256 tournamentId, address owner, uint256[] tokenId);
    event Cancel(uint256 entryId, uint256[] tokenId);
    event AdminCancel(uint256[] tokenId);
    event EndTournament(uint256 tournamentId);

    Counters.Counter private tournamentIdCounter;
    Counters.Counter private entryIdCounter;

    struct Tournament {
        uint256 tournamentId;
        string tournamentName;
        bool status;
    }
    struct Entry {
        uint256 _TournamentId;
        uint256[] tokenId;
        address owner;
    }
    struct Winner {
        address winnerAddress;
        uint256[] tokenId;
    }

    address payable public nftEntryAddress;

    mapping(uint256 => Tournament) public tournaments;
    mapping(uint256 => Entry[]) entryers;
    mapping(uint256 => Entry) entryer;
    mapping(uint256 => bool) History;
    mapping(address => mapping(uint256 => bool)) seenNonces;

    
    /**
     * @dev Initialize the contract with trusted forwarders and initial owner operators.
     * @param _nftAddress Address of nft entry.
     * @param _trustedForwarder List of trusted forwarder contract addresses for meta transactions.
     */

    function initialize(address payable _nftAddress, address[] memory _trustedForwarder) external initializer {
        // Inititalize the operator for contract
        OwnerOperator.initialize();
        // Inititalize the context for ERC2771 meta transactions
        __ERC2771Context_init(_trustedForwarder);
        // Set nft entry address
         nftEntryAddress = _nftAddress;
        
    }


    modifier verifySignature(
        uint256 nonce,
        uint256 tournamentId,
        bytes memory signature
    ) {
        // This recreates the message hash that was signed on the client.
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, nonce, tournamentId));
        bytes32 messageHash = hash.toEthSignedMessageHash();
        // Verify that the message's signer is the owner of the order
        require(messageHash.recover(signature) == owner(), 'INVALID SIGNATURE');
        require(!seenNonces[msg.sender][nonce], 'USED NONCE');
        seenNonces[msg.sender][nonce] = true;
        _;
    }

    /**
     * @dev The `setNFTEntryAddress` function is used to set the address of the nft by operator.
     * @param _nftEntryAddress Address of nft entry
     */
    function setNFTEntryAddress(address payable _nftEntryAddress) public operatorOrOwner {
        require(_nftEntryAddress != address(0), 'INVALID NFT ENTRY ADDRESS.');
        nftEntryAddress = _nftEntryAddress;
    }

    /**
     * The `createTournament` function is called by operator when creating a new tournament.
     * @param _tournamentName Name of the tournament
     */
    function createTournament(string memory _tournamentName) external operatorOrOwner returns (uint256 _tournamentId) {
        tournamentIdCounter.increment();
        _tournamentId = tournamentIdCounter.current();
        bool _status = false;
        Tournament memory tournament = Tournament(_tournamentId, _tournamentName, _status);
        tournaments[_tournamentId] = tournament;
        emit CreateTournament(_tournamentId, _tournamentName);
    }


    /**
     * @dev The libesEntry function is a function for user can be entry by nft entry
     * @param _tournamentId Id of the tournament.
     * @param _tokenId List token ID to entry.
     * @param _userAddress Address of user.
     */
    function libesEntry(
        uint256 _tournamentId,
        uint256[] memory _tokenId,
        address _userAddress
    ) external 
    returns (uint256 _entryId) {
        // Check if msg.sender is contract Trust Forward or not
        require(isTrustedForwarder(msg.sender) == true, "YOU ARE NOT THE ENTRYER");

        // Check if tournament is over or not
         require(tournaments[_tournamentId].status != true, 'THE TOURNAMENT IS OVER');
        for (uint256 i = 0; i < _tokenId.length; i++) {
            // Check if user is owner of nft or not
            require(
                IERC721A(nftEntryAddress).ownerOf(_tokenId[i]) == _userAddress,
                'YOU ARE NOT THE OWNER OF THE NFT'
            );

            // Check if nft is entryed or not
            require(History[_tokenId[i]] != true, 'THIS TOKEN HAS BEEN ENTRYED!');
        }

        // Lock nft when user entry
        NFTEntry(nftEntryAddress).lockToken(_tokenId);

        // Increase entry id
        entryIdCounter.increment();
        _entryId = entryIdCounter.current();

        // Add to list entry
        Entry memory entry = Entry(_tournamentId, _tokenId, _userAddress);
        entryers[_tournamentId].push(entry);
        entryer[_entryId] = entry;

        // Add nft to the history list so user don't use it to entry next time
        addHistory(_tokenId);

        emit LibesEntry(_entryId, _tournamentId, _userAddress, _tokenId);
    }


    function addHistory(uint256[] memory _tokenId) private {
        for (uint256 i = 0; i < _tokenId.length; i++) {
            History[_tokenId[i]] = true;
        }
    }

    function checkHistory(uint256 _tokenId) public view returns (bool) {
        return History[_tokenId];
    }

    /**
     * @dev The `cancel` function is called when the user wants to cancel the entry if tournament is not finished yet.
     * @param _entryId ID of the entry.
     * @param _listToken List of tokens that be entryed.
     * @param nonce Nonce of the user entry.
     * @param signature Signatur of the user entry
     */
    function cancel(
        uint256 _entryId,
        uint256[] memory _listToken,
        uint256 nonce,
        bytes memory signature
    ) external verifySignature(nonce, _entryId, signature) {
        // Check if msg.sender is entryer or not
        require(entryer[_entryId].owner == msg.sender, 'YOU ARE NOT THE ENTRYER');

        // Check if tournament is finished or not
        require(tournaments[entryer[_entryId]._TournamentId].status != true, 'THE TOURNAMENT IS FINISHED YET');

        // Unlock nft for user
        NFTEntry(nftEntryAddress).unlockToken(_listToken);
        // Delete nft from history entry
        for (uint256 i = 0; i < _listToken.length; i++) {
            History[_listToken[i]] = false;
        }

        emit Cancel(_entryId, _listToken);
    }

    function adminCancel(
        uint256[] memory _listToken
    ) external operatorOrOwner {

        // Unlock nft for user
        NFTEntry(nftEntryAddress).unlockToken(_listToken);
        // Delete nft from history entry
        for (uint256 i = 0; i < _listToken.length; i++) {
            History[_listToken[i]] = false;
        }

        emit AdminCancel(_listToken);
    }
    
    /**
     * @dev The `endTournament` function is called by operator when the tournament is ended.
     * @param _tournamentId ID of the tournament
     */
    function endTournament(uint256 _tournamentId) external operatorOrOwner {
        // Check if tournament is finished or not
        require(tournaments[_tournamentId].status != true, 'THE TOURNAMENT IS FINISHED YET');

        // Change status of the tournament
        tournaments[_tournamentId].status = true;

        // Unlock nft for users entryed the tournament
        for (uint256 i = 0; i < entryers[_tournamentId].length; i++) {
            NFTEntry(nftEntryAddress).unlockToken(entryers[_tournamentId][i].tokenId);
        }
        emit EndTournament(_tournamentId);
    }

}
