//SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "./ERC20.sol";
import "./IUniswapV2Pair.sol";

import "./UniswapLibrary.sol";
import "./IOracle.sol";
import "./ITokenManager.sol";
import "./IBondManager.sol";
import "./IEmissionManager.sol";
import "./SyntheticToken.sol";
import "./Operatable.sol";
import "./Migratable.sol";

/// TokenManager manages all tokens and their price data
contract TokenManager is ITokenManager, Operatable, Migratable {
    struct TokenData {
        SyntheticToken syntheticToken;
        ERC20 underlyingToken;
        IUniswapV2Pair pair;
        IOracle oracle;
    }

    /// Token data (key is synthetic token address)
    mapping(address => TokenData) public tokenIndex;
    /// A set of managed synthetic token addresses
    address[] public tokens;
    /// Addresses of contracts allowed to mint / burn synthetic tokens
    address[] tokenAdmins;
    /// Uniswap factory address
    address public immutable uniswapFactory;

    IBondManager public bondManager;
    IEmissionManager public emissionManager;

    // ------- Constructor ----------

    /// Creates a new Token Manager
    /// @param _uniswapFactory The address of the Uniswap Factory
    constructor(address _uniswapFactory) public {
        uniswapFactory = _uniswapFactory;
    }

    // ------- Modifiers ----------

    /// Fails if a token is not currently managed by Token Manager
    /// @param syntheticTokenAddress The address of the synthetic token
    modifier managedToken(address syntheticTokenAddress) {
        require(
            isManagedToken(syntheticTokenAddress),
            "TokenManager: Token is not managed"
        );
        _;
    }

    modifier initialized() {
        require(
            isInitialized(),
            "TokenManager: BondManager or EmissionManager is not initialized"
        );
        _;
    }

    modifier tokenAdmin() {
        require(
            isTokenAdmin(msg.sender),
            "TokenManager: Must be called by token admin"
        );
        _;
    }

    // ------- View ----------

    /// A set of synthetic tokens under management
    /// @dev Deleted tokens are still present in the array but with address(0)
    function allTokens() public view override returns (address[] memory) {
        return tokens;
    }

    /// Checks if the token is managed by Token Manager
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @return True if token is managed
    function isManagedToken(address syntheticTokenAddress)
        public
        view
        override
        returns (bool)
    {
        return
            address(tokenIndex[syntheticTokenAddress].syntheticToken) !=
            address(0);
    }

    /// Checks if token ownerships are valid
    /// @return True if ownerships are valid
    function validTokenPermissions() public view returns (bool) {
        for (uint32 i = 0; i < tokens.length; i++) {
            SyntheticToken token = SyntheticToken(tokens[i]);
            if (address(token) != address(0)) {
                if (token.operator() != address(this)) {
                    return false;
                }
                if (token.owner() != address(this)) {
                    return false;
                }
            }
        }
        return true;
    }

    /// Checks if prerequisites for starting using TokenManager are fulfilled
    function isInitialized() public view returns (bool) {
        return
            (address(bondManager) != address(0)) &&
            (address(emissionManager) != address(0));
    }

    /// All token admins allowed to mint / burn
    function allTokenAdmins() public view returns (address[] memory) {
        return tokenAdmins;
    }

    /// Check if address is token admin
    /// @param admin - address to check
    function isTokenAdmin(address admin) public view override returns (bool) {
        for (uint256 i = 0; i < tokenAdmins.length; i++) {
            if (tokenAdmins[i] == admin) {
                return true;
            }
        }
        return false;
    }

    /// Address of the underlying token
    /// @param syntheticTokenAddress The address of the synthetic token
    function underlyingToken(address syntheticTokenAddress)
        public
        view
        override
        managedToken(syntheticTokenAddress)
        returns (address)
    {
        return address(tokenIndex[syntheticTokenAddress].underlyingToken);
    }

    /// Average price of the synthetic token according to price oracle
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @param syntheticTokenAmount The amount to be priced
    /// @return The equivalent amount of the underlying token required to buy syntheticTokenAmount (average)
    /// @dev Fails if the token is not managed
    function averagePrice(
        address syntheticTokenAddress,
        uint256 syntheticTokenAmount
    )
        public
        view
        override
        managedToken(syntheticTokenAddress)
        returns (uint256)
    {
        IOracle oracle = tokenIndex[syntheticTokenAddress].oracle;
        return oracle.consult(syntheticTokenAddress, syntheticTokenAmount);
    }

    /// Current price of the synthetic token according to Uniswap
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @param syntheticTokenAmount The amount to be priced
    /// @return The equivalent amount of the underlying token required to buy syntheticTokenAmount
    /// @dev Fails if the token is not managed
    function currentPrice(
        address syntheticTokenAddress,
        uint256 syntheticTokenAmount
    )
        public
        view
        override
        managedToken(syntheticTokenAddress)
        returns (uint256)
    {
        address underlyingTokenAddress =
            address(tokenIndex[syntheticTokenAddress].underlyingToken);
        (uint256 syntheticReserve, uint256 undelyingReserve) =
            UniswapLibrary.getReserves(
                uniswapFactory,
                syntheticTokenAddress,
                underlyingTokenAddress
            );
        return
            UniswapLibrary.quote(
                syntheticTokenAmount,
                syntheticReserve,
                undelyingReserve
            );
    }

    /// Get one synthetic unit
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @return one unit of the synthetic asset
    function oneSyntheticUnit(address syntheticTokenAddress)
        public
        view
        override
        managedToken(syntheticTokenAddress)
        returns (uint256)
    {
        SyntheticToken synToken =
            SyntheticToken(tokenIndex[syntheticTokenAddress].syntheticToken);
        return uint256(10)**synToken.decimals();
    }

    /// Get one underlying unit
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @return one unit of the underlying asset
    function oneUnderlyingUnit(address syntheticTokenAddress)
        public
        view
        override
        managedToken(syntheticTokenAddress)
        returns (uint256)
    {
        ERC20 undToken = tokenIndex[syntheticTokenAddress].underlyingToken;
        return uint256(10)**undToken.decimals();
    }

    // ------- External --------------------

    /// Update oracle price
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @dev This modifier must always come with managedToken and oncePerBlock
    function updateOracle(address syntheticTokenAddress)
        public
        override
        managedToken(syntheticTokenAddress)
    {
        IOracle oracle = tokenIndex[syntheticTokenAddress].oracle;
        try oracle.update() {} catch {}
    }

    // ------- External, Owner ----------

    function addTokenAdmin(address admin) public onlyOwner {
        _addTokenAdmin(admin);
    }

    function deleteTokenAdmin(address admin) public onlyOwner {
        _deleteTokenAdmin(admin);
    }

    // ------- External, Operator ----------

    /// Adds token to managed tokens
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @param bondTokenAddress The address of the bond token
    /// @param underlyingTokenAddress The address of the underlying token
    /// @param oracleAddress The address of the price oracle for the pair
    /// @dev Requires the operator and the owner of the synthetic token to be set to TokenManager address before calling
    function addToken(
        address syntheticTokenAddress,
        address bondTokenAddress,
        address underlyingTokenAddress,
        address oracleAddress
    ) external onlyOperator initialized {
        require(
            syntheticTokenAddress != underlyingTokenAddress,
            "TokenManager: Synthetic token and Underlying tokens must be different"
        );
        require(
            !isManagedToken(syntheticTokenAddress),
            "TokenManager: Token is already managed"
        );
        SyntheticToken syntheticToken = SyntheticToken(syntheticTokenAddress);
        SyntheticToken bondToken = SyntheticToken(bondTokenAddress);
        ERC20 underlyingTkn = ERC20(underlyingTokenAddress);
        IOracle oracle = IOracle(oracleAddress);
        IUniswapV2Pair pair =
            IUniswapV2Pair(
                UniswapLibrary.pairFor(
                    uniswapFactory,
                    syntheticTokenAddress,
                    underlyingTokenAddress
                )
            );
        require(
            syntheticToken.decimals() == bondToken.decimals(),
            "TokenManager: Synthetic and Bond tokens must have the same number of decimals"
        );

        require(
            address(oracle.pair()) == address(pair),
            "TokenManager: Tokens and Oracle tokens are different"
        );
        TokenData memory tokenData =
            TokenData(syntheticToken, underlyingTkn, pair, oracle);
        tokenIndex[syntheticTokenAddress] = tokenData;
        tokens.push(syntheticTokenAddress);
        bondManager.addBondToken(syntheticTokenAddress, bondTokenAddress);
        emit TokenAdded(
            syntheticTokenAddress,
            underlyingTokenAddress,
            address(oracle),
            address(pair)
        );
    }

    /// Removes token from managed, transfers its operator and owner to target address
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @param newOperator The operator and owner of the token will be transferred to this address.
    /// @dev Fails if the token is not managed
    function deleteToken(address syntheticTokenAddress, address newOperator)
        external
        managedToken(syntheticTokenAddress)
        onlyOperator
        initialized
    {
        bondManager.deleteBondToken(syntheticTokenAddress, newOperator);
        uint256 pos;
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == syntheticTokenAddress) {
                pos = i;
            }
        }
        TokenData memory data = tokenIndex[tokens[pos]];
        data.syntheticToken.transferOperator(newOperator);
        data.syntheticToken.transferOwnership(newOperator);
        delete tokenIndex[syntheticTokenAddress];
        delete tokens[pos];
        emit TokenDeleted(
            syntheticTokenAddress,
            address(data.underlyingToken),
            address(data.oracle),
            address(data.pair)
        );
    }

    /// Burns synthetic token from the owner
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @param owner Owner of the tokens to burn
    /// @param amount Amount to burn
    function burnSyntheticFrom(
        address syntheticTokenAddress,
        address owner,
        uint256 amount
    )
        public
        override
        managedToken(syntheticTokenAddress)
        initialized
        tokenAdmin
    {
        SyntheticToken token = tokenIndex[syntheticTokenAddress].syntheticToken;
        token.burnFrom(owner, amount);
    }

    /// Mints synthetic token
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @param receiver Address to receive minted token
    /// @param amount Amount to mint
    function mintSynthetic(
        address syntheticTokenAddress,
        address receiver,
        uint256 amount
    )
        public
        override
        managedToken(syntheticTokenAddress)
        initialized
        tokenAdmin
    {
        SyntheticToken token = tokenIndex[syntheticTokenAddress].syntheticToken;
        token.mint(receiver, amount);
    }

    // --------- Operator -----------

    /// Updates bond manager address
    /// @param _bondManager new bond manager
    function setBondManager(address _bondManager) public onlyOperator {
        require(
            address(bondManager) != _bondManager,
            "TokenManager: bondManager with this address already set"
        );
        deleteTokenAdmin(address(bondManager));
        addTokenAdmin(_bondManager);
        bondManager = IBondManager(_bondManager);
        emit BondManagerChanged(msg.sender, _bondManager);
    }

    /// Updates emission manager address
    /// @param _emissionManager new emission manager
    function setEmissionManager(address _emissionManager) public onlyOperator {
        require(
            address(emissionManager) != _emissionManager,
            "TokenManager: emissionManager with this address already set"
        );
        deleteTokenAdmin(address(emissionManager));
        addTokenAdmin(_emissionManager);
        emissionManager = IEmissionManager(_emissionManager);
        emit EmissionManagerChanged(msg.sender, _emissionManager);
    }

    /// Updates oracle for synthetic token address
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @param oracleAddress new oracle address
    function setOracle(address syntheticTokenAddress, address oracleAddress)
        public
        onlyOperator
        managedToken(syntheticTokenAddress)
    {
        IOracle oracle = IOracle(oracleAddress);
        require(
            oracle.pair() == tokenIndex[syntheticTokenAddress].pair,
            "TokenManager: Tokens and Oracle tokens are different"
        );
        tokenIndex[syntheticTokenAddress].oracle = oracle;
        emit OracleUpdated(msg.sender, syntheticTokenAddress, oracleAddress);
    }

    // ------- Internal ----------

    function _addTokenAdmin(address admin) internal {
        if (isTokenAdmin(admin)) {
            return;
        }
        tokenAdmins.push(admin);
        emit TokenAdminAdded(msg.sender, admin);
    }

    function _deleteTokenAdmin(address admin) internal {
        for (uint256 i = 0; i < tokenAdmins.length; i++) {
            if (tokenAdmins[i] == admin) {
                delete tokenAdmins[i];
                emit TokenAdminDeleted(msg.sender, admin);
            }
        }
    }

    // ------- Events ----------

    /// Emitted each time the token becomes managed
    event TokenAdded(
        address indexed syntheticTokenAddress,
        address indexed underlyingTokenAddress,
        address oracleAddress,
        address pairAddress
    );
    /// Emitted each time the token becomes unmanaged
    event TokenDeleted(
        address indexed syntheticTokenAddress,
        address indexed underlyingTokenAddress,
        address oracleAddress,
        address pairAddress
    );
    /// Emitted each time Oracle is updated
    event OracleUpdated(
        address indexed operator,
        address indexed syntheticTokenAddress,
        address oracleAddress
    );
    /// Emitted each time BondManager is updated
    event BondManagerChanged(address indexed operator, address newManager);
    /// Emitted each time EmissionManager is updated
    event EmissionManagerChanged(address indexed operator, address newManager);
    /// Emitted when migrated
    event Migrated(address indexed operator, address target);
    event TokenAdminAdded(address indexed operator, address admin);
    event TokenAdminDeleted(address indexed operator, address admin);
}
