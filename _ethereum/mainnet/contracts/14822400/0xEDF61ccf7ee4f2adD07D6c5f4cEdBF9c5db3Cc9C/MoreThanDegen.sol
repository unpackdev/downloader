//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";

contract MoreThanDegen is ERC721A, Ownable, ReentrancyGuard, Pausable {
    event SaleStateChange(uint256 _newState);
    event PriceChange(uint256 _newPrice);

    using Strings for uint256;

    bytes32 public freeMintMerkleRoot;

    uint256 public maxTokens = 5000;
    uint256 public freeTokens = 300;

    uint256 public maxFreeMints = 1;
    uint256 public price = 0.01 ether;

    string private baseURI;
    string public notRevealedJson =
        "ipfs://bafybeiezpvsic4i27qrf6ewemq5si5qjjl7prn5wv4s3dw4jdfws6bhuiy/";

    bool public revealed;

    enum SaleState {
        NOT_ACTIVE,
        FREE,
        PUBLIC_SALE
    }

    SaleState public saleState = SaleState.NOT_ACTIVE;

    mapping(address => uint256) mintedFree;

    constructor() ERC721A("More Than Degen", "MTD") {}

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        if (revealed) {
            return
                string(
                    abi.encodePacked(_baseURI(), tokenId.toString(), ".json")
                );
        }
        return
            string(
                abi.encodePacked(notRevealedJson, tokenId.toString(), ".json")
            );
    }

    function withdrawBalance() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "Withdrawal failed!");
    }

    function revealTokens(string calldata _ipfsCID) external onlyOwner {
        baseURI = string(abi.encodePacked("ipfs://", _ipfsCID, "/"));
        revealed = true;
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function setMaxFreeMints(uint256 _amount) external onlyOwner {
        maxFreeMints = _amount;
    }

    function setFreeMintMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        freeMintMerkleRoot = _merkleRoot;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
        emit PriceChange(_newPrice);
    }

    function setSaleState(uint256 _state) external onlyOwner {
        if (_state == 0) {
            saleState = SaleState.NOT_ACTIVE;
        } else if (_state == 1) {
            saleState = SaleState.FREE;
        } else if (_state == 2) {
            saleState = SaleState.PUBLIC_SALE;
        }
        emit SaleStateChange(_state);
    }

    receive() external payable {}

    function freeMint(uint256 _amount, bytes32[] calldata _merkleProof)
        external
        nonReentrant
        whenNotPaused
        isValidMerkleProof(_merkleProof, freeMintMerkleRoot)
    {
        require(saleState == SaleState.FREE, "Free mint not active!");
        require(
            totalSupply() + _amount <= freeTokens,
            "End of supply of free tokens!"
        );
        require(
            _amount > 0 && _amount + mintedFree[msg.sender] <= maxFreeMints,
            "Too many tokens per wallet!"
        );
        require(
            maxTokens >= _amount + totalSupply(),
            "Not enough tokens left!"
        );
        _safeMint(msg.sender, _amount);
        mintedFree[msg.sender] += _amount;
    }

    function mint(uint256 _amount) external payable nonReentrant whenNotPaused {
        require(saleState == SaleState.PUBLIC_SALE, "Public sale not active!");
        require(
            maxTokens >= _amount + totalSupply(),
            "Not enough tokens left!"
        );
        require(msg.value >= price * _amount, "Not enough ETH");
        _safeMint(msg.sender, _amount);
    }
}
