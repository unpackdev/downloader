// SPDX-License-Identifier: MIT
/**
 * @title obscurityDAO
 * @email obscuirtyceo@gmail.com
 * @dev Nov 3, 2020
 * ERC-20 
 * obscurityDAO Copyright and Disclaimer Notice:
 */
pragma solidity ^0.8.7 <0.9.0;

import "./IERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ECDSAUpgradeable.sol";

import "./founders.sol";


contract crowdsalePhaseZero is IERC20Upgradeable, FounderWallets, ReentrancyGuardUpgradeable { // ContextUpgradeable, 

    event DepositFunds(address indexed sender, uint amount, uint balance);
    
    IERC20Upgradeable private _token;

    address private _wallet;

    address payable _walletAddress;

    uint256 private _rate;
    uint256 private _ethAmountForSale;
    uint256 private _currentPhase;

    uint256 private initializedPhaseTwo;
    uint256 private initializedPhaseThree;
    uint256 private initializedPhaseFour;

    uint256 private _weiRaised;

    uint256 private phaseTwoETHAmount; // change before release depending on ETH price
    uint256 private phaseThreeETHAmount; // change before release depending on ETH price
    uint256 private phaseFourETHAmount; // change before release depending on ETH price

    uint256 _crowdSalePaused;
    uint256 private _crowdSalePhaseZeroInitialized; 
    mapping(address => bytes32[]) usedMessages;

    function initialize() initializer public {      
        require(_crowdSalePhaseZeroInitialized == 0);
        _crowdSalePhaseZeroInitialized = 1;
        _founders_init();
        __Context_init();
        __ReentrancyGuard_init();
        _ethAmountForSale = 200;
        setPhase(1);
        _rate = 5; //1;
        _walletAddress = payable(address(0x920Bf81087C296D57B4F7f5fCfd96cA71582F066)); // company wallet proxy address
        _wallet = address(0x920Bf81087C296D57B4F7f5fCfd96cA71582F066); // company wallet proxy address
        _token = IERC20Upgradeable(address(0x1d036Bbb3535a112186103a51A93B452307Ebd30)); // OBSC token proxy address
        
        _setupRole(DEFAULT_ADMIN_ROLE, tx.origin);
        _setupRole(globals.ADMIN_ROLE, tx.origin);
        _grantRole(globals.UPGRADER_ROLE, tx.origin);

        _setupRole(globals.PAUSER_ROLE, address(0x60A7A4Ce65e314642991C46Bed7C1845588F6cD0));
        _setupRole(globals.PAUSER_ROLE, address(0x6188b15bAE64416d779560D302546e5dE15E5d1E));

        phaseTwoETHAmount = 600;
        phaseThreeETHAmount = 4000;
        phaseFourETHAmount = 20000;
    }

    receive() external payable {
        emit DepositFunds(tx.origin, msg.value, _wallet.balance); 
        _forwardFunds();
    }

    function _forwardFunds() internal {
       (bool success, ) = _wallet.call{value:msg.value}("");
        require(success, "Transfer failed.");
    }

    function getPhaseZeroAddress() public view returns(address)
    {
        return address(this);
    }

    function getTokenAddress() public view returns(IERC20Upgradeable)
    {
        return _token;
    }

    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    fallback() external payable  {
        buyTokens(_msgSender());
    }

    function token() public view returns (IERC20Upgradeable) {
        return _token;
    }

    function rate() public view returns (uint256) {
        return _rate;
    }

    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    function buyTokens(address beneficiary) public payable  nonReentrant() {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        // update state
        _weiRaised = _weiRaised + weiAmount;

        _processPurchase(beneficiary, tokens);
        emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);

        _updatePurchasingState(beneficiary, weiAmount);

        _forwardFunds();
        _postValidatePurchase(beneficiary, weiAmount);
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0), "0");
        require(weiAmount != 0, "1");
        require(_crowdSalePaused == 0);
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    function _postValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        // solhint-disable-previous-line no-empty-blocks
    }

    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.transferForCrowdSale(address(ADMIN_ADDRESS), beneficiary, tokenAmount);
    }

    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _deliverTokens(beneficiary, tokenAmount);
    }

    function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal {
        // solhint-disable-previous-line no-empty-blocks
    }

    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount * ((10**9) * _rate / _ethAmountForSale); // 10^7 * 5 5B 1 eth  200eth 2500/eth
        //return weiAmount * ((10**9) * _rate / 600); // 10^7 * 9 9B 1 eth  600eth 2500/eth
    }

    function pauseSale() 
    public {
        require(hasRole(PAUSER_ROLE, msg.sender), "C");
        _crowdSalePaused = 1;
    }

    function unpauseSale()
    public {
        require(hasRole(PAUSER_ROLE, msg.sender), "C");
        _crowdSalePaused = 0;
    }

    function setPhaseTwoRate(uint256 ethAmount)
    public {
        require(hasRole(PAUSER_ROLE, msg.sender), "C");
        require(_currentPhase == 1);
        phaseTwoETHAmount = ethAmount;
    }

    function setPhaseThreeRate(uint256 ethAmount)
    public {
        require(hasRole(PAUSER_ROLE, msg.sender), "C");
        require(_currentPhase == 2);
        phaseThreeETHAmount = ethAmount;
    }

    function setPhaseFourRate(uint256 ethAmount)
    public {
        require(hasRole(PAUSER_ROLE, msg.sender), "C");
        require(_currentPhase == 3);
         phaseFourETHAmount = ethAmount;
    }

    function initiatePhaseTwo()
    public {
        require(hasRole(PAUSER_ROLE, msg.sender), "C");
        require(initializedPhaseTwo != 1, "A.");
        require(_currentPhase == 1);
        initializedPhaseTwo = 1;
        pauseSale();
        setRate(9);
        setETHAmount(phaseTwoETHAmount);
        setPhase(2);
        unpauseSale();
    }

    function initiatePhaseThree()
    public  {
        require(hasRole(globals.PAUSER_ROLE, msg.sender), "C");
        require(initializedPhaseThree != 1);
        initializedPhaseThree = 1;
        require(_currentPhase == 2);
        pauseSale();
        setRate(36);
        setETHAmount(phaseThreeETHAmount);
        setPhase(3);
        unpauseSale();
    }

    function initiatePhaseFour()
    public  {
        require(hasRole(PAUSER_ROLE, msg.sender), "C");
        require(initializedPhaseFour != 1);
        require(_currentPhase == 3);
        initializedPhaseFour = 1;
        pauseSale();
        setRate(50);
        setETHAmount(phaseFourETHAmount);
        setPhase(4);
        unpauseSale();
    }

    function getPhaseTwoETHRate() public view returns (uint256) {
        return phaseTwoETHAmount; 
    }

    function getPhaseThreeETHRate() public view returns (uint256) {
        return phaseThreeETHAmount; 
    }

    function getPhaseFourETHRate() public view returns (uint256) {
        return phaseFourETHAmount; 
    }

    function getSalePhase() public view returns (uint256) {
        return _currentPhase; 
    }

    function getSaleRate() public view returns (uint256) {
        return _rate; 
    }

    function getSaleETHAmount() public view returns (uint256) {
        return _ethAmountForSale; 
    }

    function setPhase(uint256 newPhase) internal {
        _currentPhase = newPhase;
    }

    function setRate(uint256 newRate) internal {
        _rate = newRate;
    }

     function setETHAmount(uint256 newAmount) internal {
        _ethAmountForSale = newAmount;
    }

    /*overrides*/
    function allowance(address owner, address spender) external override view returns (uint256) {
        _token.allowance(owner, spender);
    } 

    function approve(address spender, uint256 amount) external override returns (bool) {
        return _token.approve(spender, amount);
    }

    function totalSupply() external override view returns (uint256) {
        return _token.totalSupply();
    }

    function balanceOf(address account) external override view returns (uint256) {
        return _token.balanceOf(account);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _token.transfer(recipient, amount);
    }

    function transferForCrowdSale(
        address sender,
        address recipient,
        uint256 amount
    ) external override {
        _token.transferForCrowdSale(sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _token.transferFrom(sender, recipient, amount);
    }

    /*Founder functions - ETH Amount*/ 
    function completeETHAmountChangeProposal(uint256 proposalID)
    public 
    virtual onlyRole(PAUSER_ROLE) {
        if(founderExecution(proposalID) == 1)
        {
            setETHAmount(proposalVotes[proposalID].newAmount);
        }
    }
    
    function createETHAmountChangeProposal(uint256 newAmount, bytes32 desc) 
    public 
    virtual
    nonReentrant() 
    onlyRole(PAUSER_ROLE)  {
        _createETHAmountProposal(newAmount, desc);
    }

    function getPState(uint256 proposalID) 
    public 
    view returns (uint256) {
        return gPState(proposalID);
    }

    function getPDesc(uint256 proposalID) 
    public 
    view returns (bytes32) {
        return gPDesc(proposalID);
    }

    function founderETHAmountChangeVote(
        uint256  proposalID,
        uint256 vote,
        address to, 
        uint256 amount, 
        string memory message,
        uint nonce,
        bytes memory signature
    ) external 
    nonReentrant()
    onlyRole(PAUSER_ROLE) {
        if (tx.origin == founderOne.founderAddress) {
            require(verify(founderOne.founderAddress, to, amount, message, nonce, signature) == true, "O");
            f1VoteOnETHAmountChangeProposal(vote, proposalID);
        }
        if (tx.origin == founderTwo.founderAddress) {
            require(verify(founderTwo.founderAddress, to, amount, message, nonce, signature) == true, "T");
            f2VoteOnETHAmountChangeProposal(vote, proposalID);
        }
    }
    

    /*Founder Functions - Addr*/
    function completeAddrTransferProposal(uint256 proposalID)
    public 
    virtual onlyRole(PAUSER_ROLE) {
        addressSwapExecution(proposalID);
    }
    
    function createAddrTransferProposal(address payable oldAddr, address payable newAddr, bytes32 desc)  
    public 
    virtual
    nonReentrant() 
    onlyRole(PAUSER_ROLE) {
        _createAddressSwapProposal(oldAddr, newAddr, desc);
    }

    function getAddrPState(uint256 proposalID) 
    public 
    view returns (uint256) {
        return gPSwapState(proposalID);
    }

    function getAddrPDesc(uint256 proposalID) 
    public 
    view returns (bytes32) {
        return gPSwapDesc(proposalID);
    }

    function founderAddrVote(
        uint256  proposalID,
        uint256 vote,
        address to, 
        uint256 amount, 
        string memory message,
        uint nonce,
        bytes memory signature
    ) external 
    nonReentrant()
    onlyRole(PAUSER_ROLE) {
        if (tx.origin == founderOne.founderAddress) {
            require(verify(founderOne.founderAddress, to, amount, message, nonce, signature) == true);
            f1VoteOnSwapProposal(vote, proposalID);
        }
        if (tx.origin == founderTwo.founderAddress) {
            require(verify(founderTwo.founderAddress, to, amount, message, nonce, signature) == true);
            f2VoteOnSwapProposal(vote, proposalID);
        }
    }

    /*Signature Methods*/
    function getMessageHash(
       address _to,
       uint _amount,
       string memory _message,
       uint _nonce
    ) 
    public 
    pure returns (bytes32) {
        return keccak256(abi.encode(_to, _amount, _message, _nonce));
    }

    function verify(
        address _signer,
        address _to,
        uint _amount,
        string memory _message,
        uint _nonce,
        bytes memory signature
    ) 
    public returns (bool) {
        bytes32 messageHash = getMessageHash(_to, _amount, _message, _nonce);

        for(uint i = 0; i < usedMessages[tx.origin].length; i++) {
            require(usedMessages[tx.origin][i] != messageHash);
        }
        bool temp = recoverSigner(messageHash, signature) == _signer;
        if (temp)
            usedMessages[tx.origin].push(messageHash);
        return temp;
    }

    function recoverSigner(bytes32 msgHash, bytes memory _signature)
    public
    pure returns (address) {
        bytes32 _temp = ECDSAUpgradeable.toEthSignedMessageHash(msgHash);
        address tempAddr = ECDSAUpgradeable.recover(_temp, _signature);
        return tempAddr;
    }
}
