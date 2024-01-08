// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./AccessControl.sol";
import "./ECDSA.sol";
import "./ITokenERC20.sol";

/**
 * @notice Bridge to swap tokens between several blockchain by create vrs by validator
 * @dev instance of this bridge must exist on all networks between which you want to swap
 */
contract Bridge is AccessControl {
    using ECDSA for bytes32;

    enum SwapState {
        EMPTY,
        SWAPPED,
        REDEEMED
    }

    struct Swap {
        uint256 nonce;
        SwapState state;
    }

    struct TokenInfo {
        address tokenAddress;
        string symbol;
    }

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");

    /// @notice get token structure by symbol
    mapping(string => TokenInfo) public tokenBySymbol;

    /**
     * @notice get boolean of chain state by id
     * @return state - state of chain
     */
    mapping(uint256 => bool) public isChainActiveById;

    /// @notice get swap structure by hash
    mapping(bytes32 => Swap) public swapByHash;

    /**
     * @notice array with all token symbols
     * @return array of symbols
     */
    string[] public tokenSymbols;

    /**
     * @notice event emitting with swap
     * @param initiator - address of user who call redeem method
     * @param recipient - address of user who get tokens
     * @param initTimestamp - timestamp of block when redeem was created
     * @param amount - amount of tokens
     * @param chainFrom - chain id where tokens swap from
     * @param chainTo - chain id where tokens swap to
     * @param nonce - id of swap
     * @param symbol - symbol of token
     */
    event SwapInitialized(
        address indexed initiator,
        address recipient,
        uint256 initTimestamp,
        uint256 amount,
        uint256 chainFrom,
        uint256 chainTo,
        uint256 nonce,
        string symbol
    );

    /**
     * @notice event emitting with redeem
     * @param initiator - address of user who call redeem method
     * @param recipient - address of user who get tokens
     * @param initTimestamp - timestamp of block when redeem was created
     * @param amount - amount of tokens
     * @param chainFrom - chain id where tokens swap from
     * @param chainTo - chain id where tokens swap to
     * @param nonce - id of swap
     * @param symbol - symbol of token
     */
    event SwapRedeemed(
        address indexed initiator,
        address recipient,
        uint256 initTimestamp,
        uint256 amount,
        uint256 chainFrom,
        uint256 chainTo,
        uint256 nonce,
        string symbol
    );

    /**
     * @notice constructor
     * @dev use real id of blockchain, for example 4 for rinkeby, 97 for bsc testnet etc
     */
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    }

    /**
     * @notice add or update chain to chain map, activate or deactivate chain by id
     * @dev use real id of blockchain in map, for example 4 for rinkeby, 97 for bsc testnet etc
     * @param _chainId - id of blockchain to update
     * @param _isActive - new state of chain
     */
    function updateChainById(uint256 _chainId, bool _isActive)
        external
        onlyRole(ADMIN_ROLE)
    {
        isChainActiveById[_chainId] = _isActive;
    }

    /**
     * @notice add token (to token_list) which can be swapped
     * @dev you should have admin role to execute this method
     * @param _symbol - symbol of token which you want to add
     * @param _tokenAddress - address of token which you want to add
     */
    function includeToken(string memory _symbol, address _tokenAddress)
        external
        onlyRole(ADMIN_ROLE)
    {
        tokenBySymbol[_symbol] = TokenInfo({
            tokenAddress: _tokenAddress,
            symbol: _symbol
        });
        tokenSymbols.push(_symbol);
    }

    /**
     * @notice remove token (from token_list) which can be swapped
     * @dev you should have admin role to execute this method
     * @param _symbol - symbol of token which you want to add
     */
    function excludeToken(string memory _symbol) external onlyRole(ADMIN_ROLE) {
        delete tokenBySymbol[_symbol];
        bytes32 symbol = keccak256(abi.encodePacked(_symbol));
        for (uint256 i; i < tokenSymbols.length; i++) {
            if (keccak256(abi.encodePacked(tokenSymbols[i])) == symbol) {
                tokenSymbols[i] = tokenSymbols[tokenSymbols.length - 1];
                tokenSymbols.pop();
            }
        }
    }

    /**
     * @notice init swap and create event
     * @dev you can get arguments for redeem from event of swap
     * @param _recipient - The address of recipient of tokens in target chain
     * @param _symbol - The symbol of swap token
     * @param _amount - amount of tokens
     * @param _chainTo - chain id where tokens swap to
     * @param _nonce - unique id of swap
     */
    function swap(
        address _recipient,
        uint256 _amount,
        uint256 _chainTo,
        uint256 _nonce,
        string memory _symbol
    ) external {
        uint256 chainFrom_ = getChainID();
        require(
            _chainTo != chainFrom_,
            "Bridge: Invalid chainTo is same with current bridge chain"
        );

        require(
            isChainActiveById[_chainTo],
            "Bridge: Destination chain is not active"
        );

        bytes32 hash_ = keccak256(
            abi.encodePacked(
                _recipient,
                _amount,
                chainFrom_,
                _chainTo,
                _nonce,
                _symbol
            )
        );
        require(
            swapByHash[hash_].state == SwapState.EMPTY,
            "Bridge: Swap with given params already exists"
        );

        TokenInfo memory token = tokenBySymbol[_symbol];
        require(
            token.tokenAddress != address(0),
            "Bridge: Token does not exist"
        );

        ITokenERC20(token.tokenAddress).burn(msg.sender, _amount);

        swapByHash[hash_] = Swap({nonce: _nonce, state: SwapState.SWAPPED});

        emit SwapInitialized(
            msg.sender,
            _recipient,
            block.timestamp,
            _amount,
            chainFrom_,
            _chainTo,
            _nonce,
            _symbol
        );
    }

    /**
     * @notice you get tokens if you have vrs
     * @dev all arguments except v, r and s, comes from swap event
     * @param _recipient - The address of recipient of tokens in target chain
     * @param _symbol - The symbol of swap token
     * @param _amount - amount of tokens
     * @param _chainFrom - chain id where tokens swap from
     * @param _nonce - unique id of swap
     * @param _signature - signature
     */
    function redeem(
        address _recipient,
        uint256 _amount,
        uint256 _chainFrom,
        uint256 _nonce,
        string memory _symbol,
        bytes calldata _signature
    ) external {
        uint256 chainTo_ = getChainID();

        require(
            _chainFrom != chainTo_,
            "Bridge: Invalid chainFrom is same with current bridge chain"
        );

        require(
            isChainActiveById[_chainFrom],
            "Bridge: Initial chain is not active"
        );

        bytes32 hash_ = keccak256(
            abi.encodePacked(
                _recipient,
                _amount,
                _chainFrom,
                chainTo_,
                _nonce,
                _symbol
            )
        ).toEthSignedMessageHash();
        require(
            swapByHash[hash_].state == SwapState.EMPTY,
            "Bridge: Redeem with given params already exists"
        );

        address validatorAddress_ = hash_.recover(_signature);
        require(
            hasRole(VALIDATOR_ROLE, validatorAddress_),
            "Bridge: Validator address isn't correct"
        );

        TokenInfo memory token = tokenBySymbol[_symbol];
        require(
            token.tokenAddress != address(0),
            "Bridge: Token does not exist"
        );

        ITokenERC20(token.tokenAddress).mint(_recipient, _amount);

        swapByHash[hash_] = Swap({nonce: _nonce, state: SwapState.REDEEMED});

        emit SwapRedeemed(
            msg.sender,
            _recipient,
            block.timestamp,
            _amount,
            _chainFrom,
            chainTo_,
            _nonce,
            _symbol
        );
    }

    /**
     *@dev withdraw token to sender by token address, if sender is admin
     *@param token address token
     *@param amount amount
     */
    function withdrawToken(address token, uint256 amount)
        external
        onlyRole(ADMIN_ROLE)
    {
        ITokenERC20(token).transfer(msg.sender, amount);
    }

    function getSwapState(bytes32 _txHash) external view returns (uint256) {
        return uint256(swapByHash[_txHash].state);
    }

    /**
     * @notice get token list, which have addresses, symbols and state of all tokens
     * @return TokenInfo[] - array of structs of tokens, which have tokenAddress, symbol and state
     */
    function getTokenList() external view returns (TokenInfo[] memory) {
        TokenInfo[] memory tokens = new TokenInfo[](tokenSymbols.length);
        for (uint256 i = 0; i < tokenSymbols.length; i++) {
            tokens[i] = tokenBySymbol[tokenSymbols[i]];
        }
        return tokens;
    }

    function getChainID() public view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }
}
