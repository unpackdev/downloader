// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.12;

import "./IERC721.sol";

import "./Controllable.sol";
import "./MetroVaultStorageStructs.sol";
import "./IMetroVaultStorage.sol";
import "./IMetroNFTLookup.sol";

contract MetroVaultStorage is Controllable, IMetroVaultStorage {

    address public nftLookupAddress;
    
    mapping(uint256 => Stake) vault;
    mapping(address => Account) accounts;

    event BlockStaked(address indexed owner, uint256 indexed tokenId, uint256 timestamp, uint16 indexed cityId, uint40 extra);
    event BlockUnstaked(address indexed owner, uint256 indexed tokenId, uint256 timestamp, uint16 indexed cityId, uint40 extra);
    event BlockTransfer(address indexed owner, uint256 indexed tokenId,  address indexed to);

    constructor(address _nftLookupAddress) {
      nftLookupAddress = _nftLookupAddress;
    }

    function setNFTLookup(address _nftLookupAddress) external onlyOwner {
        nftLookupAddress = _nftLookupAddress;
    }

    function getNFTContractAddress(uint256 tokenId) public view returns (address) {
        return IMetroNFTLookup(nftLookupAddress).getNFTContractAddress(tokenId);
    }

    function balanceOf(address owner) public view returns (uint256){
      return accounts[owner].balance;
    }

    function ownerOf(uint256 tokenId) public view returns (address){
      address owner = vault[tokenId].owner;
      require(owner != address(0x0), 'Token not in vault');
      return owner;
    }

    function getAccount(address owner) external view returns (Account memory) {
        return accounts[owner];
    }

    function getStake(uint256 tokenId) external view returns (Stake memory) {
        return vault[tokenId];
    }

    function stakeBlocks(address owner, uint256[] calldata tokenIds, uint16 cityId, uint40 extra) external onlyController {
        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            Stake storage s = vault[tokenId];
            require(s.owner == address(0), "Token is already staked");

            IERC721 nft = IERC721(getNFTContractAddress(tokenId));
            nft.transferFrom(owner, address(this), tokenId);

            s.owner = owner;
            s.timestamp = uint40(block.timestamp);
            s.cityId = cityId;
            s.extra = extra;

            emit BlockStaked(owner, tokenId, uint40(block.timestamp), cityId, extra);
        }

        accounts[owner].balance += uint24(tokenIds.length);
    }

    function stakeBlocks(
      address owner,
      uint256[] calldata tokenIds,
      uint16[] calldata cityIds,
      uint40[] calldata extras,
      uint40[] calldata timestamps
    ) external onlyController {

        require(tokenIds.length == cityIds.length && tokenIds.length == extras.length && tokenIds.length == timestamps.length);

        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            Stake storage s = vault[tokenId];
            require(s.owner == address(0), "Token is already staked");

            IERC721 nft = IERC721(getNFTContractAddress(tokenId));
            nft.transferFrom(owner, address(this), tokenId);

            s.owner = owner;
            s.timestamp = timestamps[i];
            s.cityId = cityIds[i];
            s.extra = extras[i];

            emit BlockStaked(owner, tokenId, timestamps[i], cityIds[i], extras[i]);
        }

        accounts[owner].balance += uint24(tokenIds.length);
    }

    function stakeFromMint(address owner, uint256[] calldata tokenIds, uint16 cityId, uint40 extra) public onlyController {
        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            Stake storage s = vault[tokenId];
            s.owner = owner;
            s.timestamp = uint40(block.timestamp);
            s.cityId = cityId;
            s.extra = extra;

            emit BlockStaked(owner, tokenId, block.timestamp, cityId, extra);
        }

        accounts[owner].balance += uint24(tokenIds.length);
    }

    function stakeFromMint(address owner, uint256[] calldata tokenIds, uint16 cityId, uint32 extra) external onlyController {
        stakeFromMint(owner, tokenIds, cityId, uint40(extra));
    }

    function unstakeBlocks(address owner, uint256[] calldata tokenIds) external onlyController {
      _unstakeBlocks(owner, owner, tokenIds);
    }

    function unstakeBlocksTo(address owner, address to, uint256[] calldata tokenIds) external onlyController {
      _unstakeBlocks(owner, to, tokenIds);
    }

    function _unstakeBlocks(address owner, address to, uint256[] calldata tokenIds) private {
        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];      
            Stake memory staked = vault[tokenId];
            require(owner == staked.owner, "Not an owner");

            delete vault[tokenId];
            IERC721 nft = IERC721(getNFTContractAddress(tokenId));
            nft.transferFrom(address(this), to, tokenId);
            emit BlockUnstaked(staked.owner, tokenId, block.timestamp, staked.cityId, staked.extra);
        }

        accounts[owner].balance -= uint24(tokenIds.length);
    }

    function setStake(uint256 tokenId, Stake calldata newStake) external onlyController {
        require(newStake.owner != address(0), "Owner cannot be nil");

        if (vault[tokenId].owner != newStake.owner) {
          accounts[vault[tokenId].owner].balance -= 1;
          accounts[newStake.owner].balance += 1;
          emit BlockTransfer(vault[tokenId].owner, tokenId, newStake.owner);
        }

        vault[tokenId] = newStake;
    }

    function setStakeTimestamp(uint256[] calldata tokenIds, uint40 timestamp) external onlyController {
        for (uint i = 0; i < tokenIds.length; i++) {
          uint256 tokenId = tokenIds[i];
          Stake storage staked = vault[tokenId];
          staked.timestamp = timestamp;
        }
    }

    function setStakeCity(uint256[] calldata tokenIds, uint16 cityId, bool resetTimestamp) external onlyController {
        for (uint i = 0; i < tokenIds.length; i++) {
          uint256 tokenId = tokenIds[i];
          Stake storage staked = vault[tokenId];
          staked.cityId = cityId;
          if (resetTimestamp) {
            staked.timestamp = uint40(block.timestamp);
          }
        }
    }

    function setStakeExtra(uint256[] calldata tokenIds, uint40 extra, bool resetTimestamp) external onlyController {
        for (uint i = 0; i < tokenIds.length; i++) {
          uint256 tokenId = tokenIds[i];
          Stake storage staked = vault[tokenId];
          staked.extra = extra;
          if (resetTimestamp) {
            staked.timestamp = uint40(block.timestamp);
          }
        }
    }

    function changeStakeOwner(uint256 tokenId, address newOwner, bool resetTimestamp) external onlyController {
        require(newOwner != address(0x0), "Owner cannot be nil");

        Stake storage s = vault[tokenId];

        require(s.owner != address(0x0), "No stake found");

        emit BlockTransfer(s.owner, tokenId, newOwner);

        accounts[s.owner].balance -= 1;
        accounts[newOwner].balance += 1;

        s.owner = newOwner;

        if (resetTimestamp) {
          s.timestamp = uint40(block.timestamp);
        }
    }

    function setStakeOwner(uint256[] calldata tokenIds, address newOwner, bool resetTimestamp) external onlyController {
        require(newOwner != address(0), "Owner cannot be nil");

        address[] memory owners = new address[](tokenIds.length);
        uint256[] memory amounts = new uint256[](tokenIds.length);

        for (uint i = 0; i < tokenIds.length; i++) {
          uint256 tokenId = tokenIds[i];
          Stake storage staked = vault[tokenId];

          for (uint256 j; j < owners.length; j++) {
            if (owners[j] == address(0x0)) {
              owners[j] = staked.owner; 
              amounts[j] = 1;
              break;
            } else if (owners[j] == staked.owner) {
              amounts[j] += 1;
              break;
            }
          }

          emit BlockTransfer(staked.owner, tokenId, newOwner);

          staked.owner = newOwner;
          if (resetTimestamp) {
            staked.timestamp = uint40(block.timestamp);
          }
        }

        for (uint256 j; j < owners.length; j++) {
          if (owners[j] != address(0x0)) {
            accounts[owners[j]].balance -= uint24(amounts[j]); 
          } else {
            break;
          }
        }

        accounts[newOwner].balance += uint24(tokenIds.length);
    }

    function setAccountExtra(address owner, uint232 extra) external onlyController {
        accounts[owner].extra = extra;
    }

    function setAccountsExtra(address[] calldata owners, uint232[] calldata extras) external onlyController {
        require(owners.length == extras.length, "Incorrect input");

        for (uint i; i < owners.length; i++) {
          address owner = owners[i];
          uint232 extra = extras[i];
          accounts[owner].extra = extra;
        }
    }

    function deleteStake(uint256[] calldata tokenIds) public onlyController {
        address[] memory owners = new address[](tokenIds.length);
        uint256[] memory amounts = new uint256[](tokenIds.length);

        for (uint i = 0; i < tokenIds.length; i++) {
          uint256 tokenId = tokenIds[i];

          Stake memory staked = vault[tokenId];
          delete vault[tokenId];

          for (uint256 j; j < owners.length; j++) {
            if (owners[j] == address(0x0)) {
              owners[j] = staked.owner; 
              amounts[j] = 1;
              break;
            } else if (owners[j] == staked.owner) {
              amounts[j] += 1;
              break;
            }
          }

        }

        for (uint256 j; j < owners.length; j++) {
          if (owners[j] != address(0x0)) {
            accounts[owners[j]].balance -= uint24(amounts[j]); 
          } else {
            break;
          }
        }

    }

    // should never be used inside of transaction because of gas fee
    function tokensOfOwner(address owner, uint256 start, uint256 stop) public view returns (uint256[] memory) {
        uint256 balance = accounts[owner].balance;
        if (balance == 0) {
            return new uint256[](0);
        }

        uint256 index = 0;
        uint256[] memory tmp = new uint256[](balance);

        for(uint tokenId = start; tokenId <= stop; tokenId++) {
            if (vault[tokenId].owner == owner) {
                    tmp[index] = tokenId;
                    index += 1;
                    if (index == balance) {
                        break;
                }
            }
        }

        uint256[] memory tokens = new uint256[](index);
        for(uint i = 0; i < index; i++) {
            tokens[i] = tmp[i];
        }

        return tokens;
    }
}
