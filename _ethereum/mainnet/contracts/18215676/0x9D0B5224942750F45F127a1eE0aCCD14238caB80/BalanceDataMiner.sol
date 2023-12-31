pragma solidity ^0.5.16;


interface TokenContract {
    function balanceOf(address _tokenOwner) external view returns (uint);
}

interface NftContract {
    function balanceOf(address _tokenOwner) external view returns(uint);
    function ownerOf(uint _tokenId) external view returns(address);
    function tokenOfOwnerByIndex(address _tokenOwner, uint _index) external view returns (uint);
}

interface MultiTokenContract {
    function balanceOf(address _tokenOwner, uint _tokenId) external view returns(uint);
}


contract BalanceDataMiner {
    //-------------------------------------------------------------------------
    /// @notice Gets balances for each wallet address for a given token contract
    //-------------------------------------------------------------------------
    function getBatchBalance(
        address _contractAddress,
        address[] memory _walletAddresses
    ) public view returns(uint[] memory) {
        uint[] memory balances = new uint[](_walletAddresses.length);

        if (_contractAddress == address(0)) {
            for (uint i = 0; i < balances.length; ++i) {
                balances[i] = _walletAddresses[i].balance;
            }
        }
        else {
            TokenContract tokenContract = TokenContract(_contractAddress);
            for (uint i = 0; i < balances.length; ++i) {
                balances[i] = tokenContract.balanceOf(_walletAddresses[i]);
            }
        }
        return balances;
    }

    //-------------------------------------------------------------------------
    /// @notice Gets balances and owned token ids for each wallet address for
    ///  a given nft contract
    //-------------------------------------------------------------------------
    function getBatchNfts(
        address _contractAddress,
        address[] calldata _walletAddresses
    ) external view returns (uint[] memory, uint[] memory) {
        NftContract nftContract = NftContract(_contractAddress);
        uint[] memory balances = new uint[](_walletAddresses.length);
        uint numberOfTokens = 0;

        for (uint i = 0; i < balances.length; ++i) {
            balances[i] = nftContract.balanceOf(_walletAddresses[i]);
            numberOfTokens += balances[i];
        }

        uint[] memory tokenIds = new uint[](numberOfTokens);

        uint tokenIdsIndex = 0;
        for (uint i = 0; i < balances.length; ++i) {
            for (uint j = 0; j < balances[i]; ++j) {
                tokenIds[tokenIdsIndex] = nftContract.tokenOfOwnerByIndex(_walletAddresses[i], j);
                ++tokenIdsIndex;
            }
        }

        return (balances, tokenIds);
    }

    //-------------------------------------------------------------------------
    /// @notice Gets owner wallet addresses for each token ID
    //-------------------------------------------------------------------------
    function getBatchNftOwners(
        address _contractAddress,
        uint[] calldata _tokenIds
    ) external view returns (address[] memory) {
        NftContract nftContract = NftContract(_contractAddress);
        address[] memory tokenOwners = new address[](_tokenIds.length);

        for (uint i = 0; i < _tokenIds.length; ++i) {
            tokenOwners[i] = nftContract.ownerOf(_tokenIds[i]);
        }

        return tokenOwners;
    }

    //-------------------------------------------------------------------------
    /// @notice Gets balances for each wallet address for a given token id of
    ///  a given multi token contract
    //-------------------------------------------------------------------------
    function getBatchMultiTokenBalance(
        address _contractAddress,
        uint _tokenId,
        address[] calldata _walletAddresses
    ) external view returns (uint[] memory) {
        MultiTokenContract tokenContract = MultiTokenContract(_contractAddress);
        uint[] memory balances = new uint[](_walletAddresses.length);
        for (uint i = 0; i < _walletAddresses.length; ++i) {
            balances[i] = tokenContract.balanceOf(_walletAddresses[i], _tokenId);
        }
        return balances;
    }

    //-------------------------------------------------------------------------
    /// @notice Gets whether each wallet address owns any of the given token
    ///  ids of a given multi token contract
    //-------------------------------------------------------------------------
    function getBatchMultiTokenOwnership(
        address _contractAddress,
        uint[] calldata _tokenIds,
        address[] calldata _walletAddresses
    ) external view returns(bool[] memory) {
        MultiTokenContract tokenContract = MultiTokenContract(_contractAddress);
        bool[] memory ownerships = new bool[](_walletAddresses.length);
        for (uint i = 0; i < _walletAddresses.length; ++i) {
            for (uint j = 0; j < _tokenIds.length; ++j) {
                if (tokenContract.balanceOf(_walletAddresses[i], _tokenIds[j]) > 0) {
                    ownerships[i] = true;
                    break;
                }
            }
        }
        return ownerships;
    }
}