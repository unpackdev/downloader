// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "./LinkTokenInterface.sol";
import "./VRFConsumerBase.sol";

import "./Ownable.sol";
import "./ERC721.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";

import "./UselessLibrary.sol";


contract UselessNFT is ERC721, Ownable, ReentrancyGuard, VRFConsumerBase {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;
    using UselessLibrary for *;

    event Withdrawal(address indexed receiver, uint amount);
    event URIOverridesRatePerDayChanged(uint ratePerDay);
    event BaseURIChanged(string newURI);
    event URIOverride(UselessLibrary.Tier tier, uint lockedUntilTimestamp, string newURI);
    event URIRevert(UselessLibrary.Tier tier);

    uint256 public constant LINK_FEE = 2 ether;

    bool public isSaleOpen;
    uint16 public maxSupply;
    uint256 public mintPrice;
    address public ogDeveloper;
    address public ogArtist;
    address public council;
    uint256 public uriOverridesPricePerDay;
    bytes32 public vrfKeyHash;
    uint256 public randomNumber;

    mapping(UselessLibrary.Tier => string) public uriOverrides;
    mapping(UselessLibrary.Tier => uint) public uriOverridesLockedUntil;

    Counters.Counter private _tokenIds;

    constructor(
        string memory _baseURI,
        address _ogDeveloper,
        address _ogArtist,
        uint256 _maxSupply,
        uint256 _uriOverridesPricePerDay,
        uint256 _mintPrice,
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _vrfKeyHash
    )
    public
    VRFConsumerBase(_vrfCoordinator, _linkToken)
    ERC721("Useless NFT", "USELESS") {
        require(_maxSupply <= 10000, "How many useless NFTs do you need?");
        require(_mintPrice > 0, "Wow, I guess you wanted to make them worthless AND useless");
        _setBaseURI(_baseURI);
        ogDeveloper = _ogDeveloper;
        ogArtist = _ogArtist;
        maxSupply = uint16(_maxSupply);
        _setURIOverridesPricePerDay(_uriOverridesPricePerDay);
        mintPrice = _mintPrice;
        vrfKeyHash = _vrfKeyHash;
        isSaleOpen = true;
    }

    modifier requireIsInitialized(uint _tokenId) {
        require(
            randomNumber != 0,
            "Reveal has not occurred yet"
        );
        require(
            ownerOf(_tokenId) == msg.sender,
            "You are not the owner of this useless NFT"
        );
        _;
    }

    modifier requireIsUnlockedAndValid(uint256 _tokenId, UselessLibrary.Tier _tier) {
        require(
            uint8(getTier(_tokenId)) < uint8(_tier),
            "You must be higher up the pyramid to override this tier"
        );
        require(
            !isURILocked(_tier),
            "URI for this tier is still locked"
        );
        _;
    }

    receive() external payable {
        revert("Do not blindly send ETH to this contract. We told you it's not audited!");
    }

    function setCouncil(address _council) public {
        require(council == address(0), "council already set");
        council = _council;
    }

    function setURIOverridesPricePerDay(uint _uriOverridesPricePerDay) external {
        require(msg.sender == council, "Only the council of elders can set the tax rate");
        _setURIOverridesPricePerDay(_uriOverridesPricePerDay);
    }

    function _setURIOverridesPricePerDay(uint _uriOverridesPricePerDay) internal {
        require(_uriOverridesPricePerDay > 0, "I know these NFTs are useless, but come on, have some respect!");
        uriOverridesPricePerDay = _uriOverridesPricePerDay;
        emit URIOverridesRatePerDayChanged(_uriOverridesPricePerDay);
    }

    function requestRandomNumber() public returns (bytes32 requestId) {
        require(!isSaleOpen, "Sale must be over");
        require(LINK.balanceOf(address(this)) >= LINK_FEE, "Not enough LINK - fill contract first");
        return _callRequestRandomness();
    }

    function _callRequestRandomness() internal virtual returns (bytes32 requestId) {
        // function is made to be overrode in TestUselessNFT for increased test coverage
        return requestRandomness(vrfKeyHash, LINK_FEE);
    }

    function fulfillRandomness(bytes32, uint256 _randomNumber) internal override {
        randomNumber = _randomNumber;
    }

    function withdrawETH() public nonReentrant {
        _withdraw(ogArtist, address(this).balance / 2);
        // send remaining balance; this helps deal with any truncation errors
        _withdraw(ogDeveloper, address(this).balance);
    }

    function rescueTokens(address[] calldata tokens) public nonReentrant {
        // users were useless enough to send tokens to the contract?
        bool _isSaleOpen = isSaleOpen;
        uint _randomNumber = randomNumber;
        for (uint i = 0; i < tokens.length; i++) {
            if (_isSaleOpen || _randomNumber == 0) {
                IERC20(tokens[i]).safeTransfer(ogDeveloper, IERC20(tokens[i]).balanceOf(address(this)));
            } else {
                IERC20(tokens[i]).safeTransfer(council, IERC20(tokens[i]).balanceOf(address(this)));
            }
        }
    }

    function _withdraw(address _receiver, uint256 _amount) internal {
        (bool success,) = _receiver.call{value : _amount}("");
        require(success, "_withdraw failed");
        emit Withdrawal(_receiver, _amount);
    }

    function mint(uint quantity) public payable nonReentrant {
        require(quantity > 0 && quantity <= 5, "quantity must be > 0 and <= 5");
        require(msg.value == mintPrice * quantity, "invalid ETH amount sent");
        require(isSaleOpen, "The sale is over. Wait, the sale is over!? Wow, this really happened?");
        require(totalSupply() + quantity <= maxSupply, "Can only mint up to the totalSupply amount");

        address _msgSender = msg.sender;
        uint tokenIds = _tokenIds.current();
        for (uint i = 0; i < quantity; ++i) {
            _safeMint(_msgSender, tokenIds);
            ++tokenIds;
        }
        _tokenIds._value = tokenIds;

        isSaleOpen = totalSupply() != maxSupply;
    }

    function setBaseURI(string calldata _baseURI) public onlyOwner {
        _setBaseURI(_baseURI);
        emit BaseURIChanged(_baseURI);
    }

    function owner() public override view returns (address) {
        if (isSaleOpen || randomNumber == 0) {
            return super.owner();
        } else {
            return ownerOf(getPlatinumTokenId());
        }
    }

    function getTier(uint256 _id) public view returns (UselessLibrary.Tier) {
        if (randomNumber == 0 || _id >= maxSupply) {
            // random number is not set yet
            return UselessLibrary.Tier.TIER_UNKNOWN;
        }

        uint result = _wrapIdIfNecessary((randomNumber % maxSupply) + _id);
        if (result == 0) {
            return UselessLibrary.Tier.TIER_ZERO;
        } else if (result >= 3000 && result < 3010) {
            return UselessLibrary.Tier.TIER_ONE;
        } else if (result >= 6000 && result < 6100) {
            return UselessLibrary.Tier.TIER_TWO;
        } else if (result >= 9000 && result < 10000) {
            return UselessLibrary.Tier.TIER_THREE;
        } else {
            return UselessLibrary.Tier.TIER_FOUR;
        }
    }

    function getCouncilIds() public view returns (uint[] memory) {
        if (isSaleOpen || randomNumber == 0) {
            // sale is not over yet and traits have not been assigned
            return new uint[](0);
        }

        uint platinumTokenId = getPlatinumTokenId();
        uint goldTokenStartId = _wrapIdIfNecessary(platinumTokenId + 3000);

        uint[] memory result = new uint[](11);
        result[0] = platinumTokenId;
        result[1] = _wrapIdIfNecessary(goldTokenStartId + 0);
        result[2] = _wrapIdIfNecessary(goldTokenStartId + 1);
        result[3] = _wrapIdIfNecessary(goldTokenStartId + 2);
        result[4] = _wrapIdIfNecessary(goldTokenStartId + 3);
        result[5] = _wrapIdIfNecessary(goldTokenStartId + 4);
        result[6] = _wrapIdIfNecessary(goldTokenStartId + 5);
        result[7] = _wrapIdIfNecessary(goldTokenStartId + 6);
        result[8] = _wrapIdIfNecessary(goldTokenStartId + 7);
        result[9] = _wrapIdIfNecessary(goldTokenStartId + 8);
        result[10] = _wrapIdIfNecessary(goldTokenStartId + 9);
        return result;
    }

    function getPlatinumTokenId() public view returns (uint) {
        if (randomNumber == 0) {
            return uint(-1);
        }

        return randomNumber % maxSupply == 0 ? 0 : maxSupply - (randomNumber % maxSupply);
    }

    function _wrapIdIfNecessary(uint _tokenId) internal view returns (uint) {
        uint16 _maxSupply = maxSupply;
        if (_tokenId >= _maxSupply) {
            return _tokenId - _maxSupply;
        } else {
            return _tokenId;
        }
    }

    function overridePeasantURI(
        uint _tokenId,
        UselessLibrary.Tier _tierToOverride,
        string calldata _newURI
    )
    external
    payable
    requireIsInitialized(_tokenId)
    requireIsUnlockedAndValid(_tokenId, _tierToOverride)
    nonReentrant {
        require(
            bytes(_newURI).length > 0,
            "invalid new URI"
        );

        uint leftOverTax = msg.value % uriOverridesPricePerDay;
        if (leftOverTax > 0) {
            _withdraw(msg.sender, leftOverTax);
        }

        uint taxPaid = msg.value - leftOverTax;
        if (taxPaid > 0) {
            _withdraw(council, taxPaid);
        }

        uint daysToLock = taxPaid / uriOverridesPricePerDay;
        uriOverrides[_tierToOverride] = _newURI;
        uriOverridesLockedUntil[_tierToOverride] = block.timestamp + (daysToLock * 1 days);
        emit URIOverride(_tierToOverride, block.timestamp + (daysToLock * 1 days), _newURI);
    }

    function isURILocked(UselessLibrary.Tier _tierToOverride) public view returns (bool) {
        return block.timestamp <= uriOverridesLockedUntil[_tierToOverride];
    }

    function revertPeasantURI(
        uint _tokenId,
        UselessLibrary.Tier _tierToRevert
    )
    external
    requireIsInitialized(_tokenId)
    requireIsUnlockedAndValid(_tokenId, _tierToRevert)
    {
        uriOverrides[_tierToRevert] = "";
        emit URIRevert(_tierToRevert);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        if (randomNumber == 0) {
            return string(abi.encodePacked(baseURI(), _tokenId.toString(), "_x.json"));
        } else {
            UselessLibrary.Tier tier = getTier(_tokenId);
            if (tier == UselessLibrary.Tier.TIER_ZERO) {
                return string(abi.encodePacked(baseURIOrOverride(tier), _tokenId.toString(), "_0.json"));
            } else if (tier == UselessLibrary.Tier.TIER_ONE) {
                return string(abi.encodePacked(baseURIOrOverride(tier), _tokenId.toString(), "_1.json"));
            } else if (tier == UselessLibrary.Tier.TIER_TWO) {
                return string(abi.encodePacked(baseURIOrOverride(tier), _tokenId.toString(), "_2.json"));
            } else if (tier == UselessLibrary.Tier.TIER_THREE) {
                return string(abi.encodePacked(baseURIOrOverride(tier), _tokenId.toString(), "_3.json"));
            } else {
                assert(tier == UselessLibrary.Tier.TIER_FOUR);
                return string(abi.encodePacked(baseURIOrOverride(tier), _tokenId.toString(), "_4.json"));
            }
        }
    }

    function baseURIOrOverride(UselessLibrary.Tier tier) public view returns (string memory) {
        string memory uriOverride = uriOverrides[tier];
        if (bytes(uriOverride).length == 0 && keccak256(bytes(uriOverride)) == keccak256(bytes(""))) {
            return baseURI();
        } else {
            return uriOverride;
        }
    }
}
