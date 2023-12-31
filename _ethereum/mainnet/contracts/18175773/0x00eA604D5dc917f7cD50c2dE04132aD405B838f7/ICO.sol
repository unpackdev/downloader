// SPDX-License-Identifier: MIT

/**  ICO Contract */
/** Author: Aceson (2022.8) */

pragma solidity ^0.8.16;

import "./OwnableUpgradeable.sol";
import "./IERC20MetadataUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./IWalletStore.sol";
import "./IVestingV2.sol";

contract ICO is OwnableUpgradeable, ReentrancyGuardUpgradeable {
  using SafeMathUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

  /**
   *
   * @dev InvestorInfo is the struct type which store investor information
   *
   */
  struct InvestorInfo {
    uint256 joinDate; //Time when user first invested
    uint256 investAmount; //Total amount invested
    uint256 tokenReceived; // Total token received
  }

  /**
   *
   * @dev ICOInfo will have information about ico.
   * It will contains ico details between innovator and investor.
   * For now, innovatorWallet will reflect owner of the platform.
   *
   */
  struct ICOInfo {
    address innovatorWallet; //Address where raised amount is sent
    uint256 softcap; //Softcap for ICO
    uint256 hardcap; //Hardcap for ICO
    uint256 startDate; //Start date of ICO round
    uint256 endDate; //End date of ICO round
    uint256 minInvestment; //Minimum amount of investment for a wallet
    uint256 maxInvestment; //Maximum amount a wallet can invest
    uint256 price; //Price of 1 absolute token (Including decimals)
    //ex: If 1 token costs 10 BUSD, enter 10*10**18 as input (as BUSD have 18 decimals)
    IERC20MetadataUpgradeable token; //Payment token address (ex: BUSD)
    uint256 totalInvestFund; //Total raised fund for a round
    uint256 totalClaimed;
    address[] participants; //Participants list of a round
    bool isPaused; //Whether ICO is active or not
    bool onlyWhitelisted;
    mapping(address => InvestorInfo) investorList; //investors Info
  }

  /**
   * @dev this variable is the instance of wallet storage
   */
  IWalletStore public _walletStore;

  /**
   * @dev this variable is the instance of vesting contract
   */
  IVestingV2 public _vestingContract;

  /**
   * @dev icos store icos info of this contract.
   */
  ICOInfo[] public icos;

  /**
   * @dev this event will call when new ico generated.
   * this is called when innovator create a new ico but for now,
   * it is calling when owner create new ico
   */
  event ICOCreated(
    address innovator,
    uint256 softcap,
    uint256 hardcap,
    uint256 startDate,
    uint256 endDate,
    uint256 minInvestment,
    uint256 maxInvestment,
    uint256 price,
    address token
  );

  /**
   * @dev it is calling when new investor joinning to the existing ico
   */
  event NewInvestment(uint8 roundId, address wallet, uint256 investAmount, uint256 tokenReceived);

  /**
   * @dev this event is called when innovator claim withdrawl
   */
  event ClaimFund(uint8 roundId, address innovatorWallet, uint256 totalInvestFund);

  /**
   * @dev Event is called when new whitelist is added
   */
  event WhitelistAdded(uint8 vestingId, address wallet, uint256 amount, bool status);

  function initialize(address _walletStoreAddr) external initializer {
    __Ownable_init();
    __ReentrancyGuard_init();
    _walletStore = IWalletStore(_walletStoreAddr);
  }

  function createNewICO(
    address _innovator,
    uint256 _softcap,
    uint256 _hardcap,
    uint256 _startDate,
    uint256 _endDate,
    uint256 _minInvestment,
    uint256 _maxInvestment,
    uint256 _price,
    address _token,
    bool _onlyWhitelisted
  ) external onlyOwner {
    /** generate the new ico */
    ICOInfo storage newAgreement = icos.push();

    newAgreement.innovatorWallet = _innovator;
    newAgreement.softcap = _softcap;
    newAgreement.hardcap = _hardcap;
    newAgreement.startDate = _startDate;
    newAgreement.endDate = _endDate;
    newAgreement.token = IERC20MetadataUpgradeable(_token);
    newAgreement.totalInvestFund = 0;
    newAgreement.minInvestment = _minInvestment;
    newAgreement.maxInvestment = _maxInvestment;
    newAgreement.price = _price;
    newAgreement.isPaused = false;
    newAgreement.onlyWhitelisted = _onlyWhitelisted;

    /** emit the ico generation event */
    emit ICOCreated(
      _innovator,
      _softcap,
      _hardcap,
      _startDate,
      _endDate,
      _minInvestment,
      _maxInvestment,
      _price,
      _token
    );
  }

  /**
   *
   * @dev set the terms of the ico
   *
   * @param {_softcap} minimum amount to raise
   * @param {_hardcap} maximum amount to raise
   * @param {_startDate} date the fundraising starts
   * @param {_gaMulti} guaranteed allocation multiplier
   * @param {_token} token being used for fundraising
   * @return {bool} return status of operation
   *
   */
  function setICO(
    uint8 _roundId,
    address _innovator,
    uint256 _softcap,
    uint256 _hardcap,
    uint256 _startDate,
    uint256 _endDate,
    uint256 _minInvestment,
    uint256 _maxInvestment,
    uint256 _price,
    address _token,
    bool _onlyWhitelisted
  ) external onlyOwner returns (bool) {
    ICOInfo storage ico = icos[_roundId];

    ico.softcap = _softcap;
    ico.innovatorWallet = _innovator;
    ico.hardcap = _hardcap;
    ico.startDate = _startDate;
    ico.endDate = _endDate;
    ico.token = IERC20MetadataUpgradeable(_token);
    ico.minInvestment = _minInvestment;
    ico.maxInvestment = _maxInvestment;
    ico.price = _price;
    ico.onlyWhitelisted = _onlyWhitelisted;

    return true;
  }

  function setICOState(uint8 _roundId, bool _state) external onlyOwner {
    icos[_roundId].isPaused = _state;
  }

  /**
   *
   * @dev set vesting address for contract
   *
   * @param {_contract} address of vesting contract
   * @return {bool} return status of operation
   *
   */
  function setVestingContract(address _contract) external onlyOwner returns (bool) {
    require(_contract != address(0), "Zero address");
    _vestingContract = IVestingV2(_contract);
    return true;
  }

  /**
   *
   * @dev set wallet store address for contract
   *
   * @param {_contract} address of wallet store
   * @return {bool} return status of operation
   *
   */
  function setWalletStore(address _contract) external onlyOwner returns (bool) {
    require(_contract != address(0), "Zero address");
    _walletStore = IWalletStore(_contract);
    return true;
  }

  /**
   *
   * @dev investor join available ico. Already complied users can pass empty signature
   *
   * @param {uint256} Deposit amount
   * @param {bytes} Signature of user
   *
   * @return {bool} return if investor successfully joined to the ico
   *
   */
  function fundICO(uint8 _roundId, uint256 _investFund) external nonReentrant returns (bool) {
    ICOInfo storage ico = icos[_roundId];
    InvestorInfo storage investor = ico.investorList[msg.sender];    
    require(investor.investAmount.add(_investFund) <= ico.maxInvestment, "Amount exceeding Max");
    require(!ico.isPaused, "ICO not active");
    require(block.timestamp >= ico.startDate, "Too early");
    require(block.timestamp <= ico.endDate, "Too late");
    require(ico.totalInvestFund.add(_investFund) <= ico.hardcap, "Hardcap already met");
    if (ico.onlyWhitelisted) {
      require(_walletStore.isVerified(msg.sender), "User not verified");
    }
    if (investor.joinDate == 0) {
      /** add new investor to investor list for specific agreeement */
      require(_investFund >= ico.minInvestment, "Invalid Amount");
      investor.joinDate = block.timestamp;
      ico.participants.push(msg.sender);
    }
    ico.token.safeTransferFrom(msg.sender, address(this), _investFund);
    // uint256 tokenAmount = (_investFund * 10 ** (ico.token.decimals())) / ico.price;
    uint256 tokenAmount = (_investFund * 10 ** 18) / ico.price;

    investor.investAmount = investor.investAmount.add(_investFund);
    investor.tokenReceived = investor.tokenReceived.add(tokenAmount);
    ico.totalInvestFund = ico.totalInvestFund.add(_investFund);

    //Vesting strat should be added prior to ICO
    bool status = _vestingContract.addWhitelist(msg.sender, investor.tokenReceived, _roundId);

    emit NewInvestment(_roundId, msg.sender, _investFund, tokenAmount);
    emit WhitelistAdded(_roundId, msg.sender, _investFund, status);

    return true;
  }

  /**
   *
   * @dev boilertemplate function for innovator to claim funds
   *
   * @param {address}
   *
   * @return {bool} return status of claim
   *
   */
  function claimInnovatorFund(uint8 _roundId) external nonReentrant returns (bool) {
    ICOInfo storage ico = icos[_roundId];

    require(msg.sender == ico.innovatorWallet, "Only innovator can claim");

    uint256 amount = ico.totalInvestFund - ico.totalClaimed;

    /** check if endDate already passed and softcap is reached */
    require(
      (block.timestamp >= ico.endDate && ico.totalInvestFund >= ico.softcap) ||
        ico.totalInvestFund >= ico.hardcap,
      "Date and cap not met"
    );

    /** check if treasury have enough funds to withdraw to innovator */
    require(ico.token.balanceOf(address(this)) >= amount, "Not enough funds in treasury");

    /** 
          transfer token from treasury to innovator
      */
    ico.token.safeTransfer(ico.innovatorWallet, amount);
    emit ClaimFund(_roundId, ico.innovatorWallet, amount);

    ico.totalClaimed += amount;
    return true;
  }

  /**
   *
   * @dev we will have function to transfer coins to company wallet
   *
   * @param {address} token address
   *
   * @return {bool} return status of the transfer
   *
   */

  function transferToken(address _token) external onlyOwner returns (bool) {
    IERC20MetadataUpgradeable token = IERC20MetadataUpgradeable(_token);
    uint256 balance = token.balanceOf(address(this));
    token.safeTransfer(owner(), balance);

    return true;
  }

  /**
   *
   * @dev getter function for list of participants
   *
   * @return {uint256} return total participant count of ICO
   *
   */
  function getRoundParticipants(uint8 _roundId) external view returns (address[] memory) {
    return icos[_roundId].participants;
  }

  function userInvestment(
    uint8 _roundId,
    address _address
  ) external view returns (InvestorInfo memory) {
    return icos[_roundId].investorList[_address];
  }
}
