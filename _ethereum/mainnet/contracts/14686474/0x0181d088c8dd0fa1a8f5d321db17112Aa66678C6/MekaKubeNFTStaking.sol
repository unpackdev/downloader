//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract MekaKubeNFTStaking is ERC721, Ownable {
    uint256 private _stakingId = 1;
    uint256 private _rewardNftId;
    string private _baseUriExtended;
    ERC721 public _xoids;
    IERC20 public _ctzn;

    uint256 public stakingPeriod;
    uint256 public erc20StakingAmount;

    constructor(ERC721 xoids_, IERC20 ctzn_) ERC721("Meka Kube", "MEKAKUBE") {
        _xoids = xoids_;
        _ctzn = ctzn_;
    }

    struct nftStaking {
        uint256 nftId;
        uint256 startingTime;
        address staker;
    }
    mapping(uint256 => nftStaking) _allNftStaked;
    mapping(address => uint256[]) _ownerStakingId;

    event NftStaked(
        address indexed staker,
        uint256 stakeId,
        uint256 tokenId,
        uint256 time
    );
    event NftUnStaked(
        address indexed staker,
        uint256 stakeId,
        uint256 tokenId,
        uint256 time
    );

    modifier unStakeTime(uint256 stakingId) {
        require(
            _allNftStaked[stakingId].startingTime + stakingPeriod <
                block.timestamp,
            "cannot unstake before time"
        );
        _;
    }

    modifier onlyStaker(uint256 stakingId) {
        require(
            _allNftStaked[stakingId].staker == msg.sender,
            "caller not owner"
        );
        _;
    }

    function stakeNft(uint256 _nftId) external {
        _xoids.transferFrom(msg.sender, address(this), _nftId);
        _ctzn.transferFrom(msg.sender, address(this), erc20StakingAmount);

        _allNftStaked[_stakingId] = nftStaking(
            _nftId,
            block.timestamp,
            msg.sender
        );
        _ownerStakingId[msg.sender].push(_stakingId);
        emit NftStaked(msg.sender, _stakingId, _nftId, block.timestamp);
        _stakingId++;
    }

    function unstakeNFT(uint256 stakingId)
        external
        onlyStaker(stakingId)
        unStakeTime(stakingId)
    {
        nftStaking memory stake = _allNftStaked[stakingId];
        _xoids.safeTransferFrom(address(this), msg.sender, stake.nftId);
        _ctzn.transfer(msg.sender, erc20StakingAmount);
        _rewardNftId++;
        _safeMint(msg.sender, _rewardNftId);

        delete _allNftStaked[stakingId];
        for (
            uint256 indx = 0;
            indx < _ownerStakingId[msg.sender].length;
            indx++
        ) {
            if (stakingId == _ownerStakingId[msg.sender][indx]) {
                _ownerStakingId[msg.sender][indx] = _ownerStakingId[msg.sender][
                    _ownerStakingId[msg.sender].length - 1
                ];
                _ownerStakingId[msg.sender].pop();
            }
        }

        emit NftUnStaked(msg.sender, stakingId, stake.nftId, block.timestamp);
    }

    function setStakingPeriod(uint256 period) external onlyOwner {
        stakingPeriod = period;
    }

    function depositAmount(uint256 amount) external onlyOwner {
        erc20StakingAmount = amount;
    }

    function getStalkingDetails(uint256 stakingId)
        external
        view
        returns (nftStaking memory)
    {
        return _allNftStaked[stakingId];
    }

    function getUserStaking(address user)
        external
        view
        returns (uint256[] memory)
    {
        return _ownerStakingId[user];
    }

    function currentRewardSupply() public view returns (uint256) {
        return _stakingId;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        require(bytes(baseURI_).length > 0, "Cannot be null");
        _baseUriExtended = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUriExtended;
    }

    function totalSupply() public view returns (uint256) {
        return _rewardNftId;
    }
}
