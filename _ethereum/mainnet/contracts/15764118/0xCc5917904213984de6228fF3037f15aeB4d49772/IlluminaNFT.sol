// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./ERC2981ContractWideRoyalties.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./IOperatorFilter.sol";
import "./BlackSquareNFT.sol";

contract IlluminaNFT is ERC721, Ownable, ERC2981ContractWideRoyalties, VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface COORDINATOR;
    using Counters for Counters.Counter;

    uint256 public s_requestId;
    uint256 private min;
    uint256 private max;
    uint256 private illuminaFactor;
    uint256 private editionEditCounter = 0;
    uint256 private randomIlluDate = 0;
    uint256 private illuminasSold = 0;
    uint256 public releaseCounter = 1;
    uint256 constant THRESHOLD = 25;
    uint256 constant ILLUMINA_BASE_SUPPLY = 20000;
    uint256 constant ILLUMINA_REGULAR_PRICE = 225;
    uint256 constant ILLUMINA_MIN_PRICE = 30;

    uint16 requestConfirmations = 3;
    uint32 numWords =  1;
    uint32 callbackGasLimit = 100000;
    uint64 s_subscriptionId;

    bytes32 keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;
    address vrfCoordinator = 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D;
    address private treasury;

    string private illuminaURI;
    string private baseURI;

    bool private mintable = true;
    bool public getRandomnessFromOracles;


    OBYToken obyToken;
    BlackSquareNFT blackSquare;
    IOperatorFilter operatorFilter;
    Counters.Counter private _tokenIds;

    mapping(uint256 => uint256) private _nextEditionIlluminationDate;
    mapping(uint256 => string) private _tokenURIs;
    mapping(address => bool) private _eligibles;
    mapping(uint256 => bool) private _burnedTokens;

    event MintToken(uint256 tokenId, address purchaser);
    event BatchMinted();

    constructor(address tokenAddress, address _blackSquareAddress, address _treasury, 
    uint256 _royaltyValue, uint64 _subscriptionId, string memory _illuminaBaseURI,
    uint256 _minTime, uint256 _maxTime, uint256 _illuminaFactor, bool _getRandomnessFromOracles, address _operatorFilter) VRFConsumerBaseV2(vrfCoordinator) ERC721("Illumina", "Ill") {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        obyToken = OBYToken(tokenAddress);
        blackSquare = BlackSquareNFT(_blackSquareAddress);
        operatorFilter = IOperatorFilter(_operatorFilter);
        treasury = _treasury;
        s_subscriptionId = _subscriptionId;
        baseURI = _illuminaBaseURI;
        min = _minTime;
        max = _maxTime;
        illuminaFactor = _illuminaFactor;
        getRandomnessFromOracles = _getRandomnessFromOracles;
        _setRoyalties(_treasury, _royaltyValue);
    }

     modifier onlyEligible() {
        require(owner() == _msgSender() || _eligibles[_msgSender()] == true, "IlluminaNFT: caller is not eligible");
        _;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setEligibles(address _eligible) public onlyOwner {
        _eligibles[_eligible] = true;
    }

    function setRandomnessFromOracles(bool _getRandomnessFromOracles) public onlyOwner {
        getRandomnessFromOracles = _getRandomnessFromOracles;
    }

    function setRoyalties(address recipient, uint256 value) external onlyOwner {
        _setRoyalties(recipient, value);
    }

    function setKeyHash(bytes32 _keyHash) external onlyOwner {
        keyHash = _keyHash;
    }

    function setMin(uint8 _min) external onlyOwner {
        min = _min;
    }

    function setMax(uint8 _max) external onlyOwner {
        max = _max;
    }

    function setSubscriptionId(uint64 _s_subscriptionId) external onlyOwner {
        s_subscriptionId = _s_subscriptionId;
    }

    function setMintable(bool _mintable) external onlyOwner {
        mintable = _mintable;
    }

    function setContractURI(string memory _contractURI) external onlyOwner {
        illuminaURI = _contractURI;
    }

    function setBaseURI(string memory _illuminaBaseURI) external onlyOwner {
        baseURI = _illuminaBaseURI;
    }

    function setTokenIpfsHash(uint256 tokenId, string memory ipfsHash) external onlyOwner {
        _tokenURIs[tokenId] = ipfsHash;
    }

    function getIlluminaMaxSupply () internal pure returns (uint256) {
        return ILLUMINA_BASE_SUPPLY;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function contractURI() public view returns (string memory) {
        return illuminaURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory illuminaBaseURI = _baseURI();
        string memory tokenURIHash = _tokenURIs[tokenId];
        return bytes(illuminaBaseURI).length > 0 ? string(abi.encodePacked(illuminaBaseURI, tokenURIHash)) : "";
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721) {
        if (
            from != address(0) &&
            to != address(0) &&
            !_mayTransfer(msg.sender, tokenId)
        ) {
            revert("ERC721OperatorFilter: illegal operator");
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _mayTransfer(address operator, uint256 tokenId)
        private
        view
        returns (bool)
    {
        IOperatorFilter filter = operatorFilter;
        if (address(filter) == address(0)) return true;
        if (operator == ownerOf(tokenId)) return true;
        return filter.mayTransfer(msg.sender);
    }

    function _requestRandomWords() internal  {
    s_requestId = COORDINATOR.requestRandomWords(
        keyHash,
        s_subscriptionId,
        requestConfirmations,
        callbackGasLimit,
        numWords
        );
    }

    function fulfillRandomWords(
        uint256,
        uint256[] memory randomWords
    ) internal override {
        require(randomWords.length > 0, 'OracleContract: No Number delivered');
        uint256 illuminationDate = randomWords[0] % (max - min + 1) + min;

        _nextEditionIlluminationDate[editionEditCounter] = illuminationDate;

        randomIlluDate = illuminationDate;
    }

    function getTokensHeldByUser(address user) public view returns (uint256[] memory) {
        uint256 balance = balanceOf(user);
        uint256[] memory emptyTokens = new uint256[](0);
        uint256[] memory tokenIds = new uint256[](balance);
        uint256 j = 0;
        for (uint256 i = 1; i <= _tokenIds.current(); i++ ) {
            if (!_burnedTokens[i]) {
                address tokenOwner = ownerOf(i);

                if (tokenOwner == user) {
                    tokenIds[j] = i;
                    j++;
                }
            }
        }
        if (tokenIds.length > 0) {
            return tokenIds;
        }  else {
            return emptyTokens;
        }
    }

    function buyTokenForOBY(string memory ipfsHash, uint256 tokenId) public {
        require(mintable == true, 'No tokens can be minted at the moment');

        require(_tokenIds.current() <= getIlluminaMaxSupply(), 'Max Amount of Illuminas minted');

        require(tokenId == getNextTokenId(), 'Trying to mint Token with incorrect Metadata');

        require(blackSquare.getAvailableIlluminaCount() > _tokenIds.current(), 'IlluminaNFT, max mintable number reached');

        (uint256 pricePerToken, ,) = getIlluminaPrice();

        bool ok1 = obyToken.checkBalances(pricePerToken, _msgSender());
        require(ok1, 'IlluminaNFT, insufficient balances');

        _tokenIds.increment();

        require(!_exists(_tokenIds.current()), "IlluminaNFT: Token already exists");

        _mint(_msgSender(), _tokenIds.current());

        emit MintToken(_tokenIds.current(), _msgSender());

        _tokenURIs[_tokenIds.current()] = ipfsHash;

        illuminasSold++;

        obyToken.burnToken(pricePerToken, _msgSender());

        if (_tokenIds.current() == THRESHOLD || (_tokenIds.current() > THRESHOLD && _tokenIds.current() % THRESHOLD == 0)) {
            editionEditCounter++;

            if (getRandomnessFromOracles == true) {
                _requestRandomWords();
            } else {
                uint256 illuminationDate = uint256(keccak256("wow")) % (max - min + 1) + min;
                _nextEditionIlluminationDate[editionEditCounter] = illuminationDate;

                randomIlluDate = illuminationDate;
            }
        }
    }

    function checkForEditableEditions () view external returns (uint256, uint256) {
        uint256 editionId = blackSquare.getFirstEditionToSetIlluminationDate();

        require(editionId != 0, 'No Edition Found to be edited!');

        uint256 illuDate = 0;
        uint256 index;

        for (uint256 i = 0; i <= editionEditCounter; i++) {
            if (_nextEditionIlluminationDate[i] > 0) {
                illuDate = _nextEditionIlluminationDate[i];
                index = i;
                break;
            }
        }

        return (illuDate, index);
    }


    function handleEditEdition (uint256 _illuDate, uint256 _index) external onlyOwner {

        uint256 editionId = blackSquare.getFirstEditionToSetIlluminationDate();

        if (_illuDate > 0) {
            uint256 newIlluminationDate = block.timestamp + _illuDate;
            blackSquare.editEdition(editionId, newIlluminationDate);

            releaseCounter ++;

            delete _nextEditionIlluminationDate[_index];

            randomIlluDate = 0;
        }
    }

    function getRandomNumberFromContract() external view returns (uint256) {
        return randomIlluDate;
    }

    function getIlluminaPrice() public view returns (uint256, uint256, uint256) {
        uint256 availableIllumina = blackSquare.getAvailableIlluminaCount();

        uint256 vacantIllumina = availableIllumina - illuminasSold;

        if (ILLUMINA_REGULAR_PRICE > (vacantIllumina / illuminaFactor)) {
            uint256 residualPrice = ILLUMINA_REGULAR_PRICE - ( vacantIllumina / illuminaFactor );

            if (residualPrice > ILLUMINA_MIN_PRICE) {
                return (residualPrice, availableIllumina, vacantIllumina);
            }
        }

        return (ILLUMINA_MIN_PRICE, availableIllumina, vacantIllumina);
    }

    function getNextTokenId() public view returns (uint256) {
        if (blackSquare.getAvailableIlluminaCount() == 0) {
            return 0;
        } else {
            return _tokenIds.current() + 1;
        }
    }

    function burnIllumina(address user, uint256 _burnThreshold) public onlyEligible {
        uint256[] memory tokenIds = getTokensHeldByUser(user);

        for (uint256 i = 0; i < tokenIds.length; i++ ) {
            if (i < _burnThreshold) {
                uint256 tokenId = tokenIds[i];

                super._burn(tokenId);

                _burnedTokens[tokenId] = true;
            }
        }
    }
}