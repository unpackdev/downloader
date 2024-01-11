// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./EnumerableSet.sol";
import "./ERC165Checker.sol";


contract Token is ERC721Enumerable, Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _allowList;

    struct AllowParams {
        uint256 price;
        uint256 purchasedAmount;
        mapping(uint256 => bool) usedTokens;
    }

    mapping(address => AllowParams[]) public allowListParams;

    event AddedToAllowList(address indexed _address, uint256 indexed _price);
    event ChangedAllowListPrice(address indexed _address, uint256 indexed _price);
    event RemovedFromAllowList(address indexed _address, uint256 _purchasedAmount);
    event PresalePurchase(address indexed contract_, address indexed _address, uint256 _purchasedAmount);

    uint16 public allowListLimit;

    modifier checkInAllowList(address contract_) {
        require(inAllowList(contract_), "Token: Contract address is not in the allowed list");
        _;
    }


    bool public presaleActive;
    uint8 public presaleTransactionLimit;
    uint256 public presaleLimit;
    uint256 public presaleSupply;

    event PresaleStart(uint256 indexed _presaleStartTime, uint8 _presaleTransactionLimit);
    event PresalePaused(uint256 indexed _presalePauseTime, uint256 indexed _presaleSupply);
    event PresaleLimitChanged(uint256 indexed _limitStartTime, uint256 indexed _saleLimit, uint256 _saleSupply);

    bool public saleActive;
    uint8 public saleTransactionLimit;
    uint256 public saleLimit;
    uint256 public salePrice;
    uint256 public saleSupply;

    event SaleStart(uint256 indexed _saleStartTime, uint8 _saleTransactionLimit, uint256 indexed _salePrice);
    event SalePaused(uint256 indexed _salePauseTime, uint256 _saleSupply);
    event SaleLimitChanged(uint256 indexed _limitStartTime, uint256 indexed _saleLimit, uint256 _saleSupply);

    modifier whenPresaleActive() {
        require(presaleActive, "Token: Presale is paused");
        _;
    }

    modifier whenPresalePaused() {
        require(!presaleActive, "Token: Presale is already active");
        _;
    }

    modifier whenSaleActive() {
        require(saleActive, "Token: Sale is paused");
        _;
    }

    modifier whenSalePaused() {
        require(!saleActive, "Token: Sale is already active");
        _;
    }

    string private baseURI;

    constructor(
        string memory name_, string memory symbol_, string memory baseURI_, uint16 allowListLimit_
    ) ERC721(name_, symbol_)  {
        baseURI = baseURI_;
        allowListLimit = allowListLimit_;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setAllowListLimit(uint16 allowListLimit_) external onlyOwner {
        allowListLimit = allowListLimit_;
    }

    function checkContract(address contract_) public view returns (bool) {
        return ERC165Checker.supportsInterface(contract_, type(IERC721).interfaceId);
    }

    function addToAllowList(address[] memory addresses, uint256[] memory prices) external onlyOwner {
        require(addresses.length <= allowListLimit, "Token: List of addresses is too large");
        require(addresses.length == prices.length, "Token: Both lists should be the same length");
        for(uint index = 0; index < addresses.length; index += 1) {
            if (checkContract(addresses[index])) {
                if (inAllowList(addresses[index])) {
                    uint lastIndex = _paramsLengthByContract(addresses[index]) - 1;
                    emit RemovedFromAllowList(addresses[index], allowListParams[addresses[index]][lastIndex].purchasedAmount);
                }

                _allowList.add(addresses[index]);

                AllowParams storage params = allowListParams[addresses[index]].push();
                params.price = prices[index];

                emit AddedToAllowList(addresses[index], prices[index]);
            }
        }
    }

    function removeFromAllowList(address[] memory addresses) external onlyOwner {
        require(addresses.length <= allowListLimit, "Token: List of addresses is too large");
        for(uint index = 0; index < addresses.length; index += 1) {
            if (_allowList.remove(addresses[index])) {
                uint lastIndex = _paramsLengthByContract(addresses[index]) - 1;
                emit RemovedFromAllowList(addresses[index], allowListParams[addresses[index]][lastIndex].purchasedAmount);
            }
        }
    }

    function changeAllowListPrice(address[] memory addresses, uint256[] memory prices) external onlyOwner {
        require(addresses.length <= allowListLimit, "Token: List of addresses is too large");
        require(addresses.length == prices.length, "Token: Both lists should be the same length");
        for(uint index = 0; index < addresses.length; index += 1) {
            if (inAllowList(addresses[index])) {
                uint lastIndex = _paramsLengthByContract(addresses[index]) - 1;
                allowListParams[addresses[index]][lastIndex].price = prices[index];
                emit ChangedAllowListPrice(addresses[index], prices[index]);
            }
        }
    }

    function inAllowList(address value) public view returns (bool) {
        return _allowList.contains(value);
    }

    function allowListLength() external view returns (uint256) {
        return _allowList.length();
    }

    function allowAddressByIndex(uint256 index) external view returns (address) {
        require(index < _allowList.length(), "Token: Index out of bounds");
        return _allowList.at(index);
    }

    function _paramsLengthByContract(address contract_) internal view returns(uint) {
        return allowListParams[contract_].length;
    }

    function paramsLengthByContract(address contract_) checkInAllowList(contract_) external view returns(uint) {
        return _paramsLengthByContract(contract_);
    }

    function _allowListParamsByIndex(address contract_, uint256 _index) internal view returns (uint256, uint256) {
        return (allowListParams[contract_][_index].price, allowListParams[contract_][_index].purchasedAmount);
    }

    function allowListParamsByIndex(address contract_, uint256 _index) external view returns (uint256, uint256) {
        require(_index < _paramsLengthByContract(contract_), "Token: Index out of params");
        return _allowListParamsByIndex(contract_, _index);
    }

    function allowListParamsLast(address contract_) checkInAllowList(contract_) external view returns (uint256, uint256) {
        return _allowListParamsByIndex(contract_, _paramsLengthByContract(contract_) - 1);
    }

    function tokenIsUsedByAddress(address contract_, uint256 token_) checkInAllowList(contract_) external view returns(bool) {
        return allowListParams[contract_][_paramsLengthByContract(contract_) - 1].usedTokens[token_];
    }

    function _setPresaleLimit(uint256 limit_) internal {
        emit PresaleLimitChanged(block.timestamp, presaleLimit, presaleSupply);
        presaleSupply = 0;
        presaleLimit = limit_;
    }

    function setPresaleLimit(uint256 limit_) external onlyOwner  {
        _setPresaleLimit(limit_);
    }

    function _setSaleLimit(uint256 limit_) internal {
        emit SaleLimitChanged(block.timestamp, saleLimit, saleSupply);
        saleSupply = 0;
        saleLimit = limit_;
    }

    function setSaleLimit(uint256 saleLimit_) external onlyOwner  {
        _setSaleLimit(saleLimit_);
    }

    function startPresale(uint8 transactionLimit_, uint256 limit_) external onlyOwner whenPresalePaused {
        presaleTransactionLimit = transactionLimit_;

        _setPresaleLimit(limit_);

        presaleActive = true;
        emit PresaleStart(block.timestamp, presaleTransactionLimit);
    }

    function pausePresale() external onlyOwner whenPresaleActive {
        presaleActive = false;
        emit PresalePaused(block.timestamp, presaleSupply);
    }

    function startSale(uint256 price_, uint8 transactionLimit_, uint256 limit_) external onlyOwner whenSalePaused {
        salePrice = price_;
        saleTransactionLimit = transactionLimit_;

        _setSaleLimit(limit_);

        saleActive = true;
        emit SaleStart(block.timestamp, saleTransactionLimit, salePrice);
    }

    function pauseSale() external onlyOwner whenSaleActive {
        saleActive = false;
        emit SalePaused(block.timestamp, saleSupply);
    }

    function _buyTokens(uint256 tokensAmount) internal returns (uint256[] memory) {
        uint256[] memory tokens = new uint256[](tokensAmount);

        for (uint index = 0; index < tokensAmount; index += 1) {
            tokens[index] = totalSupply() + 1;
            _safeMint(msg.sender, tokens[index]);
        }

        return tokens;
    }

    function buyTokens(uint256 tokensAmount) external payable whenSaleActive nonReentrant returns (uint256[] memory) {
        require(msg.sender != address(0));
        require(tokensAmount > 0, "Token: Must mint at least one token");

        if (saleLimit > 0) { // if saleLimit equals to 0 than sale in unlimited
            require(tokensAmount + saleSupply <= saleLimit, "Token: Sale limit exceeded");
        }
        require(tokensAmount <= saleTransactionLimit, "Token: Transaction limit exceeded");
        require(salePrice * tokensAmount <= msg.value, "Token: Insufficient funds");

        saleSupply += tokensAmount;

        return _buyTokens(tokensAmount);
    }

    function buyTokensByContract(address contract_, uint256[] memory tokens_) checkInAllowList(contract_) external payable whenPresaleActive nonReentrant returns (uint256[] memory) {
        require(msg.sender != address(0));
        uint256 tokensAmount = tokens_.length;
        require(tokensAmount > 0, "Token: Presale, must mint at least one token");

        if (presaleLimit > 0) { // if presaleLimit equals to 0 than presale in unlimited
            require(tokensAmount + presaleSupply <= presaleLimit, "Token: Presale limit exceeded");
        }
        require(tokensAmount <= presaleTransactionLimit, "Token: Presale, transaction limit exceeded");

        uint lastIndex = _paramsLengthByContract(contract_) - 1;
        require(allowListParams[contract_][lastIndex].price * tokensAmount <= msg.value, "Token: Presale, insufficient funds");

        for (uint i = 0; i < tokensAmount; i += 1) {
            require(IERC721(contract_).ownerOf(tokens_[i]) == msg.sender, "Token: Sender is not owner of token");
            require(!allowListParams[contract_][lastIndex].usedTokens[tokens_[i]], "Token: Presale, token already used");
            allowListParams[contract_][lastIndex].usedTokens[tokens_[i]] = true;
        }

        allowListParams[contract_][lastIndex].purchasedAmount += tokensAmount;
        presaleSupply += tokensAmount;

        emit PresalePurchase(contract_, msg.sender, tokensAmount);

        return _buyTokens(tokensAmount);
    }

    function withdraw(address payable wallet, uint256 amount) external onlyOwner {
        require(amount <= address(this).balance);
        wallet.transfer(amount);
    }

    function renounceOwnership() public override onlyOwner {
        revert('Token: Cannot renounce ownership');
    }
}
