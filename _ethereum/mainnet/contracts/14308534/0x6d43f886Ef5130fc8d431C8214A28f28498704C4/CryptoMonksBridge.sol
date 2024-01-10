//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

interface IMigration  {
    function mintMachine(address _owner, uint256 _tokenId)  external returns (uint256);
    function exists(uint256 _tokenId) external view returns (bool);
}

import "./IERC1155.sol";
import "./ERC1155Holder.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";


/// @title Opensea Migration Bridge
/// @author hwonder | puzlworld
/// @notice Allows migration from opensea ERC-1155 shared contract to own ERC-1155 contract using ERC1155Holder because it does not inherit AccessControl
contract CryptoMonksBridge is ERC1155Holder, Ownable, ReentrancyGuard {
    /**
    * @dev Shared 1155 Contract
    **/
    address public Shared_Contract;

    /**
    * @dev Migration 721 Contract
    **/
    address public Migrate_Contract;

    /**
    * @dev Security to prevent resizing collection
    **/
    uint8 public lockedSeedEncodings = 0;
   
    /**
     * @dev total bridged NFTs
     */
    uint32 public totalMigrated;

    /**
     * @dev NFTs from opensea collection (unclaimed)
     */
    uint256[] public incoming;

    /**
     * @dev keeps all the ids that are sent, claimed and the owners of them
     */
    mapping(uint256 => address) public idsAndSenders;
    mapping(address => uint256[]) public sendersAndIds;
    mapping(uint256 => address) public migrated;

    /**
    * @dev Opensea Encoding Map manging converted OS hash to standard tokenId
      seed is used to catch errors in IDs and present in human readable format
      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000000FFFFFFFFFFF
        |------------- MAKER ADDRESS ----------|--- NFT ID --|-- AID --|
    **/
    mapping(uint256 => uint256) public encodedHashes;

        constructor() {}


    /**
    * @dev Seed (FROM Contract, TO contract), FROM Contract ID encodings, TO IDs. Allow this to be one time call for security purposes
    **/
    function seedEncodedHashes(address[] calldata _contracts, uint256[] calldata _encodings, uint256[] calldata _ids) external onlyOwner {
        require(_encodings.length == _ids.length, "encodings invalid");
        require(lockedSeedEncodings == 0, "Locked");
        for (uint256 i = 0; i < _encodings.length; i++) {
            encodedHashes[_encodings[i]] = _ids[i];
        }
        Migrate_Contract = _contracts[1];
        Shared_Contract = _contracts[0];
        lockedSeedEncodings = 1;
    }

    function getIdsTransfered(uint256 _ids) external view returns (uint256) {
        return incoming[_ids];
    }

    /**
     * @dev get the ids already transferred by a collector
     */
    function getTransferredByCollector(address _collector) external view returns (uint256[] memory) {
        require(_collector != address(0), "_collector is address 0");
        return sendersAndIds[_collector];
    }

    /**
     * @dev keep inventory of received 1155s and claims
     *  sender can not be address(0) and encoded tokenId needs to be allowed
     */
    function triggerReceived1155(address _sender, uint256 _tokenId) internal {
        require(_sender != address(0), "Update from address 0");
        incoming.push(_tokenId);
        idsAndSenders[_tokenId] = _sender;
        sendersAndIds[_sender].push(_tokenId);
    }

    event ReceivedFromOS(address indexed _sender, address indexed _receiver, uint256 indexed _tokenId, uint256 _amount);
    event Minted721(address indexed _sender, uint256 indexed _tokenId); 

    /**
     * @dev triggered when 1155 of opensea shared collection token is received 
     */
    function onERC1155Received(
        address _sender,
        address _receiver,
        uint256 _tokenId,
        uint256 _amount,
        bytes memory _data
    ) public override nonReentrant returns (bytes4) {
        require(msg.sender == address(Shared_Contract), "Forbidden");
        triggerReceived1155(_sender, _tokenId);
        emit ReceivedFromOS(_sender, _receiver, _tokenId, _amount);
        return super.onERC1155Received(_sender, _receiver, _tokenId, _amount, _data);
    }


    /***********External**************/
    /**
     * @dev address can claim a token if in seed encoding gas reduction on multiple claims enabled
     */
    function claim(
        uint256 _oldId
    ) external nonReentrant {
        require(msg.sender != address(0), "Can not claim to address 0");
        require(encodedHashes[_oldId] > 0, "invalid claim");
        require(idsAndSenders[_oldId] == msg.sender, "Not owner");
        totalMigrated++;
        migrated[_oldId] = msg.sender;
        mintClaim(msg.sender, encodedHashes[_oldId]);
    }

    function mintClaim(address _sender, uint256 _tokenId) internal returns (bool) {
        require(!IMigration(Migrate_Contract).exists(_tokenId), "already migrated");
        IMigration(Migrate_Contract).mintMachine(_sender, _tokenId);
        emit Minted721(_sender, _tokenId);
        return true;
    }


    /***********Emergency**************/
    /**
     * @dev transfer 1155 from bridge in case token gets stuck or someone is sending by mistake
     */
    function transfer1155(uint256 _tokenId, address _owner) external onlyOwner nonReentrant {
        require(_owner != address(0), "Can not send to address 0");
        require(!IMigration(Migrate_Contract).exists(_tokenId), "already migrated");
        IERC1155(Shared_Contract).safeTransferFrom(address(this), _owner, _tokenId, 1, "");
    }
    

}