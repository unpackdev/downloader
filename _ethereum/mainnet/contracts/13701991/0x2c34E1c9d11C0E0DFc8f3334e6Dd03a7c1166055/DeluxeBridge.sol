//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./BearsDeluxeI.sol";
import "./IERC1155.sol";

import "./ReentrancyGuard.sol";
import "./Ownable.sol";

import "./ERC1155Holder.sol";
import "./MerkleProof.sol";

/**
 * @dev DeluxeBridge is bridging a 1155 BearsDeluxe into a 721
 */
contract DeluxeBridge is ERC1155Holder, Ownable, ReentrancyGuard {
    /**
     * @dev total bridged NFTs
     */
    uint32 public totalBridged;

    /**
     * received NFTs (not yet claimed and transformed into 721)
     */
    uint256[] public idsReceived;

    /**
     * @dev received and successfully claimed (this contains newly 721 ids)
     */
    uint16[] public idsBridged;

    /**
     * @dev in case something goes bad, to stop claiming
     */
    bool public bridgingEnabled;

    /**
     * @dev keeps all the ids that are sent and the owners of them
     */
    mapping(uint256 => address) public idsAndSenders;
    mapping(address => uint256[]) public sendersAndIds;

    /**
     * @dev olds OS ids bridged
     */
    mapping(address => uint256[]) public oldsIdsBridgedBySender;

    bytes32 private merkleRoot;

    /**
     * @dev OpenSea and BearsDeluxe contract
     */
    IERC1155 public osContract;
    BearsDeluxeI public bdContract;

    event ReceivedFromOS(address indexed _sender, address indexed _receiver, uint256 indexed _tokenId, uint256 _amount);

    event ReceivedFrom721(address indexed _sender, address indexed _receiver, uint256 indexed _tokenId);

    event Minted721(address indexed _sender, uint256 indexed _tokenId);

    event ToggleBridging(bool _enabled);

    event Transferred1155(address indexed _to, uint256 indexed _tokenId);

    constructor() {}

    /**
     * @dev triggered by 1155 transfer only from openSea
     */
    function onERC1155Received(
        address _sender,
        address _receiver,
        uint256 _tokenId,
        uint256 _amount,
        bytes memory _data
    ) public override nonReentrant returns (bytes4) {
        require(msg.sender == address(osContract), "Forbidden");
        require(!bridgingEnabled, "Bridging is stopped");

        triggerReceived1155(_sender, _tokenId);

        emit ReceivedFromOS(_sender, _receiver, _tokenId, _amount);
        return super.onERC1155Received(_sender, _receiver, _tokenId, _amount, _data);
    }

    /***********External**************/
    /**
     * @dev a user can claim a token based on a merkle proof that was precomputed and that is part of the
     * merkleRoot structure
     */
    function claim(
        uint256 _oldId,
        uint16 _newId,
        bytes32 _leaf,
        bytes32[] calldata _merkleProof
    ) external nonReentrant {
        require(!bridgingEnabled, "Bridging is stopped");

        //construct merkle node
        bytes32 node = keccak256(abi.encodePacked(_oldId, _newId));

        require(node == _leaf, "Leaf not matching the node");
        require(MerkleProof.verify(_merkleProof, merkleRoot, _leaf), "Invalid proof.");
        require(idsAndSenders[_oldId] == msg.sender, "Not owner of OS id");

        totalBridged++;
        idsBridged.push(_newId);
        oldsIdsBridgedBySender[msg.sender].push(_oldId);

        mintOnClaiming(msg.sender, _newId);
    }

    /**
     * @dev owner minting 721
     */

    function mint721(uint16 _tokenId, address _to) external onlyOwner {
        require(_to != address(0), "Mint to address 0");
        require(!bdContract.exists(_tokenId), "Token exists");

        if (bdContract.exists(_tokenId) && bdContract.ownerOf(_tokenId) == address(this)) {
            bdContract.safeTransferFrom(address(this), _to, _tokenId);
            return;
        }
        _mint721(_tokenId, _to);
    }

    /**
     * @dev transfer BD 721 from bridge in case token gets stuck or someone is sending by mistake
     */
    function transfer721(uint256 _tokenId, address _owner) external onlyOwner {
        require(_owner != address(0), "Can not send to address 0");
        bdContract.safeTransferFrom(address(this), _owner, _tokenId);
    }

    /***********Private**************/

    /**
     * @dev minting 721 to the owner
     */
    function _mint721(uint16 _tokenId, address _owner) private {
        bdContract.mint(_owner, uint16(_tokenId));
        emit Minted721(_owner, _tokenId);
    }

    /**
     * @dev update params once we receive a transfer from 1155
     * the sender can not be address(0) and tokenId needs to be allowed
     */
    function triggerReceived1155(address _sender, uint256 _tokenId) internal {
        require(_sender != address(0), "Update from address 0");

        idsReceived.push(_tokenId);
        idsAndSenders[_tokenId] = _sender;
        sendersAndIds[_sender].push(_tokenId);
    }

    /**
     * @dev when receive a deluxe from OS, it mints a 721
     */
    function mintOnClaiming(address _sender, uint16 _tokenId) internal returns (bool) {
        require(_sender != address(0), "Can not mint to address 0");
        require(_tokenId != 0, "New token id !exists");

        require(!bdContract.exists(_tokenId), "Token already minted");

        bdContract.mint(_sender, _tokenId);
        emit Minted721(_sender, _tokenId);
        return true;
    }

    /***********Setters**************/

    /**
     * @dev sets Bears Deluxe 721 token
     */
    function setBDContract(address _contract) external onlyOwner {
        require(_contract != address(0), "_contract !address 0");
        bdContract = BearsDeluxeI(_contract);
    }

    /**
     * @dev sets Bears Deluxe 721 token
     */
    function setOSContract(address _contract) external onlyOwner {
        require(_contract != address(0), "_contract !address 0");
        osContract = IERC1155(_contract);
    }

    /**
     * @dev sets  merkle root, should be called only once
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /***********Views**************/

    /**
     * @dev check a OS token balance
     */
    function checkBalance(address _collector, uint256 _tokenId) external view returns (uint256) {
        require(_collector != address(0), "_collector is address 0");
        return osContract.balanceOf(_collector, _tokenId);
    }

    /**
     * @dev get the ids already transferred by a collector
     */
    function getTransferredByCollector(address _collector) external view returns (uint256[] memory) {
        require(_collector != address(0), "_collector is address 0");
        return sendersAndIds[_collector];
    }

    /**
     * @dev get the ids that were bridged by collector
     */
    function getBridgedByCollector(address _collector) external view returns (uint256[] memory) {
        require(_collector != address(0), "_collector is address 0");
        return oldsIdsBridgedBySender[_collector];
    }

    /***********Getters**************/
    /**
     * @dev get merkle root just by the owner
     */
    function getMerkleRoot() external view onlyOwner returns (bytes32) {
        return merkleRoot;
    }

    /**
     * @dev get total transfer count
     */
    function getTokenBridgedCount() external view returns (uint128) {
        return totalBridged;
    }

    /**
     * @dev get bridged ids (claimed already), this will be the new 721 ids
     */
    function getBridgedTokens() external view returns (uint16[] memory) {
        return idsBridged;
    }

    /**
     * @dev get ids of tokens that were transfered to the bridge
     */
    function getIdsTransfered() external view returns (uint256[] memory) {
        return idsReceived;
    }

    /**
     * @dev get 721 contract address
     */
    function getBDContract() external view returns (address) {
        return address(bdContract);
    }

    /**
     * @dev get OpenSea contract address
     */
    function getOSContract() external view returns (address) {
        return address(osContract);
    }

    /***********Emergency**************/
    /**
     * @dev transfer BD 1155 from bridge in case token gets stuck or someone is sending by mistake
     */
    function transfer1155(uint256 _tokenId, address _owner) external onlyOwner nonReentrant {
        require(_owner != address(0), "Can not send to address 0");
        osContract.safeTransferFrom(address(this), _owner, _tokenId, 1, "");
        emit Transferred1155(_owner, _tokenId);
    }

    /**
     * @dev can enable/disable claiming and bridging
     */
    function toggleBridging(bool _enabled) external onlyOwner {
        bridgingEnabled = _enabled;
        emit ToggleBridging(_enabled);
    }
}
