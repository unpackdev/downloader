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

    constructor() {}


    /**
    * @dev Seed (FROM Contract, TO contract) Allow this to be one time call for security purposes
    **/
    function seed(address[] calldata _contracts) external onlyOwner {
        Migrate_Contract = _contracts[1];
        Shared_Contract = _contracts[0];
        lockedSeedEncodings = 1;
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
        require(msg.sender == address(Shared_Contract), "Forbidden T");
        triggerReceived1155(_sender, _tokenId);
        emit ReceivedFromOS(_sender, _receiver, _tokenId, _amount);
        return super.onERC1155Received(_sender, _receiver, _tokenId, _amount, _data);
    }

    /***********External**************/
    /**
     * @dev claim using hash if signed by owner
     */
    function claim(
        bytes32 _hashedMessage, uint8 _v, bytes32 _r, bytes32 _s,
        uint256 _oldId, uint256 hashmq
    ) external {
        require(idsAndSenders[hashmq] == msg.sender, "Not owner");
        require(migrated[_oldId] == address(0), "Migrated");
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _hashedMessage));
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        address admin = owner();
        require(signer == admin, "Invalid");
        totalMigrated++;
        migrated[_oldId] = msg.sender;
        mintClaim(msg.sender, _oldId);
    }

    function mintClaim(address _sender, uint256 _tokenId) internal returns (bool) {
        IMigration(Migrate_Contract).mintMachine(_sender, _tokenId);
        emit Minted721(_sender, _tokenId);
        return true;
    }


}