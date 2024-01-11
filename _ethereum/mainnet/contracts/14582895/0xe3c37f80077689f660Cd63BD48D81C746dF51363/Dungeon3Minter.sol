// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";

import "./Relic.sol";

interface LootOwner
{
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface GenesisLootOwner
{
    function ownerOf(uint256 tokenId) external view returns (address);
    function getLootTokenIds(uint256 tokenId) external view returns(uint256[8] memory);
    function getOrder(uint256 tokenId) external view returns (string memory);
}

interface IRiftData {
    function addXP(uint256 xp, uint256 bagId) external;
}

contract Dungeon3Minter is Ownable, IRelicMinter
{
    LootOwner internal _oloot;
    LootOwner internal _mloot;
    GenesisLootOwner internal _gloot;
    Relic internal _relic;
    string public _imageBaseURL;
    mapping(uint256 => bool) public _claims;
    mapping(address => bool) public _relayAddresses;
    address public _riftAddress;
    bool public _isXpRewardsEnabled;

    uint256[16] public _bestRaiderRelicNextIdsByRank = [
        252,
        840,
        924,
        2016,
        2100,
        2184,
        2268,
        4368,
        4452,
        4536,
        4620,
        4704,
        4788,
        4872,
        4956,
        37296
    ];

    uint256[16] public _bestRaiderLastIdsByRank = [
        335,
        923,
        1007,
        2099,
        2183,
        2267,
        2351,
        4451,
        4535,
        4619,
        4703,
        4787,
        4871,
        4955,
        5039,
        37379
    ];

    uint256[16] public _runnerUpRelicNextIdsByRank = [
        37380,
        37710,
        38040,
        38370,
        38700,
        39030,
        39360,
        39690,
        40020,
        40350,
        40680,
        41010,
        41340,
        41670,
        42000,
        42330
    ];

    uint256[16] public _runnerUpRelicLastIdsByRank = [
        37709,
        38039,
        38369,
        38699,
        39029,
        39359,
        39689,
        40019,
        40349,
        40679,
        41009,
        41339,
        41669,
        41999,
        42329,
        42659
    ];

    constructor(
        address olootAddress,
        address mlootAddress,
        address glootAddress,
        address relicAddress,
        address riftAddress,
        string memory imageBaseURL
    )
    {
        _oloot = LootOwner(olootAddress);
        _mloot = LootOwner(mlootAddress);
        _gloot = GenesisLootOwner(glootAddress);
        _relic = Relic(relicAddress);
        _riftAddress = riftAddress;
        _imageBaseURL = imageBaseURL;
    }

    function getRaidId(uint256 tokenId, uint8 raiderType)
        public pure returns (uint256)
    {
        return (raiderType) | (tokenId << 8);
    }

    function getRaidDungeonRequest(
        uint dungeonId,
        uint256 raidTokenId,
        uint256 raidTokenType,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view returns (
        bool isOwner,
        uint256[8] memory itemIds,
        string memory order,
        address signer
    ) {
        bytes32 requestHash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encode(
                "raidDungeon",
                dungeonId,
                raidTokenId,
                raidTokenType
            ))
        ));
        signer = ecrecover(requestHash, v, r, s);

        isOwner = isOwnerOf(raidTokenId, raidTokenType, signer);

        if (raidTokenType == 0) {
            itemIds = [ raidTokenId, raidTokenId, raidTokenId, raidTokenId, raidTokenId, raidTokenId, raidTokenId, raidTokenId ];
            order = "no order";
        } else if (raidTokenType == 1) {
            itemIds = [ raidTokenId, raidTokenId, raidTokenId, raidTokenId, raidTokenId, raidTokenId, raidTokenId, raidTokenId ];
            order = "no order";
        } else if (raidTokenType == 2) {
            itemIds = _gloot.getLootTokenIds(raidTokenId);
            order = _gloot.getOrder(raidTokenId);
        } else {
            require(false, "invalid raid token type");
        }

