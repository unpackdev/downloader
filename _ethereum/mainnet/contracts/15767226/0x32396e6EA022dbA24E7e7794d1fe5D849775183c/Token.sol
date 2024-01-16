// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC165Checker.sol";
import "./IERC721.sol";
import "./ERC721ABurnable.sol";
import "./StartTokenIdHelper.sol";


contract Token is StartTokenIdHelper, ERC721ABurnable, Ownable, ReentrancyGuard {

    string private _baseTokenURI;
    uint256 public limitSupply;
    address public contractAddress;
    mapping(uint256 => bool) usedTokens;

    enum SaleState { Locked, Presale, Sale }

    SaleState public saleState = SaleState.Locked;
    uint256 public price;
    uint16 public transactionLimit;


    event SaleStart(uint256 indexed _saleStartTime, SaleState indexed _saleState, uint256 _price, uint16 _transactionLimit);
    event SalePaused(uint256 indexed _salePauseTime, SaleState indexed _saleState);
    event LimitSupplyDefined(uint256 indexed _limitDefinedTime, uint256 _limitSupply);
    event ContractDefined(uint256 indexed _contractDefinedTime, address indexed _contractAddress);


    constructor(
        string memory name_, string memory symbol_,string memory baseURI_, uint256 startTokenId_
    ) StartTokenIdHelper(startTokenId_) ERC721A(name_, symbol_) {
        _baseTokenURI = baseURI_;
    }

    function _startTokenId() internal view override returns (uint256) {
        return startTokenId;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    function setLimitSupply(uint256 limit_) external onlyOwner  {
        require(limitSupply == 0, "Token: Limit supply has already defined.");
        limitSupply = limit_;
        emit LimitSupplyDefined(block.timestamp, limitSupply);
    }

    function checkContract(address contract_) public view returns (bool) {
        return ERC165Checker.supportsInterface(contract_, type(IERC721).interfaceId);
    }

    function setContract(address contract_) external onlyOwner {
        require(contractAddress == address(0), "Token: Contract address has already defined.");
        require(checkContract(contract_), "Token: Contract address dose not support IERC721.");

        contractAddress = contract_;
        emit ContractDefined(block.timestamp, contractAddress);
    }

    function configureSaleState(SaleState saleState_, uint256 price_, uint16 transactionLimit_) external onlyOwner {
        require(limitSupply != 0, "Token: Limit supply should be defined.");
        require(saleState_ != SaleState.Locked, "Token: Cannot lock sale.");

        if (saleState_ == SaleState.Presale) {
            require(contractAddress != address(0), "Token: Contract address should be defined.");
        }

        if (saleState != SaleState.Locked) {
            emit SalePaused(block.timestamp, saleState);
        }

        saleState = saleState_;
        price = price_;
        transactionLimit = transactionLimit_;

        emit SaleStart(block.timestamp, saleState, price, transactionLimit);
    }

    function pauseAnySale() external onlyOwner {
        SaleState _saleState = saleState;
        saleState = SaleState.Locked;
        emit SalePaused(block.timestamp, _saleState);
    }

    function _preValidateMint(uint256 tokensAmount) internal {
        require(tokensAmount <= transactionLimit, "Token: Limited amount of tokens per transaction.");
        require(_totalMinted() + tokensAmount <= limitSupply, "Token: Limited amount of tokens.");
        require(price * tokensAmount <= msg.value, "Token: Insufficient funds.");
    }

    function mint(uint16 tokensAmount) external payable nonReentrant {
        require(saleState == SaleState.Sale, "Token: Sale is not active.");
        _preValidateMint(tokensAmount);
        _safeMint(msg.sender, tokensAmount);
    }

    function presaleMint(uint256[] memory tokens_) external payable nonReentrant {
        require(saleState == SaleState.Presale, "Token: Presale is paused.");

        uint256 tokensAmount = tokens_.length;
        _preValidateMint(tokensAmount);

        for (uint256 i = 0; i < tokensAmount; i += 1) {
            require(IERC721(contractAddress).ownerOf(tokens_[i]) == msg.sender, "Token: Sender is not owner of token.");
            require(!usedTokens[tokens_[i]], "Token: Presale, token already used.");
            usedTokens[tokens_[i]] = true;
        }

        _safeMint(msg.sender, tokensAmount);
    }


    function withdraw(address payable wallet, uint256 amount) external onlyOwner {
        require(amount <= address(this).balance);
        wallet.transfer(amount);
    }

    function getOwnershipAt(uint256 index) external view returns (TokenOwnership memory) {
        return _ownershipAt(index);
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function totalBurned() external view returns (uint256) {
        return _totalBurned();
    }

    function numberBurned(address owner) external view returns (uint256) {
        return _numberBurned(owner);
    }
}