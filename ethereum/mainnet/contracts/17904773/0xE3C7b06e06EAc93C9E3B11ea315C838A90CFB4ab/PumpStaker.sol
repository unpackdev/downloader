// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Ownable.sol";

import "./ERC721A.sol";

import "./PumpNft.sol";

contract PumpStaker is Ownable, ERC721A__IERC721Receiver {
    struct Stake {
        uint24 tokenId;
        uint48 timestamp;
        address owner;
        uint96 period;
    }

    PumpNft public vaultToken;
    uint256 public periodUnit = 30 days;
    uint256 public totalStaked;
    mapping(uint24 => Stake) public vaults;

    event NFTStaked(address owner, uint256 tokenId, uint256 time, uint256 period);
    event NFTUnstaked(address owner, uint256 tokenId, uint256 time, uint256 period);

    error NotOwner();
    error NotVaultToken();
    error InvalidPeriod();
    error VaultStaked();
    error NotComplete();

    function setPeriodUnit(uint256 _periodUnit) external onlyOwner {
        periodUnit = _periodUnit;
    }

    function setVaultToken(address _vaultToken) external onlyOwner {
        vaultToken = PumpNft(_vaultToken);
    }

    function sendNft(uint256 id) external onlyOwner {
        vaultToken.safeTransferFrom(address(this), owner(), id);
    }

    function stake(uint256[] calldata tokenIds, uint256 period) external {
        if (period != 3 && period != 6 && period != 12) revert InvalidPeriod();

        totalStaked += tokenIds.length;

        for (uint i = 0; i < tokenIds.length; i++) {
            uint24 tokenId = uint24(tokenIds[i]);

            if (vaultToken.ownerOf(tokenId) != msg.sender) revert NotOwner();
            if (vaults[tokenId].tokenId != 0) revert VaultStaked();

            vaultToken.safeTransferFrom(msg.sender, address(this), tokenId);
            emit NFTStaked(msg.sender, tokenId, block.timestamp, period);

            vaults[tokenId] = Stake({
                owner: msg.sender,
                tokenId: uint24(tokenId),
                timestamp: uint48(block.timestamp),
                period: uint96(period)
            });
        }
    }

    function stakeTo(address account, uint256[] calldata tokenIds, uint256 period) external {
        if (period != 3 && period != 6 && period != 12) revert InvalidPeriod();

        if (msg.sender != address(vaultToken)) revert NotVaultToken();

        totalStaked += tokenIds.length;

        for (uint i = 0; i < tokenIds.length; i++) {
            uint24 tokenId = uint24(tokenIds[i]);

            if (vaults[tokenId].tokenId != 0) revert VaultStaked();

            emit NFTStaked(account, tokenId, block.timestamp, period);

            vaults[tokenId] = Stake({
                owner: account,
                tokenId: uint24(tokenId),
                timestamp: uint48(block.timestamp),
                period: uint96(period)
            });
        }
    }

    function unstake(uint256[] calldata tokenIds) external {
        _unstakeMany(msg.sender, tokenIds);
    }

    function _unstakeMany(address account, uint256[] calldata tokenIds) internal {
        totalStaked -= tokenIds.length;

        for (uint i = 0; i < tokenIds.length; i++) {
            uint24 tokenId = uint24(tokenIds[i]);

            Stake memory staked = vaults[tokenId];
            if (staked.owner != msg.sender) revert NotOwner();

            if (block.timestamp < stakeEndsTime(tokenId)) revert NotComplete();

            delete vaults[tokenId];
            emit NFTUnstaked(account, tokenId, block.timestamp, staked.period);
            vaultToken.transferFrom(address(this), account, tokenId);
        }
    }

    function stakeEndsTime(uint256 tokenId) public view returns (uint256) {
        Stake memory staked = vaults[uint24(tokenId)];
        return staked.timestamp + uint256(staked.period) * periodUnit;
    }

    function balanceOf(address account) external view returns (uint256) {
        uint256 balance = 0;
        uint256 supply = vaultToken.totalMinted();
        for (uint24 i = 1; i <= supply; i++) {
            if (vaults[i].owner == account) {
                balance += 1;
            }
        }
        return balance;
    }

    function tokensOfOwner(address account) external view returns (Stake[] memory ownerTokens) {
        uint256 index = 0;

        uint256 supply = vaultToken.totalMinted();
        Stake[] memory tmp = new Stake[](supply);
        for (uint24 tokenId = 1; tokenId <= supply; tokenId++) {
            if (vaults[tokenId].owner == account) {
                tmp[index] = vaults[tokenId];
                index += 1;
            }
        }

        Stake[] memory tokens = new Stake[](index);
        for (uint i = 0; i < index; i++) {
            tokens[i] = tmp[i];
        }

        return tokens;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return ERC721A__IERC721Receiver.onERC721Received.selector;
    }
}
