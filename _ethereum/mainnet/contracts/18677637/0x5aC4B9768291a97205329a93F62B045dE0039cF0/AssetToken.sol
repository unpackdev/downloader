// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC20.sol";
import "./ReentrancyGuard.sol";
import "./IAssetTokenData.sol";

/// @author Swarm Markets
/// @title AssetToken
/// @notice Main Asset Token Contract
contract AssetToken is ERC20, ReentrancyGuard {
    /// @dev Used to check access to functions as a kindof modifiers
    uint256 private constant ACTIVE_CONTRACT = 1 << 0;
    uint256 private constant UNFROZEN_CONTRACT = 1 << 1;
    uint256 private constant ONLY_ISSUER = 1 << 2;
    uint256 private constant ONLY_ISSUER_OR_GUARDIAN = 1 << 3;
    uint256 private constant ONLY_ISSUER_OR_AGENT = 1 << 4;

    uint8 private immutable _decimals;

    /// @dev This is a WAD on DSMATH representing 1
    uint256 public constant DECIMALS = 10 ** 18;
    /// @dev This is a proportion of 1 representing 100%, equal to a WAD
    uint256 public constant HUNDRED_PERCENT = 10 ** 18;

    /// @notice AssetTokenData Address
    address public assetTokenDataAddress;

    /// @notice Structure to hold the Mint Requests
    struct MintRequest {
        address destination;
        uint256 amount;
        string referenceTo;
        bool completed;
    }
    /// @notice Mint Requests mapping and last ID
    mapping(uint256 => MintRequest) public mintRequests;
    uint256 public mintRequestID;

    /// @notice Structure to hold the Redemption Requests
    struct RedemptionRequest {
        address sender;
        string receipt;
        uint256 assetTokenAmount;
        uint256 underlyingAssetAmount;
        bool completed;
        bool fromStake;
        string approveTxID;
        address canceledBy;
    }
    /// @notice Redemption Requests mapping and last ID
    mapping(uint256 => RedemptionRequest) public redemptionRequests;
    uint256 public redemptionRequestID;

    /// @notice stakedRedemptionRequests is map from requester to request ID
    /// @notice exists to detect that sender already has request from stake function
    mapping(address => uint256) public stakedRedemptionRequests;

    /// @notice mapping to hold each user safeguardStake amoun
    mapping(address => uint256) public safeguardStakes;

    /// @notice sum of the total stakes amounts
    uint256 public totalStakes;

    /// @notice the percetage (on 18 digits)
    /// @notice if this gets overgrown the contract change state
    uint256 public statePercent;

    /// @notice know your asset string
    string public kya;

    /// @notice minimum Redemption Amount (in Asset token value)
    uint256 public minimumRedemptionAmount;

    /// @notice Emitted when the address of the asset token data is set
    event AssetTokenDataChanged(address indexed _oldAddress, address indexed _newAddress, address indexed _caller);

    /// @notice Emitted when kya string is set
    event KyaChanged(string _kya, address indexed _caller);

    /// @notice Emitted when minimumRedemptionAmount is set
    event MinimumRedemptionAmountChanged(uint256 _newAmount, address indexed _caller);

    /// @notice Emitted when a mint request is requested
    event MintRequested(
        uint256 indexed _mintRequestID,
        address indexed _destination,
        uint256 _amount,
        address indexed _caller
    );

    /// @notice Emitted when a mint request gets approved
    event MintApproved(
        uint256 indexed _mintRequestID,
        address indexed _destination,
        uint256 _amountMinted,
        address indexed _caller
    );

    /// @notice Emitted when a redemption request is requested
    event RedemptionRequested(
        uint256 indexed _redemptionRequestID,
        uint256 _assetTokenAmount,
        uint256 _underlyingAssetAmount,
        bool _fromStake,
        address indexed _caller
    );

    /// @notice Emitted when a redemption request is cancelled
    event RedemptionCanceled(
        uint256 indexed _redemptionRequestID,
        address indexed _requestReceiver,
        string _motive,
        address indexed _caller
    );

    /// @notice Emitted when a redemption request is approved
    event RedemptionApproved(
        uint256 indexed _redemptionRequestID,
        uint256 _assetTokenAmount,
        uint256 _underlyingAssetAmount,
        address indexed _requestReceiver,
        address indexed _caller
    );

    /// @notice Emitted when the token gets bruned
    event TokenBurned(uint256 _amount, address indexed _caller);

    /// @notice Emitted when the contract change to safeguard
    event SafeguardUnstaked(uint256 _amount, address indexed _caller);

    /// @notice Constructor: sets the state variables and provide proper checks to deploy
    /// @param _assetTokenData the asset token data contract address
    /// @param _statePercent the state percent to check the safeguard convertion
    /// @param _kya verification link
    /// @param _minimumRedemptionAmount less than this value is not allowed
    /// @param _name of the token
    /// @param _symbol of the token
    constructor(
        address _assetTokenData,
        uint256 _statePercent,
        string memory _kya,
        uint256 _minimumRedemptionAmount,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        require(_assetTokenData != address(0), "AssetToken: assetTokenData is address 0");
        require(_statePercent > 0, "AssetToken: statePercent must be > 0");
        require(_statePercent <= HUNDRED_PERCENT, "AssetToken: statePercent <= HUNDRED_PERCENT");
        require(bytes(_kya).length > 3, "AssetToken: incorrect kya passed");

        // IT IS THE WAD EQUIVALENT USED IN DSMATH
        _decimals = 18;
        assetTokenDataAddress = _assetTokenData;
        statePercent = _statePercent;
        kya = _kya;
        minimumRedemptionAmount = _minimumRedemptionAmount;
    }

    /// @notice kindof modifier to frist-check data on functions
    /// @param modifiers an array containing the modifiers to check (the enums)
    function checkAccessToFunction(uint256 modifiers) internal view {
        bool found;
        IAssetTokenData assetTknDtaContract = IAssetTokenData(assetTokenDataAddress);
        if (modifiers & ACTIVE_CONTRACT != 0) {
            assetTknDtaContract.onlyActiveContract(address(this));
            found = true;
        }
        if (modifiers & UNFROZEN_CONTRACT != 0) {
            assetTknDtaContract.onlyUnfrozenContract(address(this));
            found = true;
        }
        if (modifiers & ONLY_ISSUER != 0) {
            assetTknDtaContract.onlyIssuer(address(this), _msgSender());
            found = true;
        }
        if (modifiers & ONLY_ISSUER_OR_GUARDIAN != 0) {
            assetTknDtaContract.onlyIssuerOrGuardian(address(this), _msgSender());
            found = true;
        }
        if (modifiers & ONLY_ISSUER_OR_AGENT != 0) {
            assetTknDtaContract.onlyIssuerOrAgent(address(this), _msgSender());
            found = true;
        }
        require(found, "AssetToken: access not found");
    }

    /// @notice Hook to be executed before every transfer and mint
    /// @notice This overrides the ERC20 defined function
    /// @param _from the sender
    /// @param _to the receipent
    /// @param _amount the amount (it is not used  but needed to be defined to override)
    function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal virtual override {
        //  on safeguard the only available transfers are from allowed addresses and guardian
        //  or from an authorized user to this contract
        //  address(this) is added as the _from for approving redemption (burn)
        //  address(this) is added as the _to for requesting redemption (transfer to this contract)
        //  address(0) is added to the condition to allow burn on safeguard
        checkAccessToFunction(UNFROZEN_CONTRACT);
        IAssetTokenData assetTknDtaContract = IAssetTokenData(assetTokenDataAddress);

        if (assetTknDtaContract.isOnSafeguard(address(this))) {
            /// @dev  State is SAFEGUARD
            if (
                // receiver is NOT this contract AND sender is NOT this contract AND sender is NOT guardian
                _to != address(this) &&
                _from != address(this) &&
                _from != assetTknDtaContract.getGuardian(address(this))
            ) {
                require(
                    assetTknDtaContract.isAllowedTransferOnSafeguard(address(this), _from),
                    "AssetToken: beforeTokenTransfer: not allowed (onSafeguard)"
                );
            } else {
                require(
                    assetTknDtaContract.mustBeAuthorizedHolders(address(this), _from, _to, _amount),
                    "AssetToken: beforeTokenTransfer: not authorized (onActive)"
                );
            }
        } else {
            /// @dev State is ACTIVE
            // this is mint or transfer
            // mint signature: ==> _beforeTokenTransfer(address(0), account, amount);
            // burn signature: ==> _beforeTokenTransfer(account, address(0), amount);
            require(
                assetTknDtaContract.mustBeAuthorizedHolders(address(this), _from, _to, _amount),
                "AssetToken: beforeTokenTransfer: not authorized (onActive)"
            );
        }

        super._beforeTokenTransfer(_from, _to, _amount);
    }

    /// @notice Sets Asset Token Data Address
    /// @param _newAddress value to be set
    function setAssetTokenData(address _newAddress) external {
        checkAccessToFunction(UNFROZEN_CONTRACT | ONLY_ISSUER_OR_GUARDIAN);
        require(_newAddress != address(0), "AssetToken: newAddress is address 0");
        emit AssetTokenDataChanged(assetTokenDataAddress, _newAddress, _msgSender());
        assetTokenDataAddress = _newAddress;
    }

    /// @notice Sets the verification link
    /// @param _kya value to be set
    function setKya(string calldata _kya) external {
        checkAccessToFunction(ONLY_ISSUER_OR_GUARDIAN | UNFROZEN_CONTRACT);
        require(bytes(_kya).length > 3, "AssetToken: incorrect kya passed");
        emit KyaChanged(_kya, _msgSender());
        kya = _kya;
    }

    /// @notice Sets the _minimumRedemptionAmount
    /// @param _minimumRedemptionAmount value to be set
    function setMinimumRedemptionAmount(uint256 _minimumRedemptionAmount) external {
        checkAccessToFunction(ONLY_ISSUER_OR_GUARDIAN | UNFROZEN_CONTRACT);
        emit MinimumRedemptionAmountChanged(_minimumRedemptionAmount, _msgSender());
        minimumRedemptionAmount = _minimumRedemptionAmount;
    }

    /// @notice Freeze the contract
    function freezeContract() external {
        checkAccessToFunction(ONLY_ISSUER_OR_GUARDIAN);
        IAssetTokenData assetTknDtaContract = IAssetTokenData(assetTokenDataAddress);
        require(!assetTknDtaContract.isContractFrozen(address(this)), "AssetToken: contract is frozen");
        require(assetTknDtaContract.freezeContract(address(this)), "AssetToken: freezing failed");
    }

    /// @notice unfreeze the contract
    function unfreezeContract() external {
        checkAccessToFunction(ONLY_ISSUER_OR_GUARDIAN);
        IAssetTokenData assetTknDtaContract = IAssetTokenData(assetTokenDataAddress);
        require(assetTknDtaContract.isContractFrozen(address(this)), "AssetToken: contract is not frozen");
        require(assetTknDtaContract.unfreezeContract(address(this)), "AssetToken: unfreezing failed");
    }

    /// @notice Requests a mint to the caller
    /// @param _amount the amount to mint in asset token format
    /// @return uint256 request ID to be referenced in the mapping
    function requestMint(uint256 _amount) external returns (uint256) {
        return _requestMint(_amount, _msgSender());
    }

    /// @notice Requests a mint to the _destination address
    /// @param _amount the amount to mint in asset token format
    /// @param _destination the receiver of the tokens
    /// @return uint256 request ID to be referenced in the mapping
    function requestMint(uint256 _amount, address _destination) external returns (uint256) {
        return _requestMint(_amount, _destination);
    }

    /// @notice Performs the Mint Request to the destination address
    /// @param _amount entered in the external functions
    /// @param _destination the receiver of the tokens
    /// @return uint256 request ID to be referenced in the mapping
    function _requestMint(uint256 _amount, address _destination) private returns (uint256) {
        checkAccessToFunction(ACTIVE_CONTRACT | UNFROZEN_CONTRACT | ONLY_ISSUER_OR_AGENT);
        require(_amount > 0, "AssetToken: amount must be > 0");

        mintRequestID++;
        emit MintRequested(mintRequestID, _destination, _amount, _msgSender());

        mintRequests[mintRequestID] = MintRequest(_destination, _amount, "", false);

        IAssetTokenData assetTknDtaContract = IAssetTokenData(assetTokenDataAddress);
        if (_msgSender() == assetTknDtaContract.getIssuer(address(this))) {
            approveMint(mintRequestID, "IssuerMint");
        }
        return mintRequestID;
    }

    /// @notice Approves the Mint Request
    /// @param _mintRequestID the ID to be referenced in the mapping
    /// @param _referenceTo reference comment for the issuer
    function approveMint(uint256 _mintRequestID, string memory _referenceTo) public nonReentrant {
        checkAccessToFunction(ACTIVE_CONTRACT | ONLY_ISSUER);
        require(mintRequests[_mintRequestID].destination != address(0), "AssetToken: requestID does not exist");
        require(!mintRequests[_mintRequestID].completed, "AssetToken: request is completed");

        mintRequests[_mintRequestID].completed = true;
        mintRequests[_mintRequestID].referenceTo = _referenceTo;

        IAssetTokenData assetTknDtaContract = IAssetTokenData(assetTokenDataAddress);
        assetTknDtaContract.update(address(this));
        uint256 currentRate = assetTknDtaContract.getCurrentRate(address(this));

        uint256 amountToMint = (mintRequests[_mintRequestID].amount * (DECIMALS)) / (currentRate);
        emit MintApproved(_mintRequestID, mintRequests[_mintRequestID].destination, amountToMint, _msgSender());

        _mint(mintRequests[_mintRequestID].destination, amountToMint);
    }

    /// @notice Requests an amount of assetToken Redemption
    /// @param _assetTokenAmount the amount of Asset Token to be redeemed
    /// @param _destination the off chain hash of the redemption transaction
    /// @return uint256 redemptionRequest ID to be referenced in the mapping
    function requestRedemption(
        uint256 _assetTokenAmount,
        string memory _destination
    ) external nonReentrant returns (uint256) {
        require(_assetTokenAmount > 0, "AssetToken: assetTokenAmount must be > 0");
        require(balanceOf(_msgSender()) >= _assetTokenAmount, "AssetToken: caller has insufficient funds");

        IAssetTokenData assetTknDtaContract = IAssetTokenData(assetTokenDataAddress);
        address issuer = assetTknDtaContract.getIssuer(address(this));
        address guardian = assetTknDtaContract.getGuardian(address(this));
        bool isOnSafeguard = assetTknDtaContract.isOnSafeguard(address(this));

        if ((!isOnSafeguard && _msgSender() != issuer) || (isOnSafeguard && _msgSender() != guardian)) {
            require(
                _assetTokenAmount >= minimumRedemptionAmount,
                "AssetToken: minimumRedemptionAmount not reached yet"
            );
        }

        assetTknDtaContract.update(address(this));
        uint256 currentRate = assetTknDtaContract.getCurrentRate(address(this));
        uint256 underlyingAssetAmount = (_assetTokenAmount * (currentRate)) / (DECIMALS);

        redemptionRequestID++;
        emit RedemptionRequested(redemptionRequestID, _assetTokenAmount, underlyingAssetAmount, false, _msgSender());

        redemptionRequests[redemptionRequestID] = RedemptionRequest(
            _msgSender(),
            _destination,
            _assetTokenAmount,
            underlyingAssetAmount,
            false,
            false,
            "",
            address(0)
        );

        /// @dev make the transfer to the contract for the amount requested (18 digits)
        _transfer(_msgSender(), address(this), _assetTokenAmount);

        /// @dev approve instantly when called by issuer or guardian
        if ((!isOnSafeguard && _msgSender() == issuer) || (isOnSafeguard && _msgSender() == guardian)) {
            approveRedemption(redemptionRequestID, "AutomaticRedemptionApproval");
        }

        return redemptionRequestID;
    }

    /// @notice Approves the Redemption Requests
    /// @param _redemptionRequestID redemption request ID to be referenced in the mapping
    /// @param _motive motive of the cancelation
    function cancelRedemptionRequest(uint256 _redemptionRequestID, string memory _motive) external {
        require(
            redemptionRequests[_redemptionRequestID].sender != address(0),
            "AssetToken: redemptionRequestID does not exist"
        );
        require(
            redemptionRequests[_redemptionRequestID].canceledBy == address(0),
            "AssetToken: redemption has been cancelled"
        );
        require(!redemptionRequests[_redemptionRequestID].completed, "AssetToken: redemption already completed");
        require(!redemptionRequests[_redemptionRequestID].fromStake, "AssetToken: staked request - unstake to redeem");
        IAssetTokenData assetTknDtaContract = IAssetTokenData(assetTokenDataAddress);
        if (_msgSender() != redemptionRequests[_redemptionRequestID].sender) {
            // not owner of the redemption so guardian or issuer should be the caller
            assetTknDtaContract.onlyIssuerOrGuardian(address(this), _msgSender());
        }

        uint256 refundAmount = redemptionRequests[_redemptionRequestID].assetTokenAmount;
        emit RedemptionCanceled(
            _redemptionRequestID,
            redemptionRequests[_redemptionRequestID].sender,
            _motive,
            _msgSender()
        );

        redemptionRequests[_redemptionRequestID].assetTokenAmount = 0;
        redemptionRequests[_redemptionRequestID].underlyingAssetAmount = 0;
        redemptionRequests[_redemptionRequestID].canceledBy = _msgSender();

        _transfer(address(this), redemptionRequests[_redemptionRequestID].sender, refundAmount);
    }

    /// @notice Approves the Redemption Requests
    /// @param _redemptionRequestID redemption request ID to be referenced in the mapping
    /// @param _approveTxID the transaction ID
    function approveRedemption(uint256 _redemptionRequestID, string memory _approveTxID) public {
        checkAccessToFunction(ONLY_ISSUER_OR_GUARDIAN);
        require(
            redemptionRequests[_redemptionRequestID].canceledBy == address(0),
            "AssetToken: redemptionRequestID has been cancelled"
        );
        require(
            redemptionRequests[_redemptionRequestID].sender != address(0),
            "AssetToken: redemptionRequestID is incorrect"
        );
        require(!redemptionRequests[_redemptionRequestID].completed, "AssetToken: redemptionRequestID completed");

        if (redemptionRequests[_redemptionRequestID].fromStake) {
            IAssetTokenData assetTknDtaContract = IAssetTokenData(assetTokenDataAddress);
            require(
                assetTknDtaContract.isOnSafeguard(address(this)),
                "AssetToken: contract is active (not onSafeguard)"
            );
        }

        emit RedemptionApproved(
            _redemptionRequestID,
            redemptionRequests[_redemptionRequestID].assetTokenAmount,
            redemptionRequests[_redemptionRequestID].underlyingAssetAmount,
            redemptionRequests[_redemptionRequestID].sender,
            _msgSender()
        );
        redemptionRequests[_redemptionRequestID].completed = true;
        redemptionRequests[_redemptionRequestID].approveTxID = _approveTxID;

        // burn tokens from the contract
        _burn(address(this), redemptionRequests[_redemptionRequestID].assetTokenAmount);
    }

    /// @notice Burns a certain amount of tokens
    /// @param _amount qty of assetTokens to be burned
    function burn(uint256 _amount) external {
        emit TokenBurned(_amount, _msgSender());
        _burn(_msgSender(), _amount);
    }

    /// @notice Performs the Safeguard Stake
    /// @param _amount the assetToken amount to be staked
    /// @param _receipt the off chain hash of the redemption transaction
    function safeguardStake(uint256 _amount, string calldata _receipt) external nonReentrant {
        checkAccessToFunction(ACTIVE_CONTRACT);
        require(balanceOf(_msgSender()) >= _amount, "AssetToken: caller has insufficient funds");

        safeguardStakes[_msgSender()] = safeguardStakes[_msgSender()] + _amount;
        totalStakes = totalStakes + (_amount);
        uint256 stakedPercent = (totalStakes * (HUNDRED_PERCENT)) / (totalSupply());

        IAssetTokenData assetTknDtaContract = IAssetTokenData(assetTokenDataAddress);
        if (stakedPercent >= statePercent) {
            require(assetTknDtaContract.setContractToSafeguard(address(this)), "AssetToken: error on safeguard change");
            /// @dev now the contract is on safeguard
        }

        uint256 _requestID = stakedRedemptionRequests[_msgSender()];
        if (_requestID == 0) {
            /// @dev zero means that it's new request
            redemptionRequestID++;
            redemptionRequests[redemptionRequestID] = RedemptionRequest(
                _msgSender(),
                _receipt,
                _amount,
                0,
                false,
                true,
                "",
                address(0)
            );

            stakedRedemptionRequests[_msgSender()] = redemptionRequestID;
            _requestID = redemptionRequestID;
        } else {
            /// @dev non zero means the request already exist and need only add amount
            redemptionRequests[_requestID].assetTokenAmount =
                redemptionRequests[_requestID].assetTokenAmount +
                (_amount);
        }

        emit RedemptionRequested(
            _requestID,
            redemptionRequests[_requestID].assetTokenAmount,
            redemptionRequests[_requestID].underlyingAssetAmount,
            true,
            _msgSender()
        );
        _transfer(_msgSender(), address(this), _amount);
    }

    /// @notice Calls to UnStake all the funds
    function safeguardUnstake() external {
        _safeguardUnstake(safeguardStakes[_msgSender()]);
    }

    /// @notice Calls to UnStake with a certain amount
    /// @param _amount to be unStaked in asset token
    function safeguardUnstake(uint256 _amount) external {
        _safeguardUnstake(_amount);
    }

    /// @notice Performs the UnStake with a certain amount
    /// @param _amount to be unStaked in asset token
    function _safeguardUnstake(uint256 _amount) private {
        checkAccessToFunction(ACTIVE_CONTRACT | UNFROZEN_CONTRACT);
        require(_amount > 0, "AssetToken: amount must be > 0");
        require(safeguardStakes[_msgSender()] >= _amount, "AssetToken: amount exceeds staked");

        emit SafeguardUnstaked(_amount, _msgSender());
        safeguardStakes[_msgSender()] = safeguardStakes[_msgSender()] - (_amount);
        totalStakes = totalStakes - (_amount);

        uint256 _requestID = stakedRedemptionRequests[_msgSender()];
        redemptionRequests[_requestID].assetTokenAmount = redemptionRequests[_requestID].assetTokenAmount - _amount;

        _transfer(address(this), _msgSender(), _amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}
