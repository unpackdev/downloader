pragma solidity ^0.8.9;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./IERC721.sol";
import "./ECDSA.sol";
import "./PaymentSplitter.sol";
import "./PudgySerumsInterface.sol";
import "./FridgeInterface.sol";

contract MutantPudgyFridgeClub is ERC721Enumerable, Ownable, ReentrancyGuard, Pausable, PaymentSplitter {
    using Counters for Counters.Counter;
    using ECDSA for bytes32;
    using SafeMath for uint256;

    uint256[] private _shares = [10,20,70];
    address[] private _shareholders = [
        0x81Bf2Bc8119695ed2A196556e4182DaF49872163,
        0x3461895e441a1D368E04525276B96Aeb87431fe9,
        0x3584fE4F1e719FD0cC0F814a4A675181438B45DD
    ];

    uint constant public M2_OFFSET = 3333;
    uint constant public M3_OFFSET = 6667;
    uint constant public SALE_OFFSET = 6672;

    uint256 public maxSupplyPublic = 3333;
    uint256 public mintPriceMainsale = 0.025 ether;
    uint256 public mintPricePresale = 0.015 ether;
    uint256 public reservedMutants = 200;
    uint256 public maxTX = 100;

    string public baseTokenURI;
    address public PAFC;
    address public PS;
    address public Fridge;

    Counters.Counter private _m3Id;
    Counters.Counter private _publicSale;

    uint public mutationActive = 1650474000;
    uint public mainsaleActive = 1650486000;
    uint public presaleActive = 1650481200;

    address private _signer;

    mapping(uint => bool) public mutatedWithM3;

    constructor(address _pafc, address _ps, string memory _baseTokenURI) ERC721("Mutant Pudgy Fridge Club", "MPFC") PaymentSplitter(_shareholders, _shares) {
        baseTokenURI = _baseTokenURI;
        PAFC = _pafc;
        PS = _ps;
    }

    modifier isSecure(uint _amount) {
        require(_amount <= maxTX, "MPFC: You can't buy more than 100 pudgies at once!");
        require(msg.sender == tx.origin, "MPFC: Must use EOA");
        require(maxSupplyPublic.sub(reservedMutants) >= _publicSale.current().add(_amount), "MPFC: Minting would exceed max supply!");
        _;
    }

    function _mintMultiple(uint _amount) private {
        for(uint i = 0; i < _amount; i++) {
            uint id = SALE_OFFSET + _publicSale.current();
            _publicSale.increment();
            _safeMint(msg.sender, id);
        }
    }

    function isWhitelisted(bytes memory _signature) public view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(msg.sender));
        bytes32 messageHash = hash.toEthSignedMessageHash();
        return messageHash.recover(_signature) == _signer;
    }

    function buyMutant(uint _amount) external payable isSecure(_amount) whenNotPaused {
        require(block.timestamp >= mainsaleActive, "MPFC: Mainsale didn't start yet!");
        require(msg.value >= mintPriceMainsale.mul(_amount), "MPFC: You don't have enough ETH to mint your Mutant Pudgies!");
        _mintMultiple(_amount);
    }

    function presaleMint(uint _amount, bytes memory _signature) external payable isSecure(_amount) whenNotPaused {
        require(block.timestamp >= presaleActive, "MPFC: Presale didn't start yet!");
        require(isWhitelisted(_signature), "MPFC: You aren't whitelisted!");
        require(msg.value >= mintPricePresale.mul(_amount), "MPFC: You don't have enough ETH to mint your Mutant Pudgies!");
        _mintMultiple(_amount);
    }

    function giveAwayMint(uint _amount, address _to) external onlyOwner {
        for(uint i = 0; i < _amount; i++) {
            uint id = SALE_OFFSET + _publicSale.current();
            _publicSale.increment();
            _safeMint(_to, id);
        }
    }

    function mutate(uint _id, uint _serumType) external nonReentrant whenNotPaused {
        require(block.timestamp >= mutationActive, "MPFC: Mutation didn't start yet!");
        require(IERC721(PAFC).ownerOf(_id) == msg.sender, "MPFC: You don't own the pudgy you are trying to mutate!");
        require(PudgySerumsInterface(PS).balanceOf(msg.sender, _serumType) >= 1, "MPFC: You don't have any serums of this type!");
        require(!hasBeenMutatedWith(_id, _serumType), "MPFC: You already have mutated this pudgy with this serum type!");
        uint id;
        if(_serumType == 3) {
            id = M3_OFFSET + _m3Id.current();
            mutatedWithM3[_id] = true;
            _m3Id.increment();
        } else {
            id = getTokenId(_id, _serumType);
        }
        PudgySerumsInterface(PS).consumeSerum(_serumType, msg.sender);
        _safeMint(msg.sender, id);
    }

    function getTokenId(uint _id, uint _serumType) public pure returns (uint) {
        require(_serumType != 3, "MPFC: Can't calculate M3 ids!");
        if(_serumType == 2) {
            return M2_OFFSET + _id;
        } else {
            return _id;
        }
    }

    function hasBeenMutatedWith(uint _id, uint _serumType) public view returns (bool) {
        if(_serumType == 3) {
            return mutatedWithM3[_id];
        } else {
            return _exists(getTokenId(_id, _serumType));
        }
    }

    function getSoldAmount() public view returns (uint) {
        return _publicSale.current();
    }

    function setMutationStartTime(uint _startTime) external onlyOwner {
        mutationActive = _startTime;
    }

    function setMainsaleStartTime(uint _startTime) external onlyOwner {
        mainsaleActive = _startTime;
    }

    function setPresaleStartTime(uint _startTime) external onlyOwner {
        presaleActive = _startTime;
    }

    function setPublicMaxSupply(uint _maxSupply) external onlyOwner {
        maxSupplyPublic = _maxSupply;
    }

    function setMintPriceMainsale(uint _mintPrice) external onlyOwner {
        mintPriceMainsale = _mintPrice;
    }

    function setMintPricePresale(uint _mintPrice) external onlyOwner {
        mintPricePresale = _mintPrice;
    }

    function setReservedMutants(uint _reserved) external onlyOwner {
        reservedMutants = _reserved;
    }

    function setMaxTx(uint _maxTX) external onlyOwner {
        maxTX = _maxTX;
    }

    function setFridge(address _fridge) external onlyOwner {
        Fridge = _fridge;
    }

    function setPS(address _ps) external onlyOwner {
        PS = _ps;
    }

    function setPAFC(address _pafc) external onlyOwner {
        PAFC = _pafc;
    }

    function setTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setSigner(address newSigner) external onlyOwner {
        _signer = newSigner;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdrawAll() external onlyOwner {
        for (uint256 sh = 0; sh < _shareholders.length; sh++) {
            address payable wallet = payable(_shareholders[sh]);
            release(wallet);
        }
    }
}
