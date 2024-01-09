// SPDX-License-Identifier: MIT

import "./ERC721.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

pragma solidity 0.8.10;

contract Liferz is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;

    event CollectionRevealed();
    event ContractToggled(bool indexed state);
    event TokenURISet(string indexed tokenUri);

    uint256 public constant MAX_LIFERZ_SUPPLY = 2500;
    uint256 public constant MAX_FREE_SUPPLY = 250;
    uint256 public constant PER_TX_LIMIT = 3;
    uint256 public constant PRICE = .025 ether;
    uint256 public constant REVEAL_TIMEOUT = 6 hours;

    address private constant TEAM_W1 =
        0x85535060a815BFFd808aEEBfBd35Fe7Aa1fE68bf;
    address private constant TEAM_W2 =
        0x5fa99e05497ab910E36d032710411D31D1DD39cA;
    
    bool public paused = true;
    bool public collectionRevealed;
    uint256 public saleActivated;

    uint256 public totalSupply;
    string private __baseURI = "https://api.theliferznft.com";

    constructor() ERC721("Liferz", "LZ") {}

    function mint(uint256 qt) external payable {
        _notPaused();
        require(qt > 0 && qt <= PER_TX_LIMIT, "INVALID_QUANTITY");

        if (totalSupply == 0) {
            saleActivated = block.timestamp;
        }

        if (_freeMintsAvailable()) {
            _mintAtNoCost(qt);
        } else {
            _mintAtCost(qt);
        }
    }

    function freeMintsAvailable() external view returns (bool) {
        return _freeMintsAvailable();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory result)
    {
        require(_exists(tokenId), "UNKNOWN_TOKEN_ID");

        if (collectionRevealed) {
            return
                string(
                    abi.encodePacked(
                        __baseURI,
                        "/metadata/",
                        tokenId.toString(),
                        ".json"
                    )
                );
        } else {
            return
                string(
                    abi.encodePacked(__baseURI, "/metadata/placeholder.json")
                );
        }
    }

    function reveal() external {
        if (!collectionRevealed) {
            _contemplateReveal();
        }
    }

    // RESTRICTED
    function withdraw() external {
        uint256 w2Amount = (address(this).balance * 15) / 100;
        payable(TEAM_W2).transfer(w2Amount);
        payable(TEAM_W1).transfer(address(this).balance);
    }

    function setURI(string calldata newUri) external {
        _restrict();
        __baseURI = newUri;
        emit TokenURISet(__baseURI);
    }

    function toggle() external {
        _restrict();
        paused = !paused;
        emit ContractToggled(paused);
    }

    // INTERNALS
    function _mintAtNoCost(uint256 qt) internal {
        require(msg.value == 0, "INVALID_ETH_AMOUNT");

        _mintN(msg.sender, qt);
    }

    function _mintAtCost(uint256 qt) internal {
        require(
            totalSupply + qt <= MAX_LIFERZ_SUPPLY,
            "MINTING_EXCEEDS_SUPPLY"
        );
        require(qt * PRICE == msg.value, "INVALID_ETH_AMOUNT");

        _mintN(msg.sender, qt);
    }

    function _mintN(address to, uint256 qt) internal nonReentrant {
        for (uint256 t = 0; t < qt; t++) {
            _safeMint(to, totalSupply + t);
        }

        totalSupply += qt;

        if (!collectionRevealed) {
            _contemplateReveal();
        }
    }

    function _contemplateReveal() internal {
        if (
            (saleActivated > 0 &&
                (block.timestamp - saleActivated >= REVEAL_TIMEOUT))
        ) {
            collectionRevealed = true;
            emit CollectionRevealed();
        }
    }

    function _freeMintsAvailable() internal view returns (bool) {
        return (totalSupply < MAX_FREE_SUPPLY);
    }

    function _restrict() internal view {
        require(
            msg.sender == owner() ||
                msg.sender == TEAM_W1 ||
                msg.sender == TEAM_W2,
            "UNAUTHORIZED_ACCESS"
        );
    }

    function _notPaused() internal view {
        require(!paused, "CONTRACT_PAUSED");
    }
}