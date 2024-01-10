// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
import "./ERC721URIStorage.sol";

contract NFTITS is ERC721URIStorage {
    uint256 public projectLimit = 888;
    uint256 public tokenCount;
    address public contract_owner;
    bool public _enabled = true;
    bool public _locked = false;
    mapping(uint256 => Pass) public categoryDetails;
    mapping(uint256 => uint256) public projectMints;
    mapping(address => bool) public blackList;
    mapping(uint256 => uint256) public category;
    mapping(address => bool) public userAddr;
    struct Pass {
        uint256 id;
        string uri;
        uint256 price;
    }

    constructor() ERC721("NFTiTs", "TiTs") {
        contract_owner = msg.sender;
        categoryDetails[1] = Pass({
            id: 1,
            uri: "https://gateway.pinata.cloud/ipfs/QmPPNq5JvzQPco2jcC8KUMaW1M7HyAZ9juXWnZDpMYnJkQ",
            price: 0.155584 ether
        });
        categoryDetails[2] = Pass({
            id: 2,
            uri: "https://gateway.pinata.cloud/ipfs/QmTSTEJinXQ7R9Z1B7ZiPTuH7uWCKeatKw9cNAw7n1FTbs",
            price: 0.283114 ether
        });
        categoryDetails[3] = Pass({
            id: 3,
            uri: "https://gateway.pinata.cloud/ipfs/QmbpraiDHSHhnuKzq1bqY7S2tCbCec2GcBA75qM7y3v971",
            price: 0.601937166 ether
        });
    }

    modifier OnlyOwner() {
        require(msg.sender == contract_owner, "NTC");
        _;
    }

    modifier onlyWhenEnabled() {
        require(_enabled, "disabled");
        _;
    }

    modifier onlyWhenDisabled() {
        require(!_enabled, "enabled");
        _;
    }

    modifier onlyUnlocked() {
        require(!_locked, "locked");
        _;
    }

    function setUri(string memory tokenURI, uint256 tokenId)
        external
        OnlyOwner
    {
        _setTokenURI(tokenId, tokenURI);
    }

      function setEnabled(bool enabled)
        public
        OnlyOwner
    {
        _enabled = enabled; 
    }

      function setLocked(bool locked)
        public
        OnlyOwner
    {
        _locked = locked; 
    }

    function setCategoryUri(string memory tokenURI, uint256 categoryId)
        public
        OnlyOwner
    {
        categoryDetails[categoryId].uri = tokenURI;
    }

    function transferOwnership(address owner) public OnlyOwner {
        contract_owner = owner;
    }

    function setPrice(uint256 silverPrice, uint256 goldPrice, uint256 platinumPrice) external OnlyOwner {
        categoryDetails[1].price = silverPrice;
        categoryDetails[2].price = goldPrice;
        categoryDetails[3].price = platinumPrice;
    }

    function updateMintingLimit(uint256 limit) external OnlyOwner {
        projectLimit = limit;
    }



    function isOwner(address user) public view returns (bool) {
        if (user == contract_owner) {
            return true;
        } else {
            return false;
        }
    }

    function burn(uint256 tokenId) public OnlyOwner {
       _burn(tokenId);
    }

    function blockUser(address user) public OnlyOwner {
        blackList[user] = true;
    }

    function unblockUser(address user) public OnlyOwner {
        blackList[user] = false;
    }

    function airdrop(
        address[] memory _to,
        uint256[] memory _value,
        uint256 categoryId
    ) public OnlyOwner {
        require(_to.length == _value.length);
        for (uint256 i = 0; i < _to.length; i++) {
            for (uint256 j = 0; j < _value[i]; j++) {
            uint256 currentMint = projectMints[categoryId];
            require(!blackList[_to[i]], "blocked user");
            require(categoryId > 0);
            require(categoryId < 4);
            require(currentMint < projectLimit, "NRP");
            require(!blackList[_to[i]], "blocked user");
            currentMint++;
            tokenCount++;
            userAddr[_to[i]] = true;
            _mint(_to[i], tokenCount);
            _setTokenURI(tokenCount, categoryDetails[categoryId].uri);
            projectMints[categoryId] = currentMint;
            category[tokenCount] = categoryId;
            }
        }
    }

    function withdraw(uint256 amount) public {
        payable(contract_owner).transfer(amount);
    }

    receive() external payable onlyWhenEnabled {
        uint256 tokenId;
        require(
            msg.value == categoryDetails[1].price ||
                msg.value == categoryDetails[2].price ||
                msg.value == categoryDetails[3].price
        );
        if (msg.value == categoryDetails[1].price) {
            tokenId = 1;
            uint256 currentMint = projectMints[tokenId];
            require(currentMint < projectLimit, "NRP");
            require(!blackList[msg.sender], "blocked user");
            currentMint++;
            tokenCount++;
            userAddr[msg.sender] = true;
            _mint(msg.sender, tokenCount);
            _setTokenURI(tokenCount, categoryDetails[tokenId].uri);
            projectMints[tokenId] = currentMint;
            category[tokenCount] = 1;
        } else if (msg.value == categoryDetails[2].price) {
            tokenId = 2;
            uint256 currentMint = projectMints[tokenId];
            require(currentMint < projectLimit, "NRP");
            require(!blackList[msg.sender], "blocked user");
            tokenCount++;
            userAddr[msg.sender] = true;
            currentMint++;
            _mint(msg.sender, tokenCount);
            _setTokenURI(tokenCount, categoryDetails[tokenId].uri);
            projectMints[tokenId] = currentMint;
            category[tokenCount] = 2;
        } else if (msg.value == categoryDetails[3].price) {
            tokenId = 3;
            uint256 currentMint = projectMints[tokenId];
            require(currentMint < projectLimit, "NRP");
            require(!blackList[msg.sender], "blocked user");
            tokenCount++;
            userAddr[msg.sender] = true;
            currentMint++;
            _mint(msg.sender, tokenCount);
            _setTokenURI(tokenCount, categoryDetails[tokenId].uri);
            projectMints[tokenId] = currentMint;
            category[tokenCount] = 3;
        }
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 passId
    ) public virtual override onlyUnlocked {
            if (userAddr[sender] == true) {
                userAddr[recipient] = true;
                super.transferFrom(sender, recipient, passId);
                if (ERC721(address(this)).balanceOf(sender) <= 0) {
                    userAddr[sender] = false;
                }
            } else {
                super.transferFrom(sender, recipient, passId);
            }
    }
}
