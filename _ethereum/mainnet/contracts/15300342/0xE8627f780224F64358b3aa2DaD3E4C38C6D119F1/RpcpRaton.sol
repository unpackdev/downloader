// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/// @title Contract of Rpcp NFTs collection
/// @author Johnleouf21

import "./ERC721A.sol";
import "./Strings.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./ReentrancyGuard.sol";

contract RpcpRaton is ERC721A, PaymentSplitter, Ownable, ReentrancyGuard {


    //To concatenate the URL of an NFT
    using Strings for uint256;
   
    uint public constant LIMIT_SUPPLY_RATON = 1000;

    uint256 public constant COMMISSION_RATE = 5;
    uint256 public constant COMMISSION_CYCLE = 30 * 24 * 60 * 60;
 
    uint public max_mint_allowed = 500;

    uint public priceRaton = 500000000; //500 with 6 decimals

    string public baseURIRaton;

    string public baseExtension = ".json";

    //Is the contract paused ?
    bool public paused = false;
    address public  tokenAddress;
    //The different stages of selling the collection
    enum Steps {
        Before,
        SaleRaton,
        SoldOut
    }

    Steps public sellingStep;

  //Log of bought nfts
  event CommissionWithdraw(address indexed buyer, uint256 indexed amount);

  struct SaleLog {
    uint256 unitPrice;
    uint256 qty;
    uint256 startTokenId;
    uint256 lastWithdraw;
  }

  mapping(address => SaleLog[]) saleLogs;
    
    //Owner of the smart contract
    address private _owner;
    uint256 private _currentIndex;

    //Keep a track of the number of tokens per address
    mapping(address => uint) nftsPerWallet;

    uint private teamLength;

    //Addresses of all the members of the team
    address[] private _team = [
        0xe2A958245323575753f4937EAd597587499CDd9B,
        0x27846b664A6242f1DaE9b96e89c30D579ACECC3F,
        0x7EEAaD9C49c5422Ea6B65665146187A66F22c48E,
        0x2005B0314DD86741bbc436e0448f2be42e2f4c69,
        0x32a8Da1ad9D63126E1Fb2293710e1Bad58AffD34,
        0x4a8E9AfFC6323A5338DC6b83Db4E717B5c062624,
        0xc119240Bd828FA36b7342dDf2eE4737b18afAc6A
    ];
    uint[] private _teamShares = [
        85, 
        10,
        1,
        1,
        1,
        1,
        1
    ];

    //Constructor of the collection
    constructor(string memory _theBaseURIRaton, address _tokenAddress) ERC721A("Rpcp", "RPCP") PaymentSplitter(_team, _teamShares) {
        transferOwnership(msg.sender);
        sellingStep = Steps.Before;
        baseURIRaton = _theBaseURIRaton;
        teamLength = _team.length;
        tokenAddress = _tokenAddress;
    }

    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }

    /** 
    * @notice Change the number of NFTs that an address can mint
    *
    * @param _maxMintAllowed The number of NFTs that an address can mint
    **/
    function changeMaxMintAllowed(uint _maxMintAllowed) external onlyOwner {
        max_mint_allowed = _maxMintAllowed;
    }

    function setBaseUriRaton(string memory _newBaseURIRaton) external onlyOwner {
        baseURIRaton = _newBaseURIRaton;
    }

    /**
    * @notice Return URI of the NFTs when revealed
    *
    * @return The URI of the NFTs when revealed
    **/
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURIRaton;
    }

    function setBaseExtension(string memory _baseExtension) external onlyOwner {
        baseExtension = _baseExtension;
    }

    function setUpSaleRaton() external onlyOwner {
        sellingStep = Steps.SaleRaton;
    }

    function addSaleLog(
        address _buyer,
        uint256 price,
        uint256 qty
    ) internal {
        saleLogs[_buyer].push(SaleLog(price, qty, _currentIndex + 1, block.timestamp));
    }

    function getBillableCommissionCycle(uint256 lastWithdraw, uint256 currentTime)
        internal
        pure
        returns (uint256)
    {
        uint256 duration = currentTime - lastWithdraw;
        return duration / COMMISSION_CYCLE;
    }

    function calculateCommission(address _buyer, uint256 currentTime)
        internal
        view
        returns (uint256)
    {
        uint256 amount = 0;

        for (uint256 i = 0; i < saleLogs[_buyer].length; i++) {
        SaleLog memory saleLog = saleLogs[_buyer][i];
        uint256 billableCycle = getBillableCommissionCycle(
            saleLog.lastWithdraw,
            currentTime
        );
        uint256 billableAmount = (billableCycle *
            saleLog.unitPrice * saleLog.qty *
            COMMISSION_RATE) / 100;
        amount += billableAmount;
        }

        return amount;
    }

    function afterWithdrawCommission(address _buyer, uint256 currentTime)
        internal
    {
        for (uint256 i = 0; i < saleLogs[_buyer].length; i++) {
        uint256 billableCycle = getBillableCommissionCycle(
            saleLogs[_buyer][i].lastWithdraw,
            currentTime
        );
        uint256 billableDuration = billableCycle * COMMISSION_CYCLE;
        saleLogs[_buyer][i].lastWithdraw += billableDuration;
        }
    }

    function withdrawCommission() external nonReentrant {
        address buyer =  msg.sender;
        uint256 currentTime = block.timestamp;

        require(saleLogs[buyer].length > 0, "You haven't bought any items");
        uint256 amount = calculateCommission(buyer, currentTime);
        require(amount > 0, "There is nothing to withdraw");
        require(IERC20(tokenAddress).balanceOf(address(this)) >= amount, "Contract's balance is not enough");
		require(IERC20(tokenAddress).transfer(buyer,amount),"Not enought funds.");
        //bool success, ) = payable(buyer).call{value: amount}("");
        //require(success, "Failed to withdraw");

        afterWithdrawCommission(buyer, currentTime);
        emit CommissionWithdraw(buyer, amount);
    }

    function getBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function deposit(uint amount) public  onlyOwner {
       // require(msg.value > 0, "No funds");
     require(IERC20(tokenAddress).transferFrom(msg.sender,address(this),amount),"Not enought funds.");

    }
    function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual override {
      if (saleLogs[from].length > 0) {
          for (uint256 i = 0; i < saleLogs[from].length; i++) {
            SaleLog memory log = saleLogs[from][i];
            bool isInTokenRange = log.startTokenId <= startTokenId && log.startTokenId + log.qty >= startTokenId + quantity && quantity <= log.qty;

            if (isInTokenRange) {
                // Any token transfer will break the current sale log to 2 new sale logs
                uint256 headLogQty =  startTokenId - log.startTokenId;
                uint256 tailLogQty = log.qty - quantity - headLogQty;
                delete saleLogs[from][i];

                if (headLogQty > 0) {
                    saleLogs[from].push(SaleLog(log.unitPrice, headLogQty, log.startTokenId, log.lastWithdraw));
                }

                if (tailLogQty > 0) {
                    saleLogs[from].push(SaleLog(log.unitPrice, tailLogQty, startTokenId + quantity, log.lastWithdraw));
                }             

                // Add new sale log for buyer
                saleLogs[to].push(SaleLog(log.unitPrice, quantity, startTokenId, log.lastWithdraw));
            }
        }
      }
    }


  
		 
    function saleRaton(uint256 _quantity) external {
        //Get the number of NFT sold
        uint numberNftSold = totalSupply();
        //Get the price of one NFT in Sale
        uint price = priceRaton;
        //If Sale didn't start yet
        require(sellingStep == Steps.SaleRaton, "Sorry, saleRaton has not started yet.");

        //The user can only mint max 5 NFTs
        require(nftsPerWallet[msg.sender] + _quantity <= max_mint_allowed, "You can't mint more than the limit");

        require(IERC20(tokenAddress).transferFrom(msg.sender,address(this),price * _quantity),"Not enought funds.");
        //If the user try to mint any non-existent token
        require(numberNftSold + _quantity <= LIMIT_SUPPLY_RATON, "SaleRaton is almost done and we don't have enought NFTs left.");
        //Add the _quantity of NFTs minted by the user to the total he minted
        nftsPerWallet[msg.sender] += _quantity;
        //If this account minted the last NFTs available
        if(numberNftSold + _quantity >= LIMIT_SUPPLY_RATON) {
             sellingStep = Steps.SoldOut;   
        }

        addSaleLog(msg.sender, price, _quantity);
        // _safeMint's second argument now takes in a _quantity, not a tokenId.
        _safeMint(msg.sender, _quantity);
    }

    /**
    * @notice Allows to get the complete URI of a specific NFT by his ID
    *
    * @param _nftId The id of the NFT
    *
    * @return The token URI of the NFT which has _nftId Id
    **/
    function tokenURI(uint _nftId) public view override(ERC721A) returns (string memory) {
        require(_exists(_nftId), "This NFT doesn't exist.");
    string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0 
            ? string(abi.encodePacked(currentBaseURI, _nftId.toString(), baseExtension))
            : "";
    }    

    //ReleaseALL
    function releaseAll() external {
        for(uint i = 0 ; i < teamLength ; i++) {
            release(payable(payee(i)));
        }
    }
}