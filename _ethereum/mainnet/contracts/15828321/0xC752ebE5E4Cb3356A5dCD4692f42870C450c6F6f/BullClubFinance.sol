// SPDX-License-Identifier: MIT License
pragma solidity ^0.8.17;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./StringsUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";

contract BullClubFinance is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ERC721EnumerableUpgradeable
{
    struct Currency {
        IERC20Upgradeable token;
        uint256 mintPrice;
    }

    Currency[] public currencies;
    string public baseURI;
    address public investmentFundAddress;
    uint256 public maxSupply;
    uint256 public maxMintPerTx;
    mapping(address => uint256) public reservedTokens;

    using StringsUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function initialize(string memory _name, string memory _symbol)
        public
        initializer
    {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ERC721_init(_name, _symbol);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function addCurrency(IERC20Upgradeable _token, uint256 _mintPrice)
        public
        onlyOwner
    {
        currencies.push(Currency(_token, _mintPrice));
    }

    function setCurrencyPrice(uint256 _currencyId, uint256 _mintPrice)
        public
        onlyOwner
    {
        currencies[_currencyId].mintPrice = _mintPrice;
    }

    function removeCurrency(uint256 _currencyId) public onlyOwner {
        delete currencies[_currencyId];
    }

    function setInvestmentFundAddress(address _investmentFundAddress)
        public
        onlyOwner
    {
        investmentFundAddress = _investmentFundAddress;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMaxMintPerTx(uint256 _maxMintPerTx) public onlyOwner {
        maxMintPerTx = _maxMintPerTx;
    }

    function setReservedTokens(address _address, uint256 _amount)
        public
        onlyOwner
    {
        reservedTokens[_address] = _amount;
    }

    function tokensOfOwnerByAddress(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 amountTokens = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](amountTokens);

        for (uint256 i = 0; i < amountTokens; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function mint(
        address _to,
        uint256 _amount,
        uint256 _currencyId
    ) public {
        require(
            investmentFundAddress != address(0),
            "Investment fund address is not set"
        );
        require(
            _amount <= maxMintPerTx,
            "Amount exceeds max mint per transaction"
        );
        require(_currencyId < currencies.length, "Invalid currency id");
        require(_amount > 0, "Invalid amount");
        require(_to != address(0), "Invalid address");

        uint256 supply = totalSupply();

        require(supply + _amount <= maxSupply, "Exceeds max supply");

        Currency storage currency = currencies[_currencyId];
        uint256 totalMintPrice = currency.mintPrice * _amount;

        if (msg.sender != owner()) {
            require(
                currency.token.allowance(msg.sender, address(this)) >=
                    totalMintPrice,
                "Insufficient allowance"
            );
            require(
                currency.token.balanceOf(msg.sender) >= totalMintPrice,
                "Insufficient payment"
            );

            currency.token.safeTransferFrom(
                msg.sender,
                investmentFundAddress,
                totalMintPrice
            );
        }

        for (uint256 i = 0; i < _amount; i++) {
            _safeMint(_to, supply + i);
        }
    }

    function mintReserved(uint256 _amount) public {
        require(
            _amount <= maxMintPerTx,
            "Amount exceeds max mint per transaction"
        );
        require(_amount > 0, "Invalid amount");
        require(reservedTokens[msg.sender] > 0, "No reserved tokens");
        require(reservedTokens[msg.sender] >= _amount, "Insufficient reserved");

        uint256 supply = totalSupply();

        require(supply + _amount <= maxSupply, "Exceeds max supply");

        for (uint256 i = 0; i < _amount; i++) {
            _safeMint(msg.sender, supply + i);

            reservedTokens[msg.sender] -= 1;
        }
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory base = _baseURI();

        return
            bytes(base).length > 0
                ? string(abi.encodePacked(base, _tokenId.toString()))
                : "";
    }
}
