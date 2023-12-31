// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./AccessControl.sol";
import "./Pausable.sol";

abstract contract ContractGlossary {
    function getAddress(
        string memory name
    )
    public
    view
    virtual
    returns (address);
}

abstract contract Land {
    function eMint(
        address to,
        uint256 amount_req,
        string memory landType,
        bool freeStable
    )
    external
    virtual;
}

contract LandPurchaserV1 is AccessControl, Pausable {
    
    struct Sale {
        string saleId;
        uint price;
        bool paused;
        uint maxPerTx;
        uint expirationInSeconds;
        bool valid;
    }
    
    struct Receipt {
        address buyer;
        string saleId;
        uint quantity;
        uint pricePer;
        string referenceId;
        uint total;
    }
    
    event Purchased(uint receiptId);
    
    address indexContractAddress;
    
    mapping(uint => string) public SaleIndexToId;
    mapping(uint => address) public ReceiptToBuyer;
    
    mapping(string => Sale) internal sales;
    mapping(uint => Receipt) internal receipts;
    
    uint public saleCount;
    uint public receiptCount;
    
    bytes32 public constant LAND_PURCHASE_ADMIN = keccak256("LAND_PURCHASE_ADMIN");
    
    constructor(
        address _indexContractAddress,
        string memory _initSaleId,
        uint _initSalePrice,
        bool _initSalePaused,
        uint _initSaleMaxPerTx,
        uint _initExpirationInSeconds
    ) {
        indexContractAddress = _indexContractAddress;
    
        sales[_initSaleId] = Sale(
            _initSaleId,
            _initSalePrice,
            _initSalePaused,
            _initSaleMaxPerTx,
            _initExpirationInSeconds,
            true
        );
    
        SaleIndexToId[saleCount] = _initSaleId;
        saleCount++;
    
        _setRoleAdmin(LAND_PURCHASE_ADMIN, DEFAULT_ADMIN_ROLE);
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(LAND_PURCHASE_ADMIN, _msgSender());
    }
    
    function purchase(
        string calldata _saleId,
        string calldata _referenceId,
        uint _quantity,
        uint _executionTimeInSeconds
    )
    public
    payable
    whenNotPaused
    returns(uint)
    {
        (uint price, bool paused, uint maxPerTx, uint expirationInSeconds, bool valid) = getSale(_saleId);
        require(
            block.timestamp <= (_executionTimeInSeconds + expirationInSeconds),
            "EXPIRED_PURCHASE"
        );
        require(
            valid && !paused,
            "NOT_VALID_OR_PAUSED"
        );
        require(
            msg.value % price == 0 &&
            ((msg.value / price) * price == (price * _quantity)),
            "INV_ETH_TOTAL"
        );
        require(
            maxPerTx == 0 || (msg.value / price) <= maxPerTx,
            "PER_TX_ERROR"
        );
    
        ContractGlossary indexContract = ContractGlossary(indexContractAddress);
        Land landContract = Land(indexContract.getAddress("Land"));
        landContract.eMint(msg.sender, _quantity, "Purchased", false);
        
        receiptCount++;
        receipts[receiptCount] = Receipt(
            msg.sender,
            _saleId,
            _quantity,
            price,
            _referenceId,
            msg.value);
        ReceiptToBuyer[receiptCount] = msg.sender;
    
        emit Purchased(receiptCount);
    
        return receiptCount;
    }
    
    function setIndexContractAddress(
        address _indexContractAddress
    )
    public
    onlyRole(LAND_PURCHASE_ADMIN)
    {
        indexContractAddress = _indexContractAddress;
    }
    
    function getReceipt(
        uint _receiptId
    )
    public
    view
    returns (
        address buyer,
        string memory saleId,
        uint quantity,
        uint pricePer,
        string memory referenceId,
        uint total
    ) {
        return (
        receipts[_receiptId].buyer,
        receipts[_receiptId].saleId,
        receipts[_receiptId].quantity,
        receipts[_receiptId].pricePer,
        receipts[_receiptId].referenceId,
        receipts[_receiptId].total
        );
    }
    
    function setSale(
        string calldata _saleId,
        uint _price,
        bool _paused,
        uint _maxPerTx,
        uint _expirationInSeconds,
        bool _valid
    )
    public
    onlyRole(LAND_PURCHASE_ADMIN)
    {
        if (!sales[_saleId].valid){
            SaleIndexToId[saleCount] = _saleId;
            saleCount++;
        }
        
        sales[_saleId] = Sale(
            _saleId,
            _price,
            _paused,
            _maxPerTx,
            _expirationInSeconds,
            _valid
        );
    }
    
    function getSale(
        string calldata _saleId
    )
    public
    view
    returns (
        uint price,
        bool paused,
        uint maxPerTx,
        uint expirationInSeconds,
        bool valid
    ) {
        return (
        sales[_saleId].price,
        sales[_saleId].paused,
        sales[_saleId].maxPerTx,
        sales[_saleId].expirationInSeconds,
        sales[_saleId].valid
        );
    }
    
    function pause()
    public
    onlyRole(LAND_PURCHASE_ADMIN)
    {
        _pause();
    }
    
    function unpause()
    public
    onlyRole(LAND_PURCHASE_ADMIN)
    {
        _unpause();
    }
    
    // Basic withdrawal of funds function in order to transfer ETH out of the smart contract
    function withdrawFunds(address to)
    public
    onlyRole(LAND_PURCHASE_ADMIN)
    {
        payable(to).transfer(address(this).balance);
    }
}