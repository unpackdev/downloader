// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

import "./ModuleBaseWithFee.sol";

/**
 * @title                   PrimeDeals Token Swap Module
 * @notice                  Smart contract to handle token swap
                            interactions for PrimeDeals
 */
contract TokenSwapModule is ModuleBaseWithFee {
    uint32 public lastDealId;
    // mapping of token swaps where the key is a dealId
    mapping(uint32 => TokenSwap) public tokenSwaps;
    /// Metadata => deal ID
    mapping(bytes32 => uint32) public metadataToDealId;

    /**
     * @dev
     * pathFrom Description:
     * Used to storing how many tokens does each DAO send to the module
     *
     * Example on how the values are stored:
     * token -> DAO -> amount
     * [[123, 0, 123], [0, 123, 0]]
     * token 1: DAO 1 sends 123, DAO 2 sends 0, DAO 3 sends 123, etc.
     *
     * pathTo Description:
     * Used for storing how many tokens does each DAO receive from the module
     * includes vesting. For each DAO there is a tuple of four values:
     * instant amount, vested amount, vesting cliff, vesting duration.
     * The start time will be the block.timestamp when executing the deal.
     * This timestamp + vestingDuration can be used to calculate the vesting end.
     *
     * Example on how the values are stored:
     * token -> DAO -> tuple(4)
     * [[instantAmount_dao1, vestedAmount_dao1, vestingCliff_dao1,
     * vestingDuration_dao1, instantAmount_dao2, ...], [...]]
     */
    struct TokenSwap {
        /// The participating DAOs
        address[] daos;
        /// The tokens involved in the swap
        address[] tokens;
        /// The token flow from the DAOs to the module, see above
        uint256[][] pathFrom;
        /// The token flow from the module to the DAO, see above
        uint256[][] pathTo;
        /// Amount of time in seconds the token swap can be executed
        uint32 deadline;
        /// Unix timestamp of the execution
        uint32 executionDate;
        /// Hash of the deal information.
        bytes32 metadata;
        // boolean to check if the deal has been executed
        bool isExecuted;
    }

    /**
     * @notice              This event is emitted when a token swap is created
     * @param module        Address of this module
     * @param dealId        Deal id for the created token swap
     * @param metadata      Unique ID that is generated throught the Prime Deals frontend
     * @param daos          Array containing the DAOs that are involed in creating the token swap
     * @param tokens        Array containing the tokens that are involed in creating the token swap
     * @param pathFrom      Two-dimensional array containing the tokens flowing from the
                            DAOs into the module
     * @param pathTo        Two-dimensional array containing the tokens flowing from the
                            module to the DAOs
     * @param deadline      The amount of time between the creation of the swap and the time when
                            it can no longer be executed, in seconds
     */
    event TokenSwapCreated(
        address indexed module,
        uint32 indexed dealId,
        bytes32 indexed metadata,
        address[] daos,
        address[] tokens,
        uint256[][] pathFrom,
        uint256[][] pathTo,
        uint32 deadline
    );

    /**
     * @notice              This event is emitted when a token swap is executed
     * @param module        Address of this module
     * @param dealId        Deal id for the executed token swap
     * @param metadata      Unique ID that is generated throught the Prime Deals frontend
     */
    event TokenSwapExecuted(
        address indexed module,
        uint32 indexed dealId,
        bytes32 indexed metadata
    );

    // solhint-disable-next-line no-empty-blocks
    constructor(address _dealManager) ModuleBaseWithFee(_dealManager) {}

    /**
      * @notice             Creates a new token swap action
      * @param _daos        Array containing the DAOs that are involed in this action
      * @param _tokens      Array containing the tokens that are involed in this action
      * @param _pathFrom    Two-dimensional array containing the tokens flowing from the
                            DAOs into the module:
                              - First array level is for each token
                              - Second array level is for each dao
                              - Detailed overview on how to configure the array can be found at the
                                TokenSwap struct description
      * @param _pathTo      Two-dimensional array containing the tokens flowing from the
                            module to the DAOs:
                              - First array level is for each token
                              - Second array level is for each dao
                              - Detailed overview on how to configure the array can be found at the
                                TokenSwap struct description
      * @param _metadata    Unique ID that is generated throught the Prime Deals frontend
      * @param _deadline    The amount of time between the creation of the swap and the time when
                            it can no longer be executed, in seconds
      * @return uint32      The dealId of the new token swap
    */
    function _createSwap(
        address[] memory _daos,
        address[] memory _tokens,
        uint256[][] memory _pathFrom,
        uint256[][] memory _pathTo,
        bytes32 _metadata,
        uint32 _deadline
    ) internal returns (uint32) {
        require(_metadata != "", "TokenSwapModule: Error 101");
        require(_metadataDoesNotExist(_metadata), "TokenSwapModule: Error 203");
        require(_daos.length >= 2, "TokenSwapModule: Error 204");
        require(_tokens.length != 0, "TokenSwapModule: Error 205");
        require(_deadline != 0, "TokenSwapModule: Error 101");

        // Check outer arrays
        uint256 pathFromLen = _pathFrom.length;
        require(
            _tokens.length == pathFromLen && pathFromLen == _pathTo.length,
            "TokenSwapModule: Error 102"
        );

        // Check duplicate token addresses
        for (uint256 i; i < _tokens.length; ++i) {
            for (uint256 j = i + 1; j < _tokens.length; ++j)
                require(_tokens[i] != _tokens[j], "TokenSwapModule: Error 104");
        }

        // Check inner arrays
        uint256 daosLen = _daos.length;
        for (uint256 i; i < pathFromLen; ++i) {
            require(
                _pathFrom[i].length == daosLen &&
                    _pathTo[i].length == daosLen << 2,
                "TokenSwapModule: Error 102"
            );
        }

        TokenSwap memory ts = TokenSwap(
            _daos,
            _tokens,
            _pathFrom,
            _pathTo,
            // solhint-disable-next-line not-rely-on-time
            uint32(block.timestamp) + _deadline,
            0,
            _metadata,
            false
        );

        ++lastDealId;

        tokenSwaps[lastDealId] = ts;

        metadataToDealId[_metadata] = lastDealId;

        emit TokenSwapCreated(
            address(this),
            lastDealId,
            _metadata,
            _daos,
            _tokens,
            _pathFrom,
            _pathTo,
            _deadline
        );
        return lastDealId;
    }

    /**
      * @notice             Create a new token swap action and automatically
                            creates Dao Deposit Manager for each DAO that does not have one
      * @param _daos        Array containing the DAOs that are involed in this action
      * @param _tokens      Array containing the tokens that are involed in this action
      * @param _pathFrom    Two-dimensional array containing the tokens flowing from the
                            DAOs into the module:
                              - First array level is for each token
                              - Second array level is for each dao
                              - Detailed overview on how to configure the array can be found at the
                                TokenSwap struct description
      * @param _pathTo      Two-dimensional array containing the tokens flowing from the
                            module to the DAOs:
                              - First array level is for each token
                              - Second array level is for each dao
                              - Detailed overview on how to configure the array can be found at the
                                TokenSwap struct description
      * @param _metadata    Unique ID that is generated throught the Prime Deals frontend
      * @param _deadline    The amount of time between the creation of the swap and the time when
                            it can no longer be executed, in seconds
      * @return uin32       The dealId of the new token swap
    */
    function createSwap(
        address[] calldata _daos,
        address[] calldata _tokens,
        uint256[][] calldata _pathFrom,
        uint256[][] calldata _pathTo,
        bytes32 _metadata,
        uint32 _deadline
    ) external returns (uint32) {
        for (uint256 i; i < _daos.length; ++i) {
            address dao = _daos[i];
            if (!dealManager.hasDaoDepositManager(dao)) {
                dealManager.createDaoDepositManager(dao);
            }
        }
        return (
            _createSwap(
                _daos,
                _tokens,
                _pathFrom,
                _pathTo,
                _metadata,
                _deadline
            )
        );
    }

    /**
      * @notice             Checks whether a token swap action can be executed, which is the case
                            if all DAOs have deposited
      * @param _dealId      The dealId of the action (key to the mapping)
      * @return bool        A bool flag indiciating whether the action can be executed
    */
    function checkExecutability(uint32 _dealId)
        public
        view
        validDealId(_dealId)
        returns (bool)
    {
        TokenSwap memory ts = tokenSwaps[_dealId];
        if (hasDealExpired(_dealId)) {
            return false;
        }

        address[] memory t = ts.tokens;
        uint256 tokenArrayLength = t.length;
        for (uint256 i; i < tokenArrayLength; ++i) {
            uint256[] memory p = ts.pathFrom[i];
            uint256 pathArrayLength = p.length;
            for (uint256 j; j < pathArrayLength; ++j) {
                if (p[j] == 0) {
                    continue;
                }
                // for each token and each pathFrom entry for this
                // token, check whether the corresponding DAO
                // has deposited the corresponding amount into their
                // deposit contract
                uint256 bal = IDaoDepositManager(
                    dealManager.getDaoDepositManager(ts.daos[j])
                ).getAvailableDealBalance(address(this), _dealId, t[i]);
                if (bal < p[j]) {
                    return false;
                }
            }
        }
        return true;
    }

    /**
     * @notice              Executes a token swap action
     * @param _dealId       The dealId of the action (key to the mapping)
     */
    function executeSwap(uint32 _dealId)
        external
        validDealId(_dealId)
        isNotExecuted(_dealId)
    {
        TokenSwap storage ts = tokenSwaps[_dealId];

        require(checkExecutability(_dealId), "TokenSwapModule: Error 265");

        // set to true directly before we touch any tokens
        // to prevent any reentrancies from happening
        ts.isExecuted = true;
        // solhint-disable-next-line not-rely-on-time
        ts.executionDate = uint32(block.timestamp);

        // transfer the tokens from the deposit manager of the DAOs
        // into this module
        uint256[] memory amountsIn = _pullTokensIntoModule(
            _dealId,
            ts.daos,
            ts.tokens,
            ts.pathFrom
        );

        // distribute the tokens from this module to the DAOs
        // and (if applicable) and their vesting contracts
        uint256[] memory amountsOut = _distributeTokens(ts, _dealId);

        // verify whether the amounts being pulled and pushed match
        uint256 tokenArrayLength = ts.tokens.length;
        for (uint256 i; i < tokenArrayLength; ++i) {
            require(
                amountsIn[i] == amountsOut[i],
                "TokenSwapModule: Error 103"
            );
        }

        emit TokenSwapExecuted(address(this), _dealId, ts.metadata);
    }

    /**
      * @notice             Distributes the tokens based on the supplied information to the DAOs
                            or their vesting contracts
      * @param _ts          TokenSwap object containing all the information of the action
      * @param _dealId      The dealId of the action (key to the mapping)
      * @return amountsOut  The two min values for the token amounts _ts
    */
    function _distributeTokens(TokenSwap memory _ts, uint32 _dealId)
        internal
        returns (uint256[] memory amountsOut)
    {
        amountsOut = new uint256[](_ts.tokens.length);
        // Distribute tokens from the module
        uint256 tokenArrayLength = _ts.tokens.length;
        for (uint256 i; i < tokenArrayLength; ++i) {
            uint256[] memory pt = _ts.pathTo[i];
            address token = _ts.tokens[i];
            uint256 pathArrayLength = pt.length >> 2;
            for (uint256 k; k < pathArrayLength; ++k) {
                // every 4 values, the values for a new dao start
                // value 0 = instant amount
                // value 1 = vested amount
                // value 2 = vesting cliff
                // value 3 = vesting duration
                uint256 instant = pt[k << 2];
                uint256 vested = pt[(k << 2) + 1];

                if (instant > 0) {
                    amountsOut[i] += instant;
                    _transferWithFee(token, _ts.daos[k], instant);
                }

                if (vested > 0) {
                    amountsOut[i] += vested;
                    uint256 amount = _payFeeAndReturnRemainder(token, vested);
                    address daoDepositManager = dealManager
                        .getDaoDepositManager(_ts.daos[k]);
                    if (token != address(0)) {
                        _approveDaoDepositManager(token, _ts.daos[k], amount);
                    }

                    uint256 callValue = token == address(0) ? amount : 0;
                    IDaoDepositManager(daoDepositManager).startVesting{
                        value: callValue
                    }(
                        _dealId,
                        token,
                        amount, // amount
                        uint32(pt[(k << 2) + 2]), // cliff
                        uint32(pt[(k << 2) + 3]) // duration
                    );
                }
            }
        }
    }

    /**
     * @notice              Returns the TokenSwap struct associated with the metadata
     * @param _metadata     Unique ID that is generated throught the Prime Deals frontend
     * @return swap         Token swap struct associated with the metadata
     */
    function getTokenswapFromMetadata(bytes32 _metadata)
        public
        view
        returns (TokenSwap memory swap)
    {
        return tokenSwaps[metadataToDealId[_metadata]];
    }

    /**
     * @notice              Checks if the deal has been expired
     * @param _dealId       The dealId of the action (key to the mapping)
     * @return bool         A bool flag indiciating whether token swap has expired
     */
    function hasDealExpired(uint32 _dealId)
        public
        view
        override
        validDealId(_dealId)
        returns (bool)
    {
        TokenSwap memory swap = tokenSwaps[_dealId];
        return
            swap.isExecuted ||
            // solhint-disable-next-line not-rely-on-time
            swap.deadline < uint32(block.timestamp);
    }

    /**
     * @notice              Checks if the given metadata is Unique, and not already used
     * @param _metadata     Unique ID that is generated throught the Prime Deals frontend
     * @return bool         A bool flag indiciating whether the metadata is unique
     */
    function _metadataDoesNotExist(bytes32 _metadata)
        internal
        view
        returns (bool)
    {
        TokenSwap memory ts = getTokenswapFromMetadata(_metadata);
        return ts.metadata == 0;
    }

    /**
     * @notice              Modifier that validates if the given deal ID is valid
     * @param _dealId       The dealId of the action (key to the mapping)
     */
    modifier validDealId(uint32 _dealId) {
        require(
            tokenSwaps[_dealId].metadata != 0,
            "TokenSwapModule: Error 207"
        );
        _;
    }

    /**
     * @notice              Modifier that validates if token swap has not been executed
     * @param _dealId       The dealId of the action (key to the mapping)
     */
    modifier isNotExecuted(uint32 _dealId) {
        require(!tokenSwaps[_dealId].isExecuted, "TokenSwapModule: Error 266");
        _;
    }

    fallback() external payable {}

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}
