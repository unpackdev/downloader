// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./EnumerableSet.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
import "./ICreatureRewards.sol";

contract LifeOfGameCreature is ERC721, Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Counters for Counters.Counter;
    using ECDSA for bytes32;
    using Strings for uint256;

    struct UserData {
        uint128 modifiedBlock;
        uint64 claimNonce;
        uint64 __reserved__data;
    }

    uint constant MAX_CREATURES = 10000;
    mapping (uint => bool) public unstaked;
    mapping (uint => uint) public darkEnergy;
    Counters.Counter public totalSupply;
    ICreatureRewards public creatureRewards;
    bool public claimActive = false;
    bool public allowStakedTransfer = false;
    string public tokenBaseURI;

    EnumerableSet.AddressSet private marketplaces;
    mapping (address => bool) private blacklisted;
    mapping (address => UserData) private userData;
    address private signer;

    event PaymentReceived(address indexed, uint);

    constructor(address _rewardContract) ERC721("LifeGameCreature", "LGC") {
        require(_rewardContract != address(0), "addr 0");
        creatureRewards = ICreatureRewards(_rewardContract);
        // check supportsInterface of rewards contract
        require(creatureRewards.supportsInterface(type(ICreatureRewards).interfaceId));
    }

    // ======== Admin functions ========

    function setTokenBaseURI(string calldata _baseURI) external onlyOwner {
        tokenBaseURI = _baseURI;
    }

    function setClaimActive(bool _active) external onlyOwner {
        claimActive = _active;
    }

    function setAllowStakedTransfer(bool _allow) external onlyOwner {
        allowStakedTransfer = _allow;
    }

    function setMarketplaces(address _market, bool _active) external onlyOwner {
        if (_active) {
            marketplaces.add(_market);
        }
        else {
            marketplaces.remove(_market);
        }
    }

    function setBlacklist(address _addr, bool _active) external onlyOwner {
        blacklisted[_addr] = _active;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function boostEnergies(uint[] calldata tokenIds, uint[] calldata energies) external onlyOwner {
        require(tokenIds.length == energies.length, "input length mismatch");
        for (uint i = 0; i < tokenIds.length; i++) {
            _boostEnergy(tokenIds[i], energies[i]);
        }
    }

    function slashEnergies(uint[] calldata tokenIds, uint[] calldata energies) external onlyOwner {
        require(tokenIds.length == energies.length, "input length mismatch");
        for (uint i = 0; i < tokenIds.length; i++) {
            _slashEnergy(tokenIds[i], energies[i]);
        }
    }
    
    function safeMint(uint _darkEnergy, address to) external onlyOwner nonReentrant {
        uint tokenId = totalSupply.current();
        require(tokenId < MAX_CREATURES);
        totalSupply.increment();
        darkEnergy[tokenId] = _darkEnergy;
        // userData[to].modifiedBlock = uint128(block.number);
        _safeMint(to, tokenId);
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // ======== View functions ========

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
	    if (unstaked[_tokenId]) {
            return string(abi.encodePacked(tokenBaseURI, "unstaked/", _tokenId.toString()));
        }
        else {
            return string(abi.encodePacked(tokenBaseURI, "staked/", _tokenId.toString()));
        }
    }

    function userCanMint(address user, uint _darkEnergy, uint _maxId, uint _maxTimestamp, bytes calldata _signature) external view returns(bool, string memory) {
        if(!claimActive) { return (false, "Claim is not active");}
        if(block.timestamp > _maxTimestamp) { return (false, "Signature expired");}
        if(totalSupply.current() >= _maxId) { return (false, "Category quota exceeded");}
        if(totalSupply.current() >= MAX_CREATURES) { return (false, "Supply cap exceeded");}
        if(!_verifySignerSignature(keccak256(abi.encode(_darkEnergy, _maxId, _maxTimestamp, user, userData[user].claimNonce, address(this))), _signature)) { return (false, "Invalid signature");}
        else { return (true, "");}
    }


    // ======== Public functions ========

    function claimCreature(uint _darkEnergy, uint _maxId, uint _maxTimestamp, bytes calldata _signature) external payable nonReentrant {
        // minimize on-chain data to save gas
        require(msg.sender == tx.origin, "Claim from wallet only");
        require(claimActive, "Claim is not active");
        require(block.timestamp <= _maxTimestamp, "Signature expired");
        uint tokenId = totalSupply.current();
        require(tokenId < _maxId, "Category quota exceeded");
        require(tokenId < MAX_CREATURES, "Supply cap exceeded");
        require(_verifySignerSignature(keccak256(abi.encode(_darkEnergy, _maxId, _maxTimestamp, msg.sender, userData[msg.sender].claimNonce, address(this))), _signature), "Invalid signature");

        totalSupply.increment();
        darkEnergy[tokenId] = _darkEnergy;
        // userData[msg.sender].modifiedBlock = uint128(block.number);
        userData[msg.sender].claimNonce++;
        _safeMint(msg.sender, tokenId);
        emit PaymentReceived(msg.sender, msg.value);
    }

    function stake(uint[] calldata tokenIds) external nonReentrant {
        for (uint i = 0; i < marketplaces.length(); i++) {
            require(!isApprovedForAll(msg.sender, marketplaces.at(i)), "Cannot stake when marketplace approved");
        }
        for (uint i; i < tokenIds.length; i++) {
            require(ownerOf(tokenIds[i]) == msg.sender, "Caller is not the owner");
            _stake(msg.sender, tokenIds[i]);
        }
    }

    function unstake(uint[] calldata tokenIds) external nonReentrant {
        for (uint i; i < tokenIds.length; i++) {
            require(ownerOf(tokenIds[i]) == msg.sender, "Caller is not the owner");
            _unstake(msg.sender, tokenIds[i]);
        }
    }
    
    receive() external payable {
        emit PaymentReceived(msg.sender, msg.value);
    }

    // ======== Internal functions ========

    function _verifySignerSignature(bytes32 hash, bytes calldata signature) internal view returns(bool) {
        return hash.toEthSignedMessageHash().recover(signature) == signer;
    }

    function _boostEnergy(uint tokenId, uint energy) internal {
        darkEnergy[tokenId] += energy;
        if (!unstaked[tokenId]) {
            creatureRewards.alertBoost(ownerOf(tokenId), tokenId, true, energy);
        }
    }

    function _slashEnergy(uint tokenId, uint energy) internal {
        darkEnergy[tokenId] -= energy;
        if (!unstaked[tokenId]) {
            creatureRewards.alertBoost(ownerOf(tokenId), tokenId, false, energy);
        }
    }

    function _stake(address user, uint id) internal {
        require(unstaked[id] == true, "Already staked");
        require(getApproved(id) == address(0), "Cannot stake when token approved");
        unstaked[id] = false;
        creatureRewards.alertStaked(user, id, true, darkEnergy[id]);
    }

    function _unstake(address user, uint id) internal {
        require(unstaked[id] == false, "Already unstaked");
        unstaked[id] = true;
        creatureRewards.alertStaked(user, id, false, darkEnergy[id]);
    }


    // ======== Function overrides ========

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721) {
        require(!blacklisted[from] && !blacklisted[to], "ERC721: go fuck yourself"); // scammers stay away!
        // non-blocking transfer for staked items to avoid stuck marketplace listings
        if (!unstaked[tokenId]) {
            if (from == address(0)) { // mint
                creatureRewards.alertStaked(to, tokenId, true, darkEnergy[tokenId]);
            }
            else if (to == address(0)) { // burn
                creatureRewards.alertStaked(from, tokenId, false, darkEnergy[tokenId]);
            }
            else { // staked transfer is slashable
                require(allowStakedTransfer, "ERC721: cannot transfer when staked");
                _unstake(from, tokenId);
                creatureRewards.alertStakedTransfer(from, to, tokenId, darkEnergy[tokenId]);
            }
        }
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal override(ERC721) {
        require(!blacklisted[owner] && !blacklisted[operator], "ERC721: blacklisted");
        // disable marketplace approvals when ANY NFT is staked
        // the workaround for approving without unstaking all is to approve a specific tokenId
        if (marketplaces.contains(operator) && approved) {
            require(creatureRewards.stakedEnergy(owner) == 0, "ERC721: cannot enable marketplace when staked");
        }
        super._setApprovalForAll(owner, operator, approved);
    }

    function _approve(address to, uint256 tokenId) internal override(ERC721) {
        require(!blacklisted[to], "ERC721: blacklisted");
        if (marketplaces.contains(to)) {
            require(unstaked[tokenId], "ERC721: cannot approve marketplace when staked");
        }
        super._approve(to,tokenId);
    }
}

