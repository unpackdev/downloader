// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

//@author Nifby.xyz
//@title Minterans

import "./Ownable.sol";

import "./PaymentSplitter.sol";
import "ERC721A.sol";
error SupplyExceeded(string message);


contract Minterans is Ownable, ERC721A, PaymentSplitter {

    string private _baseTokenURI;

    bool public baseTokenPrerevealURIisActive = false;
    bool public baseTokenURIHasBeenSet = false;

    bool public whiteListStepActivated = false;
    bool public mainSaleStepActivated = false;

    uint16 public MAX_SUPPLY = 1000;

    uint256 public onGoingFees = 0 ether;
    uint256 public feesPerNft = 0.00055 ether;

    uint256 public PUBLIC_PRICE = 0.01 ether;
    uint32 public PUBLIC_START_TIME = 1702807200;
    uint16 public PUBLIC_MAX_TOKEN_PER_WALLET= 50;
    mapping(address => uint256) public amountNFTsperWalleSale;

    uint256 private teamLength;


    bool public paused;

    struct ReferralConf {
      address owner;
      uint16 discountPerTenThousand;
      uint16 revenuPerTenThousand;
      uint256 mintCount;
    }
    // referralCode => ReferralConf
    mapping(string => ReferralConf) public referrals;

    uint8 nifbyReferralsPerTenThousand = 125;

    constructor(address[] memory _team, uint256[] memory _teamShares) ERC721A("Minterans", "MINTERANS")
    PaymentSplitter(_team, _teamShares) {
        
        teamLength = _team.length;
    }

    modifier callerIsUser() {
      require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
    modifier notPaused(){
      require(paused == false, "Mint paused");
      _;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
      return 1;
    }


    function ownerMint(address _account, uint256 _quantity) external payable callerIsUser onlyOwner {

      if(totalSupply() + _quantity > MAX_SUPPLY) revert SupplyExceeded("Supply exceeded");

      CostGuard(feesPerNft, _quantity);
      onGoingFees += feesPerNft * _quantity;
      _safeMint(_account, _quantity);
    }

    function addReferral(string memory referralCode, address account, uint16 discountPerTenThousand, uint16 revenuPerTenThousand) external onlyOwner {

        ReferralConf memory newReferral;
        newReferral.owner = account;
        newReferral.discountPerTenThousand = discountPerTenThousand;
        newReferral.revenuPerTenThousand = revenuPerTenThousand;
        newReferral.mintCount = 0;

        referrals[referralCode] = newReferral;
    }

    function referralMint(address _account, uint256 _quantity, string memory referralCode) external payable callerIsUser notPaused
    {

      ReferralConf memory referralConf = referrals[referralCode];

      require(abi.encode(referralConf).length > 0, "Invalid referral code");

      publicSaleMintGuards(_quantity);

      //uint256 memory priceWithDiscount = PUBLIC_PRICE - ((PUBLIC_PRICE * referralConf.discountPerTenThousand) / 10000) ;
      CostGuard((PUBLIC_PRICE - ((PUBLIC_PRICE * referralConf.discountPerTenThousand) / 10000)) + feesPerNft, _quantity);

      //uint256 memory referralNifbyFee = (PUBLIC_PRICE * nifbyReferralsPerTenThousand) / 10000;
      onGoingFees += (feesPerNft + ((PUBLIC_PRICE * nifbyReferralsPerTenThousand) / 10000)) * _quantity;
      _safeMint(_account, _quantity);
      if(referralConf.revenuPerTenThousand>0){
        Address.sendValue(payable(referralConf.owner), (PUBLIC_PRICE * referralConf.revenuPerTenThousand) / 10000);
      }
      referrals[referralCode].mintCount += 1;
    }

    function publicSaleMint(address _account, uint256 _quantity) external payable callerIsUser notPaused {

      publicSaleMintGuards(_quantity);

      CostGuard(PUBLIC_PRICE + feesPerNft, _quantity);
      amountNFTsperWalleSale[msg.sender] += _quantity;
      onGoingFees += feesPerNft * _quantity;
      _safeMint(_account, _quantity);
    }

    function publicSaleMintGuards(uint256 _quantity) internal view {
      require(mainSaleStepActivated, "Public sale is not activated");
      require(currentTime() >= PUBLIC_START_TIME, "Public sale has not started yet");

      require(amountNFTsperWalleSale[msg.sender] + _quantity <= PUBLIC_MAX_TOKEN_PER_WALLET, "Max token per wallet reach");

      if(totalSupply() + _quantity > MAX_SUPPLY ) revert SupplyExceeded("Supply exceeded");
    }

    function setPUBLIC_START_TIME(uint32 _PUBLIC_START_TIME) external onlyOwner {
      PUBLIC_START_TIME = _PUBLIC_START_TIME;
    }

    function _baseURI() internal view override returns (string memory) {
      return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
      baseTokenURIHasBeenSet = true;
      baseTokenPrerevealURIisActive = false;
      _baseTokenURI = baseURI;
    }

    function setBasePrerevealURI(string calldata baseURI) external onlyOwner {
      baseTokenPrerevealURIisActive = true;
      _baseTokenURI = baseURI;
    }

    /**
    * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
    */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
      if (!_exists(tokenId)) _revert(URIQueryForNonexistentToken.selector);

      string memory baseURI = _baseURI();
      return
          bytes(baseURI).length != 0
              ? baseTokenPrerevealURIisActive ? string(baseURI) : string(abi.encodePacked(baseURI, _toString(tokenId)))
              : '';
    }

    function currentTime() internal view returns(uint) {
      return block.timestamp;
    }

    function setwhiteListStepActivated(bool  _whiteListStepActivated) external onlyOwner {
      whiteListStepActivated = _whiteListStepActivated;
    }

    function setmainSaleStepActivated(bool  _mainSaleStepActivated) external onlyOwner {
      mainSaleStepActivated = _mainSaleStepActivated;
    }



    function CostGuard(uint256 cost, uint256 _quantity) internal{
      require(msg.value >= cost * _quantity, "Not enought funds");
    }

    /**
    * @dev Getter for the amount of payee\'s releasable Ether.
    */
    function releasable(address account) public view override returns (uint256) {
      uint256 balanceWithoutOnGoingNifbyFees =  address(this).balance - onGoingFees;
      uint256 totalReceived = balanceWithoutOnGoingNifbyFees + totalReleased();
      return _pendingPayment(account, totalReceived, released(account));
    }

    //ReleaseALL native BC coin
    function releaseAll() external {
       releaseNifbyFees();

      for(uint i = 0 ; i < teamLength ; i++) {
          release(payable(payee(i)));
      }
    }

    /**
    * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
    * total shares and their previous withdrawals.
    */
    function release(address payable account) public virtual override {
      require(_shares[account] > 0, 'PaymentSplitter: account has no shares');

      uint256 payment = releasable(account);

      require(payment != 0, 'PaymentSplitter: account is not due payment');

      // _totalReleased is the sum of all values in _released.
      // If "_totalReleased += payment" does not overflow, then "_released[account] += payment" cannot overflow.
      _totalReleased += payment;
      unchecked {
          _released[account] += payment;
      }

      Address.sendValue(account, payment);
      emit PaymentReleased(account, payment);
    }

    // Manual release of nifby fees
    function releaseNifbyFees() public {
      if(onGoingFees != 0){
        Address.sendValue(payable(0x70e81C2Ce5D06E825Db1e2f10746B83BB317DEd0), onGoingFees);
        onGoingFees = 0 ether;
      }
    }

    function setPaused(bool _paused) external onlyOwner{
      paused = _paused;
    }

    receive() override external payable {
      revert('Only if you mint');
    }

    // List of editable data

    function __setMaxSupply(uint16 _MAX_SUPPLY) external onlyOwner {
      require(_MAX_SUPPLY < MAX_SUPPLY, "You cannot increase the max supply");
      MAX_SUPPLY = _MAX_SUPPLY;
    }

    function __setPublicPrice(uint _PUBLIC_PRICE) external onlyOwner {
      PUBLIC_PRICE  = _PUBLIC_PRICE;
    }


    function __setPublicStartTime(uint32 _PUBLIC_START_TIME) external onlyOwner {
      PUBLIC_START_TIME  = _PUBLIC_START_TIME;
    }






}

