//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ParallabsMintPassSigner.sol";

contract ParallabsMintPass is
    ERC721EnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    ParallabsMintPassSigner
{
    struct division{
        uint256 buyLimit;
        uint256 cap;
        uint256 mintTracker;
        mapping(address => uint256) accountMintTracker;
    }

    string public baseURI;
    uint256 public maxSupply;
    address public designatedSigner;

    division public silverList;
    division public goldList;    


    modifier onlyEOA() {
        require(msg.sender == tx.origin, "Only wallets please");
        _;
    }


    modifier supplyController(uint256 _amount) {
        require(
            _amount > 0, 
            "Invalid amount"
        );
        require(
            totalSupply() + _amount <= maxSupply,
            "Exceeding maximum supply"
        );
        _;
    }


    modifier listController(listed memory _buyer, uint256 _listType) {
        require(
            getSigner(_buyer) == designatedSigner,
            "Invalid signature"
        );
        require(
            _buyer.addr == msg.sender,
            "Invalid address"
        );

        if(_listType == 1){
            require( 
                _buyer.inSilverList, 
                "Not listed"
            );
        } 
        else {
            require( 
                _buyer.inGoldList, 
                "Not listed"
            );
        }
        _;
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        address designatedSigner_
    ) public initializer {
        require(
            designatedSigner_ != address(0), 
            "Initialize: invalid designated signer address"
        );

        __ERC721_init(name_, symbol_);
        __ParallabsMintPassSigner_init();
        __ERC721Enumerable_init();
        __Pausable_init();
        __Ownable_init();
        __ReentrancyGuard_init();

        designatedSigner = designatedSigner_;
        maxSupply = 4500;

        silverList.buyLimit = 1;
        goldList.buyLimit = 1;

        silverList.cap = 4000;
        goldList.cap = 500;
    }

    
    function mint_silverList(listed memory _buyer, uint256 _amount)
        external
        nonReentrant
        onlyEOA
        whenNotPaused
        supplyController(_amount)
        listController(_buyer, 1)
    {
        require(
            silverList.mintTracker + _amount <= silverList.cap,
            "SilverList: Exceeding cap"
        );
        require(
            silverList.accountMintTracker[_buyer.addr] + _amount
                <= silverList.buyLimit,
            "SilverList: Exceeding buy limit"
        );

        silverList.accountMintTracker[_buyer.addr] += _amount;

        for(uint i=0; i < _amount; i++){
            _mint(_buyer.addr, goldList.cap + silverList.mintTracker + 1);
            silverList.mintTracker += 1;
        }
    }

    function mint_goldList(listed memory _buyer, uint256 _amount) 
        external
        nonReentrant
        onlyEOA
        whenNotPaused
        supplyController(_amount)
        listController(_buyer, 2)
    {
        require(
            goldList.mintTracker + _amount <= goldList.cap,
            "GoldList: Exceeding cap"
        );
        require(
            goldList.accountMintTracker[_buyer.addr] + _amount
                <= goldList.buyLimit,
            "GoldList: Exceeding buy limit"
        );

        goldList.accountMintTracker[_buyer.addr] += _amount;
        for(uint i=0; i < _amount; i++){
            _mint(_buyer.addr, goldList.mintTracker + 1);
            goldList.mintTracker += 1;
        }
    }

    function getMintedPassForUser(address _user, bool _isGoldList) public view returns(uint){
        require(_user != address (0), "Invalid Address");
        if(_isGoldList){
            return goldList.accountMintTracker[_user];
        }
        else {
            return silverList.accountMintTracker[_user];
        }
    }

    function setDesignatedSigner(address _designatedSigner) external onlyOwner {
        designatedSigner = _designatedSigner;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setCaps(uint256 _silverListCap, uint256 _goldListCap) external onlyOwner {
        silverList.cap = _silverListCap;
        goldList.cap = _goldListCap;
    }
    
    function setBuyLimit(uint256 _silverListBuyLimit, uint256 _goldListBuyLimit) external onlyOwner {
        silverList.buyLimit = _silverListBuyLimit;
        goldList.buyLimit = _goldListBuyLimit;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

}
