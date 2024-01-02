// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./DMXHero.sol";
import "./ERC721Upgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";

contract DMXHeroStaker is OwnableUpgradeable {
    using ECDSA for bytes32;
    //TODO: assure minting authority for potential future Minter contract
    
    mapping(uint32 => address) public stakedNfts; //nftId -> ownerAddress
    mapping(address => uint256) public unstaking_nonces;
    address public hero;
    event Stake(uint32 tokenId, address NftOwner);
    event Unstake(uint32 tokenId, address NftOwner);

    struct StakingData {
        uint32 nft_id;
        bool staked;
        address owner;
    }

    function isStaked(uint tokenId) public view returns(bool staked) {
        return stakedNfts[uint32(tokenId)] != address(0);
    }

    function initialize()  public initializer {
        __Ownable_init();
    }

    function setHero(address HeroContract) public onlyOwner {
        hero = HeroContract;
    }

    function getOwner()
    public pure returns (string memory owner) {
        return owner;
    }
  
    function _stake(uint32 nft_id)
    internal {
        // FIXME: Is it safe to use tx.origin here?
        // https://github.com/ethereum/solidity/issues/683
        DMXHero dmxHero = DMXHero(address(hero));
        require(dmxHero.ownerOf(nft_id) == tx.origin, "Caller must own the NFT.");
        require(stakedNfts[nft_id] == address(0), "Nft is already staked.");
        stakedNfts[nft_id] = tx.origin;
        emit Stake(nft_id, tx.origin);
    }

    function stakeNFT(uint32 nft_id)
    public {
        // FIXME: Is it safe to use tx.origin here?
        // https://github.com/ethereum/solidity/issues/683
       _stake(nft_id);
    }

    function bulkStakeNFT(uint32[] memory nft_ids)
    public {
        uint32 i = 0;
        while(i < nft_ids.length) {
            _stake(nft_ids[i]);
            i++;
        }
    }

    function _unstake(uint32 nft_id)
    internal {
        DMXHero dmxHero = DMXHero(address(hero));
        require(dmxHero.ownerOf(nft_id) == tx.origin, "Caller must own the NFT.");
        require(stakedNfts[nft_id] != address(0), "Nft is already unstaked.");
        address prevOwner = stakedNfts[nft_id];
        stakedNfts[nft_id] = address(0);
        emit Unstake(uint32(nft_id), prevOwner);
    }

    function emulateStake(uint32 nft_id)
    public
    onlyOwner {
        DMXHero dmxHero = DMXHero(address(hero));
        dmxHero.emitStaked(nft_id);
    }

    function emulateStakeBulk(uint32[] memory tokenIds)
    public onlyOwner {
        DMXHero dmxHero = DMXHero(address(hero));
        uint32 i = 0;
        while(i < tokenIds.length) {
            dmxHero.emitStaked(tokenIds[i]);
            i++;
        }
    }

    function emulateUnstake(uint32 nft_id)
    public
    onlyOwner {
        DMXHero dmxHero = DMXHero(address(hero));
        dmxHero.emitUnstaked(nft_id);
    }

    function emulateUnstakeBulk(uint32[] memory tokenIds)
    public onlyOwner {
        DMXHero dmxHero = DMXHero(address(hero));
        uint32 i = 0;
        while(i < tokenIds.length) {
            dmxHero.emitUnstaked(tokenIds[i]);
            i++;
        }
    }

    function unstakeNFT(bytes32 eth_hash, bytes memory signature, uint256 nft_id, uint256 nonce, address nft_owner)
    public {
        require((eth_hash.toEthSignedMessageHash().recover(signature) == owner()), "Message was not signed by contract owner");
        require(eth_hash == keccak256(abi.encodePacked(nft_id, nonce, nft_owner)), "Incorrect hash");
        require(unstaking_nonces[nft_owner] + 1 == nonce, "Incorrect nonce");
        _unstake(uint32(nft_id));
        unstaking_nonces[nft_owner]++;
    }

    function bulkUnstakeNFT(bytes32 eth_hash, bytes memory signature, uint256[] memory nft_ids, uint256 nonce, address nft_owner)
    public {
        require((eth_hash.toEthSignedMessageHash().recover(signature) == owner()), "Message was not signed by contract owner");
        require(eth_hash == keccak256(abi.encodePacked(abi.encodePacked(nft_ids), nonce, nft_owner)), "Incorrect hash");
        require(unstaking_nonces[nft_owner] + 1 == nonce, "Incorrect nonce");
        
        uint32 i = 0;
        while(i < nft_ids.length) {
            _unstake(uint32(nft_ids[i]));
            i++;
        }
        unstaking_nonces[nft_owner]++;
    }

    function getStakingData(uint32 nft_id)
    public view returns (StakingData memory data) {
        return StakingData(nft_id, (stakedNfts[nft_id] != address(0)), stakedNfts[nft_id]);
    }
}
