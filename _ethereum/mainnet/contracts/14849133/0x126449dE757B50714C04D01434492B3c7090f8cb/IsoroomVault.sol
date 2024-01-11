// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./IERC721Receiver.sol";
import "./IERC721.sol";
import "./ECDSA.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

contract IsoroomVault is Ownable, IERC721Receiver {
    uint256 public totalStaked;

    // struct to store a stake's token, owner, and earning values
    struct Stake {
        address erc721Contract;
        uint256 tokenId;
        uint48 timestamp;
        address owner;
    }
    mapping(uint256 => Stake) public vault;

    event BlockStaked(
        address owner,
        address erc721Contract,
        uint256 tokenId,
        uint256 value
    );
    event BlockUnstaked(
        address owner,
        address erc721Contract,
        uint256 tokenId,
        uint256 value
    );

    mapping(address => IERC721) public allowedContract;

    constructor() {}

    function addAllowedContract(IERC721 _contract) external onlyOwner {
        address erc721Address = address(_contract);
        allowedContract[erc721Address] = _contract;
    }

    function stake(address _erc721Address, uint256[] calldata _tokenIds)
        external
    {
        IERC721 erc721Contract = allowedContract[_erc721Address];
        require(
            erc721Contract.isApprovedForAll(msg.sender, address(this)),
            "Staking contract not approved"
        );

        totalStaked += _tokenIds.length;

        uint256 uniqueId;
        uint256 tokenId;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            tokenId = _tokenIds[i];
            uniqueId = uint256(uint160(address(_erc721Address))) + tokenId;

            require(
                erc721Contract.ownerOf(tokenId) == msg.sender,
                "Not your token"
            );
            require(vault[uniqueId].tokenId == 0, "Already staked");

            erc721Contract.transferFrom(msg.sender, address(this), tokenId);
            emit BlockStaked(
                msg.sender,
                _erc721Address,
                tokenId,
                block.timestamp
            );

            vault[uniqueId] = Stake({
                erc721Contract: _erc721Address,
                owner: msg.sender,
                tokenId: uint24(tokenId),
                timestamp: uint48(block.timestamp)
            });
        }
    }

    function stakeDuringMint(
        address _ownerAddress,
        address _erc721Address,
        uint256[] calldata _tokenIds
    ) external {
        require(
            msg.sender == address(_erc721Address),
            "Can be called only by NFT contract"
        );
        
        totalStaked += _tokenIds.length;
        
        IERC721 erc721Contract = allowedContract[_erc721Address];
        uint256 tokenId;
        uint256 uniqueId;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            tokenId = _tokenIds[i];
            uniqueId = uint256(uint160(address(_erc721Address))) + tokenId;

            require(
                erc721Contract.ownerOf(tokenId) == address(this),
                "nft must be sent first"
            );
            require(vault[uniqueId].tokenId == 0, "already staked");

            vault[uniqueId] = Stake({
                erc721Contract: _erc721Address,
                owner: _ownerAddress,
                tokenId: uint24(tokenId),
                timestamp: uint48(block.timestamp)
            });

            emit BlockStaked(
                _ownerAddress,
                _erc721Address,
                tokenId,
                block.timestamp
            );
        }
    }

    function unstake(address _erc721Address, uint256[] calldata _tokenIds)
        external
    {
        totalStaked -= _tokenIds.length;

        uint256 tokenId;
        uint256 uniqueId;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            tokenId = _tokenIds[i];
            uniqueId = uint256(uint160(address(_erc721Address))) + tokenId;

            Stake memory staked = vault[uniqueId];
            require(staked.owner == msg.sender, "Not an owner");

            delete vault[uniqueId];
            emit BlockUnstaked(
                msg.sender,
                _erc721Address,
                tokenId,
                block.timestamp
            );
            allowedContract[_erc721Address].transferFrom(
                address(this),
                msg.sender,
                tokenId
            );
        }
    }

    function onERC721Received(
        address,
        address _from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(_from == address(0x0), "Cannot send nfts to Vault directly");
        return IERC721Receiver.onERC721Received.selector;
    }

    function balanceOf(
        address _contractAddress,
        uint256 _totalSupply,
        address _address
    ) public view returns (uint256) {
        uint256 balance = 0;
        uint256 contractInt = uint256(uint160(address(_contractAddress)));

        for (uint256 i = contractInt; i <= contractInt + _totalSupply; i++) {
            if (vault[i].owner == _address) {
                balance += 1;
            }
        }
        return balance;
    }

    function tokensOfOwner(
        address _contractAddress,
        uint256 _totalSupply,
        address account
    ) public view returns (uint256[] memory ownerTokens) {
        uint256 contractInt = uint256(uint160(address(_contractAddress)));
        uint256[] memory tmp = new uint256[](_totalSupply);

        uint256 index = 0;
        for (
            uint256 tokenId = contractInt;
            tokenId <= contractInt + _totalSupply;
            tokenId++
        ) {
            if (vault[tokenId].owner == account) {
                tmp[index] = vault[tokenId].tokenId;
                index += 1;
            }
        }

        uint256[] memory tokens = new uint256[](index);
        for (uint256 i = 0; i < index; i++) {
            tokens[i] = tmp[i];
        }

        return tokens;
    }
}
