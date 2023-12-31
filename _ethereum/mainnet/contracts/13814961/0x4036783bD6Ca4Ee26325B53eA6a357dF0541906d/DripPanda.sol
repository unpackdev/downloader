// SPDX-License-Identifier: MIT

/**
 * Drip Panda Punk Contract
 * @author 
 */

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./ERC721URIStorage.sol";
import "./Strings.sol";
import "./SafeMath.sol";

contract DripPanda is Ownable, ERC721URIStorage, ReentrancyGuard {
    using SafeMath for uint256;
    using Strings for uint256;


    uint256 public constant PANDAS_MAX = 2222;
    uint256 public maxCountPerClaim = 5;
    uint256 public maxCountPerWallet = 5;
    uint256 public pricePerPanda = 0.075 ether;
    address public feeToken = address(0x0);

    uint256 public totalMinted = 0;

    bool    private _isActive = false;
    string  private _tokenBaseURI = "";

    uint256[2222] private _availableTokens;
    uint256 private _numAvailableTokens = 2222;

    mapping(address => uint256) claims;

    address public walletA = 0xD599202E6a023f34427bDfe52d30632709525C08;
    address private devAddr;

    struct Item {
        address to;
        uint256 count;
        uint256 paidCount;
    }
    Item[] private whitelist;
    uint256 curIndex = 0;

    event StatusUpdated(bool active);
    event Claimed(address account, uint256 times);
    event BaseURIUpdated(string uri);

    event ClaimMaxCountUpdated(uint256 count);
    event ClaimMaxCountPerWalletUpdated(uint256 count);
    event PaymentTokenUpdated(address token);
    event PriceUpdated(uint256 price);
    event DevAddressUpdated(address addr);


    modifier onlyActive() {
        require(_isActive && totalMinted < PANDAS_MAX, 'DripPanda: not active');
        _;
    }

    constructor() ERC721("DripPanda", "DP") {
        whitelist.push(Item(0xfD4F4591137b09af43128550756Ef0744CC38703, 16, 0));
        whitelist.push(Item(0xeF8c798b48708e30357862A9BFA368Ee09609AA5, 65, 0));
        whitelist.push(Item(0xACA66dE7577907DA6a7a451ED8e8B3E23E87e6fd, 65, 0));

        devAddr = msg.sender;

        _premint();
    }

    function claim(uint256 numberOfTokens) external payable onlyActive nonReentrant{
        require(numberOfTokens > 0, "DripPanda: zero count");
        require(numberOfTokens <= _numAvailableTokens, "DripPanda: not enough panda");

        if(msg.sender != walletA) {
            require(numberOfTokens <= maxCountPerClaim, "DripPanda: exceeded max limit per claim");
            require(claims[msg.sender].add(numberOfTokens) <= maxCountPerWallet, "DripPanda: exceeded max limit per wallet");
        }

        uint256 fee = pricePerPanda.mul(numberOfTokens);
        if(feeToken == address(0x0)) {
            require(msg.value >= fee, "DripPanda: Too little sent, please send more eth");
            if(msg.value > fee) {
                payable(msg.sender).transfer(msg.value - fee);
            }
        }

        _distributeFee(numberOfTokens);

        uint256 updatedNumAvailableTokens = _numAvailableTokens;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 randomId =  useRandomAvailableToken(numberOfTokens, i);

            _safeMint(msg.sender, randomId);
            super._setTokenURI(randomId, randomId.toString());

            totalMinted = totalMinted.add(1);
            claims[msg.sender]++;
            updatedNumAvailableTokens--;
        }
        _numAvailableTokens = updatedNumAvailableTokens;

        emit Claimed(msg.sender, numberOfTokens);
    }

    function useRandomAvailableToken(uint256 _numToFetch, uint256 _idx) internal returns (uint256) {
        uint256 randomNum =
            uint256(
                keccak256(
                    abi.encode(
                        msg.sender,
                        tx.gasprice,
                        block.number,
                        block.timestamp,
                        blockhash(block.number - 1),
                        _numToFetch,
                        _idx
                    )
                )
            );

        uint256 randomIndex = randomNum % _numAvailableTokens;

        uint256 valAtIndex = _availableTokens[randomIndex];
        uint256 result;
        if (valAtIndex == 0) {
            // This means the index itself is still an available token
            result = randomIndex;
        } else {
            // This means the index itself is not an available token, but the val at that index is.
            result = valAtIndex;
        }

        uint256 lastIndex = _numAvailableTokens - 1;
        if (randomIndex != lastIndex) {
            // Replace the value at randomIndex, now that it's been used.
            // Replace it with the data from the last index in the array, since we are going to decrease the array size afterwards.
            uint256 lastValInArray = _availableTokens[lastIndex];
            if (lastValInArray == 0) {
                // This means the index itself is still an available token
                _availableTokens[randomIndex] = lastIndex;
            } else {
                // This means the index itself is not an available token, but the val at that index is.
                _availableTokens[randomIndex] = lastValInArray;
            }
        }

        _numAvailableTokens--;
        return result;
    }

    function _premint() internal {
        uint256[51] memory ids = [uint256(93), 169, 203, 215, 216, 254, 263, 293, 299, 385, 443, 405, 411, 434, 450, 463, 511, 512, 531, 549, 563, 575, 576, 610, 618, 628, 639, 642, 701, 755, 777, 875, 1021, 1087, 1459, 1552, 1611, 1716, 1802, 1860, 1895, 1921, 1994, 2010, 2028, 2053, 2072, 2122, 2139, 2177, 2187];

        for(uint i = 0; i < ids.length; i++) {
            uint256 randomIndex = ids[i];

            uint256 valAtIndex = _availableTokens[randomIndex];
            uint256 randomId;
            if (valAtIndex == 0) {
                // This means the index itself is still an available token
                randomId = randomIndex;
            } else {
                // This means the index itself is not an available token, but the val at that index is.
                randomId = valAtIndex;
            }

            uint256 lastIndex = _numAvailableTokens - 1;
            if (randomIndex != lastIndex) {
                // Replace the value at randomIndex, now that it's been used.
                // Replace it with the data from the last index in the array, since we are going to decrease the array size afterwards.
                uint256 lastValInArray = _availableTokens[lastIndex];
                if (lastValInArray == 0) {
                    // This means the index itself is still an available token
                    _availableTokens[randomIndex] = lastIndex;
                } else {
                    // This means the index itself is not an available token, but the val at that index is.
                    _availableTokens[randomIndex] = lastValInArray;
                }
            }

            _safeMint(walletA, randomId);
            super._setTokenURI(randomId, randomId.toString());

            totalMinted = totalMinted.add(1);
            _numAvailableTokens--;
        }
    }

    function _distributeFee(uint256 _count) internal {
        uint256 _whitelist_length = whitelist.length;
        if(curIndex > _whitelist_length) {
            _transferFee(devAddr, pricePerPanda.mul(_count));
            return;
        }

        uint256 count = _count;
        uint256 _startIndex = curIndex;
        for (uint256 i = _startIndex; i < _whitelist_length; i++) {
            if(count == 0) return;

            uint256 _remained = whitelist[i].count.sub(whitelist[i].paidCount);
            if(_remained > count) {
                _transferFee(whitelist[i].to, pricePerPanda.mul(count));

                whitelist[i].paidCount = whitelist[i].paidCount.add(count);
                return;
            } else {
                _transferFee(whitelist[i].to, pricePerPanda.mul(_remained));

                whitelist[i].paidCount = whitelist[i].paidCount.add(_remained);
                count = count.sub(_remained);

                curIndex = curIndex.add(1);
            }
        }

        if(count > 0) {
            _transferFee(devAddr, pricePerPanda.mul(count));
        }
    }

    function _transferFee(address _to, uint256 _amount) internal {
        if(feeToken == address(0x0)) {
            payable(_to).transfer(_amount);
        } else {
            require(IERC20(feeToken).transferFrom(msg.sender, _to, _amount), "DripPanda: failed to transfer tokens");
        }
    }

    function remainPunks() public view returns(uint256) {
        return _numAvailableTokens;
    }

    function price() public view returns(uint256) {
        return pricePerPanda;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721URIStorage) returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
    
    function _baseURI() internal view override returns (string memory) {
        return _tokenBaseURI;
    }

    /////////////////////////////////////////////////////////////
    //////////////////   Admin Functions ////////////////////////
    /////////////////////////////////////////////////////////////
   
    function setActive(bool isActive) external onlyOwner {
        _isActive = isActive;

        emit StatusUpdated(isActive);
    }

    function setTokenBaseURI(string memory _uri) external onlyOwner {
        _tokenBaseURI = _uri;

        emit BaseURIUpdated(_uri);
    }

    function setFeeToken(address _token) external onlyOwner {
        require(feeToken != _token, "DripPanda: already set");
        feeToken = _token;

        emit PaymentTokenUpdated(_token);
    }

    function setDevAddress(address _addr) external onlyOwner {
        require(_addr != address(0x0), "DripPanda: Invalid address");
        require(_addr != devAddr, "DripPanda: already set");
        devAddr = _addr;

        emit DevAddressUpdated(_addr);
    }

    function setWalletA(address _addr) external onlyOwner {
        require(_addr != address(0x0), "DripPanda: Invalid address");
        require(_addr != devAddr, "DripPanda: already set");

        walletA = _addr;
    }

    function setPricePerPanda(uint _price) external onlyOwner {
        pricePerPanda = _price;

        emit PriceUpdated(_price);
    }

    function setMaxCountPerClaim(uint _count) external onlyOwner {
        require(_count <= 500);
        maxCountPerClaim = _count;

        emit ClaimMaxCountUpdated(_count);
    }

    function setMaxCountPerWallet(uint _count) external onlyOwner {
        require(_count <= 500);
        maxCountPerWallet = _count;

        emit ClaimMaxCountPerWalletUpdated(_count);
    }

    receive() external payable {}
}