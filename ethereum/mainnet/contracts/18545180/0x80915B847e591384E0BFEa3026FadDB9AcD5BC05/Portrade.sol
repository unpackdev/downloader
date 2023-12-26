// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./MessageHashUtils.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./Arrays.sol";

contract Portrade is ERC1155, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;
    using Strings for uint256;
    using Arrays for uint256[];

    uint256 public ethPrice;

    uint256 private _collectionSupply;
    mapping(uint256 id => uint256 quantity) public tokenSupply;
    mapping(address owner => uint256 count) public totalBalances;

    uint256 public constant MAX_SUPPLY = 100;
    uint256 public constant MAX_INVENTORY = 367;
    uint256 public constant MINT_LIMIT = 3;

    uint256 private constant TOKEN_STOCK_4_ID = 33;
    uint256 private constant TOKEN_STOCK_5_ID = 49;

    address private _signerAddress;

    string public name;
    string public symbol;
    bool public isPaused;
    bool public isPublicMint;
    bool public isGuaranteedMint;

    constructor(
        address signerAddress
    )
        ERC1155(
            "https://storage.googleapis.com/portrade/portrade-1_0/metadata/"
        )
        Ownable(msg.sender)
    {
        _signerAddress = signerAddress;
        name = "Portrade 1.0";
        symbol = "PTRD";
        ethPrice = 0.3 ether;
        isPaused = true;
        isPublicMint = false;
        isGuaranteedMint = true;
    }

    modifier checkIsPaused() {
        require(!isPaused, "Portrade is currently locked.");
        _;
    }

    modifier checkIsPublicMint() {
        require(isPublicMint, "Public mint is not enabled.");
        _;
    }

    //decode signature to get the id of the token
    function _verify(
        bytes memory signature,
        uint256 id
    ) internal view returns (bool) {
        bytes32 message = keccak256(abi.encodePacked(msg.sender, id));
        return
            message.toEthSignedMessageHash().recover(signature) ==
            _signerAddress;
    }

    function uri(uint256 id) public view override returns (string memory) {
        require(id >= 0 && id < MAX_SUPPLY, "Invalid Id");
        string memory baseUri = super.uri(id);
        return
            bytes(baseUri).length > 0
                ? string(abi.encodePacked(baseUri, id.toString(), ".json"))
                : "";
    }

    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }

    function setEthPrice(uint256 newPrice) external onlyOwner {
        ethPrice = newPrice;
    }

    function flipPause() external onlyOwner {
        isPaused = !isPaused;
    }

    function flipPublicMint() external onlyOwner {
        isPublicMint = !isPublicMint;
    }

    function flipGuaranteeMint() external onlyOwner {
        isGuaranteedMint = !isGuaranteedMint;
    }

    function setSignerAddress(address signerAddress) external onlyOwner {
        _signerAddress = signerAddress;
    }

    function collectionSupply() external view returns (uint256) {
        return _collectionSupply;
    }

    function isAvailable(uint256 id) external view returns (bool) {
        require(id >= 0 && id < MAX_SUPPLY, "Invalid ID");
        if (id <= TOKEN_STOCK_4_ID) {
            return tokenSupply[id] < 4;
        } else if (id <= TOKEN_STOCK_5_ID) {
            return tokenSupply[id] < 5;
        } else {
            return tokenSupply[id] < 3;
        }
    }

    function isSoldOut() external view returns (bool) {
        return _collectionSupply >= MAX_SUPPLY;
    }

    function mint(
        bytes memory signature,
        uint256 id
    ) external payable checkIsPaused nonReentrant {
        require(id >= 0 && id < MAX_SUPPLY, "Invalid ID");
        require(_verify(signature, id), "Invalid Signature");
        require(totalBalances[msg.sender] < MINT_LIMIT, "Max 3 per owner");
        require(_collectionSupply < MAX_SUPPLY, "Sold Out");
        if (id <= TOKEN_STOCK_4_ID) {
            require(tokenSupply[id] < 4, "Sold Out");
        } else if (id <= TOKEN_STOCK_5_ID) {
            require(tokenSupply[id] < 5, "Sold Out");
        } else {
            require(tokenSupply[id] < 3, "Sold Out");
        }
        require(msg.value >= ethPrice, "Not enough ETH");

        uint256 amount = 1;
        tokenSupply[id] += amount;
        _collectionSupply += amount;
        _mint(msg.sender, id, amount, "");
    }

    function mintPublic(
        uint256 id
    ) external payable checkIsPaused checkIsPublicMint nonReentrant {
        require(id >= 0 && id < MAX_SUPPLY, "Invalid ID");
        require(totalBalances[msg.sender] < MINT_LIMIT, "Max 3 per owner");
        require(_collectionSupply < MAX_SUPPLY, "Sold Out");
        if (id <= TOKEN_STOCK_4_ID) {
            require(tokenSupply[id] < 4, "Sold Out");
        } else if (id <= TOKEN_STOCK_5_ID) {
            require(tokenSupply[id] < 5, "Sold Out");
        } else {
            require(tokenSupply[id] < 3, "Sold Out");
        }
        require(msg.value >= ethPrice, "Not enough ETH");

        uint256 amount = 1;
        tokenSupply[id] += amount;
        // totalBalances[msg.sender] += amount;
        _collectionSupply += amount;
        _mint(msg.sender, id, amount, "");
    }

    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal virtual override {
        super._update(from, to, ids, values);
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 value = values.unsafeMemoryAccess(i);

            if (from != address(0)) {
                totalBalances[from] -= value;
            }

            if (to != address(0)) {
                totalBalances[to] += value;
            }
        }
    }

    function withdrawFunding() external onlyOwner {
        uint256 currentBalance = address(this).balance;
        (bool sent, ) = address(msg.sender).call{value: currentBalance}("");
        require(sent, "Error while transferring balance");
    }
}
