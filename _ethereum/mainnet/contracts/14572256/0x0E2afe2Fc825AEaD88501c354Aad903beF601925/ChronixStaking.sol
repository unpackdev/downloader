// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./ECDSA.sol";
import "./ContextUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Initializable.sol";

contract ChronixStaking is Initializable, ReentrancyGuardUpgradeable, ContextUpgradeable {
    ERC721A public ChronixNFT;
    ERC721A public KitsNFT;
    ERC721A public PushersNFT;

    uint256 public SECONDS_IN_DAY;
    uint public pot;
    address public signerAddress;
    address[] public authorisedContracts;
    address public owner;
    bool public stakingLaunched;
    bool public depositPaused;

    modifier onlyOwner(){
      require(_msgSender() == owner);
      _;
    }

    struct Staker {
      uint256 currentYield;
      uint256 accumulatedAmount;
      uint256 lastCheckpoint;
      uint256[] stakedChronix;
      uint256[] stakedKits;
      uint[] stakedPushers;
      uint ownPot;
    }

    enum ContractTypes {CRX,CRG,CRP}

    
    mapping(address => Staker) private _stakers;
    mapping(address => mapping(uint256 => address)) private _ownerOfToken;
    mapping(address => ContractTypes) private _contractTypes;
    mapping(address => uint) public traitsForContract;
    mapping(address => mapping(uint256 => uint256)) private _tokensInfo;
    mapping (address => bool) private _authorised;

    event Deposit(address indexed staker,address contractAddress,uint256 tokensAmount);
    event Withdraw(address indexed staker,address contractAddress,uint256 tokensAmount);
    event AutoDeposit(address indexed contractAddress,uint256 tokenId,address indexed owner);
    event WithdrawStuckERC721(address indexed receiver, address indexed tokenAddress, uint256 indexed tokenId);

    function initialize(address _crx,address _signerAddress,address _owner) initializer public {
        ChronixNFT = ERC721A(_crx);
        _contractTypes[_crx] = ContractTypes.CRX;
        SECONDS_IN_DAY = 24 * 60 * 60;
        owner= _owner;
        signerAddress = _signerAddress;
    }
    modifier authorised() {
      require(_authorised[_msgSender()], "The token contract is not authorised");
        _;
    }
    function getPotTax(address staker) public view returns(uint) {
        Staker memory user = _stakers[staker];
        if(user.stakedChronix.length !=0 && user.stakedPushers.length !=0){
           return (pot- user.ownPot)*((user.stakedPushers.length * 10000) / ERC721A(PushersNFT).totalSupply()) /10000;
        }
        else {
          return 0;
        }
        
    }
    function deposit(address contractAddress,uint256[] memory tokenIds,uint256[] memory tokenTraits,bytes calldata signature) public nonReentrant {
      require(!depositPaused, "Deposit paused");
      require(stakingLaunched, "Staking is not launched yet");
      require(contractAddress != address(0) && contractAddress == address(ChronixNFT) || contractAddress == address(KitsNFT) || contractAddress == address(PushersNFT),"Unknown contract");
      ContractTypes contractType = _contractTypes[contractAddress];
      
      if (tokenTraits.length > 0 && contractType == ContractTypes.CRX) {
        require(_validateSignature(signature,contractAddress,tokenIds,tokenTraits), "Invalid data provided");
        _setTokensInfo(contractAddress, tokenIds, tokenTraits);
      }
      

      Staker storage user = _stakers[_msgSender()];
      
      if(contractType != ContractTypes.CRX) {
        require(user.stakedChronix.length != 0, "You need to have a chronix staked");
      }
      
      uint256 newYield = user.currentYield;
        user.accumulatedAmount = user.accumulatedAmount + getCurrentReward(_msgSender()) ;

      for (uint256 i; i < tokenIds.length; i++) {
        require(ERC721A(contractAddress).ownerOf(tokenIds[i]) == _msgSender(), "Not the owner");
        ERC721A(contractAddress).safeTransferFrom(_msgSender(), address(this), tokenIds[i]);

        _ownerOfToken[contractAddress][tokenIds[i]] = _msgSender();

        
        
        
        
            if (contractType == ContractTypes.CRG || contractType == ContractTypes.CRX) {
             newYield += getTokenYield(contractAddress, tokenIds[i]);
           }

          
        if (user.stakedChronix.length ==0 && user.stakedPushers.length !=0) { user.ownPot=pot; }
        if (contractType == ContractTypes.CRX) { user.stakedChronix.push(tokenIds[i]); }
        if (contractType == ContractTypes.CRG) { user.stakedKits.push(tokenIds[i]); }
        if (contractType == ContractTypes.CRP) { 
          user.stakedPushers.push(tokenIds[i]); 
          user.accumulatedAmount +=getPotTaxOf(user.stakedPushers.length,_msgSender());
          user.ownPot=pot;
        }
        
      }

      accumulate(_msgSender());
      user.currentYield = newYield;

      emit Deposit(_msgSender(), contractAddress, tokenIds.length);
    }
    function withdraw(  address contractAddress,uint256[] memory tokenIds) public nonReentrant {
      require(contractAddress != address(0) && contractAddress == address(ChronixNFT) || contractAddress == address(PushersNFT) || contractAddress == address(KitsNFT),"Unknown contract");
      ContractTypes contractType = _contractTypes[contractAddress];
      Staker storage user = _stakers[_msgSender()];
      uint256 newYield = user.currentYield;
      
       user.accumulatedAmount = user.accumulatedAmount + getCurrentReward(_msgSender()) ;
      for (uint256 i; i < tokenIds.length; i++) {
        require(ERC721A(contractAddress).ownerOf(tokenIds[i]) == address(this), "Not the owner");
        require(_ownerOfToken[contractAddress][tokenIds[i]]== _msgSender());

        _ownerOfToken[contractAddress][tokenIds[i]] = address(0);

        if (user.currentYield != 0 && contractType !=ContractTypes.CRP) {
          uint256 tokenYield = getTokenYield(contractAddress, tokenIds[i]);
          newYield -= tokenYield;
        }

        if (contractType == ContractTypes.CRX && user.stakedChronix.length ==1) { 
          user.accumulatedAmount +=getPotTaxOf(user.stakedChronix.length,_msgSender());
        }

        if (contractType == ContractTypes.CRX) {
          user.stakedChronix = _moveTokenInTheList(user.stakedChronix, tokenIds[i]);
          user.stakedChronix.pop();
        }
        if (contractType == ContractTypes.CRG) {
          user.stakedKits = _moveTokenInTheList(user.stakedKits, tokenIds[i]);
          user.stakedKits.pop();
        }
       

        if (contractType == ContractTypes.CRP) {
          user.stakedPushers = _moveTokenInTheList(user.stakedPushers, tokenIds[i]);
          user.stakedPushers.pop();
          user.accumulatedAmount +=getPotTaxOf(tokenIds.length,_msgSender());
         
         
        }
        
        ERC721A(contractAddress).safeTransferFrom(address(this), _msgSender(), tokenIds[i]);
      }

      accumulate(_msgSender());
      user.currentYield = newYield;

      emit Withdraw(_msgSender(), contractAddress, tokenIds.length);
    }
    function getTax(uint amount) public authorised {
        pot += amount;
    }
    function registerDeposit(address ownerOfToken, address contractAddress, uint256 tokenId) public authorised {
      require(contractAddress != address(0) && contractAddress == address(KitsNFT) || contractAddress == address(PushersNFT),"Unknown contract");
      
      require(ERC721A(contractAddress).ownerOf(tokenId) == address(this), "!Owner");
      require(ownerOf(contractAddress, tokenId) == address(0), "Already deposited");
      _ownerOfToken[contractAddress][tokenId] = ownerOfToken;
      Staker storage user = _stakers[ownerOfToken];
      

      ContractTypes contractType = _contractTypes[contractAddress];
      uint256 newYield = user.currentYield;
         if (contractType == ContractTypes.CRG) {  newYield += getTokenYield(contractAddress, tokenId); user.stakedKits.push(tokenId); }
         if (contractType == ContractTypes.CRP) { 
            user.stakedPushers.push(tokenId);    
            user.accumulatedAmount +=getPotTaxOf(user.stakedPushers.length,_msgSender());
            user.ownPot=pot;
            
         }
        
      accumulate(ownerOfToken);
      user.currentYield = newYield;

      emit AutoDeposit(contractAddress, tokenId, _msgSender());
    }
    function getAccumulatedAmount(address staker) external view returns (uint256) {
      return _stakers[staker].accumulatedAmount + getCurrentReward(staker) + getPotTax(staker) ;
    }
    function getTokenYield(address contractAddress, uint256 tokenId) public view returns (uint256) {
      uint256 tokenYield = _tokensInfo[contractAddress][tokenId];
      if(tokenYield ==0){
        
          tokenYield = traitsForContract[contractAddress];
        
      }
      return tokenYield;
    }
    function genesisCheck(address staker) public view returns(bool) {
      
      return(_stakers[staker].stakedChronix.length !=0);
    }
    function getStakerYield(address staker) public view returns (uint256) {
      return _stakers[staker].currentYield;
    }
    function getStakerPot(address staker) public view returns (uint256) {
      return pot - _stakers[staker].ownPot;
    }
    function getPotTaxOf(uint amount,address staker) public view returns(uint) {
        Staker memory user = _stakers[staker];
        if(user.stakedChronix.length !=0 && user.stakedPushers.length !=0){
           return (pot- user.ownPot)*((amount * 10000) / ERC721A(PushersNFT).totalSupply()) /10000;
        }
        else {
          return 0;
        }
        
    }
    function getStakerTokens(address staker) public view returns (uint256[] memory, uint256[] memory, uint256[] memory) {
      return (_stakers[staker].stakedChronix, _stakers[staker].stakedKits, _stakers[staker].stakedPushers);
    }
    function isInfoSet(address contractAddress, uint256 tokenId) public view returns (bool) {
      return _tokensInfo[contractAddress][tokenId] > 0;
    }
    function _moveTokenInTheList(uint256[] memory list, uint256 tokenId) internal pure returns (uint256[] memory) {
      uint256 tokenIndex = 0;
      uint256 lastTokenIndex = list.length - 1;
      uint256 length = list.length;

      for(uint256 i = 0; i < length; i++) {
        if (list[i] == tokenId) {
          tokenIndex = i + 1;
          break;
        }
      }
      require(tokenIndex != 0, "_msgSender() is not the owner");

      tokenIndex -= 1;

      if (tokenIndex != lastTokenIndex) {
        list[tokenIndex] = list[lastTokenIndex];
        list[lastTokenIndex] = tokenId;
      }

      return list;
    }
    function _validateSignature(
      bytes calldata signature,
      address contractAddress,
      uint256[] memory tokenIds,
      uint256[] memory tokenTraits
      ) internal view returns (bool) {
      bytes32 dataHash = keccak256(abi.encodePacked(contractAddress, tokenIds, tokenTraits));
      bytes32 message = ECDSA.toEthSignedMessageHash(dataHash);

      address receivedAddress = ECDSA.recover(message, signature);
      return (receivedAddress != address(0) && receivedAddress == signerAddress);
    }
    function _setTokensInfo(
      address contractAddress,
      uint256[] memory tokenIds,
      uint256[] memory tokenTraits
    ) internal {
      require(tokenIds.length == tokenTraits.length, "Wrong arrays provided");
      

      for (uint256 i; i < tokenIds.length; i++) {
        if (tokenTraits[i] != 0 && tokenTraits[i] <= 3000 ether) {
          _tokensInfo[contractAddress][tokenIds[i]] = tokenTraits[i];
        }
        
      }
    }
    function getCurrentReward(address staker) public view returns (uint256) {
      Staker memory user = _stakers[staker];
      
      if (user.stakedChronix.length !=0) {
        return (block.timestamp - user.lastCheckpoint) * user.currentYield / SECONDS_IN_DAY ;
      }
      else {
        return 0;
      }
      
    }
    function accumulate(address staker) internal {
      
      _stakers[staker].lastCheckpoint = block.timestamp;
    }  
    function ownerOf(address contractAddress, uint256 tokenId) public view returns (address) {
      return _ownerOfToken[contractAddress][tokenId];
    }
    function setKITSContract(address _KITS) public onlyOwner {
      KitsNFT = ERC721A(_KITS);
      _contractTypes[_KITS] = ContractTypes.CRG;
      
    }
    function setPUSHContract(address _PUSH) public onlyOwner {
      PushersNFT = ERC721A(_PUSH);
      _contractTypes[_PUSH] = ContractTypes.CRP;
     
      
    }
    function authorise(address toAuth) public onlyOwner {
      _authorised[toAuth] = true;
      authorisedContracts.push(toAuth);
    }
    function unauthorise(address addressToUnAuth) public onlyOwner {
      _authorised[addressToUnAuth] = false;
    }
    function emergencyWithdraw(address tokenAddress, uint256[] memory tokenIds) public onlyOwner {
      require(tokenIds.length <= 50, "50 is max per tx");
      pauseDeposit(true);
      for (uint256 i; i < tokenIds.length; i++) {
        address receiver = _ownerOfToken[tokenAddress][tokenIds[i]];
        if (receiver != address(0) && ERC721A(tokenAddress).ownerOf(tokenIds[i]) == address(this)) {
          ERC721A(tokenAddress).transferFrom(address(this), receiver, tokenIds[i]);
          emit WithdrawStuckERC721(receiver, tokenAddress, tokenIds[i]);
        }
      }
    }
    function pauseDeposit(bool _pause) public onlyOwner {
      depositPaused = _pause;
    }
    function setTraits(address contractAddress, uint tokenTraits) public onlyOwner{
      traitsForContract[contractAddress]=tokenTraits ;
    }
    function updateSignerAddress(address _signer) public onlyOwner {
      signerAddress = _signer;
    }
    function launchStaking() public onlyOwner {
      require(!stakingLaunched, "Staking has been launched already");
      stakingLaunched = true;
      
    }
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns(bytes4){
      return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }


    function _transferOwnership(address newOwner) public onlyOwner {
       
        owner = newOwner;
        
    }
}