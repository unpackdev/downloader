// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./SignatureChecker.sol";
import "./PullPayment.sol";
import "./Brand.sol";

contract Minter is Ownable, PullPayment {
  Brand private _token;

  // minting management
	bool public mintEnabled;
	uint256 public mintPrice;
	uint256 public invitedMintDiscount;
	uint256 public invitedMintMaxDiscount;
	uint256 public discountedThresholdAmount;
	uint256 public discountThreshold;

  // ref management
  mapping (address => address) public referral;
  uint256 public inviterMintReward;
  uint256 public inviterMintMaxReward;

	// custom sells to partners
	mapping (address => uint256) public partnersThresholds;
	mapping (address => uint256) public partnersPrices;

  // payout vaults
	enum Vault {
		CREATORS,
		BRAND,
		CHARITY
	}
	mapping (Vault => address) public vaults;

  constructor(
    address token_, 
    address creatorsVault_, 
    address brandVault_, 
    address charityVault_, 
    uint256 mintPrice_, 
    uint256 invitedMintDiscount_, 
    uint256 invitedMintMaxDiscount_, 
    uint256 discountedThresholdAmount_,
    uint256 discountThreshold_,
    uint256 inviterMintReward_,
    uint256 inviterMintMaxReward_
  ) {
    _token = Brand(token_);

    mintPrice = mintPrice_;
    invitedMintDiscount = invitedMintDiscount_;
    invitedMintMaxDiscount = invitedMintMaxDiscount_;
    discountedThresholdAmount = discountedThresholdAmount_;
    discountThreshold = discountThreshold_;
    inviterMintReward = inviterMintReward_;
    inviterMintMaxReward = inviterMintMaxReward_;

    vaults[Vault.CREATORS] = creatorsVault_;
    vaults[Vault.BRAND] = brandVault_;
    vaults[Vault.CHARITY] = charityVault_;
  }

  // -- LOGIC IMPLEMENTATION ---------

  function partnerMint(uint256 amount_) public payable returns(bool) {
		require(mintEnabled == true, "Mint is closed.");
		require((partnersThresholds[msg.sender] - amount_) >= 0, "You already minted your NFTs.");
		require(msg.value >= (partnersPrices[msg.sender] * amount_), "Please check amount sent for mint.");

		_token.mint(msg.sender, amount_);
		partnersThresholds[msg.sender] -= amount_;

		_splitPayment(msg.value);

		return true;
	}

  function mint(uint256 amount_, address inviter_, bytes memory inviterSignature_, bytes32 inviterSignatureHash_) public payable returns(bool) {
    require(mintEnabled == true, "Mint is closed.");
    require(amount_ > 0, "Amount should be at least 1");
    require(msg.sender != inviter_, "You cannot invite yourself.");
    
    uint256 inviterTokenBalance;
    bool isInvited = false;
    if(inviter_ != address(0)) {
      inviterTokenBalance = _token.balanceOf(inviter_);
      require(SignatureChecker.isValidSignatureNow(inviter_, inviterSignatureHash_, inviterSignature_), "The inviter signature is invalid.");
      require(inviterTokenBalance > 0, "The inviter has no tokens.");
      require(referral[msg.sender] == address(0), "You have already minted with an invite.");
      isInvited = true;
    }

    require(msg.value >= calculateMintPrice(amount_, isInvited), "Please check amount sent for mint.");

    uint256 sentToInviter = _payoutInviter(inviter_, inviterTokenBalance, amount_);
    
    referral[msg.sender] = inviter_;
    _token.mint(msg.sender, amount_);
    
    _splitPayment(msg.value - sentToInviter);

    return true;
  }

	function reveal(string memory uri_) public onlyOwner {
		_token.reveal(uri_);
	}

	function toggleMint() public onlyOwner {
		mintEnabled = !mintEnabled;
	}

	function setMintPrice(uint256 price_) public onlyOwner {
		mintPrice = price_;
	}
	
  function setInvitedMintDiscountAndMaxDiscount(uint256 discount_, uint256 maxDiscount_) public onlyOwner {
    invitedMintDiscount = discount_;
    invitedMintMaxDiscount = maxDiscount_;
  }

  function setInviterMintRewardAndMaxReward(uint256 reward_, uint256 maxReward_) public onlyOwner {
    inviterMintReward = reward_;
    inviterMintMaxReward = maxReward_;
  }

	function setDiscountForThreshold(uint256 discount_, uint256 threshold_) public onlyOwner {
		discountedThresholdAmount = discount_;
    discountThreshold = threshold_;
	}

	function setPartnerThresholdAndPrice(address partner_, uint256 threshold_, uint256 price_) public onlyOwner {
		partnersThresholds[partner_] = threshold_;
    partnersPrices[partner_] = price_;
	}

  function setVault(Vault vault_, address address_) public onlyOwner {
		vaults[vault_] = address_;
	}

  function donate() payable public {
    _splitPayment(msg.value);
  }

  function calculateMintPrice(uint256 amount_, bool isInvited_) public view returns(uint256) {
    if(amount_ == 0) {
      return 0;
    }
    
    uint256 price = mintPrice * amount_;
    
    if(amount_ >= discountThreshold) {
      uint256 totalThresholdDiscount = uint(uint(amount_) / uint(discountThreshold)) * discountedThresholdAmount;
      price -= totalThresholdDiscount;
    }

    if(isInvited_) {
      uint256 totalInvitationDiscount = invitedMintDiscount * amount_;
      if(totalInvitationDiscount > invitedMintMaxDiscount) {
        totalInvitationDiscount = invitedMintMaxDiscount;
      }
      price -= totalInvitationDiscount;
    }

    return price;
  }

	function _splitPayment(uint256 amount_) private {
    _asyncTransfer(vaults[Vault.CREATORS], amount_ / 100 * 40);
    _asyncTransfer(vaults[Vault.BRAND], amount_ / 100 * 40);
    _asyncTransfer(vaults[Vault.CHARITY], amount_ / 100 * 20);
	}

  function _payoutInviter(address inviter_, uint256 inviterTokenBalance_, uint256 amount_) private returns(uint256) {
    if(inviterTokenBalance_ == 0) {
      return 0;
    }

    uint256 rewardPerMint = inviterTokenBalance_ * inviterMintReward;
    if(rewardPerMint > inviterMintMaxReward) {
      rewardPerMint = inviterMintMaxReward;
    }
    
    uint256 sentToInviter = rewardPerMint * amount_;
    payable(inviter_).transfer(sentToInviter);

    return sentToInviter;
  }
}