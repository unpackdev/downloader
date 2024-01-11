// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract TigerLand is AccessControl, ReentrancyGuard, ERC721, Ownable {
    using Strings for uint256;
    uint public offerCount;                     // Index of the current buyable NFT in that type. offCount=0 means no NFT is left in that type
    uint public unitPrice;                      // Unit price(Wei)
    uint public minPurchase = 1;                // Minimum NFT to buy per purchase
    uint public maxPurchase = 3;                // Maximum NFT to buy per purchase
    uint public fund;                           // Payment tokens collected
    bool public paused = true;                  // Pause status
    bool public requireWhitelist = true;        // If require whitelist
    bool public limitOrder = true;        // If require limitOrder
    mapping(address => uint) public highLevelWhitelist;  // high-level whitelist users Address-to-claimable-amount mapping
    mapping(address => uint) public lowLevelWhitelist;  // low-level whitelist users Address-to-claimable-amount mapping

    mapping(address => uint) public userlist;  // user Address-to-claimable-amount mapping


    string public baseTokenURI;

    bytes32 public constant CLAIM_FUND_ROLE = keccak256("CLAIM_FUND_ROLE");    // Role that can claim the collected fund

    event UnitPriceSet(uint unitPrice);
    event MinPurchaseSet(uint minPurchase);
    event MaxPurchaseSet(uint maxPurchase);
    event Mint(uint tokenId);
    event Paused();
    event UnPaused();
    event SetRequireWhitelist();
    event SetLimitOrder();
    event HighLevelWhitelistAdded();
    event LowLevelWhitelistAdded();
    event HighLevelWhitelistBatchAdded();
    event LowLevelWhitelistBatchAdded();
    event OfferFilled(uint amount, uint totalPrice, address indexed filler, string _referralCode);
    event FundClaimed();

    constructor()
    ERC721("TigerVC DAO", "TigerVC"){
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CLAIM_FUND_ROLE, msg.sender);
    }

    modifier inPause() {
        require(paused, "Claims in progress");
        _;
    }

    modifier inProgress() {
        require(!paused, "Claims paused");
        _;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success,) = recipient.call{value : amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function setUnitPrice(uint _unitPrice) public onlyRole(DEFAULT_ADMIN_ROLE) inPause() {
        unitPrice = _unitPrice;
        emit UnitPriceSet(_unitPrice);
    }

    function setMinPurchase(uint _minPurchase) public onlyRole(DEFAULT_ADMIN_ROLE) inPause() {
        minPurchase = _minPurchase;
        emit MinPurchaseSet(_minPurchase);
    }

    function setMaxPurchase(uint _maxPurchase) public onlyRole(DEFAULT_ADMIN_ROLE) inPause() {
        maxPurchase = _maxPurchase;
        emit MaxPurchaseSet(maxPurchase);
    }

    function setLimitOrder(bool _limitOrder) public onlyRole(DEFAULT_ADMIN_ROLE) {
        limitOrder = _limitOrder;
        emit SetLimitOrder();
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) inProgress() {
        paused = true;
        emit Paused();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) inPause() {
        require(unitPrice > 0, "Unit price is not set");
        paused = false;
        emit UnPaused();
    }

    function setRequireWhitelist(bool _requireWhitelist) public onlyRole(DEFAULT_ADMIN_ROLE) {
        requireWhitelist = _requireWhitelist;
        emit SetRequireWhitelist();
    }

    function isWhitelist(address user) public view returns (uint level) {
        if (highLevelWhitelist[user] > 0) {
            return 1;
        } else if (lowLevelWhitelist[user] > 0) {
            return 2;
        } else {
            return 0;
        }
    }

    function setLowLevelWhitelist(address _whitelisted, uint _claimable) public onlyRole(DEFAULT_ADMIN_ROLE) {
        lowLevelWhitelist[_whitelisted] = _claimable;
        emit LowLevelWhitelistAdded();
    }

    function setLowLevelWhitelistBatch(address[] calldata _whitelisted, uint[] calldata _claimable) public onlyRole(DEFAULT_ADMIN_ROLE) inPause() {
        require(_whitelisted.length == _claimable.length, "_whitelisted and _claimable should have the same length");
        for (uint i = 0; i < _whitelisted.length; i++) {
            lowLevelWhitelist[_whitelisted[i]] = _claimable[i];
        }
        emit LowLevelWhitelistBatchAdded();
    }

    function setHighLevelWhitelist(address _whitelisted, uint _claimable) public onlyRole(DEFAULT_ADMIN_ROLE) {
        highLevelWhitelist[_whitelisted] = _claimable;
        emit HighLevelWhitelistAdded();
    }

    function setHighLevelWhitelistBatch(address[] calldata _whitelisted, uint[] calldata _claimable) public onlyRole(DEFAULT_ADMIN_ROLE) inPause() {
        require(_whitelisted.length == _claimable.length, "_whitelisted and _claimable should have the same length");
        for (uint i = 0; i < _whitelisted.length; i++) {
            highLevelWhitelist[_whitelisted[i]] = _claimable[i];
        }
        emit HighLevelWhitelistBatchAdded();
    }

    function fillOffersWithReferral(uint _amount, string memory _referralCode) public payable inProgress() nonReentrant {
        require(_amount >= minPurchase, "Amount must >= minPurchase");
        require(msg.value == unitPrice * _amount, "The transaction value should match with the total price");
        uint level = isWhitelist(msg.sender);
        require((requireWhitelist && level > 0) || !requireWhitelist, "whitelisting for external users is disabled");
        if (level == 1) {
            require(_amount <= highLevelWhitelist[msg.sender], "Insufficient claimable quota");
        }
        if (level == 2) {
            require(_amount <= lowLevelWhitelist[msg.sender], "Insufficient claimable quota");
        }
        userlist[msg.sender] = userlist[msg.sender] + _amount;
        if (limitOrder && userlist[msg.sender] > maxPurchase) {
            revert("Reached MaxPurchase!");
        }
        uint totalPrice = unitPrice * _amount;
        if (requireWhitelist && level == 1) highLevelWhitelist[msg.sender] -= _amount;
        if (requireWhitelist && level == 2) lowLevelWhitelist[msg.sender] -= _amount;
        fund += totalPrice;
        for (uint i = 1; i <= _amount; i ++) {
            _safeMint();
        }
        emit OfferFilled(_amount, totalPrice, msg.sender, _referralCode);
    }

    function _safeMint() internal {
        offerCount ++;
        _safeMint(msg.sender, offerCount);
        emit Mint(offerCount);
    }


    function claimFund() public onlyRole(CLAIM_FUND_ROLE) inPause() nonReentrant {
        require(fund > 0, "There is no fund to be claimed");
        uint toTransfer = fund;
        fund = 0;
        sendValue(payable(msg.sender), toTransfer);
        emit FundClaimed();
    }


    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721) {
        super._afterTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public override view returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
        string memory baseURI = _baseURI();
        string memory uriSuffix = Strings.toString(tokenId);
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, uriSuffix)) : '';
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    // Fallback: reverts if Ether is sent to this smart-contract by mistake
    fallback() external {
        revert();
    }
}
