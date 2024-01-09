// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ECDSA.sol";

contract Chibitek is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    Counters.Counter private _tokenIdCounter;
    string private _baseUri = "https://chibitek.io/api/units/";

    uint256 public maxSupply = 10000;

    bool public isPresale = false;
    bool public isLaunched = false;

    uint256 public presalePrice = 0.075 ether;
    uint256 public salePrice = 0.075 ether;

    bool public premintComplete = false;
    uint256 public premintQty = 150;

    uint256 public maxQtyPerAddress = 4;

    string public globalHash = "5a7ddfde9d118f3db86ffdda33d476941f27a52e1961705356ab63bc9f2881da";

    constructor() ERC721("chibiTEK", "chibitek") {}

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        _baseUri = uri;
    }

    function withdraw() external onlyOwner {
        address payable _owner = payable(owner());
        _owner.transfer(address(this).balance);
    }

    function _safeMint(address to) private {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    /**
     * - An address is whitelisted if it contains a signed message with the right parameters
     * - The signed message payload should be a concatenation of contract address + user address
     */
    modifier onlyWhitelisted(address user_address, bytes calldata signature) {
        bytes32 payload_hash = keccak256(
            abi.encode(address(this), user_address)
        );
        address signer_address = payload_hash.toEthSignedMessageHash().recover(
            signature
        );
        require(signer_address == owner(), "Not in whitelist.");
        _;
    }

    /**
     * - presale mint function - can only be called during presale and before launch
     * - requires the caller to be whitelisted, which is verified with the signature parameters
     */
    function mintPresale(
        address to,
        uint256 quantity,
        bytes calldata signature
    ) external payable onlyWhitelisted(to, signature) {
        require(isPresale, "The presale is closed.");
        require(!isLaunched, "The token has launched. Use mint().");
        require(
            totalSupply() + quantity <= maxSupply,
            "The requested quantity is more than the available supply. Sorry!"
        );
        require(msg.value == presalePrice * quantity, "Incorrect amount.");
        require(
            balanceOf(to) + quantity <= maxQtyPerAddress,
            "Maximum quantity for this address would be exceeded."
        );
        for (uint256 i = 0; i < quantity; ++i) {
            _safeMint(to);
        }
    }

    /**
     * mint function - can only be called after launch
     */
    function mint(address to, uint256 quantity) external payable {
        require(!isPresale && isLaunched, "Sales are closed.");
        require(
            balanceOf(to) + quantity <= maxQtyPerAddress,
            "Maximum quantity for this address would be exceeded."
        );
        require(
            totalSupply() + quantity <= maxSupply,
            "The requested quantity is more than the available supply. Sorry!"
        );
        require(msg.value == salePrice * quantity, "Incorrect amount.");
        for (uint256 i = 0; i < quantity; ++i) {
            _safeMint(to);
        }
    }

    function premint() external onlyOwner {
        require(!premintComplete, "Preminting can only happen once!");
        require(
            !isPresale && !isLaunched,
            "Can only premint when not in presale or launch mode"
        );
        for (uint256 i = 0; i < premintQty; ++i) {
            _safeMint(owner());
        }
        premintComplete = true;
    }

    function setPresale() external onlyOwner {
        require(!isLaunched, "Can't set presale - token already launched.");
        require(!isPresale, "Presale already enabled.");
        isPresale = true;
    }

    function setLaunched() external onlyOwner {
        require(!isLaunched, "Can't set launched - token already launched.");
        isPresale = false;
        isLaunched = true;
    }

    function stop() external onlyOwner {
        isPresale = false;
        isLaunched = false;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
