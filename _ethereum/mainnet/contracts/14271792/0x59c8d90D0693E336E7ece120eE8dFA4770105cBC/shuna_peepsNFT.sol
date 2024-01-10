// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./PaymentSplitter.sol";
import "./Pausable.sol";

contract ShunaPeepsNFT is ERC721Enumerable, Pausable, PaymentSplitter {
    using Counters for Counters.Counter;

    struct SaleConfig {
        uint256 startTime;
        uint256 maxCount;
    }
    uint256 public maxTotalSupply = 1000;
    uint256 public totalNFT;
    bool public isBurnEnabled;
    string public baseURI;
    SaleConfig public saleConfig;
    Counters.Counter private _tokenIds;
    uint256[] private _teamShares = [50, 50];
    address[] private _team = [
        0xcf292665ea0E174A40Ad9Ad1e528da899dd00b5D,
        0xAEABaFC9a7D7781A16325e87D5c5Aa4A05a46bcD        
    ];
    mapping(address => uint256) public _saleClaimed;
    mapping(address => uint256) public _totalClaimed;

    enum WorkflowStatus {
        Sale,
        SoldOut
    }
    WorkflowStatus public workflow;


    event ChangeSaleConfig(uint256 _startTime, uint256 _maxCount);
    event ChangeBaseURI(string _baseURI);
    event SaleMint(address indexed _minter, uint256 _amount, uint256 _price);
    event WorkflowStatusChange(
        WorkflowStatus newStatus
    );

    constructor()
        ERC721("PEEPS & Shuna Special Collab Edition NFTs", "Peeps&Shuna")
        PaymentSplitter(_team, _teamShares)
    {}

    function setBaseURI(string calldata _tokenBaseURI) external onlyOwner {
        baseURI = _tokenBaseURI;
        emit ChangeBaseURI(_tokenBaseURI);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setUpSale() external onlyOwner {
        
        uint256 _startTime = block.timestamp;
        uint256 _maxCount = 10;
        saleConfig = SaleConfig(_startTime, _maxCount);
        emit ChangeSaleConfig(_startTime, _maxCount);
        workflow = WorkflowStatus.Sale;
        emit WorkflowStatusChange(WorkflowStatus.Sale);
    }

    function getPrice() public view returns (uint256) {
        uint256 _price;       
        SaleConfig memory _saleConfig = saleConfig;
       
            _price = 200000000000000000; //0.2 ETH
              
        return _price;
    }

    function saleMint(uint256 _amount) internal {
        SaleConfig memory _saleConfig = saleConfig;
        require(_amount > 0, "Shuna&Peeps: zero amount");
        require(_saleConfig.startTime > 0, "Shuna&Peeps: sale is not active");
        require(
            block.timestamp >= _saleConfig.startTime,
            "Shuna&Peeps: sale not started"
        );
        require(
            _amount <= _saleConfig.maxCount,
            "Shuna&Peeps:  Can only mint 10 tokens at a time"
        );
        require(
            totalNFT + _amount <= maxTotalSupply,
            "Shuna&Peeps: max supply exceeded"
        );
        uint256 _price = getPrice();
        require(
            _price * _amount <= msg.value,
            "Shuna&Peeps: Ether value sent is not correct"
        );
        uint256 _newItemId;
        for (uint256 ind = 0; ind < _amount; ind++) {
            _tokenIds.increment();
            _newItemId = _tokenIds.current();
            _safeMint(msg.sender, _newItemId);
            _saleClaimed[msg.sender] = _saleClaimed[msg.sender] + _amount;
            _totalClaimed[msg.sender] = _totalClaimed[msg.sender] + _amount;
            totalNFT = totalNFT + 1;
        }
        emit SaleMint(msg.sender, _amount, _price);
    }

    function mainMint(uint256 _amount) external payable whenNotPaused {

        saleMint(_amount);
        
        if (totalNFT + _amount == maxTotalSupply) {
            workflow = WorkflowStatus.SoldOut;
            emit WorkflowStatusChange(
               
                WorkflowStatus.SoldOut
            );
        }
    }

    function getWorkflowStatus() public view returns (uint256) {
        uint256 _status;
        if (workflow == WorkflowStatus.Sale) {
            _status = 3;
        }
        if (workflow == WorkflowStatus.SoldOut) {
            _status = 4;
        }
        return _status;
    }
}