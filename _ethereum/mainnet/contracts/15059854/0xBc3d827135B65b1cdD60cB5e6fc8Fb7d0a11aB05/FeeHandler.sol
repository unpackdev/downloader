// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Percent.sol";
import "./OwnableTimelockUpgradeable.sol";

import "./IHelixChefNFT.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

/// Handles routing received fees to internal contracts
contract FeeHandler is Initializable, OwnableUpgradeable, OwnableTimelockUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Emitted when a new treasury address is set by the owner
    event SetTreasury(address indexed setter, address _treasury);

    // Emitted when a new nftChef address is set by the owner
    event SetNftChef(address indexed setter, address _nftChef);

    // Emitted when a new nftChef percent is set by the owner
    event SetDefaultNftChefPercent(address indexed setter, uint256 _defaultNftChefPercent);

    event AddFeeCollector(address indexed setter, address indexed feeCollector);
    event RemoveFeeCollector(address indexed setter, address indexed feeCollector);

    // Emitted when a new nftChef percent relating to a particular source is set by the owner
    event SetNftChefPercents(
        address indexed setter, 
        address indexed source,
        uint256 _nftChefPercent
    );

    // Emitted when fees are transferred by the handler
    event TransferFee(
        address indexed token,
        address indexed from,
        address indexed rewardAccruer,
        address nftChef,
        address treasury,
        uint256 fee,
        uint256 nftChefAmount,
        uint256 treasuryAmount
    );

    /// Thrown when attempting to transfer a fee of 0
    error ZeroFee();

    /// Thrown when address(0) is encountered
    error ZeroAddress();

    error NotFeeCollector(address _feeCollector);
    error AlreadyFeeCollector(address _feeCollector);

    /// Thrown when this contract's balance of token is less than amount
    error InsufficientBalance(address token, uint256 amount);

    address public helixToken;

    /// Owner defined fee recipient
    address public treasury;

    /// Owner defined pool where fees can be staked
    IHelixChefNFT public nftChef;

    /// Determines default percentage of collector fees sent to nftChef
    uint256 public defaultNftChefPercent;

    /// Maps contract address to individual nftChef collector fee percents
    mapping(address => uint256) public nftChefPercents;

    /// Maps contrct address to true if address has nftChefPercent set and false otherwise
    mapping(address => bool) public hasNftChefPercent;

    /// Maps address to true if address is registered as a feeCollector and false otherwise
    mapping(address => bool) public isFeeCollector;
    
    modifier onlyValidFee(uint256 _fee) {
        require(_fee > 0, "FeeHandler: zero fee");
        _;
    }

    modifier onlyValidAddress(address _address) {
        require(_address != address(0), "FeeHandler: zero address");
        _;
    }

    modifier onlyValidPercent(uint256 _percent) {
        require(Percent.isValidPercent(_percent), "FeeHandler: percent exceeds max");
        _;
    } 

    modifier onlyFeeCollector(address _feeCollector) {
        if (!isFeeCollector[_feeCollector]) revert NotFeeCollector(_feeCollector);
        _;
    }

    modifier notFeeCollector(address _feeCollector) {
        if (isFeeCollector[_feeCollector]) revert AlreadyFeeCollector(_feeCollector);
        _;
    }

    modifier hasBalance(address _token, uint256 _amount) {
        if (IERC20Upgradeable(_token).balanceOf(address(this)) < _amount) {
            revert InsufficientBalance(_token, _amount);
        }
        _;
    }

    function initialize(
        address _treasury, 
        address _nftChef, 
        address _helixToken, 
        uint256 _defaultNftChefPercent
    ) external initializer {
        __Ownable_init();
        __OwnableTimelock_init();
        treasury = _treasury;
        nftChef = IHelixChefNFT(_nftChef);
        helixToken = _helixToken;
        defaultNftChefPercent = _defaultNftChefPercent;
    }
    
    /// Called by a FeeCollector to send _amount of _token to this FeeHandler
    /// handles sending fees to treasury and staking with nftChef
    function transferFee(
        address _token, 
        address _from, 
        address _rewardAccruer, 
        uint256 _fee
    ) 
        external 
        onlyValidFee(_fee) 
    {
        (uint256 nftChefAmount, uint256 treasuryAmount) = getNftChefAndTreasuryAmounts(_token, _fee);
        
        if (nftChefAmount > 0) {
            IERC20Upgradeable(_token).safeTransferFrom(_from, address(nftChef), nftChefAmount);
            nftChef.accrueReward(_rewardAccruer, nftChefAmount);
        }

        if (treasuryAmount > 0) {
            IERC20Upgradeable(_token).safeTransferFrom(_from, treasury, treasuryAmount);
        }

        emit TransferFee(
            address(_token),
            _from,
            _rewardAccruer,
            address(nftChef),
            treasury,
            _fee,
            nftChefAmount,
            treasuryAmount
        );
    }

    /// Called by the owner to set a new _treasury address
    function setTreasury(address _treasury) external onlyTimelock onlyValidAddress(_treasury) { 
        treasury = _treasury;
        emit SetTreasury(msg.sender, _treasury);
    }

    /// Called by the owner to set a new _nftChef address
    function setNftChef(address _nftChef) 
        external 
        onlyOwner
        onlyValidAddress(_nftChef) 
    {
        nftChef = IHelixChefNFT(_nftChef);
        emit SetNftChef(msg.sender, _nftChef);
    }

    /// Called by the owner to set the _defaultNftChefPercent taken from the total collector fees
    /// and staked with the nftChef
    function setDefaultNftChefPercent(uint256 _defaultNftChefPercent) 
        external 
        onlyOwner 
        onlyValidPercent(_defaultNftChefPercent) 
    {
        defaultNftChefPercent = _defaultNftChefPercent;
        emit SetDefaultNftChefPercent(msg.sender, _defaultNftChefPercent);
    }

    /// Called by the owner to set the _nftChefPercent taken from the total collector fees
    /// when the fee is received from _source and staked with the nftChef
    function setNftChefPercent(address _source, uint256 _nftChefPercent) 
        external
        onlyOwner
        onlyValidPercent(_nftChefPercent)
    {
        nftChefPercents[_source] = _nftChefPercent;
        hasNftChefPercent[_source] = true;
        emit SetNftChefPercents(msg.sender, _source, _nftChefPercent);
    }

    /// Called by the owner to register a new _feeCollector
    function addFeeCollector(address _feeCollector) 
        external 
        onlyOwner 
        onlyValidAddress(_feeCollector) 
        notFeeCollector(_feeCollector)
    {
        isFeeCollector[_feeCollector] = true;
        emit AddFeeCollector(msg.sender, _feeCollector);
    }

    /// Called by the owner to remove a registered _feeCollector
    function removeFeeCollector(address _feeCollector)
        external
        onlyOwner
        onlyFeeCollector(_feeCollector)
    {
        isFeeCollector[_feeCollector] = false;
        emit RemoveFeeCollector(msg.sender, _feeCollector);
    }

    /// Return the nftChef fee computed from the _amount and the _caller's nftChefPercent
    function getNftChefFee(address _caller, uint256 _amount) external view returns (uint256 nftChefFee) {
        uint256 nftChefPercent = hasNftChefPercent[_caller] ? nftChefPercents[_caller] : defaultNftChefPercent;
        nftChefFee = _getFee(_amount, nftChefPercent);
    }

    /// Split _amount based on _caller's nftChef percent and return the nftChefFee and the remainder
    /// where remainder == _amount - nftChefFee
    function getNftChefFeeSplit(address _caller, uint256 _amount)
        external 
        view
        returns (uint256 nftChefFee, uint256 remainder)
    {
        uint256 nftChefPercent = hasNftChefPercent[_caller] ? nftChefPercents[_caller] : defaultNftChefPercent;
        (nftChefFee, remainder) = _getSplit(_amount, nftChefPercent);
    }

    /// Return the amounts to send to the nft chef and treasury based on the _fee and _token
    function getNftChefAndTreasuryAmounts(address _token, uint256 _fee) 
        public
        view 
        returns (uint256 nftChefAmount, uint256 treasuryAmount)
    {
        if (_token == helixToken) {
            uint256 nftChefPercent = hasNftChefPercent[msg.sender] ? nftChefPercents[msg.sender] : defaultNftChefPercent;
            (nftChefAmount, treasuryAmount) = _getSplit(_fee, nftChefPercent);
        } else {
            treasuryAmount = _fee;
        }
    }

    /// Return the fee computed from the _amount and the _percent
    function _getFee(uint256 _amount, uint256 _percent) 
        private 
        pure 
        returns (uint256 fee) 
    {
        fee = Percent.getPercentage(_amount, _percent);
    }

    /// Split _amount based on _percent and return the fee and the remainder
    /// where remainder == _amount - fee
    function _getSplit(uint256 _amount, uint256 _percent) 
        private 
        pure 
        returns (uint256 fee, uint256 remainder)
    {
        (fee, remainder) = Percent.splitByPercent(_amount, _percent);
    }
}
