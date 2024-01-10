// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./PaymentSplitter.sol";
import "./Pausable.sol";

contract TweeterFrens is ERC721Enumerable, Pausable, PaymentSplitter {
    using Counters for Counters.Counter;

    struct SaleConfig {
        uint256 startTime;
        uint256 maxCount;
    }
    uint256 public maxTotalSupply = 5000;
    uint256 public totalNFT;
    bool public isBurnEnabled;
    string public baseURI;
    SaleConfig public saleConfig;
    Counters.Counter private _tokenIds;
    uint256[] private _teamShares = [100];
    address[] private _team = [
        0x60f4A9BB885F73e606f7105E4bBdd8e746779440        
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
        ERC721("TweeterFrens", "TweeterFrens")
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
        uint256 _maxCount =33;
        saleConfig = SaleConfig(_startTime, _maxCount);
        emit ChangeSaleConfig(_startTime, _maxCount);
        workflow = WorkflowStatus.Sale;
        emit WorkflowStatusChange(WorkflowStatus.Sale);
    }

    function getPrice() public view returns (uint256) {
        uint256 _price;       
        SaleConfig memory _saleConfig = saleConfig;
       
            _price = 30000000000000000; //0.03 ETH
              
        return _price;
    }

    function saleMint(uint256 _amount) internal {
        SaleConfig memory _saleConfig = saleConfig;
        require(_amount > 0, "Tweeter Frens: zero amount");
        require(_saleConfig.startTime > 0, "Tweeter Frens: sale is not active");
        require(
            block.timestamp >= _saleConfig.startTime,
            "Tweeter Frens: sale not started"
        );
        require(
            _amount <= _saleConfig.maxCount,
            "Tweeter Frens:  Can only mint 10 tokens at a time"
        );
        require(
            totalNFT + _amount <= maxTotalSupply,
            "Tweeter Frens: max supply exceeded"
        );
        uint256 _price = getPrice();
        require(
            _price * _amount <= msg.value,
            "Tweeter Frens: Ether value sent is not correct"
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