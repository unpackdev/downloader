//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Strings.sol";

import "./IRandomNumberConsumer.sol";
import "./IERC2981.sol";

interface ITokenPRO {
    function balanceOf(address _owner) external returns(uint256 balance);
    function transferFrom(address _from, address _to, uint256 _value) external returns(bool success);
    function transfer(address _to, uint256 _value) external returns(bool success);
    function allowance(address _owner, address _spender) external returns(uint256 remaining);
}

contract Metashredders is ERC721, Ownable {
    using Strings for uint256;

    // Events
    event Buy(address buyer, uint256 amount);
    event RequestedVRF(bool isRequested, bytes32 randomNumberRequestId);
    event CommittedVRF(bytes32 randomNumberRequestId, uint256 vrfResult);

    // Controlled variables
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint256 public price;
    bool public isRandomnessRequested;
    bytes32 public randomNumberRequestId;
    uint256 public vrfResult;

    // Config variables
    string public preRevealURI;
    string public baseURI;
    uint256 public supplyLimit;
    uint256 public mintingStartTimeUnix;
    uint256 public singleOrderLimit;
    address public vrfProvider;
    address public payoutAddress;
    address public royaltyReceiver;
    uint16 public royaltyBasisPoints;
    ITokenPRO public paymentTokenPRO;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _preRevealURI,
        string memory _baseURI,
        uint256 _supplyLimit,
        uint256 _mintingStartTimeUnix,
        uint256 _singleOrderLimit,
        address _vrfProvider,
        address _payoutAddress,
        uint256 _price,
        address _paymentTokenPRO
    ) ERC721(_tokenName, _tokenSymbol) {
        preRevealURI = _preRevealURI;
        baseURI = _baseURI;
        supplyLimit = _supplyLimit;
        mintingStartTimeUnix = _mintingStartTimeUnix;
        singleOrderLimit = _singleOrderLimit;
        vrfProvider = _vrfProvider;
        payoutAddress = _payoutAddress;
        price = _price;
        paymentTokenPRO = ITokenPRO(_paymentTokenPRO);
    }

    // We signify support for ERC2981, ERC721 & ERC721Metadata
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function mint(address _recipient, uint96 _quantity) external {
        require(isRandomnessRequested == false, "MINTING_OVER");
        require(_quantity > 0, "NO_ZERO_QUANTITY");
        require(block.timestamp >= mintingStartTimeUnix, "MINTING_PERIOD_NOT_STARTED");
        require(_quantity <= singleOrderLimit, "EXCEEDS_SINGLE_ORDER_LIMIT");
        require((_tokenIds.current() + _quantity) <= supplyLimit, "EXCEEDS_MAX_SUPPLY");
        uint256 paymentValue = (price * _quantity);
        bool success = paymentTokenPRO.transferFrom(msg.sender, address(this), paymentValue);
        require(success, "PAYMENT_FAILED");

        _handleMint(_recipient, _quantity);
        emit Buy(msg.sender, _quantity);
    }

    function _handleMint(address _recipient, uint96 _quantity) internal {
        for(uint96 i = 0; i < _quantity; i++) {
            _tokenIds.increment();
            uint256 newTokenId = _tokenIds.current();
            _mint(_recipient, newTokenId);
        }
    }

    function initiateRandomDistribution() external {
        require(_tokenIds.current() == supplyLimit, "MINTING_ONGOING");
        require(isRandomnessRequested == false, "RANDOMNESS_REQ_NOT_INITIATED");
        IRandomNumberConsumer randomNumberConsumer = IRandomNumberConsumer(vrfProvider);
        randomNumberRequestId = randomNumberConsumer.getRandomNumber();
        isRandomnessRequested = true;
        emit RequestedVRF(true, randomNumberRequestId);
    }

    function forceInitiateRandomDistribution() external onlyOwner {
        // Forces ending of minting period by skipping check for all tokens being minted
        uint256 supply = _tokenIds.current();
        require(supply > 0);
        require(isRandomnessRequested == false);
        IRandomNumberConsumer randomNumberConsumer = IRandomNumberConsumer(vrfProvider);
        randomNumberRequestId = randomNumberConsumer.getRandomNumber();
        isRandomnessRequested = true;
        emit RequestedVRF(true, randomNumberRequestId);
    }

    function commitRandomDistribution() external onlyOwner {
        require(isRandomnessRequested == true, "RANDOMNESS_REQ_NOT_INITIATED");
        IRandomNumberConsumer randomNumberConsumer = IRandomNumberConsumer(vrfProvider);
        uint256 result = randomNumberConsumer.readFulfilledRandomness(randomNumberRequestId);
        require(result > 0, "RANDOMNESS_NOT_FULFILLED");
        vrfResult = result;
        emit CommittedVRF(randomNumberRequestId, result);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "NONEXISTENT_TOKEN");

        if (vrfResult == 0) {
            return preRevealURI;
        }

        string memory tokenURI_ = metadataOf(tokenId);
        
        return string(abi.encodePacked(baseURI, tokenURI_, ".json"));
    }

    function metadataOf(uint256 _tokenId) public view returns (string memory) {
        require((_tokenId > 0) && (_tokenId <= totalSupply()), "INVALID_TOKEN_ID");

        uint256 seed_ = vrfResult;
        if (seed_ == 0) {
            return "";
        }

        uint256[] memory randomIds = new uint256[](supplyLimit);
        for (uint256 i = 0; i < supplyLimit; i++) {
            randomIds[i] = 1000 - i;
        }

        for (uint256 i = 0; i < supplyLimit - 1; i++) {
            uint256 j = i + (uint256(keccak256(abi.encode(seed_, i))) % (supplyLimit - i));
            (randomIds[i], randomIds[j]) = (randomIds[j], randomIds[i]);
        }

        return randomIds[_tokenId - 1].toString();
    }

    function totalSupply() public view returns(uint256) {
        return _tokenIds.current();
    }

    function updateVrfProvider(
      address _vrfProvider
    ) public onlyOwner {
        vrfProvider = _vrfProvider;
    }

    // Fee distribution logic below

    function getPercentageOf(
        uint256 _amount,
        uint16 _basisPoints
    ) internal pure returns (uint256 value) {
        value = (_amount * _basisPoints) / 10000;
    }

    function distributeFees() public onlyOwner {
        uint256 currentBalance = paymentTokenPRO.balanceOf(address(this));
        require(currentBalance > 0, "NO_FEES_TO_DISTRIBUTE");
        bool success = paymentTokenPRO.transfer(payoutAddress, currentBalance);
        require(success, "PAYMENT_FAILED");
    }

    function recoverETH() public onlyOwner {
        uint256 balance = address(this).balance;
        address recoveryAddress = owner();
        (bool recoveryDeliverySuccess, ) = recoveryAddress.call{value: balance}("");
        require(recoveryDeliverySuccess, "RECOVER_ETH_NO_DELIVERY");
    }
    
    function updateFeePayoutScheme(
      address _payoutAddress,
      uint256 _price
    ) public onlyOwner {
        payoutAddress = _payoutAddress;
        price = _price;
    }

    // ERC2981 logic

    function updateRoyaltyInfo(address _royaltyReceiver, uint16 _royaltyBasisPoints) external onlyOwner {
        royaltyReceiver = _royaltyReceiver;
        royaltyBasisPoints = _royaltyBasisPoints;
    }

    // Takes a _tokenId and _price (in wei) and returns the royalty receiver's address and how much of a royalty the royalty receiver is owed
    function royaltyInfo(uint256 _tokenId, uint256 _price) external view returns (address receiver, uint256 royaltyAmount) {
        receiver = royaltyReceiver;
        royaltyAmount = getPercentageOf(_price, royaltyBasisPoints);
    }

}
