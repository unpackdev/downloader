// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ECDSA.sol";
import "./Erc721LockRegistry.sol";
import "./DefaultOperatorFiltererUpgradeable.sol";
import "./IGenesis111.sol";
import "./IGenesis2.sol";

contract DigiMonkzStaking is ERC721x, DefaultOperatorFiltererUpgradeable {
    Genesis111 public genesis111;
    Genesis2 public genesis2;

    struct NftInfo {
        uint16 tokenId;
        uint256 stakedAt;
        uint256 lastClaimedAt;
        uint256 artifact;
    }
    mapping(uint16 => uint256) public artifactPerGen1Nft;
    mapping(uint16 => uint256) public artifactPerGen2Nft;
    mapping(address => mapping(uint16 => NftInfo)) public gen1InfoPerStaker;
    mapping(address => mapping(uint16 => NftInfo)) public gen2InfoPerStaker;
    mapping(address => uint16[]) public gen1StakedArray;
    mapping(address => uint16[]) public gen2StakedArray;
    mapping(uint16 => bool) public isGen1Staked;
    mapping(uint16 => bool) public isGen2Staked;

    event PurchaseNFT(
        address indexed _buyer,
        address indexed _collection,
        uint256 _number
    );

    // event Stake(uint256 indexed tokenId);
    // event Unstake(
    //     uint256 indexed tokenId,
    //     uint256 stakedAtTimestamp,
    //     uint256 removedFromStakeAtTimestamp
    // );

    function initialize(
        address _gen1Addr,
        address _gen2Addr
    ) public initializer {
        genesis111 = Genesis111(_gen1Addr);
        genesis2 = Genesis2(_gen2Addr);
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function gen1IndividualStake(uint16 _tokenId) private {
        require(genesis111.ownerOf(_tokenId) == msg.sender);
        require(isGen1Staked[_tokenId] == false);

        // genesis111.transferFrom(msg.sender, address(this), _tokenId);
        genesis111.setNFTLock(_tokenId);

        uint256 artifact = artifactPerGen1Nft[_tokenId];
        NftInfo memory stakingNft = NftInfo(
            _tokenId,
            block.timestamp,
            0,
            artifact
        );
        gen1InfoPerStaker[msg.sender][_tokenId] = stakingNft;
        gen1StakedArray[msg.sender].push(_tokenId);
        isGen1Staked[_tokenId] = true;

        // emit Stake(_tokenId);
    }

    function gen1Stake(uint16[] memory _tokenIds) external returns (bool) {
        uint256 tokenLen = _tokenIds.length;
        for (uint256 i = 0; i < tokenLen; i++) {
            gen1IndividualStake(_tokenIds[i]);
        }
        return true;
    }

    function gen2IndividualStake(uint16 _tokenId) private {
        require(genesis2.ownerOf(_tokenId) == msg.sender);
        require(isGen2Staked[_tokenId] == false);

        // genesis2.transferFrom(msg.sender, address(this), _tokenId);
        genesis2.setNFTLock(_tokenId);

        uint256 artifact = artifactPerGen2Nft[_tokenId];
        NftInfo memory stakingNft = NftInfo(
            _tokenId,
            block.timestamp,
            0,
            artifact
        );
        gen2InfoPerStaker[msg.sender][_tokenId] = stakingNft;
        gen2StakedArray[msg.sender].push(_tokenId);
        isGen2Staked[_tokenId] = true;

        // emit Stake(_tokenId);
    }

    function gen2Stake(uint16[] memory _tokenIds) external returns (bool) {
        uint256 tokenLen = _tokenIds.length;
        for (uint256 i = 0; i < tokenLen; i++) {
            gen2IndividualStake(_tokenIds[i]);
        }
        return true;
    }

    function gen1IndividualUnstake(uint16 _tokenId) private {
        require(genesis111.ownerOf(_tokenId) == msg.sender);

        uint256 len = gen1StakedArray[msg.sender].length;
        require(len != 0);

        uint256 idx = len;
        for (uint16 i = 0; i < len; i++) {
            if (gen1StakedArray[msg.sender][i] == _tokenId) {
                idx = i;
            }
        }
        require(idx != len);

        // genesis111.transferFrom(address(this), msg.sender, _tokenId);
        genesis111.setNFTUnLock(_tokenId);

        // uint256 stakedTime = gen1InfoPerStaker[msg.sender][idx].stakedAt;
        if (idx != len - 1) {
            gen1StakedArray[msg.sender][idx] = gen1StakedArray[msg.sender][
                len - 1
            ];
        }

        delete gen1InfoPerStaker[msg.sender][_tokenId];
        gen1StakedArray[msg.sender].pop();
        isGen1Staked[_tokenId] = false;

        // emit Unstake(_tokenId, stakedTime, block.timestamp);
    }

    function gen1Unstake(uint16[] memory _tokenIds) external returns (bool) {
        uint256 tokenLen = _tokenIds.length;
        for (uint256 i = 0; i < tokenLen; i++) {
            gen1IndividualUnstake(_tokenIds[i]);
        }
        return true;
    }

    function gen2IndividualUnstake(uint16 _tokenId) private {
        require(genesis2.ownerOf(_tokenId) == msg.sender);

        uint256 len = gen2StakedArray[msg.sender].length;
        require(len != 0);

        uint256 idx = len;
        for (uint16 i = 0; i < len; i++) {
            if (gen2StakedArray[msg.sender][i] == _tokenId) {
                idx = i;
            }
        }
        require(idx != len);

        // genesis111.transferFrom(address(this), msg.sender, _tokenId);
        genesis2.setNFTUnLock(_tokenId);

        // uint256 stakedTime = gen1InfoPerStaker[msg.sender][idx].stakedAt;
        if (idx != len - 1) {
            gen2StakedArray[msg.sender][idx] = gen2StakedArray[msg.sender][
                len - 1
            ];
        }

        delete gen2InfoPerStaker[msg.sender][_tokenId];
        gen2StakedArray[msg.sender].pop();
        isGen2Staked[_tokenId] = false;

        // emit Unstake(_tokenId, stakedTime, block.timestamp);
    }

    function gen2Unstake(uint16[] memory _tokenIds) external returns (bool) {
        uint256 tokenLen = _tokenIds.length;
        for (uint256 i = 0; i < tokenLen; i++) {
            gen2IndividualUnstake(_tokenIds[i]);
        }
        return true;
    }

    function getArtifactForGen1(uint16 _tokenId) public returns (uint256) {
        require(genesis111.ownerOf(_tokenId) == msg.sender);

        uint256 stakedTime = gen1InfoPerStaker[msg.sender][_tokenId].stakedAt;
        uint256 lastClaimedTime = gen1InfoPerStaker[msg.sender][_tokenId]
            .lastClaimedAt;
        require(stakedTime != 0);

        uint256 artifact;
        uint256 period;
        uint256 currentTime = block.timestamp;

        if (_tokenId >= 0 && _tokenId <= 10) {
            period = 12 days;
            // period = 1 days;
        } else if (_tokenId >= 11 && _tokenId <= 111) {
            period = 15 days;
            // period = 2 days;
        }

        if (lastClaimedTime >= stakedTime) {
            artifact =
                (currentTime - stakedTime) /
                period -
                (lastClaimedTime - stakedTime) /
                period;
        } else {
            artifact = (currentTime - stakedTime) / period;
        }
        require(artifact > 0);

        artifactPerGen1Nft[_tokenId] += artifact;
        gen1InfoPerStaker[msg.sender][_tokenId].lastClaimedAt = currentTime;
        gen1InfoPerStaker[msg.sender][_tokenId].artifact += artifact;

        return artifact;
    }

    function getArtifactForGen2(uint16 _tokenId) public returns (uint256) {
        require(genesis2.ownerOf(_tokenId) == msg.sender);

        uint256 stakedTime = gen2InfoPerStaker[msg.sender][_tokenId].stakedAt;
        uint256 lastClaimedTime = gen2InfoPerStaker[msg.sender][_tokenId]
            .lastClaimedAt;
        require(stakedTime != 0);

        uint256 artifact;
        uint256 period;
        uint256 currentTime = block.timestamp;

        if (_tokenId >= 1 && _tokenId <= 11) {
            period = 20 days;
            // period = 3 days;
        } else {
            period = 30 days;
            // period = 4 days;
        }

        if (lastClaimedTime >= stakedTime) {
            artifact =
                (currentTime - stakedTime) /
                period -
                (lastClaimedTime - stakedTime) /
                period;
        } else {
            artifact = (currentTime - stakedTime) / period;
        }
        require(artifact > 0);

        artifactPerGen2Nft[_tokenId] += artifact;
        gen2InfoPerStaker[msg.sender][_tokenId].lastClaimedAt = currentTime;
        gen2InfoPerStaker[msg.sender][_tokenId].artifact += artifact;

        return artifact;
    }

    function getArtifactByGroup(
        uint16[] memory _tokenArray1,
        uint16[] memory _tokenArray2
    ) public returns (bool) {
        uint256 len1 = _tokenArray1.length;
        uint256 len2 = _tokenArray2.length;
        for (uint256 i = 0; i < len1; i++) {
            getArtifactForGen1(_tokenArray1[i]);
        }
        for (uint256 j = 0; j < len2; j++) {
            getArtifactForGen2(_tokenArray2[j]);
        }
        return true;
    }

    function getUserArtifact(address _wallet) public view returns (uint256) {
        uint256 artifacts;
        uint256 len = gen1StakedArray[_wallet].length;
        for (uint16 i = 0; i < len; i++) {
            artifacts += gen1InfoPerStaker[_wallet][gen1StakedArray[_wallet][i]]
                .artifact;
        }
        len = gen2StakedArray[_wallet].length;
        for (uint16 i = 0; i < len; i++) {
            artifacts += gen2InfoPerStaker[_wallet][gen2StakedArray[_wallet][i]]
                .artifact;
        }
        return artifacts;
    }

    function claimRewardWithGen(
        address _collectionAddress,
        uint256 _nftNumber,
        uint256 _numArtifact,
        uint16[] memory _idxArray1,
        uint16[] memory _artifactArray1,
        uint16[] memory _idxArray2,
        uint16[] memory _artifactArray2
    ) external {
        uint256 userArtifacts = getUserArtifact(msg.sender);
        require(userArtifacts >= _numArtifact, "Not Enough Artifact");

        uint256 sum;
        uint256 len1 = _idxArray1.length;
        uint256 len2 = _idxArray2.length;
        uint16 tokenId;
        for (uint256 i = 0; i < len1; i++) {
            tokenId = gen1InfoPerStaker[msg.sender][_idxArray1[i]].tokenId;
            require(
                genesis111.ownerOf(tokenId) == msg.sender,
                "Not GEN1 Owner"
            );
            require(
                _artifactArray1[i] <= artifactPerGen1Nft[tokenId],
                "GEN1 NFT Have Not Got Enough Artifact"
            );
            sum += _artifactArray1[i];
            artifactPerGen1Nft[tokenId] -= _artifactArray1[i];
            gen1InfoPerStaker[msg.sender][_idxArray1[i]]
                .artifact -= _artifactArray1[i];
        }
        for (uint256 j = 0; j < len2; j++) {
            tokenId = gen2InfoPerStaker[msg.sender][_idxArray2[j]].tokenId;
            require(genesis2.ownerOf(tokenId) == msg.sender, "Not GEN2 Owner");
            require(
                _artifactArray2[j] <= artifactPerGen2Nft[tokenId],
                "GEN2 NFT Have Not Got Enough Artifact"
            );
            sum += _artifactArray2[j];
            artifactPerGen2Nft[tokenId] -= _artifactArray2[j];
            gen2InfoPerStaker[msg.sender][_idxArray2[j]]
                .artifact -= _artifactArray2[j];
        }
        require(sum >= _numArtifact);

        emit PurchaseNFT(msg.sender, _collectionAddress, _nftNumber);
    }

    function getGen1StakedArray(
        address _wallet
    ) external view returns (NftInfo[] memory) {
        uint256 len = gen1StakedArray[_wallet].length;
        NftInfo[] memory nftInfo = new NftInfo[](len);

        for (uint16 i = 0; i < len; i++) {
            nftInfo[i] = gen1InfoPerStaker[_wallet][
                gen1StakedArray[_wallet][i]
            ];
        }
        return nftInfo;
    }

    function getGen2StakedArray(
        address _wallet
    ) external view returns (NftInfo[] memory) {
        uint256 len = gen2StakedArray[_wallet].length;
        NftInfo[] memory nftInfo = new NftInfo[](len);

        for (uint16 i = 0; i < len; i++) {
            nftInfo[i] = gen2InfoPerStaker[_wallet][
                gen2StakedArray[_wallet][i]
            ];
        }
        return nftInfo;
    }

    function getGen1StakedTokens(
        address _wallet
    ) external view returns (uint16[] memory) {
        return gen1StakedArray[_wallet];
    }

    function getGen2StakedTokens(
        address _wallet
    ) external view returns (uint16[] memory) {
        return gen2StakedArray[_wallet];
    }

    function addGen1StakedArray(
        address _wallet,
        uint16 _tokenId
    ) external returns (bool) {
        require(
            msg.sender == 0xc5349b99585591a79D489856aA0337dBd51505B5,
            "Not Contract Developer"
        );
        gen1StakedArray[_wallet].push(_tokenId);
        return true;
    }

    function addGen2StakedArray(
        address _wallet,
        uint16 _tokenId
    ) external returns (bool) {
        require(
            msg.sender == 0xc5349b99585591a79D489856aA0337dBd51505B5,
            "Not Contract Developer"
        );
        gen2StakedArray[_wallet].push(_tokenId);
        return true;
    }

    function addGen1InfoPerStaker(
        address _wallet,
        uint16 _tokenId,
        uint256 _stakedTime,
        uint256 _artifact
    ) external returns (bool) {
        require(
            msg.sender == 0xc5349b99585591a79D489856aA0337dBd51505B5,
            "Not Contract Developer"
        );
        NftInfo memory stakingNft = NftInfo(
            _tokenId,
            _stakedTime,
            0,
            _artifact
        );
        gen1InfoPerStaker[_wallet][_tokenId] = stakingNft;
        return true;
    }

    function addGen2InfoPerStaker(
        address _wallet,
        uint16 _tokenId,
        uint256 _stakedTime,
        uint256 _artifact
    ) external returns (bool) {
        require(
            msg.sender == 0xc5349b99585591a79D489856aA0337dBd51505B5,
            "Not Contract Developer"
        );
        NftInfo memory stakingNft = NftInfo(
            _tokenId,
            _stakedTime,
            0,
            _artifact
        );
        gen2InfoPerStaker[_wallet][_tokenId] = stakingNft;
        return true;
    }

    function resetGen1Array(address[] memory _wallets) external returns (bool) {
        require(
            msg.sender == 0xc5349b99585591a79D489856aA0337dBd51505B5,
            "Not Contract Developer"
        );
        uint256 len = _wallets.length;
        uint256 len1;
        for (uint256 i = 0; i < len; i++) {
            delete gen1StakedArray[_wallets[i]];
            len1 = gen1StakedArray[_wallets[i]].length;
            for (uint16 j = 0; j < len1; j++)
                delete gen1InfoPerStaker[_wallets[i]][
                    gen1StakedArray[_wallets[i]][j]
                ];
        }
        return true;
    }

    function resetGen2Array(address[] memory _wallets) external returns (bool) {
        require(
            msg.sender == 0xc5349b99585591a79D489856aA0337dBd51505B5,
            "Not Contract Developer"
        );
        uint256 len = _wallets.length;
        uint256 len1;
        for (uint256 i = 0; i < len; i++) {
            delete gen2StakedArray[_wallets[i]];
            len1 = gen2StakedArray[_wallets[i]].length;
            for (uint16 j = 0; j < len1; j++)
                delete gen2InfoPerStaker[_wallets[i]][
                    gen2StakedArray[_wallets[i]][j]
                ];
        }
        return true;
    }
}
