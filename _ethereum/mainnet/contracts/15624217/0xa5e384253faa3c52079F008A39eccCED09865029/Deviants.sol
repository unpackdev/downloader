// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./ERC721A.sol";
import "./ERC2981.sol";
import "./IERC721.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./DeviantGeneGenerator.sol";

contract Deviants is ERC721A, ERC2981, Ownable, ReentrancyGuard {
    struct Params {
        string name;
        string symbol;
        string _baseURI;
        uint256 _maxTotalSupply;
        uint256 _bulkBuyLimit;
        uint256 _publicPrice;
        uint256 _discountPrice;
        address payable _daoAddress;
        address _polymorphsV1Contract;
        address _polymorphsV2Contract;
        address _facesContract;
        address _lobstersContract;
        uint96 _royaltyFee;
    }

    using DeviantGeneGenerator for DeviantGeneGenerator.Gene;

    DeviantGeneGenerator.Gene internal geneGenerator;

    address public daoAddress;

    string public baseURI;

    uint256 public maxTotalSupply;
    uint256 public bulkBuyLimit;
    uint256 public publicPrice;
    uint256 public discountPrice;

    IERC721 public immutable polymorphsV1Contract;
    IERC721 public immutable polymorphsV2Contract;
    IERC721 public immutable facesContract;
    IERC721 public immutable lobstersContract;

    mapping(uint256 => uint256) private _genes;

    mapping(address => uint256) public discountsUsed;

    event RoyaltiesChanged(address newReceiver, uint96 value);
    event TokenMinted(
        uint256 id,
        address indexed to,
        bool indexed usedDiscount
    );
    event MaxSupplyChanged(uint256 newMaxSupply);

    constructor(Params memory params) ERC721A(params.name, params.symbol) {
        baseURI = params._baseURI;
        daoAddress = params._daoAddress;
        maxTotalSupply = params._maxTotalSupply;
        bulkBuyLimit = params._bulkBuyLimit;
        publicPrice = params._publicPrice;
        discountPrice = params._discountPrice;
        polymorphsV1Contract = IERC721(params._polymorphsV1Contract);
        polymorphsV2Contract = IERC721(params._polymorphsV2Contract);
        facesContract = IERC721(params._facesContract);
        lobstersContract = IERC721(params._lobstersContract);
        _setDefaultRoyalty(params._daoAddress, params._royaltyFee);
    }

    modifier onlyDAO() {
        require(msg.sender == daoAddress, "Not Called by DAO");
        _;
    }

    function mint(uint256 _amount) public payable nonReentrant {
        require(
            (totalSupply() + _amount) <= maxTotalSupply,
            "Total supply would exceed maxTotalSupply"
        );
        require(_amount <= bulkBuyLimit, "Amount exceeds bulk Buy Limit");
        uint256 totalCost = _amount * publicPrice;
        require(msg.value >= totalCost, "Not enough ETH");

        _safeMint(msg.sender, _amount);

        uint256 lastId = lastTokenId();

        while (_amount > 0) {
            _genes[lastId] = geneGenerator.random();
            emit TokenMinted(lastId, msg.sender, false);
            lastId--;
            _amount--;
        }

        (bool transferToDaoStatus, ) = daoAddress.call{value: totalCost}("");
        require(
            transferToDaoStatus,
            "Address: unable to send value, recipient may have reverted"
        );

        uint256 excessAmount = msg.value - totalCost;
        if (excessAmount > 0) {
            (bool returnExcessStatus, ) = _msgSender().call{
                value: excessAmount
            }("");
            require(returnExcessStatus, "Failed to return excess.");
        }
    }

    function discountMint(uint256 _amount) public payable nonReentrant {
        require(
            (totalSupply() + _amount) <= maxTotalSupply,
            "Total supply would exceed maxTotalSupply"
        );
        require(_amount <= bulkBuyLimit, "Amount exceeds bulk Buy Limit");
        uint256 v1Count = polymorphsV1Contract.balanceOf(msg.sender);
        uint256 v2Count = polymorphsV2Contract.balanceOf(msg.sender);
        uint256 facesCount = facesContract.balanceOf(msg.sender);
        uint256 lobstersCount = lobstersContract.balanceOf(msg.sender);
        uint256 totalTokens = v1Count + v2Count + facesCount + lobstersCount;
        require(
            discountsUsed[msg.sender] + _amount <= totalTokens,
            "No discounts allowed"
        );

        uint256 totalCost = _amount * discountPrice;

        require(msg.value >= totalCost, "Not enough ETH sent");

        _safeMint(msg.sender, _amount);

        discountsUsed[msg.sender] += _amount;

        uint256 lastId = lastTokenId();

        while (_amount > 0) {
            _genes[lastId] = geneGenerator.random();
            emit TokenMinted(lastId, msg.sender, true);
            lastId--;
            _amount--;
        }

        (bool transferToDaoStatus, ) = daoAddress.call{value: totalCost}("");
        require(
            transferToDaoStatus,
            "Address: unable to send value, recipient may have reverted"
        );

        uint256 excessAmount = msg.value - totalCost;
        if (excessAmount > 0) {
            (bool returnExcessStatus, ) = _msgSender().call{
                value: excessAmount
            }("");
            require(returnExcessStatus, "Failed to return excess.");
        }
    }

    function daoMint(uint256 _amount) public onlyDAO {
        require((totalSupply() + _amount) <= maxTotalSupply, "Soldout");
        _safeMint(msg.sender, _amount);
        emit TokenMinted(_amount, msg.sender, false);
    }

    function lastTokenId() public view returns (uint256) {
        return _nextTokenId() - 1;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    function setRoyalties(address _recipient, uint96 _value) external onlyDAO {
        _setDefaultRoyalty(_recipient, _value);

        emit RoyaltiesChanged(_recipient, _value);
    }

    function setMintPrice(uint256 _newPrice) public onlyDAO {
        publicPrice = _newPrice;
    }

    function setDiscountPrice(uint256 _newPrice) public onlyDAO {
        discountPrice = _newPrice;
    }

    function setBulkBuyLimit(uint256 _newLimit) public onlyDAO {
        bulkBuyLimit = _newLimit;
    }

    function setBaseURI(string memory _baseURI) public onlyDAO {
        baseURI = _baseURI;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyDAO {
        maxTotalSupply = _maxSupply;

        emit MaxSupplyChanged(_maxSupply);
    }

    function emergeWithdraw() public onlyDAO {
        (bool transferToDAO, ) = daoAddress.call{value: address(this).balance}(
            ""
        );
        require(transferToDAO, "Failed to send to DAO.");
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function geneOf(uint256 tokenId) external view returns (uint256 gene) {
        return _genes[tokenId];
    }

    receive() external payable {
        mint(1);
    }
}
