// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

//    _    _      $$$$$$$$\ $$$$$$$\   $$$$$$\   $$$$$$\   $$$$$$\        _    _
//   (o)--(o)     $$  _____|$$  __$$\ $$  __$$\ $$  __$$\ $$  __$$\      (o)--(o)
//  /.______.\    $$ |      $$ |  $$ |$$ /  $$ |$$ /  \__|$$ /  $$ |    /.______.\
//  \________/    $$$$$\    $$$$$$$  |$$ |  $$ |$$ |$$$$\ $$ |  $$ |    \________/
// ./        \.   $$  __|   $$  __$$< $$ |  $$ |$$ |\_$$ |$$ |  $$ |   ./        \.
//( .        , )  $$ |      $$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |  ( .        , )
// \ \_\\//_/ /   $$ |      $$ |  $$ | $$$$$$  |\$$$$$$  | $$$$$$  |   \ \_\\//_/ /
//  ~~  ~~  ~~    \__|      \__|  \__| \______/  \______/  \______/     ~~  ~~  ~~

import "./AggregatorV3Interface.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

import "./FrogoPresaleMeta.sol";

contract FrogoPresale is FrogoPresaleMeta, Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    event NewContribution(address indexed wallet, address indexed depositToken, uint amount);
    event PresaleFinalized();

    struct PresaleConfig {
        uint64 startTime;
        uint64 endTime;
        uint ratio;
        uint hardcap;
        uint minContribution;
        uint maxContribution;
    }

    modifier whenPresaleActive() {
        if ((block.timestamp < presaleConfig.startTime) ||
        (block.timestamp >= presaleConfig.endTime) ||
        tokensSold >= presaleConfig.hardcap ||
            isFinalized == true) {
            revert PresaleInactive();
        }

        _;
    }

    AggregatorV3Interface internal priceFeed;
    PresaleConfig public presaleConfig;
    uint256 public tokensSold;
    bool public isFinalized;
    mapping(address => bool) public depositTokens;
    mapping(address => uint256) public participants;

    constructor(PresaleConfig memory _presaleConfig, address _priceFeed, address[] memory _depositTokens) {
        presaleConfig = _presaleConfig;
        priceFeed = AggregatorV3Interface(_priceFeed);
        setDepositTokens(_depositTokens);
    }

    // PUBLIC FUNCTIONS
    function participate(address depositToken, uint256 amount) external payable whenPresaleActive nonReentrant {
        _participate(depositToken, amount);
    }

    receive() external payable {
        _participate(address(0), msg.value);
    }

    function getLatestPrice() public view returns (int) {
        (,int256 price,,,) = priceFeed.latestRoundData();

        return price;
    }

    function getTokenAmount(address _token, uint256 _amount)
    public view returns (uint256)
    {
        if (_token != address(0) && !depositTokens[_token]) {
            revert InvalidDepositToken();
        }

        if (_token == address(0)) {
            // Invest in ETH
            return _amount.mul(presaleConfig.ratio).div(10 ** 18);
        }
        else {
            // Invest in Stables
            uint256 adjustedPrice = uint256(getLatestPrice()) * 10 ** 10;

            return _amount.mul(presaleConfig.ratio).div(adjustedPrice);
        }
    }

    // OWNER FUNCTIONS
    function withdraw() external onlyOwner {
        (bool success,) = msg.sender.call{value : address(this).balance}("");
        require(success, "Failed to withdraw ETH");
    }

    function finalize() external onlyOwner {
        if (isFinalized) {
            revert PresaleAlreadyFinalized();
        }

        emit PresaleFinalized();

        isFinalized = true;
    }

    function setPriceFeed(address _priceFeed) external onlyOwner {
        if (_priceFeed == address(0)) {
            revert InvalidPriceFeedAddress();
        }

        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function setPresaleConfig(PresaleConfig memory _presaleConfig) external onlyOwner {
        if (_presaleConfig.endTime < block.timestamp ||
        _presaleConfig.ratio == 0 ||
        _presaleConfig.hardcap == 0 ||
            _presaleConfig.minContribution > _presaleConfig.maxContribution) {
            revert InvalidPresaleConfig();
        }

        presaleConfig = _presaleConfig;
    }

    function setDepositTokens(address[] memory _tokens) public onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            depositTokens[_tokens[i]] = true;
        }
    }

    // PRIVATE FUNCTIONS
    function _participate(address depositToken, uint256 amount) internal {
        bool isEthDeposit = depositToken == address(0);
        uint256 tokensAmount = isEthDeposit ?
        getTokenAmount(depositToken, msg.value) :
        getTokenAmount(depositToken, amount);
        if (!isEthDeposit && !depositTokens[depositToken]) {
            revert InvalidDepositToken();
        }

        if (tokensAmount < presaleConfig.minContribution) {
            revert AmountLowError();
        }
        if (tokensAmount >= presaleConfig.maxContribution) {
            revert AmountHighError();
        }

        if (participants[msg.sender] + tokensAmount > presaleConfig.maxContribution) {
            revert ContributionAmountExceeded();
        }

        if (tokensAmount + tokensSold > presaleConfig.hardcap) {
            revert HardCapReached();
        }

        _collectInvestment(depositToken, amount);

        tokensSold = tokensSold.add(tokensAmount);
        participants[msg.sender] = participants[msg.sender].add(tokensAmount);

        emit NewContribution(msg.sender, depositToken, tokensAmount);
    }

    function _collectInvestment(address _token, uint256 _amount) internal {
        if (_token == address(0)) {
            payable(owner()).transfer(_amount);
        } else {
            IERC20(_token).safeTransferFrom(
                msg.sender,
                owner(),
                _amount
            );
        }
    }
}
