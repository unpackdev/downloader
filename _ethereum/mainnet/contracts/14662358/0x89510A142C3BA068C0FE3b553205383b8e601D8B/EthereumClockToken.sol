// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./IEthereumClockToken.sol";
import "./Raffle.sol";
import "./ERC721Tradable.sol";
import "./console.sol";

/**
 * @title EthereumClockToken
 * @author JieLi
 *
 * @notice ERC721 Eth clock token
 */
contract EthereumClockToken is IEthereumClockToken, Raffle, ERC721Tradable
{
    using Strings for uint256;

    mapping(uint256 => uint256) private tokenIdToNftIdList;
    mapping(address => uint8) public mintedCount;
    mapping(address => uint[]) public tokenIdList;

    // ============ Functions ============

    /**
     * @notice Name => `Ethereum Clock Token`, Symbol => `Eth-Clock`
     * @dev See {IERC721- contructor}
     */
    constructor(string memory _pendingURI, address _proxyRegistryAddress) ERC721Tradable("Ethereum Clock Token", "Eth-Clock", _proxyRegistryAddress) {
        _PENDING_URI_ = _pendingURI;
        _RAFFLE_ALLOWED_ = true;
        _DROP_ALLOWED_ = true;
        _RANDOM_VALUE_ = 0;
        whiteList[owner()] = true;
    }

    /**
     * @notice init function
     */
    function init(
        uint256 _maxTokenLevel,
        uint256 _preSaleCount,
        uint256 _maxMintCount,
        uint256 _whiteListCount,
        uint256 _countPerLevel,
        uint256 _price,
        uint256 _ownerPrice,
        uint256 _presalePrice,
        bool _revealAllowed,
        bool _preSaleAllowed,
        string memory _uriExtension
    ) external onlyOwners {
        _MAX_TOKEN_LEVEL_ = _maxTokenLevel;
        _PRESALE_COUNT_ = _preSaleCount;
        _MAX_MINT_COUNT_ = _maxMintCount;
        _WHITE_LIST_COUNT_ = _whiteListCount;
        _COUNT_PER_LEVEL_ = _countPerLevel;
        _PRICE_ = _price;
        _OWNER_PRICE_ = _ownerPrice;
        _PRESALE_PRICE_ = _presalePrice;
        _REVEAL_ALLOWED_ = _revealAllowed;
        _PRESALE_ALLOWED_ = _preSaleAllowed;
        _URI_EXTENSION_ = _uriExtension;
    }

    /**
     * @notice get price function - according to the msg.sender
     */
    function getPrice(address user) public view returns (uint256) {
        if (owners[user]) {
            return _OWNER_PRICE_; // Return Owner Price
        }

        if (_PRESALE_ALLOWED_) {
            return _PRESALE_PRICE_; // Return PreSale Price
        } else {
            return _PRICE_; // Return Public Price
        }
    }

    /**
     * @notice get price function - according to the msg.sender
     */
    function getMintLimitCount() public view returns (uint256) {
        if (owners[msg.sender]) {
            return _WHITE_LIST_COUNT_;
        } else {
            return _MAX_MINT_COUNT_;
        }
    }

    /**
     * @notice Directly Dropping payable function - call when the customer want to drop directly once the whitelist not filled
     */
    function directDrop() public payable returns (uint256) {
        register();
        return drop();
    }

    /**
     * @notice Drop payable function - Value shouldn't be less than 0.12eth
     */
    function drop() public payable returns (uint256) {
        require(_DROP_ALLOWED_, "DROP NOT ALLOWED");
        require(whiteList[msg.sender], "NOT WHITELIST USER");
        require(mintedCount[msg.sender] < getMintLimitCount(), "LIMIT DROP COUNT");
        require(msg.value == getPrice(msg.sender), "NOT ENOUGH PRICE");

        uint256 newItemId = mint(msg.sender);
        uint256 randomValue = uint256(keccak256(abi.encode(_getNow(), newItemId)));
        if (randomValue < 1000000) {
            randomValue = (randomValue + 1) * 123456;
        }
        uint256 environmentRandomValue = randomValue % 100 * 100;
        uint256 shineRandomValue = randomValue % 10000 / 100 * 100;
        uint256 efficiencyRandomValue = randomValue % 1000000 / 10000 *100;
        uint256 environmentIndex = 0;
        uint256 shineIndex = 0;
        uint256 efficiencyIndex = 0;

        uint256 prevPercentage = 0;
        for (uint i = 0; i < _ENVIRONMENT_PROBABILITY_.length; i ++) {
            if (environmentRandomValue >= prevPercentage && environmentRandomValue < prevPercentage + _ENVIRONMENT_PROBABILITY_[i]) {
                environmentIndex = i + 1;
            }
            prevPercentage += _ENVIRONMENT_PROBABILITY_[i];
        }

        prevPercentage = 0;
        for (uint i = 0; i < _SHINE_PROBABILITY_.length; i ++) {
            if (shineRandomValue >= prevPercentage && shineRandomValue < prevPercentage + _SHINE_PROBABILITY_[i]) {
                shineIndex = i + 1;
            }
            prevPercentage += _SHINE_PROBABILITY_[i];
        }

        prevPercentage = 0;
        for (uint i = 0; i < _EFFICIENCY_PROBABILITY_.length; i ++) {
            if (efficiencyRandomValue >= prevPercentage && efficiencyRandomValue < prevPercentage + _EFFICIENCY_PROBABILITY_[i]) {
                efficiencyIndex = i + 1;
            }
            prevPercentage += _EFFICIENCY_PROBABILITY_[i];
        }
        tokenIdToNftIdList[newItemId] = environmentIndex + shineIndex * _ENVIRONMENT_PROBABILITY_.length + efficiencyIndex * _ENVIRONMENT_PROBABILITY_.length * _SHINE_PROBABILITY_.length;
        mintedCount[msg.sender] = mintedCount[msg.sender] + 1;
        tokenIdList[msg.sender].push(newItemId);
        levels[newItemId] = 1;
        startTimestamps[newItemId] = _getNow();
        return newItemId;
    }

    /**
     * @dev External function to withdraw ETH in contract. This function can be called only by owner.
     * @param _amount ETH amount
     */
    function withdrawETH(uint256 _amount) external onlyOwners {
        uint256 balance = address(this).balance;
        require(_amount <= balance, "BATTLE ROYALE: OUT OF BALANCE");

        payable(msg.sender).transfer(_amount);

        emit EthWithdrew(msg.sender, _amount);
    }

    /**
     * @dev External function to withdraw total balance of contract. This function can be called only by owner.
     */
    function withdraw() public onlyOwners {
        require(payable(msg.sender).send(address(this).balance));

        emit Withdrew(msg.sender);
    }

    function getTokenIdList(address _owner) public view returns(uint[] memory) {
        return tokenIdList[_owner];
    }

    // ============ Advanced Functions ============

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI QUERY FOR NONE-EXISTENT TOKEN");

        string memory currentBaseURI = baseTokenURI();
        if (_REVEAL_ALLOWED_) {
            return currentBaseURI;
        } else {
            uint256 tokenIpfsId = frozen[tokenId] ? (tokenIdToNftIdList[tokenId] + _COUNT_PER_LEVEL_) : (charred[tokenId] ? tokenIdToNftIdList[tokenId] + _COUNT_PER_LEVEL_ * 2 : tokenIdToNftIdList[tokenId]);
            tokenIpfsId = tokenIpfsId + (levels[tokenId] - 1) * _COUNT_PER_LEVEL_ * 3;
            return string(
                abi.encodePacked(
                    currentBaseURI,
                    tokenIpfsId.toString(),
                    _URI_EXTENSION_
                )
            );
        }
    }

    function baseTokenURI() virtual public view returns (string memory) {
        return !_REVEAL_ALLOWED_ ? _REVEAL_URI_ : _PENDING_URI_;
    }

    function setFrozen(uint256 tokenId) external override onlyController {
        require(!frozen[tokenId], "FROZEN YET");
        frozen[tokenId] = true;

        emit Frozen(ownerOf(tokenId), tokenId);
    }

    function setCharred(uint256 tokenId) external override onlyController {
        require(!charred[tokenId], "CHARRED YET");
        charred[tokenId] = true;
        emit Charred(ownerOf(tokenId), tokenId);
    }

    function redeem(uint256 tokenId) external override onlyController {
        startTimestamps[tokenId] = _getNow();
        emit Redeem(tokenId, ownerOf(tokenId), _getNow());
    }

    function enhance(uint256 tokenId) external override onlyController returns (bool) {
        uint256 level = levels[tokenId] + 1;
        require(level <= _MAX_TOKEN_LEVEL_, "MAX LEVEL");

        levels[tokenId] = level;
        emit Enhanced(ownerOf(tokenId), tokenId);
        return true;
    }

    function godTier(uint256 tokenId) external override onlyController returns (bool) {
        uint256 level = levels[tokenId];
        require(level != _MAX_TOKEN_LEVEL_, "ALREADY GOD-TIER");

        levels[tokenId] = _MAX_TOKEN_LEVEL_;
        emit GodTier(ownerOf(tokenId), tokenId);
        return true;
    }

    function fail(uint256 tokenId) external override onlyController returns (bool) {
        uint256 level = levels[tokenId] - 1;
        require(level > 0, "MINIMUM LEVEL");

        levels[tokenId] = level;
        emit Failed(ownerOf(tokenId), tokenId);
        return true;
    }

    // ============ Params Setting Functions ============

    function setBaseURI(string memory _newBaseURI) public onlyOwners {
        if (!_REVEAL_ALLOWED_) {
            _REVEAL_URI_ = _newBaseURI;
        } else {
            _PENDING_URI_ = _newBaseURI;
        }
        emit BaseURIUpdated(_newBaseURI);
    }

}
