// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721AUpgradeable.sol";
import "./IERC721AUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC721Holder.sol";

contract NftStake is ERC721AUpgradeable, ERC721Holder, OwnableUpgradeable {
    uint16 public maxUserStake;
    uint256 public updateStakeDays;
    uint[] public stakingUsers;
    address[] public stakingNftAddress;

    struct Staking {
        address user;
        uint256 isStake;
        uint256 typeContract;
        uint256 daysStake;
        uint256 tokenuserId;
    }


    function initialize() initializerERC721A initializer public {
        __ERC721A_init('NFT Staking FREEBI Reward', 'NSFR');
        __Ownable_init();
        updateStakeDays = 90;
        maxUserStake = 10000;
    }

    function addNftContract(address nft_) public onlyOwner {
        stakingNftAddress.push(nft_);
    }

    function updateMaxUserStake (uint16 _count) public onlyOwner {
        maxUserStake = _count;
    }

    function stake (uint256 tokenId, uint256 _type, uint256 _days) external {
        uint256 isStake = 1;
        IERC721AUpgradeable _nft = IERC721AUpgradeable(stakingNftAddress[_type]);

        _nft.safeTransferFrom(msg.sender, address(this), tokenId);

        if (stakingUsers.length >= maxUserStake) {
            isStake = 0;
        }

        this.setParams(msg.sender, isStake, _days, _type, tokenId);

    }

    function unstake (uint64 tokenId, uint8 _type) external {
        address _ownerNft;
        uint256 _idInArray;
        uint256 i = 0;
        IERC721AUpgradeable _nft = IERC721AUpgradeable(stakingNftAddress[_type]);

        while (i < stakingUsers.length) {
            uint256 params = stakingUsers[i];
            address owner = address(uint160(params));
            uint256 isStake = uint256(uint40(params>>160));
            uint256 daysStake = uint256(uint16(params>>208));
            uint256 typeContract = uint256(uint16(params>>224));
            uint256 tokenuserId = uint256(uint16(params>>240));

            if (tokenuserId == tokenId &&  typeContract == _type) {
                _ownerNft = owner;
                _idInArray = i;
                break;
            }

            i++;
        }


        require(_ownerNft == msg.sender, "You can't unstake");

        _nft.safeTransferFrom(address(this), msg.sender, tokenId);

        delete stakingUsers[_idInArray];

        for (uint j = _idInArray; j< stakingUsers.length-1; j++){
            stakingUsers[j] = stakingUsers[j+1];
        }

        stakingUsers.pop();

        i = 0;

        while (i < stakingUsers.length) {
            uint256 params = stakingUsers[i];
            address owner = address(uint160(params));
            uint256 isStake = uint256(uint40(params>>160));
            uint256 daysStake = uint256(uint16(params>>208));
            uint256 typeContract = uint256(uint16(params>>224));
            uint256 tokenuserId = uint256(uint16(params>>240));

            if (isStake == 0) {
                isStake = 1;
                uint256 updateParams = uint256(uint160(owner));
                updateParams |= isStake<<160;
                updateParams |= daysStake<<208;
                updateParams |= typeContract<<224;
                updateParams |= tokenuserId<<240;
                stakingUsers[i] = updateParams;
                break;
            }

            i++;
        }
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }


    function setParams(address owner, uint256 isStake, uint256 daysStake, uint256 typeContract, uint256 tokenuserId)
    external {
        uint256 params = uint256(uint160(owner));
        params |= isStake<<160;
        params |= daysStake<<208;
        params |= typeContract<<224;
        params |= tokenuserId<<240;

        stakingUsers.push(params);
    }

    function getParams(uint256 tokenId, uint256 _type) external view returns(address , uint256 , uint256 , uint256 , uint256 ) {
        uint256 i = 0;
        while (i < stakingUsers.length) {
            uint256 params = stakingUsers[i];
            address owner = address(uint160(params));
            uint256 isStake = uint256(uint40(params>>160));
            uint256 daysStake = uint256(uint16(params>>208));
            uint256 typeContract = uint256(uint16(params>>224));
            uint256 tokenuserId = uint256(uint16(params>>240));

            if (tokenuserId == tokenId &&  typeContract == _type) {
                return (owner, isStake, daysStake, typeContract, tokenuserId);
            }

            i++;
        }
    }

    function updateStakeDay(uint256 tokenId, uint256 _type) external {
        uint256 i = 0;
        while (i < stakingUsers.length) {
            uint256 params = stakingUsers[i];
            address owner = address(uint160(params));
            uint256 isStake = uint256(uint40(params>>160));
            uint256 daysStake = uint256(uint16(params>>208));
            uint256 typeContract = uint256(uint16(params>>224));
            uint256 tokenuserId = uint256(uint16(params>>240));

            if (tokenuserId == tokenId &&  typeContract == _type && owner == msg.sender) {
                daysStake = updateStakeDays;
                uint256 updateParams = uint256(uint160(owner));
                updateParams |= isStake<<160;
                updateParams |= daysStake<<208;
                updateParams |= typeContract<<224;
                updateParams |= tokenuserId<<240;
                stakingUsers[i] = updateParams;
                break;
            }

            i++;
        }
    }

    function getNftAddress() public view returns (address[] memory) {
        return stakingNftAddress;
    }

    function getNftStaking() public view returns (Staking[] memory ){
        uint256 i = 0;
        Staking[] memory stakingNft = new Staking[](stakingUsers.length);

        while (i < stakingUsers.length) {
            uint256 params = stakingUsers[i];
            address owner = address(uint160(params));
            uint256 isStake = uint256(uint40(params>>160));
            uint256 daysStake = uint256(uint16(params>>208));
            uint256 typeContract = uint256(uint16(params>>224));
            uint256 tokenuserId = uint256(uint16(params>>240));
            stakingNft[i] = Staking(owner, isStake, typeContract, daysStake, tokenuserId);

            i++;
        }

        return stakingNft;
    }

    function manyStaking(uint256[] calldata _tokenIds, uint256 _type, uint256 _days) external {
        uint256 len = _tokenIds.length;
        IERC721AUpgradeable _nft = IERC721AUpgradeable(stakingNftAddress[_type]);
        for (uint256 i; i < len; ++i) {
            uint256 isStake = 1;

            _nft.safeTransferFrom(msg.sender, address(this), _tokenIds[i]);

            if (stakingUsers.length >= maxUserStake) {
                isStake = 0;
            }

            this.setParams(msg.sender, isStake, _days, _type, _tokenIds[i]);
        }
    }

    function manyUpdateStakeDay(uint256[] calldata _tokenIds, uint256 _type) external {
        uint256 len = _tokenIds.length;

        for (uint256 j; j < len; ++j) {
            uint256 i = 0;
            while (i < stakingUsers.length) {
                uint256 params = stakingUsers[i];
                address owner = address(uint160(params));
                uint256 isStake = uint256(uint40(params>>160));
                uint256 daysStake = uint256(uint16(params>>208));
                uint256 typeContract = uint256(uint16(params>>224));
                uint256 tokenuserId = uint256(uint16(params>>240));

                if (tokenuserId == _tokenIds[j] &&  typeContract == _type && owner == msg.sender) {
                    daysStake = updateStakeDays;
                    uint256 updateParams = uint256(uint160(owner));
                    updateParams |= isStake<<160;
                    updateParams |= daysStake<<208;
                    updateParams |= typeContract<<224;
                    updateParams |= tokenuserId<<240;
                    stakingUsers[i] = updateParams;
                    break;
                }

                i++;
            }
        }
    }
}
