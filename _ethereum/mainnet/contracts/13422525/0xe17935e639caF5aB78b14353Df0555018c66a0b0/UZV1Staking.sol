// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Arrays.sol";

import "./IUZV1Staking.sol";
import "./IUZV1DAO.sol";

import "./UZV1ProAccess.sol";
import "./SharedDataTypes.sol";

/**
 * @title UnizenStaking
 * @author Unizen
 * @notice Unizen staking contract V1 that keeps track of stakes and TVL
 **/
contract UZV1Staking is IUZV1Staking, UZV1ProAccess {
    using SafeMath for uint256;
    /* === STATE VARIABLES === */
    // dao contract
    IUZV1DAO public dao;

    // storage of user stakes
    mapping(address => SharedDataTypes.StakerUser) public stakerUsers;

    // stakeable tokens data
    mapping(address => SharedDataTypes.StakeableToken) public stakeableTokens;

    // all whitelisted tokens
    address[] public activeTokens;

    // zcxht token address
    address public zcxht;

    // combined weight of all active tokens
    // stored to prevent recalculations of the weight
    // for every pool update
    uint256 public combinedTokenWeight;

    function initialize(
        address _zcx,
        uint256 _zcxTokenWeight,
        address _accessToken
    ) public initializer {
        UZV1ProAccess.initialize(_accessToken);
        // setup first stakeable token
        SharedDataTypes.StakeableToken storage _token = stakeableTokens[_zcx];

        // set token data
        _token.weight = _zcxTokenWeight;
        _token.active = true;

        // add token to active list
        activeTokens.push(_zcx);

        // setup helpers for token weight
        combinedTokenWeight = _zcxTokenWeight;
    }

    /* === VIEW FUNCTIONS === */

    /**
     * @dev Helper function to get the current TVL
     *
     * @return array with amounts staked on this contract
     **/
    function getTVLs() external view override returns (uint256[] memory) {
        return getTVLs(block.number);
    }

    /**
     * @dev Helper function to get the TVL on a block.number
     *
     * @return array with amounts staked on this contract
     **/
    function getTVLs(uint256 _blocknumber)
        public
        view
        override
        returns (uint256[] memory)
    {
        uint256[] memory _tvl = new uint256[](activeTokens.length);
        for (uint8 i = 0; i < activeTokens.length; i++) {
            _tvl[i] = _getTVL(_blocknumber, activeTokens[i]);
        }
        return _tvl;
    }

    function _getTVL(uint256 _blocknumber, address _token)
        internal
        view
        returns (uint256)
    {
        uint256 _tvl;
        if (_blocknumber == block.number) {
            _tvl = stakeableTokens[_token].totalValueLocked;
        } else {
            (uint256 _lastSavedBlock, ) = _findLastSavedBlock(
                stakeableTokens[_token].totalValueLockedKeys,
                _blocknumber
            );
            if (_lastSavedBlock == 0) {
                _tvl = 0;
            } else {
                _tvl = stakeableTokens[_token].totalValueLockedSnapshots[
                    _lastSavedBlock
                ];
            }
        }

        return _tvl;
    }

    /**
     * @dev used to calculate the users stake of the pool
     * @param _user optional user addres, if empty the sender will be used
     * @param _precision optional denominator, default to 3
     *
     * @return array with the percentage stakes of the user based on TVL of each allowed token
     *  [
     *   weightedAverage,
     *   shareOfUtilityToken,
     *   ShareOfLPToken...
     *  ]
     *
     **/
    function getUserTVLShare(address _user, uint256 _precision)
        external
        view
        override
        returns (uint256[] memory)
    {
        // precision is 3 by default
        if (_precision == 0) {
            _precision = 3;
        }

        // default to sender if no user is specified
        if (_user == address(0)) {
            _user = _msgSender();
        }

        uint256 _denominator = 10**(_precision.add(2));

        // for precision rounding
        _denominator = _denominator.mul(10);

        uint256[] memory _shares = new uint256[](activeTokens.length + 1);

        uint256 _sumWeight = 0;
        uint256 _sumShares = 0;

        for (uint256 i = 0; i < activeTokens.length; i++) {
            // calculate users percentage stakes
            uint256 _tokenShare;
            if (stakeableTokens[activeTokens[i]].totalValueLocked > 0) {
                _tokenShare = stakerUsers[_user]
                    .stakedAmount[activeTokens[i]]
                    .mul(_denominator)
                    .div(stakeableTokens[activeTokens[i]].totalValueLocked);
            }

            // check current weight of token
            uint256 _tokenWeight = stakeableTokens[activeTokens[i]].weight;
            // add current token weight to weight sum
            _sumWeight = _sumWeight.add(_tokenWeight);
            // add users current token share to share sum
            _sumShares = _sumShares.add(_tokenShare.mul(_tokenWeight));
            // add users percentage stakes of current token, including precision rounding
            _shares[i + 1] = _tokenShare.add(5).div(10);
        }

        // calculate final weighted average of user stakes
        _shares[0] = _sumShares.div(_sumWeight).add(5).div(10);

        return _shares;
    }

    /**
     * @dev Helper function to get the staked token amount
     *
     * @return uint256 staked amount of token
     **/
    function getUsersStakedAmountOfToken(address _user, address _token)
        external
        view
        override
        returns (uint256)
    {
        if (_token == zcxht) {
            return stakerUsers[_user].zcxhtStakedAmount;
        } else {
            return stakerUsers[_user].stakedAmount[_token];
        }
    }

    /**
     * @dev Helper function to fetch all existing data to an address
     *
     * @return array of token addresses
     * @return array of users staked amount for each token
     * @return ZCXHT staked amount
     **/
    function getUserData(address _user)
        external
        view
        override
        returns (
            address[] memory,
            uint256[] memory,
            uint256
        )
    {
        // init temporary array with token count
        uint256[] memory _userStakes = new uint256[](activeTokens.length);

        // loop through all known tokens
        for (uint8 i = 0; i < activeTokens.length; i++) {
            // get user stakes for active token
            _userStakes[i] = stakerUsers[_user].stakedAmount[activeTokens[i]];
        }

        // return active token stakes
        return (
            activeTokens,
            _userStakes,
            stakerUsers[_user].zcxhtStakedAmount
        );
    }

    /**
     * @dev Creates a list of active tokens, excluding inactive tokens
     *
     * @return address[] array of active stakeable token tokens
     **/
    function getActiveTokens() public view override returns (address[] memory) {
        return activeTokens;
    }

    /**
     * @dev Creates a list of active token weights, excluding inactive tokens
     *
     * @return weights uint256[] array including every active token weight
     * @return combinedWeight uint256 combined weight of all active tokens
     **/
    function getTokenWeights()
        external
        view
        override
        returns (uint256[] memory weights, uint256 combinedWeight)
    {
        // create new memory array at the size of the current token count
        weights = new uint256[](activeTokens.length);
        combinedWeight = combinedTokenWeight;
        // loop through maximum amount of allowed tokens
        for (uint8 i = 0; i < activeTokens.length; i++) {
            // add token to active token list
            weights[i] = stakeableTokens[activeTokens[i]].weight;
        }
    }

    /**
     * @dev  Returns all block number snapshots for an specific user and token
     *
     * @param _user Address of the user
     * @param _token Address of the token
     * @param _startBlock Start block to search for snapshots
     * @param _endBlock End block to search for snapshots
     *
     * @return snapshots snapshoted data grouped by stakes
     **/
    function getUserStakesSnapshots(
        address _user,
        address _token,
        uint256 _startBlock,
        uint256 _endBlock
    )
        external
        view
        override
        returns (SharedDataTypes.StakeSnapshot[] memory snapshots)
    {
        (, uint256 _index) = _findLastSavedBlock(
            stakerUsers[_user].stakedAmountKeys[_token],
            _startBlock
        );

        // read how many snapshots fits in the current startBlock-endBlok period
        uint256 numSnapshots;
        for (
            uint256 i = _index;
            i < stakerUsers[_user].stakedAmountKeys[_token].length &&
                stakerUsers[_user].stakedAmountKeys[_token][i] <= _endBlock;
            i++
        ) {
            numSnapshots++;
        }

        // create the snapshot array
        SharedDataTypes.StakeSnapshot[]
            memory _snapshot = new SharedDataTypes.StakeSnapshot[](
                numSnapshots
            );
        uint256 j = 0;
        for (
            uint256 i = _index;
            i < stakerUsers[_user].stakedAmountKeys[_token].length &&
                stakerUsers[_user].stakedAmountKeys[_token][i] <= _endBlock;
            i++
        ) {
            // calculate start block
            uint256 _snapshotBlock = stakerUsers[_user].stakedAmountKeys[
                _token
            ][i];
            _snapshot[j].startBlock = (_snapshotBlock < _startBlock)
                ? _startBlock
                : _snapshotBlock;
            // read staked amount
            _snapshot[j].stakedAmount = stakerUsers[_user]
                .stakedAmountSnapshots[_token][_snapshotBlock];
            j++;
        }

        // repeat the iteration to calculate endBlock and tokenTVL
        j = 0;
        for (
            uint256 i = _index;
            i < stakerUsers[_user].stakedAmountKeys[_token].length &&
                stakerUsers[_user].stakedAmountKeys[_token][i] <= _endBlock;
            i++
        ) {
            // If this is the last snapshoted block, we get the last reward
            // block. Else, we get the next initial block minus 1
            _snapshot[j].endBlock = (j == numSnapshots.sub(1))
                ? _endBlock
                : _snapshot[j.add(1)].startBlock.sub(1);
            // We read the token TVL at last block of this snapshotç
            _snapshot[j].tokenTVL = _getTVL(_snapshot[j].endBlock, _token);
            j++;
        }

        return _snapshot;
    }

    /**
     * @dev Helper function to get the current staked tokens of a user
     *
     * @return uint256[] array with amounts for every stakeable token
     **/
    function getUserStakes(address _user)
        external
        view
        override
        returns (uint256[] memory)
    {
        return getUserStakes(_user, block.number);
    }

    /**
     * @dev Helper function to get the staked tokens of a user on a block.number
     *
     * @return uint256[] array with amounts for every stakeable token
     **/
    function getUserStakes(address _user, uint256 _blocknumber)
        public
        view
        override
        returns (uint256[] memory)
    {
        // create in memory array with the size of existing active tokens
        uint256[] memory _userStakes = new uint256[](activeTokens.length);

        // loop through active tokens
        for (uint8 i = 0; i < activeTokens.length; i++) {
            // get user stakes for active token
            if (_blocknumber == block.number) {
                _userStakes[i] = stakerUsers[_user].stakedAmount[
                    activeTokens[i]
                ];
            } else {
                (uint256 _lastSavedBlock, ) = _findLastSavedBlock(
                    stakerUsers[_user].stakedAmountKeys[activeTokens[i]],
                    _blocknumber
                );
                if (_lastSavedBlock == 0) {
                    _userStakes[i] = 0;
                } else {
                    _userStakes[i] = stakerUsers[_user].stakedAmountSnapshots[
                        activeTokens[i]
                    ][_lastSavedBlock];
                }
            }
        }

        // return the data
        return _userStakes;
    }

    /* === MUTATING FUNCTIONS === */

    /**
     * @dev  Convenience function to stake zcx token
     * @param _amount Amount of tokens the user wants to stake
     *
     * @return the new amount of tokens staked
     **/
    function stake(uint256 _amount)
        external
        override
        whenNotPaused
        returns (uint256)
    {
        return _stake(activeTokens[0], _amount);
    }

    /**
     * @dev  Convenience function to stake lp token
     * @param _lpToken Address of token to stake
     * @param _amount Amount of tokens the user wants to stake
     *
     * @return the new amount of tokens staked
     **/
    function stake(address _lpToken, uint256 _amount)
        external
        override
        whenNotPaused
        returns (uint256)
    {
        return _stake(_lpToken, _amount);
    }

    /**
     * @dev  This allows users to actually add tokens to the staking pool
     *       and take part
     * @param _token Address of token to stake
     * @param _amount Amount of tokens the user wants to stake
     *
     * @return the new amount of tokens staked
     **/
    function _stake(address _token, uint256 _amount)
        internal
        returns (uint256)
    {
        require(isAllowedToken(_token), "INVALID_TOKEN");
        // transfer tokens
        SafeERC20.safeTransferFrom(
            IERC20(_token),
            _msgSender(),
            address(this),
            _amount
        );

        address _stakeToken = (_token == zcxht) ? activeTokens[0] : _token; // if stake zcxht, equal to stake zcx

        // get current user data
        SharedDataTypes.StakerUser storage _stakerUser = stakerUsers[
            _msgSender()
        ];

        // calculate new amount of user stakes
        uint256 _newStakedAmount = _stakerUser.stakedAmount[_stakeToken].add(
            _amount
        );

        uint256 _newTVL = stakeableTokens[_stakeToken].totalValueLocked.add(
            _amount
        );

        // check if holder token is staked
        if (_token == zcxht) {
            _stakerUser.zcxhtStakedAmount = _stakerUser.zcxhtStakedAmount.add(
                _amount
            );
        }

        _saveStakeInformation(
            _msgSender(),
            _stakeToken,
            _newStakedAmount,
            _newTVL
        );

        // shoot event
        emit TVLChange(_msgSender(), _stakeToken, _amount, true);

        // return users new holdings of token
        return _stakerUser.stakedAmount[_stakeToken];
    }

    /**
     * @dev  Convenience function to withdraw utility token
     * @param _amount optional value, if empty the total user stake will be used
     **/
    function withdraw(uint256 _amount)
        external
        override
        whenNotPaused
        returns (uint256)
    {
        return _withdraw(activeTokens[0], _amount);
    }

    /**
     * @dev  Convenience function to withdraw LP tokens
     * @param _lpToken Address of token to withdraw
     * @param _amount optional value, if empty the total user stake will be used
     **/
    function withdraw(address _lpToken, uint256 _amount)
        external
        override
        whenNotPaused
        returns (uint256)
    {
        return _withdraw(_lpToken, _amount);
    }

    /**
     * @dev  This allows users to unstake their tokens at any point of time
     *       and also leaves it open to the users how much will be unstaked
     * @param _token Address of token to withdraw
     * @param _amount optional value, if empty the total user stake will be used
     **/
    function _withdraw(address _token, uint256 _amount)
        internal
        returns (uint256)
    {
        require(_amount > 0, "CAN_NOT_WITHDRAW_ZERO");
        SharedDataTypes.StakerUser storage _stakerUser = stakerUsers[
            _msgSender()
        ];
        address _stakeToken = _token;
        uint256 _maxWithdrawable;
        if (_stakeToken == zcxht) {
            _stakeToken = activeTokens[0];
            _maxWithdrawable = _stakerUser.zcxhtStakedAmount;
        } else if (_stakeToken == activeTokens[0]) {
            _maxWithdrawable = _stakerUser.stakedAmount[_stakeToken].sub(
                _stakerUser.zcxhtStakedAmount
            );
        } else {
            _maxWithdrawable = _stakerUser.stakedAmount[_stakeToken];
        }
        require(_maxWithdrawable >= _amount, "AMOUNT_EXCEEDS_STAKED_BALANCE");
        SafeERC20.safeTransfer(IERC20(_token), _msgSender(), _amount); // calculate the new user stakes of the token
        uint256 _newStakedAmount = _stakerUser.stakedAmount[_stakeToken].sub(
            _amount
        );
        uint256 _newTVL = stakeableTokens[_stakeToken].totalValueLocked.sub(
            _amount
        );

        // DAO check, if available. Only applies to utility token withdrawals
        if (address(dao) != address(0) && _stakeToken == activeTokens[0]) {
            // get locked tokens of user (active votes)
            uint256 _lockedTokens = dao.getLockedTokenCount(_msgSender());
            // check that the user has enough unlocked tokens
            require(
                _stakerUser.stakedAmount[_stakeToken] >= _lockedTokens,
                "DAO_ALL_TOKENS_LOCKED"
            );
            require(
                _stakerUser.stakedAmount[_stakeToken].sub(_lockedTokens) >=
                    _amount,
                "DAO_TOKENS_LOCKED"
            );
        }

        _saveStakeInformation(
            _msgSender(),
            _stakeToken,
            _newStakedAmount,
            _newTVL
        );

        // check if holder token is withdrawn
        if (_token == zcxht) {
            _stakerUser.zcxhtStakedAmount = _stakerUser.zcxhtStakedAmount.sub(
                _amount
            );
        }
        // shoot event
        emit TVLChange(_msgSender(), _stakeToken, _amount, false);

        return _stakerUser.stakedAmount[_stakeToken];
    }

    /**
     * @dev  Checks if the token is whitelisted and active
     * @param _token address of token to check
     * @return bool Active status of checked token
     **/
    function isAllowedToken(address _token) public view returns (bool) {
        if (_token == address(0)) return false;
        return stakeableTokens[_token].active || _token == zcxht;
    }

    /**
     * @dev  Allows updating the utility token address that can be staked, in case
     *       of a token swap or similar event.
     * @param _token Address of new ERC20 token address
     **/
    function updateStakeToken(address _token) external onlyOwner {
        require(activeTokens[0] != _token, "SAME_ADDRESS");
        // deactive the old token
        stakeableTokens[activeTokens[0]].active = false;
        // cache the old weight
        uint256 weight = stakeableTokens[activeTokens[0]].weight;
        // assign the new address
        activeTokens[0] = _token;
        // update new token data with old settings
        stakeableTokens[activeTokens[0]].weight = weight;
        stakeableTokens[activeTokens[0]].active = true;
    }

    /**
     * @dev  Adds new token to whitelist
     * @param _token Address of new token
     * @param _weight Weight of new token
     **/
    function addToken(address _token, uint256 _weight) external onlyOwner {
        require(_token != address(0), "ZERO_ADDRESS");
        require(isAllowedToken(_token) == false, "EXISTS_ALREADY");

        // add token address to active token list
        activeTokens.push(_token);

        // set token weight
        stakeableTokens[_token].weight = _weight;
        // set token active
        stakeableTokens[_token].active = true;

        // add token weight to maximum weight helper
        combinedTokenWeight = combinedTokenWeight.add(_weight);
    }

    /**
     * @dev  Removes token from whitelist, if no tokens are locked
     * @param _token Address of token to remove
     **/
    function removeToken(address _token) external onlyOwner {
        require(isAllowedToken(_token) == true, "INVALID_TOKEN");
        require(stakeableTokens[_token].active, "INVALID_TOKEN");
        require(stakeableTokens[_token].totalValueLocked == 0, "LOCKED_ASSETS");

        // get token index
        uint256 _idx;
        for (uint256 i = 0; i < activeTokens.length; i++) {
            if (activeTokens[i] == _token) {
                _idx = i;
            }
        }

        // remove token weight from maximum weight helper
        combinedTokenWeight = combinedTokenWeight.sub(
            stakeableTokens[_token].weight
        );

        // reset token weight
        stakeableTokens[_token].weight = 0;

        // remove from active tokens list
        activeTokens[_idx] = activeTokens[activeTokens.length - 1];
        activeTokens.pop();
        // set token inactive
        stakeableTokens[_token].active = false;
    }

    function setHolderToken(address _zcxht) external onlyOwner {
        require(zcxht != _zcxht, "SAME_ADDRESS");
        zcxht = _zcxht;
    }

    /**
     * @dev  Allows to update the weight of a specific token
     * @param _token Address of the token
     * @param _newWeight new token weight
     **/
    function updateTokenWeight(address _token, uint256 _newWeight)
        external
        onlyOwner
    {
        require(_token != address(0), "ZERO_ADDRESS");
        require(_newWeight > 0, "NO_TOKEN_WEIGHT");
        // update token weight
        combinedTokenWeight = combinedTokenWeight
            .sub(stakeableTokens[_token].weight)
            .add(_newWeight);
        stakeableTokens[_token].weight = _newWeight;
    }

    /**
     * @dev  Allows updating the dao address, in case of an upgrade.
     * @param _newDAO Address of the new Unizen DAO contract
     **/
    function updateDAO(address _newDAO) external onlyOwner {
        require(address(dao) != _newDAO, "SAME_ADDRESS");
        dao = IUZV1DAO(_newDAO);
    }

    /* === INTERNAL FUNCTIONS === */

    /**
     * @dev Save staking information after stake or withdraw and make an
     * sanapshot
     *
     * @param _user user that makes the stake/withdraw
     * @param _token token where the stake/withdraw has been made
     * @param _newStakedAmount staked/withdrawn amount of tokens
     * @param _newTVL TVL of the token after the stake/withdraw
     */
    function _saveStakeInformation(
        address _user,
        address _token,
        uint256 _newStakedAmount,
        uint256 _newTVL
    ) internal {
        SharedDataTypes.StakerUser storage _stakerUser = stakerUsers[_user];

        // updated total stake of current user
        _stakerUser.stakedAmountSnapshots[_token][
            block.number
        ] = _newStakedAmount;
        if (
            (_stakerUser.stakedAmountKeys[_token].length == 0) ||
            _stakerUser.stakedAmountKeys[_token][
                _stakerUser.stakedAmountKeys[_token].length - 1
            ] !=
            block.number
        ) {
            _stakerUser.stakedAmountKeys[_token].push(block.number);
        }
        _stakerUser.stakedAmount[_token] = _newStakedAmount;

        // update tvl of token
        stakeableTokens[_token].totalValueLockedSnapshots[
            block.number
        ] = _newTVL;
        if (
            (stakeableTokens[_token].totalValueLockedKeys.length == 0) ||
            stakeableTokens[_token].totalValueLockedKeys[
                stakeableTokens[_token].totalValueLockedKeys.length - 1
            ] !=
            block.number
        ) {
            stakeableTokens[_token].totalValueLockedKeys.push(block.number);
        }
        stakeableTokens[_token].totalValueLocked = _newTVL;
    }

    /**
     * @dev Helper function to get the last saved block number in a block index array
     *
     * @return lastSavedBlock last block number stored in the block index array
     * @return index index of the last block number stored in the block index array
     **/
    function _findLastSavedBlock(
        uint256[] storage _blockKeys,
        uint256 _blockNumber
    ) internal view returns (uint256 lastSavedBlock, uint256 index) {
        uint256 _upperBound = Arrays.findUpperBound(
            _blockKeys,
            _blockNumber.add(1)
        );
        if (_upperBound == 0) {
            return (0, 0);
        } else {
            return (_blockKeys[_upperBound - 1], _upperBound - 1);
        }
    }

    /* === EVENTS === */
    event TVLChange(
        address indexed user,
        address indexed token,
        uint256 amount,
        bool indexed changeType
    );
}
