//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IERC20Upgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IAddressContract.sol";
import "./IDao.sol";
import "./ITreasury.sol";

contract PCREW is ERC721Upgradeable, ERC721EnumerableUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {

    // state vars 
    IERC20Upgradeable public pirate;        
    IDao public dao;
 
    uint256 public nftConversionRate;
    uint256 public MAX_PIRATE;
    uint256 public collectedFee;
    address public treasury;
    uint public totalFeesCollected;
    string public baseURI;

    mapping(uint => uint) public tokenLocked;

    // events    
    event PirateCreated(address from, uint256 tokenAmount, uint256 NftId);
    event NFTRedeemedForTokens(address from, uint256 unlockAmount, uint256 NftId);
    event CollectFees(uint nftId, uint fee);

    function initialize() external initializer {
        __ERC721_init_unchained("Pirate Crew", "PCREW");
        __ERC721Enumerable_init_unchained();
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        nftConversionRate = 75_000_000 ether; 
        MAX_PIRATE = 25;
    }

    function setContractAddresses(IAddressContract _contractFactory) external onlyOwner {
        pirate =  IERC20Upgradeable(_contractFactory.getPirate());
        dao = IDao(_contractFactory.getDao());
        treasury = _contractFactory.getTreasury();
    }

    function mintPirate(uint256 numberOfPirates) external onlyOwner  {
        for (uint i = 0; i < numberOfPirates; i++) {
            _safeMint();
        }
    }

    function becomePirate() external nonReentrant {
        uint _rate = nftConversionRate;
        require(balanceOf(msg.sender) == 0, "becomePirate:: already pirate");
        require(pirate.balanceOf(msg.sender) >= _rate,"becomePirate:: Insufficient Balance");
        
        if (totalSupply() < MAX_PIRATE) {
            _safeMint();
        }

        require(balanceOf(address(this)) > 0 , "becomePirate:: no pirate available");
        uint nftId = tokenOfOwnerByIndex(address(this),0);
        tokenLocked[nftId] = _rate;
        _transfer(address(this), msg.sender, nftId);
        require(pirate.transferFrom(msg.sender, address(this), _rate), "becomePirate:: Tokens transfer failed");
        emit PirateCreated(msg.sender, _rate, nftId);
    }

    function unlockTokens(uint256 _pirateId) external nonReentrant {

        require(_exists(_pirateId), "unlockTokens:: NFT does not exist");
        require(msg.sender == ownerOf(_pirateId), "unlockTokens:: Only the owner can redeem the NFT");
        
        uint _acitvePid = dao.getActiveProposal(_pirateId);
        require(_acitvePid == 0, "unlockTokens:: There is active proposal with this Id");

        uint waitingTime = dao.getPirateWaitingTime(_pirateId);
        require(block.timestamp > waitingTime, "unlockTokens:: waiting time not over");

        uint _blackListPid = dao.getBlackistedProposal(_pirateId);
        uint unlockAmount = getUnlockAmount(_pirateId, _blackListPid);
        
        if (_blackListPid !=0 ) {
            uint lockAmount = tokenLocked[_pirateId];
            uint fee = lockAmount - unlockAmount;
            collectedFee += fee;
            dao.unlockBlacklistPirate(_pirateId); 
            emit CollectFees(_pirateId, fee);
        }
        
        tokenLocked[_pirateId] = 0;
        transferFrom(msg.sender, address(this), _pirateId);
        require(pirate.transfer(msg.sender, unlockAmount), "unlockTokens:: Tokens transfer failed");

        emit NFTRedeemedForTokens(msg.sender, unlockAmount, _pirateId);
    }


    function getUnlockAmount(uint _pirateId, uint _blackListPid) public view returns(uint) {
        uint unlockAmount;
        if (_blackListPid == 0) {
            unlockAmount = tokenLocked[_pirateId];
        }
        else {
            uint lockedAmount = tokenLocked[_pirateId];
            uint refundedAmountEth = dao.getRefundAmount(_blackListPid);        
            uint judgmentAmountEth = dao.getJudgementAmount(_blackListPid);     
            uint _lockedAmountValueInEth = ITreasury(treasury).getExpectedEth(lockedAmount);
            uint amountDiff;
            if (judgmentAmountEth > refundedAmountEth) {
              amountDiff = judgmentAmountEth - refundedAmountEth; 
            }             

            if (amountDiff > _lockedAmountValueInEth) {                
                unlockAmount = 0;
            } else {
                uint penaltyAmount;
                if (amountDiff > 0) {
                  penaltyAmount = ITreasury(treasury).getExpectedPirateToken(amountDiff); 
                }
                if (lockedAmount > penaltyAmount) {
                   unlockAmount = lockedAmount - penaltyAmount;                             
                }
            }                                
        }

        return unlockAmount;
    }

    function changeConversionRate(uint _rate) external onlyOwner  {
        nftConversionRate = _rate;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function sendFeestoTreasury() external onlyOwner  {
        if (collectedFee > 0) {
            totalFeesCollected = totalFeesCollected + collectedFee;
            require(pirate.transfer(treasury, collectedFee), "sendFeestoTreasury:: Tokens transfer failed");
            collectedFee = 0;   
        }
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
		return IERC721ReceiverUpgradeable.onERC721Received.selector;
	}

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable, ERC721EnumerableUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _safeMint() internal {
        uint256 tokenId = totalSupply() + 1;
        require(tokenId <= MAX_PIRATE, "_safeMint:: Max Mint reached!");
        _safeMint(address(this), tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}