        return (isOwner, itemIds, order, signer);
    }

    function isOwnerOf(uint256 raidTokenId, uint raidTokenType, address addr) public view returns (bool)
    {
        if (raidTokenType == 0) {
            return addr == _oloot.ownerOf(raidTokenId);
        } else if (raidTokenType == 1) {
            return addr == _mloot.ownerOf(raidTokenId);
        } else if (raidTokenType == 2) {
            return addr == _gloot.ownerOf(raidTokenId);
        } else {
            return false;
        }
    }

    function isVerifiedClaimRequest(
        uint dungeonId,
        uint dungeonRank,
        uint256 raidTokenId,
        uint8 raidTokenType,
        uint8 raidRank,
        bytes memory claimCoupon
    ) public view returns (
        bool
    ) {
        // extract signature parts from coupon
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(claimCoupon);
        // extract signer from signature and request
        address signer = ecrecover(keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encode(
                dungeonId,
                dungeonRank,
                raidTokenId,
                raidTokenType,
                raidRank
            ))
        )), v, r, s);
        // never trust 0x0
        require(signer != address(0x0), "invalid signer");
        // return true if signed by the relay/oracle
        return _relayAddresses[signer];
    }

    function claimRewards(
        uint8[] calldata dungeonIds,
        uint8[] calldata dungeonRanks,
        uint64[] calldata raidTokenIds,
        uint8[] calldata raidTokenTypes,
        uint8[] calldata raidRanks,
        bytes[] calldata claimCoupons
    ) public {
        // claim each request
        for (uint256 i = 0; i < raidTokenIds.length; i++) {
            claimReward(
                dungeonIds[i],
                dungeonRanks[i],
                raidTokenIds[i],
                raidTokenTypes[i],
                raidRanks[i],
                claimCoupons[i]
            );
        }
    }

    function claimReward(
        uint8 dungeonId,
        uint8 dungeonRank,
        uint64 raidTokenId,
        uint8 raidTokenType,
        uint8 raidRank,
        bytes calldata claimCoupon
    ) public {

        // verify that the request is signed by the relay which is acting as an oracle for raids
        require(isVerifiedClaimRequest(
            dungeonId,
            dungeonRank,
            raidTokenId,
            raidTokenType,
            raidRank,
            claimCoupon
        ), "claim verification fail");

        // get unique raid id
        uint256 raidId = getRaidId(raidTokenId, raidTokenType);
        
        // check not already claimed
        require(!_claims[raidId], "already claimed");

        // verify that the sender is the owner of the given raidTokenId
        require(isOwnerOf(raidTokenId, raidTokenType, msg.sender), "raider does not own loot");

        // Rift XP: gLoot bag IDs must be offset by adding ‘9997460’ to their value
        uint256 lootIdOffset;
        if (raidTokenType == 2) {
            lootIdOffset = 9997460;
        }

        // find and consume the relicId for the raidRank
        uint256 relicId;
        if (raidRank == 0) {
            relicId = _bestRaiderRelicNextIdsByRank[dungeonRank];
            require(relicId <= _bestRaiderLastIdsByRank[dungeonRank], "no more relics available for rank");
            _bestRaiderRelicNextIdsByRank[dungeonRank]++;

            if (_isXpRewardsEnabled) {
                IRiftData(_riftAddress).addXP((uint256(16 - dungeonRank) * 20) + 200, uint256(raidTokenId) + lootIdOffset);
            }
        } else {
            relicId = _runnerUpRelicNextIdsByRank[dungeonRank];
            require(relicId <= _runnerUpRelicLastIdsByRank[dungeonRank], "no more relics available for rank");
            _runnerUpRelicNextIdsByRank[dungeonRank]++;
            
            if (_isXpRewardsEnabled) {
                IRiftData(_riftAddress).addXP((uint256(16 - dungeonRank) * 10) + 200, uint256(raidTokenId) + lootIdOffset);
            }
        }

        // mark this raidToken as claimed
        _claims[raidId] = true;

        // set relic data
        bytes12 data = bytes12(uint96(dungeonId & 0xffffffffffffffffffffffff));

        // mint it
        _relic.mint(msg.sender, relicId, data);
    }

    function isClaimed(
        uint8 raidTokenType,
        uint256 raidTokenId
    ) public view returns (
        bool
    ) {
        uint256 raidId = getRaidId(raidTokenId, raidTokenType);
        return _claims[raidId];
    }

    function splitSignature(bytes memory sig) public pure returns ( bytes32 r, bytes32 s, uint8 v)
    {
        require(sig.length == 65, "invalid signature length");
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }
        require(v == 27 || v == 28, "invalid signature version");
        // implicitly return (r, s, v)
    }

    function setRelayAddress(address relayAddress, bool active) external onlyOwner
    {
        _relayAddresses[relayAddress] = active;
    }

    //
    // *** IRelicMinter Interface ***
    //

    function setImageBaseURL(string memory newImageBaseURL) public onlyOwner
    {
        _imageBaseURL = newImageBaseURL;
    }

    function getTokenOrderIndex(uint256 /*tokenId*/, bytes12 data)
        external override pure returns(uint)
    {
        uint96 dungeonId = uint96(data);
        return dungeonId % 16;
    }

    function getTokenProvenance(uint256 /*tokenId*/, bytes12 /*data*/)
        external override pure returns(string memory)
    {
        return "The Crypt: Chapter Three";
    }

    function getAdditionalAttributes(uint256 /*tokenId*/, bytes12 /*data*/)
        external override pure returns(string memory)
    {
        return "";
    }

    function getImageBaseURL() external override view returns(string memory)
    {
        return _imageBaseURL;
    }

    function enableXpRewards(bool enabled) external onlyOwner
    {
        _isXpRewardsEnabled = enabled;
    }
}
