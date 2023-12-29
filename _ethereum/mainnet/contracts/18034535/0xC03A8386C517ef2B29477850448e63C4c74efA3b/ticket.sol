// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC1155.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

interface SoulBoundTokenInterface {
    
    function ownerTickets(
        address account, 
        bytes32[] memory proof, 
        uint256 amount, 
        uint8 level
        ) external returns (uint256);
    
}

contract TicketToken is ERC1155, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    SoulBoundTokenInterface _sbt;

    string public constant name = "Ticket Token";
    string public constant symbol = "TKT";

    uint256 public totalSupply;
    uint256 public _currentRound;
    mapping (uint256 => string) public _tokenURIs;
    mapping (bytes32 => bool) public _claimed;
    bytes32 public _refundWhitelist;

    address public _admin;

    event NewRoundIssued(uint256 round);
    event RefundWhitelistUpdated(bytes32 merkle_root);
    event RefundClaimed(address claimer, uint256 amount);

    constructor() ERC1155("some//uri//tbc") {}

    modifier onlyAdmin() {
        require(msg.sender == _admin || msg.sender == owner(), "Only Admin");
        _;
    }

    // MARK: - Only Owner
    function setAdmin(address admin) external onlyOwner {
        _admin = admin;
    }

    function setTokenUri(string memory uri) external onlyOwner {
        _setURI(uri);
    }

    function setSoulBoundToken(address sbt) external onlyOwner {
        _sbt = SoulBoundTokenInterface(sbt);
    }

    // MARK: - Only Admin
    function issueNewRound() external onlyAdmin {
        _currentRound++;
        emit NewRoundIssued(_currentRound);
    }

    function updateRefundWhitelist(bytes32 merkle_root) external onlyAdmin {
        _refundWhitelist = merkle_root;
        emit RefundWhitelistUpdated(merkle_root);
    }

    // MARK: - Public 
    function claimTicket(
        bytes32[] memory proof, 
        uint256 amount, 
        uint8 level
    ) external nonReentrant {
        // check if the tickets for that account is already claimed
        bytes32 key = getKeyForId(msg.sender);
        require(!_isClaimed(key), "This ticket has already been claimed.");

        uint256 toClaim = _sbt.ownerTickets(msg.sender, proof, amount, level);

        // check if to address is owner of some souls with ticket rights from extrnal soulbound contract
        require(toClaim > 0, "The address has no tickets to claim.");

        _setClaimed(key);
        // transfer the ticket from this contract to the msg.sender
        _mint(msg.sender, 0, toClaim, "");

        totalSupply += toClaim;
    }

    // MARK: - Public 
    function claimTicketAndRefund(
        bytes32[] memory proof, 
        uint256 amount, 
        uint8 level,
        bytes32[] memory refundProof, 
        uint256 refundAmount 
    ) external nonReentrant {
        // check if the tickets for that account is already claimed
        bytes32 key = getKeyForId(msg.sender);
        require(!_isClaimed(key), "This ticket has already been claimed.");

        uint256 toClaim = _sbt.ownerTickets(msg.sender, proof, amount, level);

        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(msg.sender, refundAmount))));
        uint256 val = MerkleProof.verify(refundProof, _refundWhitelist, leaf) ? refundAmount : 0;
        toClaim += val;

        // check if to address is owner of some souls with ticket rights from extrnal soulbound contract
        require(toClaim > 0, "The address has no tickets to claim.");

        _setClaimed(key);
        // transfer the ticket from this contract to the msg.sender
        _mint(msg.sender, 0, toClaim, "");

        totalSupply += toClaim;

        emit RefundClaimed(msg.sender, val);
    }

    function burn(uint256 tokenId) external {
        require(balanceOf(msg.sender, 0) > 0, "No tickets owned to burn");
        _burn(msg.sender, tokenId, 1);
        totalSupply -= 1;
    }

    // MARK: - "Resettable" Mapping
    function getKeyForId(address user) internal view returns(bytes32) {
        return keccak256(abi.encodePacked(_currentRound, user));
    }

    function _isClaimed(bytes32 key) internal view returns(bool) {
        return _claimed[key];
    }

    function _setClaimed(bytes32 key) internal {
        _claimed[key] = true;
    }
}