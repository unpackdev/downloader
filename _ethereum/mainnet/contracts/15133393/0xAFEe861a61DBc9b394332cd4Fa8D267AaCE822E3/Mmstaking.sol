// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./ReentrancyGuard.sol";
import "./IERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";

error NotApprovedCollection();
error PercentageIsLessThan35();
error Address0();
error PermissionDenied();
error CannotUnstakeBeforeEnd();

/**
    @title MeetsMeta Staking contract
    @author ^M
 */
contract MMStaking_Base is Ownable, ReentrancyGuard {
    /**
    @dev struct for stakes info
     */
    struct StakeInfo {
        address player;
        address holder;
        address collection;
        uint256 tokenId;
        uint256 percentage;
        uint256 stakedDate;
        uint256 lockingPeriod;
        uint256 id;
    }

    /**
    @dev in this array we hold all of stakes information
     */
    StakeInfo[] public allStakes;
    /**
    @dev holders mapping to an array of indexes of their staked passports
     */
    mapping(address => uint256[]) private holders;
    /**
    @dev players mapping to an array of indexes of their assigned passports
     */
    mapping(address => uint256[]) private players;
    /**
    @dev list of all approved collections
    @notice its updatable
     */
    mapping(address => bool) private approvedCollections;
    // Fires when an staking happen
    event Staked(
        address indexed holder,
        address indexed player,
        address collection,
        uint256 tokenId
    );
    // withdrawing any amount of token/ETH/NFT from the contract
    event withdraw_event(address token_address);

    /**
    @dev stake function
    @param _player address
    @param _collection address
    @param _tokenId in the collection
    @param _percentage of earnings which holder will share with the player. **should be multiplied by 100 before passing**
     */

    function stake(
        address _player,
        address _collection,
        uint256 _tokenId,
        uint256 _percentage,
        uint256 _lockingPeriod
    ) public nonReentrant {
        if (!approvedCollections[_collection]) {
            revert NotApprovedCollection();
        }
        if (_percentage < 3500) {
            revert PercentageIsLessThan35();
        }
        if (_player == address(0)) {
            revert Address0();
        }

        IERC721(_collection).transferFrom(
            _msgSender(),
            address(this),
            _tokenId
        );

        allStakes.push(
            StakeInfo(
                _player,
                _msgSender(),
                _collection,
                _tokenId,
                _percentage,
                block.timestamp,
                _lockingPeriod,
                allStakes.length
            )
        );
        holders[_msgSender()].push(allStakes.length - 1);
        players[_player].push(allStakes.length - 1);

        emit Staked(_msgSender(), _player, _collection, _tokenId);
    }

    event Unstaked(
        address indexed holder,
        address indexed player,
        address indexed collection,
        uint256 tokenId
    );

    /**
    @dev unstake function
    @param _stakeId of the item. this is the index of the item in allStakes array
    */
    function unstake(uint256 _stakeId) public nonReentrant {
        if (
            _stakeId >= allStakes.length ||
            ((allStakes[_stakeId].holder != _msgSender()) &&
                _msgSender() != owner())
        ) {
            revert PermissionDenied();
        }

        StakeInfo memory _stake = allStakes[_stakeId];
        if (_stake.player == address(0)) {
            revert Address0();
        }
        if (
            (_stake.stakedDate + _stake.lockingPeriod) > block.timestamp &&
            _msgSender() != owner()
        ) {
            revert CannotUnstakeBeforeEnd();
        }

        // deleting all the info before transfering the NFT
        uint256 i = 0;
        for (i = 0; i < holders[_stake.holder].length; i++) {
            if (holders[_stake.holder][i] == _stakeId) {
                delete holders[_stake.holder][i];
                break;
            }
        }
        for (i = 0; i < players[_stake.player].length; i++) {
            if (players[_stake.player][i] == _stakeId) {
                delete players[_stake.player][i];
                break;
            }
        }
        delete allStakes[_stakeId];

        IERC721(_stake.collection).transferFrom(
            address(this),
            _stake.holder,
            _stake.tokenId
        );

        emit Unstaked(
            _stake.holder,
            _stake.player,
            _stake.collection,
            _stake.tokenId
        );
    }

    event addApproved(address _newCollecction);

    /**
    @dev adding a new collection address to the list of approved collections
    @param _newCollection address
     */
    function addApprovedCollection(address _newCollection) public onlyOwner {
        approvedCollections[_newCollection] = true;
        emit addApproved(_newCollection);
    }

    /**
    @dev getting the player info
    @param _player address
    @return an array of players assigned passports
     */
    function getPlayerInfo(address _player)
        public
        view
        returns (StakeInfo[] memory)
    {
        uint256[] memory playerIds = players[_player];
        if (playerIds.length == 0) {
            return new StakeInfo[](1);
        } else {
            StakeInfo[] memory _results = new StakeInfo[](playerIds.length);
            for (uint256 i = 0; i < playerIds.length; i++) {
                _results[i] = allStakes[playerIds[i]];
            }
            return _results;
        }
    }

    /**
    @dev getting holders info
    @param _holder address
    @return holders all staked passports info
     */
    function getHolderInfo(address _holder)
        public
        view
        returns (StakeInfo[] memory)
    {
        uint256[] memory holderIds = holders[_holder];
        if (holderIds.length == 0) {
            return new StakeInfo[](1);
        } else {
            StakeInfo[] memory _results = new StakeInfo[](holderIds.length);
            for (uint256 i = 0; i < holderIds.length; i++) {
                _results[i] = allStakes[holderIds[i]];
            }
            return _results;
        }
    }

    /**
    @dev all staked info
    @return a list of stakes info
     */
    function getAllInfo() public view returns (StakeInfo[] memory) {
        return allStakes;
    }

    /**
    @dev withdraw all the ETH holdings to the beneficiary address 
    */
    function withdraw() public onlyOwner nonReentrant {
        payable(owner()).transfer(address(this).balance);
        emit withdraw_event(address(0));
    }

    /** 
    @dev this is a withdrawal in case of any ERC20 mistake deposit
    @param contract_address is the token contract address
    @notice this function withdraw all holdings of the token to the beneficiarys' address
    */
    function withdraw_erc20(address contract_address)
        public
        onlyOwner
        nonReentrant
    {
        IERC20(contract_address).transfer(
            owner(),
            IERC20(contract_address).balanceOf(address(this))
        );
        emit withdraw_event(contract_address);
    }

    /** 
    @dev this is a withdrawal in case of any ERC721 mistake deposit
    @param contract_address is the token contract address
    @param tokenID of the ERC721 item
    @notice this function withdraw the ERC721 token to the beneficiarys' address
    */
    function withdraw_erc721(address contract_address, uint256 tokenID)
        public
        onlyOwner
        nonReentrant
    {
        // checking the NFT is not from an approved collection to prevent any incident
        if (approvedCollections[contract_address]) {
            revert PermissionDenied();
        }
        IERC721(contract_address).transferFrom(address(this), owner(), tokenID);
        emit withdraw_event(contract_address);
    }
}
