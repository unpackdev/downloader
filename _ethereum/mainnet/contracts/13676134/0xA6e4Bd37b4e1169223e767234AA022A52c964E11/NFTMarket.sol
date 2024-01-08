// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./IERC1155.sol";
import "./NFTBase.sol";
import "./ERC20TokenList.sol";

/**
 *
 * @dev Implementation of Market [지정가판매(fixed_price), 경매(auction)]
 *
 */

// interface for ERC1155
interface NFTBaseLike {
    function getCreator(uint256 id) external view returns (address);
    function getRoyaltyRatio(uint256 id) external view returns (uint256);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
}

// interface for payment ERC20 Token List
interface ERC20TokenListLike {
    function contains(address addr) external view returns (bool);
}


contract NFTMarket is Ownable
{
    using SafeMath for uint256;
    
    struct SaleData {
        address seller;            
        bool isAuction;      // auction true, fixed_price false         
        uint256 nftId;       // ERC1155 Token Id               
        uint256 volume;      // number of nft,  volume >= 2 -> isAuction=false, remnant value : number decrease after buying
        address erc20;       // payment erc20 token 
        uint256 price;       // auction : starting price, fixed_price : sellig unit price 
        uint256 bid;         // bidding price     
        address buyer;       // fixed_price : 구매자 auction : bidder, 최종구매자 
        uint256 start;       // auction start time [unix epoch time]    unit : sec
        uint256 end;         // auction expiry time  [unix epoch time]  unit : sec     
        bool isCanceled;     // no buyer or no bidder 만 가능 
        bool isSettled;      // 정산되었는지 여부
    }
    
    mapping (uint256 => SaleData) private _sales;        //mapping from uint256 to sales data 
    uint256 private _currentSalesId = 0;                //현재 salesId 
     
    uint256 private  _feeRatio = 10;                    // 수수료율 100% = 100
    address private  _feeTo;                            // 거래수수료 수취주소 
    
    uint256 private _interval = 15 minutes;             // additionl bidding time  [seconds]
    //uint256 private _duration = 1 days;                 // 1 days total auction length  [seconds]
    
    NFTBaseLike _nftBase;                               // ERC1155
    ERC20TokenListLike _erc20s;                         // payment ERC20 Token List
    

    //event
    event Open(uint256 id,address indexed seller,bool isAuction,uint256 nftId,uint256 volume,address indexed erc20,uint256 price,uint256 start, uint256 end);
    event Buy(uint256 id,address indexed buyer,uint256 amt);
    event Clear(uint256 id);
    event Cancel(uint256 id);

    event Bid(uint256 id,address indexed guy, uint256 amount,uint256 end);
    //event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    //event Transfer(address indexed from, address indexed to, uint256 value);

    /* Keccak256 
        Open(uint256,address,bool,uint256,uint256,address,uint256)  : 0x0e884c2228e2e8cc975ba6a7d1c29574c38bda6a723957411fd523ad0c03d04e
        Buy(uint256,address,uint256)                                : 0x3b599f6217e39be59216b60e543ce0d4c7d534fe64dd9d962334924e7819894e
        Clear(uint256)                                              : 0x6e4c858d91fb3af82ec04ba219c6b12542326a62accb6ffac4cf87ba00ba95a3
        Cancel(uint256)                                             : 0x8bf30e7ff26833413be5f69e1d373744864d600b664204b4a2f9844a8eedb9ed
        Bid(uint256,address,uint256,uint256)                        : 0x3138d8d517460c959fb333d4e8d87ea984f1cf15d6742c02e2955dd27a622b70
        TransferSingle(address,address,address,uint256,uint256)     : 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62
        Transfer(address,address,uint256)                           : 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
    */

    /**
     * @dev feeTo address, ERC1155 Contract, ERC20 Payment Token List 설정 
     */
    constructor(NFTBaseLike nftBase_,ERC20TokenListLike erc20s_) {
        _feeTo = address(this);
        _nftBase = NFTBaseLike(nftBase_);
        _erc20s = ERC20TokenListLike(erc20s_);
    }

    /**
     * @dev feeRatio 설정 
     *
     * Requirements:
     *
     * - 100% 이하
     */
    function setFeeRatio(uint256 feeRatio_) external onlyOwner {
        require(feeRatio_ <= 100,"NFTMarket/FeeRation_>_100");
       _feeRatio = feeRatio_;
    }

    function getFeeRatio() external view returns(uint256) {
        return _feeRatio;
    }

    /**
     * @dev feeTo Address 설정 
     *
     * Requirements:
     *
     * - not zero address
     */

    function setFeeTo(address feeTo_) external onlyOwner {
        require(feeTo_ != address(0),"NFTMarket/FeeTo_address_is_0");
       _feeTo = feeTo_;
    }

    function getFeeTo() external view returns(address) {
        return _feeTo;
    }
    
    /**
     * @dev auction 연장 시간 설정 [minites]
     *
     * Requirements:
     * 
     */    
    function setInterval(uint256 interval_) external onlyOwner {
        _interval = interval_;
    }

    function getInterval() external view returns(uint256) {
        return _interval;
    }
    /**
     * @dev auction 시간 설정 [minites]
     *
     * Requirements:
     *
     * - not zero 
     */    
    /*     
    function setDuration(uint256 duration_) external onlyOwner   {
        require(duration_ > 0,"NFTMarket/duration_is_0");
        _duration = duration_;
    }    
    
    function getDuration() external view returns(uint256) {
        return _duration;
    }
    */

    /**
     * @dev open : 판매시작, NFT escrow , SaleData 등록
     *   args  
     *     isAuction : true - auction, false - fixed_price 
     *     nftId : ERC1155 mint token Id 
     *     volume : 수량 
     *     erc20 : payment ERC20 Token
     *     price : auction : starting price, fixed_price : sellig unit price 
     *   
     *
     * Requirements:
     *
     *   수량(volume) > 1 인 경우 fixed_price 만 가능 
     *   수량 > 0, 가격 > 0
     *   결제 ERC20 contract : ERC20TokenList 중의 하나 
     *
     * Event : Open, TransferSingle(NFTBase)
     * 
     * Return  salesId
     */ 	 
    function open(bool isAuction,uint256 nftId,uint256 volume,address erc20, uint256 price,uint256 start, uint256 end) public returns (uint256 id) {
        if(volume > 1 && isAuction) {
            revert("NFTMarket/if_volume_>_1,isAuction_should_be_false");
        }
        require(volume > 0,"NFTMarket/open_0_volume");
        require(price > 0, "NFTMarket/open_0_price");
        require(_erc20s.contains(erc20),"NFTMarket/open_erc20_not_registered");
        if(isAuction) {
            require(end > start,"NFTMarket/open_should_end_>_start");
        }
                
        _nftBase.safeTransferFrom(_msgSender(),address(this),nftId,volume,"");    

        id = ++_currentSalesId;
        _sales[id].seller = _msgSender();
        _sales[id].isAuction = isAuction;
        _sales[id].nftId = nftId;
        _sales[id].volume = volume;
        _sales[id].erc20 = erc20;
        _sales[id].price = price;
        _sales[id].isCanceled = false;
        _sales[id].isSettled = false;
        
        if(isAuction) {
            _sales[id].bid = price;
            _sales[id].start = start;
            _sales[id].end = end;
        }
        emit Open(id,_msgSender(),isAuction,nftId,volume,erc20,price,start,end);            
    }
    
    /**
     * @dev buy : 바로구매, 정산 
     *   args  
     *     id     : saleId
     *     amt    : 구매수량 

     * Requirements:
     *
     *   auction이 아니고 (fixed_price 이어야)
     *   buyer가 확정되지 않아야 하고 (settle 되어지 않아야)
     *   취소상태가 아니어야 함 
     * 
     * Event : Buy,TransferSingle(NFTBase),Transfer(ERC20)      
     * 
     */ 	 

    function buy(uint256 id,uint256 amt) public {
        require(id <= _currentSalesId,"NFTMarket/sale_is_not_open");
        require(!_sales[id].isAuction, "NFTMarket/sale_is_auction");
        require(!_sales[id].isCanceled,"NFTMarket/sale_already_cancelled");    
        require(!_sales[id].isSettled,"NFTMarket/sale_already_settled");   
        require(amt > 0,"NFTMarket/buy_must_>_0");
        require(amt <= _sales[id].volume,"NFTMarket/buy_should_<=_sale_volume");
        
        _sales[id].buyer = _msgSender();

        settle(id,amt);
        emit Buy(id,_msgSender(),amt);
    }
    
    /**
     * @dev bid : 경매 참여, ERC20 Token escrow, 경매시간 연장  
     *   args : 
     *      id : salesId
     *      amount : bidding 금액  
     *      bidder = msg.sender 
     * 
     * Requirements:
     * 
     *   auction이고
     *   취소상태가 아니고
     *   경매 종료시간이 지나지 않아야 함
     *   bidding 금액이 기존 금액(첫 bidding인경우 seller가 제시한 금액)보다 커야함     
     * 
     * Event : Bid,Transfer(ERC20)       
     */ 

    function bid(uint256 id,uint256 amount) public {
        require(id <= _currentSalesId,"NFTMarket/sale_is_not_open");
        require(_sales[id].isAuction, "NFTMarket/sale_should_be_auction");
        require(!_sales[id].isCanceled,"NFTMarket/sale_already_cancelled");    
        require(!_sales[id].isSettled,"NFTMarket/sale_already_settled");         
        require(block.timestamp >= _sales[id].start, "NFTMarket/auction_doesn't_start");     
        require(_sales[id].end >= block.timestamp, "NFTMarket/auction_finished");
        require(amount > _sales[id].bid, "NFTMarket/bid_should_be_higher");

        IERC20 erc20Token = IERC20(_sales[id].erc20);
        erc20Token.transferFrom(_msgSender(),address(this),amount);

        // not first bidding
        if(_sales[id].buyer != address(0)) {
            erc20Token.transfer(_sales[id].buyer,_sales[id].bid);     
        }
        
        _sales[id].buyer = _msgSender();
        _sales[id].bid = amount;        
        
        // auction end time increase
        if(block.timestamp < _sales[id].end && _sales[id].end < block.timestamp + _interval) 
            _sales[id].end = _sales[id].end.add(_interval);
        
        emit Bid(id,_msgSender(),amount,_sales[id].end);        
    }
    

    /**
     * @dev clear : 경매 정리, 정산  
     *   args : 
     *      id : salesId
     *      amount : bidding 금액  
     *      bidder = msg.sender 
     * 
     * Requirements:
     * 
     *      id가 존재해야 하고     
     *      auction이고 
     *      취소상태가 아니고
     *      아직 정산되지 않아야 하고 
     *      경매 종료시간이 지나야 하고 
     *      caller는 sales[id].seller 이어야 함     
     * 
     * Event : Clear,TransferSingle(NFTBase),Transfer(ERC20)       
     */ 
   
    function clear(uint256 id) public {
        require(id <= _currentSalesId,"NFTMarket/sale_is_not_open");
        require(_sales[id].isAuction, "NFTMarket/sale_should_be_auction");          
        require(!_sales[id].isCanceled,"NFTMarket/sale_already_cancelled");    
        require(_sales[id].buyer != address(0), "NFTMarket/auction_not_bidded");
        require(!_sales[id].isSettled,"NFTMarket/auction_already_settled");                  
        require(_sales[id].end < block.timestamp, "NFTMarket/auction_ongoing");
        require(_msgSender() == _sales[id].seller, "NFTMarket/only_seller_can_clear");

        settle(id,1);   
        emit Clear(id);
    }
    
	/**
     * @dev cancel : 세일 취소, escrow 반환  
     *   args : 
     *      id : salesId
     *      amount : bidding 금액  
     *      bidder = msg.sender 
     *    
     * Requirements:     
     *      id가 존재해야 하고
     *      취소상태가 아니고
     *      이미 정산되지 않아야 하고 
     *      경매의 경우 Bidder가 없어야 
     *      caller는 sales[id].seller 이어야 함 
     *
     * Event : Cancel,TransferSingle(NFTBase)       
     */ 
    function cancel(uint256 id) public {
        require(id <= _currentSalesId,"NFTMarket/sale_is_not_open");
        require(!_sales[id].isCanceled,"NFTMarket/sale_already_cancelled");
        require(!_sales[id].isSettled,"NFTMarket/sale_already_settled");
        if (_sales[id].isAuction)
            require(_sales[id].buyer == address(0), "NFTMarket/auction_not_cancellable");
        require(_msgSender() == _sales[id].seller, "NFTMarket/only_seller_can_cancel");
        _sales[id].isCanceled = true;
        _nftBase.safeTransferFrom(address(this),_sales[id].seller,_sales[id].nftId,_sales[id].volume,"");
        emit Cancel(id);
    }
    
    /**
     * @dev settle : 정산   
     *      1. 수수료 정산     : this ->  feeTo
	 *      2. royalty 정산    : this ->  creator
	 *      3. nft 오너쉽 정리 : this -> buyer     
     *
     *   args : 
     *      id  : salesId
     *      amt : number of nft in fixed-price buy or auction 
     * 
     * Requirements:
     *
     * - feeRatio + royaltyRatio < 100
     *
     * Event : TransferSingle(NFTBase), Transfer(ERC20)
     */     

    function settle(uint256 id,uint256 amt) private {
        SaleData memory sd = _sales[id];
  
        uint256 amount = sd.isAuction ? sd.bid : sd.price*amt;
        uint256 fee = amount.mul(_feeRatio).div(100);

        address creator = _nftBase.getCreator(sd.nftId);
        uint256 royaltyRatio = _nftBase.getRoyaltyRatio(sd.nftId);

        require(_feeRatio.add(royaltyRatio) <= 100, "NFTMarket/fee_+_royalty_>_100%");
        uint256 royalty = amount.mul(royaltyRatio).div(100);    

        IERC20 erc20Token = IERC20(sd.erc20);
        if(sd.isAuction) {
            erc20Token.transfer(_feeTo,fee);
            erc20Token.transfer(creator,royalty);
            erc20Token.transfer(sd.seller,amount.sub(fee).sub(royalty));
        } else {
            erc20Token.transferFrom(_msgSender(),_feeTo,fee);
            erc20Token.transferFrom(_msgSender(),creator,royalty);
            erc20Token.transferFrom(_msgSender(),sd.seller,amount.sub(fee).sub(royalty));
        }
        _nftBase.safeTransferFrom(address(this),sd.buyer,sd.nftId,amt,"");

        _sales[id].volume -= amt;
        _sales[id].isSettled = (_sales[id].volume == 0);
    }

    function getAuctionEnd(uint256 id) external view returns (uint256) 
    {
        require(_sales[id].isAuction,"NFTMarket/sale_should_be_auction");
        return _sales[id].end;
    }

    /**
     * @dev getSaleData : SaleData Return
     */
    function getSaleData(uint256 id) external view 
        returns (
            address         
            ,bool
            ,uint256
            ,uint256
            ,address
            ,uint256
            ,uint256
            ,address
            ,uint256
            ,uint256
            ,bool
            ,bool 
        ) {        
            SaleData memory sd = _sales[id];
            return (
                sd.seller            
                ,sd.isAuction
                ,sd.nftId
                ,sd.volume
                ,sd.erc20
                ,sd.price
                ,sd.bid
                ,sd.buyer
                ,sd.start
                ,sd.end
                ,sd.isCanceled
                ,sd.isSettled
            );
    }
}