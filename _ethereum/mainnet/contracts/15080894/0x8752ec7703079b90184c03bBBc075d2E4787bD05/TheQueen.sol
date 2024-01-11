// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC1155.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ERC2981.sol";
import "./ERC721AQueryable.sol";

enum Stage {
    HiveClosed,
    QueenDinner,
    Sale
}

interface IFood {
    function holderClaim(address holder, uint256 amount) external;
}

contract TheQueen is ERC1155, ERC2981, Ownable {
    using Address for address payable;
    using Strings for uint256;

    uint32 public constant TOTAL_SUPPLY = 10000;
    uint32 public constant WALLET_LIMIT = 3;
    uint32 public constant BASIC_SUPPLY = 10000;
    uint32 public constant BASIC_ID = 0;
    Stage public _stage = Stage.HiveClosed;
    address public constant BLACKHOLE = 0x000000000000000000000000000000000000dEaD;

    IERC721 public immutable _swarmGas;
    IFood public immutable _food;
    uint256 public immutable _swarmFoodPerPair;

    struct Status {
        uint32 basicSupply;
        uint32 basicMinted;
        uint32 walletLimit;
        uint256 ethPrice;
        uint32 userMinted;
        bool started;
        bool soldout;
    }

    uint32 public _basicMinted;
    mapping(address => uint32) public _userMinted;

    address public _burner;
    bool public _started;
    uint256 public _ethPrice;
    string public _metadataURI = "https://meta.the-swarm.xyz/thequeen/json/";
    
    constructor(
        address swarmGas,
        address food,
        uint256 swarmFoodPerPair
    )
        
        ERC1155(""){
            _swarmGas = IERC721(swarmGas);
            _food = IFood(food);
            _swarmFoodPerPair = swarmFoodPerPair;
        }

    function claim(uint256[] memory tokenIds) external {
        require(_stage == Stage.QueenDinner, "Hive: Claiming is not started yet");
        require(tokenIds.length > 0 && tokenIds.length % 2 == 0, "Hive: You must provide token pairs");
        uint32 pairs = uint32(tokenIds.length / 2);
        

        require(tx.origin == msg.sender, "Swarm gas !");
        _userMinted[msg.sender] += pairs;
        require(_userMinted[msg.sender] <= WALLET_LIMIT, "The queen say no more");
    
        for (uint256 i = 0; i < tokenIds.length; ) {
            _swarmGas.transferFrom(msg.sender, BLACKHOLE, tokenIds[i]);
            unchecked {
                i++;
            }
        }


        internalClaim(msg.sender, BASIC_ID, pairs);
        _food.holderClaim(msg.sender, pairs * _swarmFoodPerPair);

    }

    function internalClaim(
        address minter,
        uint32 id,
        uint32 amount
    ) internal {
        if (id == BASIC_ID) {
            _basicMinted += amount;
            require(_basicMinted <= BASIC_SUPPLY, "The queen say no more");
        } else {
            require(false, "This is not the Queen");
        }

        _mint(minter, id, amount, "");
    }
    
    function mint(uint32 amount, bool useEth) external payable {
        require(_stage == Stage.Sale, "Hive: Sale is not started");
        require(tx.origin == msg.sender, "Swarm gas !");
        _userMinted[msg.sender] += amount;
        require(_userMinted[msg.sender] <= WALLET_LIMIT, "The queen say no more");
        require(msg.value == _ethPrice * amount, "Swarm need more gas");

        internalMint(msg.sender, BASIC_ID, amount);

    }

    function internalMint(
        address minter,
        uint32 id,
        uint32 amount
    ) internal {
        if (id == BASIC_ID) {
            _basicMinted += amount;
            require(_basicMinted <= BASIC_SUPPLY, "The queen say no more");
        } else {
            require(false, "This is not the Queen");
        }

        _mint(minter, id, amount, "");
    }

    function burn(
        address who,
        uint32 amount,
        uint32 id
    ) external {
        require(msg.sender == _burner, "Consume");

        _burn(who, id, amount);
    }

    
    function _status(address minter) public view returns (Status memory) {
        return
            Status({
                basicSupply: BASIC_SUPPLY,
                basicMinted: _basicMinted,
                walletLimit: WALLET_LIMIT,
                ethPrice: _ethPrice,
                userMinted: _userMinted[minter],
                started: _started,
                soldout: _basicMinted >= BASIC_SUPPLY
            });
    }

    function uri(uint256 id) public view override returns (string memory) {
        string memory baseURI = _metadataURI;
        return string(abi.encodePacked(baseURI, "queen.json"));
    }

    function setMetadataURI(string memory metadataURI) external onlyOwner {
        _metadataURI = metadataURI;
    }

    function setBurner(address burner) external onlyOwner {
        _burner = burner;
    }

    

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC1155) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC1155).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function setFeeNumerator(uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(owner(), feeNumerator);
    }

    function setEthPrice(uint256 price) public onlyOwner {
        _ethPrice = price;
    }

    function withdrawFund(address tokenAddress) external onlyOwner {
        payable(msg.sender).sendValue(address(this).balance);
    }

    function name() public pure returns (string memory) {
        return "The Queen";
    }

    function symbol() public pure returns (string memory) {
        return "QUEEN";
    }

    function setStage(Stage stage) external onlyOwner {
        _stage = stage;
    }
}