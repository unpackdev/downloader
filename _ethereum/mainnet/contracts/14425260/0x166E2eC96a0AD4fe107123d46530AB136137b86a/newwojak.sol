// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./PaymentSplitter.sol";
import "./Pausable.sol";

contract wojak is ERC721Enumerable, Pausable, PaymentSplitter {
    using Counters for Counters.Counter;

   
    struct SaleConfig {
        uint256 startTime;
        uint256 maxCount;
    }
    uint256 public maxTotalSupply = 10069;
    uint256 public maxGiftSupply = 69;
    uint256 public giftCount;
    uint256 public totalNFT;
	bool public isBurnEnabled;
    string public baseURI;
	string public caURI;
    SaleConfig public saleConfig;
    Counters.Counter private _tokenIds;
    uint256[] private _teamShares = [100]; 
    address[] private _team = [
        0x3b4Bd977B5b9efd53FE17a196a4c972A1cDFf51a
    ];
    mapping(address => uint256) public _giftClaimed;
    mapping(address => uint256) public _saleClaimed;
    mapping(address => uint256) public _totalClaimed;

    enum WorkflowStatus {
        CheckOnPresale,
        Presale,
        Sale,
        SoldOut
    }
    WorkflowStatus public workflow;

    
    event ChangeSaleConfig(uint256 _startTime, uint256 _maxCount);
    event ChangeIsBurnEnabled(bool _isBurnEnabled);
    event ChangeBaseURI(string _baseURI);
	event ChangeContractURI(string _caURI);
    event GiftMint(address indexed _recipient, uint256 _amount);
    event SaleMint(address indexed _minter, uint256 _amount, uint256 _price);
	event NormalMint(address indexed _minter, uint256 _amount, uint256 _price);
	event RefferalMint(address indexed _minter, uint256 _amount, uint256 _price);
    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );

    constructor()
        ERC721("World of Wojak", "WOW")
        PaymentSplitter(_team, _teamShares)
    {}

    function setBaseURI(string calldata _tokenBaseURI) external onlyOwner {
        baseURI = _tokenBaseURI;
        emit ChangeBaseURI(_tokenBaseURI);
    }
	function setContractURI(string calldata _contractTokenURI) external onlyOwner {
        caURI = _contractTokenURI;
        emit ChangeContractURI(_contractTokenURI);
    }
    function contractURI() public view returns (string memory) {
        return  caURI;
    }
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

	
   
    function setUpSale() external onlyOwner {
        baseURI="https://www.worldofwojak.com/api2/";
	    caURI= "https://worldofwojak.com/contract/";
        uint256 _startTime = block.timestamp;
        uint256 _maxCount = 3;
        saleConfig = SaleConfig(_startTime, _maxCount);
        emit ChangeSaleConfig(_startTime, _maxCount);
        workflow = WorkflowStatus.Sale;
        emit WorkflowStatusChange(WorkflowStatus.Presale, WorkflowStatus.Sale);
    }
    function getPrice() public pure returns (uint256) {
        uint256 _price;
        _price = 80000000000000000; //0.08 ETH
		return _price;
    }

    function setIsBurnEnabled(bool _isBurnEnabled) external onlyOwner {
        isBurnEnabled = _isBurnEnabled;
        emit ChangeIsBurnEnabled(_isBurnEnabled);
    }
    function giftMint(address[] calldata _addresses)
        external
        onlyOwner
        whenNotPaused
    {
        require(
            totalNFT + _addresses.length <= maxTotalSupply,
            "wojak: max total supply exceeded"
        );

        require(
            giftCount + _addresses.length <= maxGiftSupply,
            "wojak: max gift supply exceeded"
        );

        uint256 _newItemId;
        for (uint256 ind = 0; ind < _addresses.length; ind++) {
            require(
                _addresses[ind] != address(0),
                "wojak: recepient is the null address"
            );
            _tokenIds.increment();
            _newItemId = _tokenIds.current();
            _safeMint(_addresses[ind], _newItemId);
            _giftClaimed[_addresses[ind]] = _giftClaimed[_addresses[ind]] + 1;
            _totalClaimed[_addresses[ind]] = _totalClaimed[_addresses[ind]] + 1;
            totalNFT = totalNFT + 1;
            giftCount = giftCount + 1;
        }
    }

	
    function refferalMint(uint256 _amount, address payable _referrer ) external payable whenNotPaused  {
       SaleConfig memory _saleConfig = saleConfig;
        require(_amount > 0, "wojak: zero amount");
        require(_saleConfig.startTime > 0, "wojak: sale is not active");
        require(		
            block.timestamp >= _saleConfig.startTime,
            "wojak: sale not started"
        );
        require(
            _amount <= _saleConfig.maxCount,
            "wojak:  Can only mint 10 tokens at a time"
        );
        require(
            totalNFT + _amount <= maxTotalSupply,
            "wojak: max supply exceeded"
        );
        uint256 _price =getPrice();
		if (balanceOf(_referrer)==1) {
		_price=getPrice()-5000000000000000;
		}
		if (balanceOf(_referrer)>1) {
		_price=getPrice()-15000000000000000;
		}
        require(
            _price * _amount <= msg.value,
            "wojak: Ether value sent is not correct"
        );
		require(_totalClaimed[msg.sender]-_giftClaimed[msg.sender]+_amount<=3,
            "wojak: Ether value sent is not correct");
		require(balanceOf(_referrer)>0,
            "wojak: Ether value sent is not correct");
		
		uint256 _newItemId;
        for (uint256 ind = 0; ind < _amount; ind++) {
            _tokenIds.increment();
            _newItemId = _tokenIds.current();
            _safeMint(msg.sender, _newItemId);
            _saleClaimed[msg.sender] = _saleClaimed[msg.sender] + 1;
            _totalClaimed[msg.sender] = _totalClaimed[msg.sender] + 1;
            totalNFT = totalNFT + 1;
			if (balanceOf(_referrer)==1) {
			_referrer.transfer(5000000000000000);
			}
			if (balanceOf(_referrer)>1) {
			_referrer.transfer(15000000000000000);
			}
        }
		
		
        emit RefferalMint(msg.sender, _amount, _price);
    }
 
    function normalMint(uint256 _amount) external payable whenNotPaused {
        SaleConfig memory _saleConfig = saleConfig;
        require(_amount > 0, "wojak: zero amount");
        require(_saleConfig.startTime > 0, "wojak: sale is not active");
        require(
            block.timestamp >= _saleConfig.startTime,
            "wojak: sale not started"
        );
        require(
            _amount <= _saleConfig.maxCount,
            "wojak:  Can only mint 10 tokens at a time"
        );
        require(
            totalNFT + _amount <= maxTotalSupply,
            "wojak: max supply exceeded"
        );
        uint256 _price = getPrice();
        require(
            _price * _amount <= msg.value,
            "wojak: Ether value sent is not correct"
        );
		require(_totalClaimed[msg.sender]-_giftClaimed[msg.sender]+_amount<=3,
            "wojak: Ether value sent is not correct");
		uint256 _newItemId;
        for (uint256 ind = 0; ind < _amount; ind++) {
            _tokenIds.increment();
            _newItemId = _tokenIds.current();
            _safeMint(msg.sender, _newItemId);
            _saleClaimed[msg.sender] = _saleClaimed[msg.sender] + 1;
            _totalClaimed[msg.sender] = _totalClaimed[msg.sender] + 1;
            totalNFT = totalNFT + 1;
        }
        emit NormalMint(msg.sender, _amount, _price);
    }
	
    function burn(uint256 tokenId) external {
        require(isBurnEnabled, "wojak: burning disabled");
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "wojak: burn caller is not owner nor approved"
        );
        _burn(tokenId);
        totalNFT = totalNFT - 1;
    }

    function getWorkflowStatus() public view returns (uint256) {
        uint256 _status;
        if (workflow == WorkflowStatus.CheckOnPresale) {
            _status = 1;
        }
        if (workflow == WorkflowStatus.Presale) {
            _status = 2;
        }
        if (workflow == WorkflowStatus.Sale) {
            _status = 3;
        }
        if (workflow == WorkflowStatus.SoldOut) {
            _status = 4;
        }
        return _status;
    }
}