// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./PaymentSplitter.sol";
import "./Strings.sol";
import "./Pausable.sol";
import "./ERC721A.sol";

contract EACFounders is ERC721A, Pausable, PaymentSplitter {

 struct PresaleConfig {
        uint256 startTime;
        uint256 duration;
        uint256 maxCount;
    }
    struct SaleConfig {
        uint256 startTime;
        uint256 maxCount;
    }
    uint256 public maxGiftSupply;
    uint256 public giftCount;
    uint256 public price;
    bool private isPresale;
    string public baseURI;
    PresaleConfig public presaleConfig;
    SaleConfig public saleConfig;
    uint256[] private _teamShares = [2, 20, 78];
    address[] private _team = [
        0x80B08457d05C19FC061e3a0454EF38DebE247Eb2,
        0xfE10502945D0BaDB57C9Ab9db6fB8A2F7301d183,
        0xA93f35732D02A59c490d6c88b5011451Dae60130    
    ];
    mapping(address => bool) private _presaleList;
    mapping(address => uint256) public _presaleClaimed;
  

 constructor(
    uint256 _maxBatchSize,
    uint256 _maxTotalSupply, 
    uint256 _maxGiftSupply
  ) ERC721A("EAC Founders", "EAC", _maxBatchSize, _maxTotalSupply) 
     PaymentSplitter(_team, _teamShares)
  {

    require(
     ((_maxGiftSupply <= _maxTotalSupply) &&  (_maxBatchSize <= _maxTotalSupply)),
      "EXCLUSIVE ART CLUB: larger collection size needed"
    );
    maxGiftSupply  = _maxGiftSupply;  
  }
 
function setBaseURI(string calldata _tokenBaseURI) external onlyOwner {
        baseURI = _tokenBaseURI;
    }


function setmaxGiftSupply(uint256 _maxGiftSupply) external onlyOwner {
        require (_maxGiftSupply> giftCount, "EXCLUSIVE ART CLUB: the new amount must be higher");
        maxGiftSupply = _maxGiftSupply;
    }


    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function addToPresaleList(address[] calldata _addresses)
        external
        onlyOwner
    {
        for (uint256 ind = 0; ind < _addresses.length; ind++) {
            require(
                _addresses[ind] != address(0),
                "EXCLUSIVE ART CLUB: Can't add a zero address"
            );
            if (_presaleList[_addresses[ind]] == false) {
                _presaleList[_addresses[ind]] = true;
            }
        }
    }

    function isOnPresaleList(address _address) external view returns (bool) {
        return _presaleList[_address];
    }

    function removeFromPresaleList(address[] calldata _addresses)
        external
        onlyOwner
    {
        for (uint256 ind = 0; ind < _addresses.length; ind++) {
            require(
                _addresses[ind] != address(0),
                "EXCLUSIVE ART CLUB: Can't remove a zero address"
            );
            if (_presaleList[_addresses[ind]] == true) {
                _presaleList[_addresses[ind]] = false;
            }
        }
    }

    function setUpPresale(uint256 _duration, uint256 _maxCount ) external onlyOwner {
      require( _duration > 0,
            "EXCLUSIVE ART CLUB: presale duration is zero"
        );
        require(_maxCount <= maxBatchSize ,
            "EXCLUSIVE ART CLUB: maxCount is higher than maxBatchSize "
        );
        uint256 _startTime = block.timestamp;
        presaleConfig = PresaleConfig(_startTime, _duration, _maxCount);
       
    }

    function setUpSale(uint256 _maxCount ) external onlyOwner {
        require(_maxCount <= maxBatchSize ,
            "EXCLUSIVE ART CLUB: maxCount is higher than maxBatchSize "
        );
        PresaleConfig memory _presaleConfig = presaleConfig;
        uint256 _presaleEndTime = _presaleConfig.startTime +
            _presaleConfig.duration;
        require(
            block.timestamp > _presaleEndTime,
            "EXCLUSIVE ART CLUB: Sale not started"
        );
        uint256 _startTime = block.timestamp;
        saleConfig = SaleConfig(_startTime, _maxCount);
    }

    function setPrice( uint256 _price) external onlyOwner {
        price = _price;
    }

     function setIsPresale(bool _isPresale) external onlyOwner {
        isPresale = _isPresale; 
    }

    function giftMint(uint256 _amount)
        external
        onlyOwner
        whenNotPaused
    {
        require(
            (totalSupply() +  _amount <= collectionSize),
            "EXCLUSIVE ART CLUB:  max total sypply  is exceeded"
        );
        require(
            giftCount + _amount <= maxGiftSupply,
            "EXCLUSIVE ART CLUB: max gift supply is exceeded"
        );
            _safeMint(msg.sender, _amount);
    
            giftCount = giftCount + _amount;
        }
    function presaleMint(uint256 _amount) internal {
        PresaleConfig memory _presaleConfig = presaleConfig;
        require(
            _presaleConfig.startTime > 0,
            "EXCLUSIVE ART CLUB: Presale must be active"
        );
        require(
            block.timestamp >= _presaleConfig.startTime,
            "EXCLUSIVE ART CLUB: Presale not started"
        );
        require(
            block.timestamp <=
                _presaleConfig.startTime + _presaleConfig.duration,
            "EXCLUSIVE ART CLUB: Presale is ended"
        );
        if (isPresale){
        require(
            _presaleList[msg.sender] == true,
            "EXCLUSIVE ART CLUB: Caller is not on the presale list"
        );
        }
        require(
            _presaleClaimed[msg.sender] + _amount <= _presaleConfig.maxCount,
            "EXCLUSIVE ART CLUB: max count per transaction is exceeded"
        );
        require(
            (totalSupply() +  _amount <= collectionSize),
            "EXCLUSIVE ART CLUB:  max total sypply is exceeded"
        );
    
        require(
            price * _amount <= msg.value,
            "EXCLUSIVE ART CLUB: Ether value sent is not correct"
        );
            _safeMint(msg.sender, _amount);
            _presaleClaimed[msg.sender] = _presaleClaimed[msg.sender] + _amount;
          
        }
        
    
    function saleMint(uint256 _amount) internal {
        SaleConfig memory _saleConfig = saleConfig;
        require(_amount > 0, "EXCLUSIVE ART CLUB: zero amount");
        require(_saleConfig.startTime > 0, "EXCLUSIVE ART CLUB: sale is not active");
        require(
            block.timestamp >= _saleConfig.startTime,
            "EXCLUSIVE ART CLUB: sale not started"
        );
        require(
            _amount <= _saleConfig.maxCount,
            "EXCLUSIVE ART CLUB: max count per transaction is exceeded"
        );

         require(
            (totalSupply() +  _amount <= collectionSize), 
            "EXCLUSIVE ART CLUB: max total sypply is exceeded"
        );
        require(
            price * _amount <= msg.value,
            "EXCLUSIVE ART CLUB: Ether value sent is not correct"
        );

            _safeMint(msg.sender, _amount);
           
        }

    function mainMint(uint256 _amount) external payable whenNotPaused {
        require(
            block.timestamp > presaleConfig.startTime,
            "EXCLUSIVE ART CLUB: presale not started"
        );
        if (
            block.timestamp <=
            (presaleConfig.startTime + presaleConfig.duration)
        ) {
            presaleMint(_amount);
        } else {
            saleMint(_amount);
        }
    }

}

   

