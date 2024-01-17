// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "./IERC20.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract Booking is Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private totalOffers;
    Counters.Counter private unavailableOffers;
    struct SellOffer {
        address payable seller;
        uint256 offerId;
        uint256 rdgCoinBalanceAmount;
        uint256 pricePerTokens;
    }
    mapping(uint256 => SellOffer) public sellOffers;
    IERC20 public rdgCoin;
    IERC20 public usdt;
    uint256 public listingFee = 0.001 ether;

    constructor(address _rdgCoin, address _usdt) {
        rdgCoin = IERC20(_rdgCoin);
        usdt = IERC20(_usdt);
    }

    event ChangeListingFee(uint256 amount);
    event RemovedAllOffers(address indexed owner);
    event RemovedOfferId(address indexed owner, uint256 offerId);
    event ListedOffer(
        address indexed owner,
        uint256 rdgAmount,
        uint256 unitPrice
    );
    event BoughtOffer(
        address indexed buyer,
        address indexed seller,
        uint256 buyingAmount,
        uint256 rdgPrice
    );
    event UpdatePriceOffer(
        address indexed owner,
        uint256 _offerId,
        uint256 oldRdgPrice,
        uint256 newRdgPrice
    );

    event AddRdgAmountOffer(
        address indexed owner,
        uint256 _offerId,
        uint256 oldAmount,
        uint256 newAmount
    );
    event RemoveRdgAmountOffer(
        address indexed owner,
        uint256 _offerId,
        uint256 oldAmount,
        uint256 newAmount
    );

    function setListingFee(uint256 _amount) public onlyOwner {
        listingFee = _amount;
        emit ChangeListingFee(_amount);
    }

    function widthdrawDevBalance() public onlyOwner {
        require(address(this).balance > 0, "Nao tem saldo disponivel");
        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        require(sent, "Falha ao enviar ether");
    }

    function listToken(uint256 _amount, uint256 _pricePerTokens)
        public
        payable
        whenNotPaused
    {
        require(msg.value >= listingFee, "Nao foi enviado taxa de operacao.");
        require(_amount > 0, "Quantidade minima deve ser maior que zero");
        require(
            rdgCoin.allowance(msg.sender, address(this)) >= _amount,
            "Quantidade nao aprovada para listagem"
        );
        rdgCoin.transferFrom(msg.sender, address(this), _amount);
        totalOffers.increment();
        sellOffers[totalOffers.current()] = SellOffer({
            offerId: totalOffers.current(),
            pricePerTokens: _pricePerTokens,
            rdgCoinBalanceAmount: _amount,
            seller: payable(msg.sender)
        });
        emit ListedOffer(msg.sender, _amount, _pricePerTokens);
    }

    function buyToken(uint256 _offerId, uint256 _amount) public {
        SellOffer storage offer = sellOffers[_offerId];
        require(
            offer.seller != msg.sender,
            "Dono da oferta nao pode comprar suas proprias moedas."
        );
        uint256 payerPrice = (offer.pricePerTokens * _amount) / 1 ether;
        uint256 amountBased = _amount * (10**12);

        require(
            usdt.allowance(msg.sender, address(this)) >= payerPrice,
            "USDT autorizado insuficiente para realizar a compra"
        );
        require(
            offer.rdgCoinBalanceAmount >= amountBased,
            "Valor solicitado superior ao disponivel da oferta"
        );
        require(
            rdgCoin.balanceOf(address(this)) >= amountBased,
            "Contrato nao tem RDG Coin"
        );
        offer.rdgCoinBalanceAmount -= amountBased;
        usdt.transferFrom(msg.sender, offer.seller, payerPrice);
        rdgCoin.transfer(msg.sender, amountBased);
        if (offer.rdgCoinBalanceAmount == 0) {
            delete sellOffers[_offerId];
            unavailableOffers.increment();
        }
        emit BoughtOffer(
            msg.sender,
            offer.seller,
            _amount,
            offer.pricePerTokens
        );
    }

    function getOffers() public view returns (SellOffer[] memory) {
        uint256 totalListedOffers = totalOffers.current() -
            unavailableOffers.current();
        SellOffer[] memory offers = new SellOffer[](totalListedOffers);
        uint256 offerIndex;
        for (uint i = 0; i < totalOffers.current(); i++) {
            SellOffer storage offer = sellOffers[i + 1];
            if (offer.rdgCoinBalanceAmount > 0) {
                offers[offerIndex] = offer;
                offerIndex++;
            }
        }
        return offers;
    }

    function getMyOffers() public view returns (SellOffer[] memory) {
        uint256 totalListedOffers = totalOffers.current() -
            unavailableOffers.current();
        SellOffer[] memory offers = new SellOffer[](totalListedOffers);
        uint256 offerIndex;
        for (uint i = 0; i < totalOffers.current(); i++) {
            SellOffer storage offer = sellOffers[i + 1];
            if (offer.rdgCoinBalanceAmount > 0 && offer.seller == msg.sender) {
                offers[offerIndex] = offer;
                offerIndex++;
            }
        }
        return offers;
    }

    function updatePriceOffer(uint256 _offerId, uint256 _updatedPricePerToken)
        public
    {
        SellOffer storage offer = sellOffers[_offerId];

        require(
            offer.seller == msg.sender,
            "Oferta so pode ser modificada pelo dono"
        );
        emit UpdatePriceOffer(
            msg.sender,
            _offerId,
            offer.pricePerTokens,
            _updatedPricePerToken
        );
        offer.pricePerTokens = _updatedPricePerToken;
    }

    function removeListedRdgAmountOffer(uint256 _offerId, uint256 _tokenAmount)
        public
    {
        SellOffer storage offer = sellOffers[_offerId];
        require(
            offer.seller == msg.sender,
            "Oferta so pode ser modificada pelo dono"
        );

        require(
            rdgCoin.balanceOf(address(this)) >= _tokenAmount,
            "RDG Coin insuficiente no contrato"
        );
        uint256 oldAmount = offer.rdgCoinBalanceAmount;
        offer.rdgCoinBalanceAmount -= _tokenAmount;
        uint256 newAmount = offer.rdgCoinBalanceAmount;
        rdgCoin.transfer(msg.sender, _tokenAmount);

        emit RemoveRdgAmountOffer(msg.sender, _offerId, oldAmount, newAmount);

        if (offer.rdgCoinBalanceAmount == 0) {
            delete sellOffers[_offerId];
            unavailableOffers.increment();
        }
    }

    function removeListedOffers() public returns (SellOffer[] memory) {
        uint256 totalOffersCount = totalOffers.current() -
            unavailableOffers.current();
        uint256 rdgCoinIndex = 0;
        uint256 rdgCoinAmount = 0;

        SellOffer[] memory offers = new SellOffer[](totalOffersCount);

        for (uint256 i = 0; i < totalOffers.current(); i++) {
            SellOffer storage offer = sellOffers[i + 1];
            if (offer.seller == msg.sender && offer.rdgCoinBalanceAmount > 0) {
                unavailableOffers.increment();
                offers[rdgCoinIndex] = offer;
                rdgCoinAmount += offer.rdgCoinBalanceAmount;
                offer.rdgCoinBalanceAmount = 0;
                rdgCoinIndex++;
            }
        }

        require(
            rdgCoinAmount > 0,
            "Nao tem nehuma oferta com saldo para saque"
        );
        require(
            rdgCoin.balanceOf(address(this)) >= rdgCoinAmount,
            "Saldo insuficiente do contrato"
        );
        rdgCoin.transfer(msg.sender, rdgCoinAmount);
        emit RemovedAllOffers(msg.sender);
        return offers;
    }

    function removeListedIdOffer(uint _offerId) public {
        SellOffer storage offer = sellOffers[_offerId];
        require(
            offer.seller == msg.sender,
            "Oferta so pode ser removida pelo dono"
        );
        unavailableOffers.increment();
        uint256 rdgCoinGiveBack = offer.rdgCoinBalanceAmount;
        require(
            rdgCoin.balanceOf(address(this)) >= rdgCoinGiveBack,
            "Saldo insuficiente no contrato"
        );
        offer.rdgCoinBalanceAmount = 0;
        delete sellOffers[_offerId];
        rdgCoin.transfer(msg.sender, rdgCoinGiveBack);
        emit RemovedOfferId(msg.sender, _offerId);
    }

    receive() external payable {}

    fallback() external payable {}
}
