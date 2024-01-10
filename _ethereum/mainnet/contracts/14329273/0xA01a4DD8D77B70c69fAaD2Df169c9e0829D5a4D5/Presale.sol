// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./IExchangeRates.sol";
import "./MixinResolver.sol";
import "./MixinSystemSettings.sol";
import "./OwnedwManager.sol";

contract Presale is OwnedwManager, MixinResolver, MixinSystemSettings, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // State variables
    bool public isPaused;
    uint public participants;
    uint public allocated;
    uint public available;

    IERC20 public pLYS;

    /* ========== ADDRESS RESOLVER CONFIGURATION ========== */
    bytes32 private constant CONTRACT_EXRATES = "ExchangeRates";
    bytes32 private constant RESERVE_TOKEN_0 = "DAI";
    bytes32 private constant RESERVE_TOKEN_1 = "USDC";
    bytes32 private constant RESERVE_TOKEN_2 = "USDT";

    bytes32[4] private addressesToCache = [
        CONTRACT_EXRATES,
        RESERVE_TOKEN_0,
        RESERVE_TOKEN_1,
        RESERVE_TOKEN_2
    ];
    mapping(address => bool) public purchases;

    /* ========== VIEWS ========== */
    function resolverAddressesRequired() public view override(MixinResolver, MixinSystemSettings) returns(bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = MixinSystemSettings.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](4);
        newAddresses[0] = CONTRACT_EXRATES;
        newAddresses[1] = RESERVE_TOKEN_0;
        newAddresses[2] = RESERVE_TOKEN_1;
        newAddresses[3] = RESERVE_TOKEN_2;
        return combineArrays(existingAddresses, newAddresses);
    }

    // ========== CONSTRUCTOR ==========
    constructor(
        address _owner,
        address _resolver,
        address _preElysian,
        uint _participants
    )
    public
    OwnedwManager(_owner, _owner)
    MixinSystemSettings(_resolver) {
        pLYS = IERC20(_preElysian);
        participants = _participants;
        allocated = 30 * 10e6 ether;
        available = allocated;
        isPaused = false;
    }

    function flagExecution(bool _isPaused) external onlyOwner {
        isPaused = _isPaused;
    }

    //Requires the contract to be paused first
    function setPreElysian(address _preElysian) external onlyOwner {
        require(isPaused, "Contract must be paused");
        pLYS = IERC20(_preElysian);
    }

    //To be executed only after adding addresses to whitelist resolver
    function setParticipants(uint _participants) external onlyOwner {
        participants = _participants;
    }

    function collectPLYS(uint _amount, bytes32 _tokenName) external 
    isReserveToken(_tokenName)
    notPaused
    nonReentrant {
        bytes32 msgSender = bytes32(uint256(uint160(msg.sender)) << 96);
        isWhitelisted(msgSender);
        isInitialized();
        require(purchases[msg.sender] == false, "You already participated in the presale.");

        uint _available = available.div(participants);
        uint transferrablePLYS = pLYS.balanceOf(address(this));

        require(_amount <= _available, "Exceeds allocation");
        require(_available <= transferrablePLYS, "Not enough pLYS in presale contract");

        //Get deposit token
        IERC20 depositToken = getReserveToken(_tokenName);

        uint amountToPay = exchangeRates().effectiveValue("pLYS", _amount, _tokenName);
        require(depositToken.balanceOf(msg.sender) >= amountToPay, "Not enough balance for this trade.");

        //Transfer tokens (requires previous approval)
        depositToken.safeTransferFrom(msg.sender, address(this), amountToPay);

        //Calculate leftover tokens?
        if (_amount < _available) {
            uint _leftOver = _available.sub(_amount);
        }

        pLYS.transfer(msg.sender, _amount);
        //Remove buyer from total participants
        participants = participants.sub(1);
        //Reduce total available tokens
        available = available.sub(_amount);
        //Record purchase
        purchases[msg.sender] = true;
    }

    function collectPLYSEth(uint _amount) external payable
    notPaused
    nonReentrant {
        bytes32 msgSender = bytes32(uint256(uint160(msg.sender)) << 96);
        isWhitelisted(msgSender);
        isInitialized();
        require(purchases[msg.sender] == false, "You already participated in the presale.");

        uint _available = available.div(participants);
        uint transferrablePLYS = pLYS.balanceOf(address(this));

        require(_amount <= _available, "Exceeds allocation");
        require(_available <= transferrablePLYS, "Not enough pLYS in presale contract");

        uint ethRatePLYS = exchangeRates().effectiveValue("pLYS", 1, "ETH");
        require(msg.value >= _amount.mul(ethRatePLYS), "SIR, plz send moar ETH");

        //Calculate leftover tokens?
        if (_amount < _available) {
            uint _leftOver = _available.sub(_amount);
        }

        pLYS.transfer(msg.sender, _amount);
        //Remove buyer from total participants
        participants = participants.sub(1);
        //Reduce total available tokens
        available = available.sub(_amount);
        //Record purchase
        purchases[msg.sender] = true;

        //Calculate excess to be returned
        if (msg.value > _amount.mul(ethRatePLYS)) {
            uint excessETH = msg.value.sub(_amount.mul(ethRatePLYS));
            msg.sender.transfer(excessETH);
        }
    }

    function transferTokens(address _multisig, bytes32 _tokenName) external onlyOwner {
        //Get deposit token
        IERC20 depositToken = getReserveToken(_tokenName);
        uint balance = depositToken.balanceOf(address(this));
        require(balance > 0, "No tokens to transfer");
        depositToken.transfer(_multisig, balance);
    }

    function transferEth(address _multisig) external onlyOwner {
        address payable multisig = payable(_multisig);
        multisig.transfer(address(this).balance);
    }

    function availablePLYS(address _who) public view returns(uint) {
        uint _available;
        if (purchases[_who]) {
            _available = 0;
        } else {
            _available = available.div(participants);
        }
        return _available;
    }

    function getQuote(uint _amount, bytes32 _currencyKey) public view returns(uint) {
        return exchangeRates().effectiveValue("pLYS", _amount, _currencyKey);
    }

    function exchangeRates() internal view returns(IExchangeRates) {
        return IExchangeRates(resolver.requireAndGetAddress(CONTRACT_EXRATES, "Missing ExchangeRates address"));
    }

    function getReserveToken(bytes32 _tokenName) internal view returns(IERC20) {
        IERC20 reserveToken = IERC20(resolver.requireAndGetAddress(_tokenName, "Not a reserve token"));
        return reserveToken;
    }

    modifier isReserveToken(bytes32 _tokenName) {
        resolver.requireAndGetAddress(_tokenName, "Not a reserve token");
        _;
    }

    function isInitialized() internal {
        require(address(pLYS) != address(0), "pLYS address is not set");
    }

    function isWhitelisted(bytes32 _depositor) internal {
        resolver.requireAndGetAddress(_depositor, "Not in whitelist");
    }

    modifier notPaused() {
        require(!isPaused, "Contract is paused.");
        _;
    }
}