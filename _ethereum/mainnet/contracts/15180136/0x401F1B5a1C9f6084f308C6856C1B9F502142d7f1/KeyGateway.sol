// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC721.sol";
import "./IKeyGateway.sol";

contract KeyGateway is IKeyGateway, Ownable {
    mapping(address => bool) collectionsToCheck;
    mapping(address => mapping(uint256 => bool)) nftsUsed;

    mapping(address => bool) userContracts;

    modifier isNftContract() {
        require(
            userContracts[msg.sender] == true,
            "Sender contract is not enabled"
        );
        _;
    }

    constructor() {}

    function updateUserContractStatus(address _contract, bool _active)
        external
        onlyOwner
    {
        userContracts[_contract] = _active;
    }

    function updateKeyCollectionStatus(address _contract, bool _active)
        external
        onlyOwner
    {
        collectionsToCheck[_contract] = _active;
    }

    function useNfts(
        uint256 _requirement,
        address[] memory _collections,
        uint256[] memory _nfts,
        address _owner
    ) external override isNftContract {
        uint256 checkedAmount;
        IERC721 nftContract;

        for (uint256 i = 0; i < _collections.length; i++) {
            if (collectionsToCheck[_collections[i]] == true) {
                nftContract = IERC721(_collections[i]);

                require(
                    nftContract.ownerOf(_nfts[i]) == _owner,
                    "Sender is not the owner"
                );

                require(
                    !isNftUsed(_collections[i], _nfts[i]),
                    "An NFT is not active"
                );

                checkedAmount++;
                nftsUsed[_collections[i]][_nfts[i]] = true;
            }
        }

        require(_requirement <= checkedAmount, "Requirement is not met");
    }

    function isNftUsed(address _collection, uint256 _nftId)
        public
        view
        returns (bool)
    {
        return nftsUsed[_collection][_nftId];
    }
}
