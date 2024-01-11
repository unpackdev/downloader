//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IBM.sol";
import "./IHoney.sol";
import "./IPriceStrategy.sol";
import "./IBonusProgram.sol";
import "./IBMSettings.sol";

import "./CCLib.sol";
import "./Validator.sol";
import "./Killswitch.sol";

contract BM is ERC721, IBM, Validator, Killswitch {
    IHoney private _honey;
    IPriceStrategy private _priceStrategy;
    IBonusProgram private _bonusProgramm;
    IBMSettings private _settings;

    mapping(uint256 => uint256) private _tokenRank;
    mapping(address => uint256) private _ownerRank;
    mapping(address => uint256) private _honeyClaimedAt;

    uint256 private _tokenNum;
    uint256 private constant MAX_SUPPLY = 9568;

    uint256 private _godfatherId = 0;
    uint256 private _godfatherRank = 0;
    string private _baseUri;
    uint256 private _salesStartTimestamp = 0;

    modifier honey() {
        require(address(_honey) != address(0), "Missing honey");
        _;
    }

    modifier sales() {
        // solhint-disable-next-line not-rely-on-time
        require(_salesStartTimestamp > 0 && block.timestamp >= _salesStartTimestamp, "sales not started");
        _;
    }

    constructor(string memory name_, string memory symbol_
        , address settingsAddress
        , address honeyAddress
        , address priceStrategy
        , address bonusProgramAddress
        ) ERC721(name_, symbol_)
    {
        setSettings(settingsAddress);
        setHoney(honeyAddress);
        setPriceStrategy(priceStrategy);
        setBonusProgram(bonusProgramAddress);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseUri;
    }

    function setBaseUri(string memory baseUri) external override onlyOwner {
        _baseUri = baseUri;
    }

    function setSettings(address settingsAddress) public override onlyOwner {
        require(settingsAddress != address(0), "invalid settingsAddress");
        _settings = IBMSettings(settingsAddress);
    }

    function setHoney(address honeyAddress) public override onlyOwner {
        require(honeyAddress != address(0), "invalid honeyAddress");
        _honey = IHoney(honeyAddress);
    }

    function setPriceStrategy(address priceStrategyAddress) public override onlyOwner {
        require(priceStrategyAddress != address(0), "invalid priceStrategyAddress");
        _priceStrategy = IPriceStrategy(priceStrategyAddress);
    }

    function setBonusProgram(address bonusProgramAddress) public override onlyOwner {
        _bonusProgramm = IBonusProgram(bonusProgramAddress);
    }

    function setSalesStartAt(uint256 timestamp) external override onlyOwner {
        _salesStartTimestamp = timestamp;
    }

    function totalSupply() public override view returns (uint256) {
        return _tokenNum;
    }

    function getPrice() public view override returns (uint256)
    {
        return _priceStrategy.getPrice(_tokenNum);
    }

    function getBearLevel(uint256 tokenId) external view override returns (uint256) {
        return _tokenRank[tokenId] + 1;
    }

    function getBearEfficiency(uint256 tokenId) external view override returns (uint256) {
        return _settings.getBaseEfficiency() + _settings.getEfficiencyPerLevel() * _tokenRank[tokenId];
    }

    function getOwnerEfficiency(address owner) public view override returns (uint256) {
        return balanceOf(owner) * _settings.getBaseEfficiency() + _settings.getEfficiencyPerLevel() * _ownerRank[owner];
    }

    function getHoneyAvailableForClaimAt(uint256 _ts) external view override returns (uint256) {
        return _getHoneyAvailableForClaimAt(msg.sender, _ts);
    }

    function getHoneyAvailableForClaimAt(address owner, uint256 _ts) external view override returns (uint256) {
        return _getHoneyAvailableForClaimAt(owner, _ts);
    }

    function claimHoney() external override {
        _claimHoneyFor(msg.sender);
    }

    function levelUp(uint256 tokenId, uint256 honeyValue) external override {
        _levelUp(msg.sender, tokenId, honeyValue);
    }

    function getLevelupPrice(uint256 currentRank) public view override returns (uint256) {
        return _settings.getLevelupPrice(currentRank);
    }

    function getSalesStartAt() external view override returns (uint256) {
        return _salesStartTimestamp;
    }

    function _getHoneyAvailableForClaimAt(address owner, uint256 _ts) internal view returns (uint256) {
        if (_honeyClaimedAt[owner] == 0 || _ts <= _honeyClaimedAt[owner]) {
          return 0;
        }
        uint256 elapsed = _ts - _honeyClaimedAt[owner];
        return elapsed * getOwnerEfficiency(owner) * _settings.getGatherFactor();
    }

    function _claimHoneyFor(address claimFor) internal honey {
        require(claimFor != address(0), "invalid claimFor");
        // solhint-disable-next-line not-rely-on-time
        uint256 _now = block.timestamp;
        uint256 amount = _getHoneyAvailableForClaimAt(claimFor, _now);
        if (amount > 0) {
            _honey.mint(claimFor, amount);
        }
        if (_now > _honeyClaimedAt[claimFor]) {
            _honeyClaimedAt[claimFor] = _now;
        }
    }

    function _levelUp(address owner, uint256 tokenId, uint256 honeyValue) internal honey {
        require(owner != address(0), "invalid owner address");
        require(owner == ownerOf(tokenId), "not an owner");

        uint256 price = getLevelupPrice(_tokenRank[tokenId]);
        require(price == honeyValue, "price doesn't match");

        _claimHoneyFor(owner);

        require(price <= _honey.balanceOf(owner), "not enough honey");
        _honey.burn(owner, price);
        _tokenRank[tokenId]++;
        _ownerRank[owner]++;

        if (_tokenRank[tokenId] > _godfatherRank) {
            uint256 prevId = _godfatherId;
            _godfatherRank = _tokenRank[tokenId];
            _godfatherId = tokenId;
            if (prevId != _godfatherId) {
                // solhint-disable-next-line not-rely-on-time
                emit NewGodFather(owner, tokenId, _godfatherRank, block.timestamp);
            }
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        uint256 tokenRank = _tokenRank[tokenId];
        if (from != address(0)) {
            _claimHoneyFor(from);
            _ownerRank[from] -= tokenRank;
        }

        if (to != address(0)) {
            _claimHoneyFor(to);
            _ownerRank[to] += tokenRank;
        }
    }

    function mint(uint256 amount) external override payable killswitch sales {
        require(msg.value == getPrice() * amount, "value doesn't match");
        _mintImpl(msg.sender, amount);

        if (address(_bonusProgramm) != address(0)) {
            _bonusProgramm.onPurchase(msg.sender, amount);
        }
    }

    function _mintImpl(address for_, uint256 amount) private {
        require(amount > 0 && amount <= 20, "can't mint 0 or above 20 per tx");
        require(_tokenNum + amount <= MAX_SUPPLY, "can't mint above MAX_SUPPLY");

        uint256 _initial = _tokenNum + 1;
        for (uint256 i = 0; i < amount; ++i) {
            _safeMint(for_, _initial + i);
        }
        _tokenNum += amount;
    }

    function validatorMintOne(address mintFor) external override onlyValidator killswitch {
        _mintImpl(mintFor, 1);
    }

    function validatorMint(address mintFor, uint256 tokenId) external override onlyValidator killswitch {
        require(mintFor != address(0), "invalid mintFor");
        require(tokenId <= _tokenNum, "not allowed: totalSupply");
        _safeMint(mintFor, tokenId);
    }

    function validatorBurn(uint256 tokenId) external override onlyValidator killswitch {
        _burn(tokenId);
    }

    function withdraw() external override onlyOwner {
        address payable cbA = payable(_settings.getCashbackAddress());
        if (cbA != address(0)) {
            uint256 cbP = _settings.getCashbackPercent();
            uint256 cbValue = address(this).balance * cbP / 100;
            if (cbValue > 0) {
                cbA.transfer(cbValue);
            }
        }

        uint256 value = address(this).balance;
        if (value > 0) {
            address payable to = payable(owner());
            to.transfer(value);
        }
    }
}
