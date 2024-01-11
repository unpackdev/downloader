// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;
import "./Strings.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./IERC20.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";

contract A2Heroes is
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    AccessControl,
    Ownable
{
    using SafeMath for uint256;

    bytes32 public constant REDEEM_ROLE = keccak256("REDEEM_ROLE");
    bytes32 public constant BURI_ROLE = keccak256("BURI_ROLE");
    bytes32 public constant PRESALE_ROLE = keccak256("PRESALE_ROLE");

    event TokenRedeemed(uint256 indexed tokenId);
    event TokenMinted(uint256 indexed tokenId, bytes mintedData);

    constructor() ERC721("A2Heroes", "A2H") {
        creator = "A2Heroes";
        currentAdmin = msg.sender;
        _setupRole(
            DEFAULT_ADMIN_ROLE,
            msg.sender
        );
        _setupRole(REDEEM_ROLE, msg.sender);
        _setupRole(BURI_ROLE, msg.sender);
        _setupRole(PRESALE_ROLE, msg.sender);
        baseuri = "https://gateway.pinata.cloud/ipfs";
    }

    address public currentAdmin;
    string public creator;
    bool public saleIsActive = true;
    string public baseuri;

    uint256 public walletLimit = 20;
    uint256 public MAX_SUPPLY = 10000000000;

    uint64 public presaleStartDate;
    uint64 public presaleStopDate;

    mapping(uint256 => uint256) public character_price;
    mapping(uint256 => uint256) public character_supply;
    mapping(address => uint256) public _mintedAmount;
    mapping(uint256 => uint256) public character_minted;
    mapping(uint256 => string) public tokenNames;
    mapping(string => uint256) public names;
    mapping(uint256 => string) public realTokenUri;
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => uint256) public tokenPrice;
    mapping(uint256 => address) public tokenOwner;
    mapping(uint256 => bool) public tokenRedeemable;

    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI(tokenId);
        return
            bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI)) : "";
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _transfer(from, to, tokenId);
        tokenOwner[tokenId] = to;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);

        tokenOwner[tokenId] = to;
    }

    function setSaleActive() public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller has not the role of admin"
        );
        saleIsActive = true;
    }

    function resetSaleActive() public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller has not the role of admin"
        );
        saleIsActive = false;
    }

    function setRedeemer(address newRedeemer) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller has not the role of admin"
        );
        _setupRole(REDEEM_ROLE, newRedeemer);
    }

    function setBaseURIRole(address newBaseURIRole) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller has not the role of admin"
        );
        _setupRole(BURI_ROLE, newBaseURIRole);
    }

    function setPresaleRole(address newPresaleRole) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller has not the role of admin"
        );
        _setupRole(PRESALE_ROLE, newPresaleRole);
    }

    function Mint(
        string memory _name,
        string memory cid,
        uint256 characterId,
        uint256 amount
    ) public payable {
        uint256 supply = totalSupply();
        require(character_price[characterId] > 0, "Character does not exist");

        require(saleIsActive, "Sale must be active to mint");
        require(
            _mintedAmount[msg.sender] < walletLimit,
            "Exceeds personal wallet limits"
        );
        require(totalSupply() < MAX_SUPPLY, "Exceeds max supply of contract");
        require(
            amount <
                character_supply[characterId] - character_minted[characterId],
            "The number of characters is insufficient."
        );
        require(
            msg.value >= character_price[characterId] * amount,
            "The price is not enough"
        );
        require(
            character_minted[characterId] < character_supply[characterId],
            "The character amount for this archetype has reached its limit"
        );

        for (uint256 idx = 1; idx <= amount; idx++) {
            setRealTokenURI(supply + idx, cid);
            _safeMint(msg.sender, supply + idx);
            _setTokenURI(supply + idx, cid);

            _mintedAmount[msg.sender] = _mintedAmount[msg.sender].add(1);
            character_minted[characterId] = character_minted[characterId] + 1;
            tokenPrice[supply + idx] = msg.value;
            tokenOwner[supply + idx] = msg.sender;
            string memory upperName;

            tokenNames[supply + idx] = _name;
            names[upperName] = supply + idx;
        }
    }

    function ownerMint(
        string memory _name,
        string memory cid,
        uint256 characterId,
        uint256 amount
    ) public payable onlyOwner {
        uint256 supply = totalSupply();
        uint256 blockTimeStamp = block.timestamp;
        uint256 currentTimeStamp = blockTimeStamp.mul(1000);
        require(saleIsActive, "Sale must be active to mint");
        require(totalSupply() < MAX_SUPPLY, "Exceeds max supply of contract");
        require(
            amount <
                character_supply[characterId] - character_minted[characterId],
            "The number of characters is insufficient."
        );
        require(
            character_minted[characterId] < character_supply[characterId],
            "The character amount for this archetype has reached its limit"
        );
        require(currentTimeStamp < presaleStartDate);

        for (uint256 idx = 1; idx <= amount; idx++) {
            setRealTokenURI(supply + idx, cid);
            _safeMint(msg.sender, supply + idx);
            _setTokenURI(supply + idx, cid);

            character_minted[characterId] = character_minted[characterId] + 1;
            _mintedAmount[msg.sender] = _mintedAmount[msg.sender].add(1);
            tokenPrice[supply + idx] = msg.value;
            tokenOwner[supply + idx] = msg.sender;
            string memory upperName;

            tokenNames[supply + idx] = _name;
            names[upperName] = supply + idx;
        }
    }

    function batchMint(
        string memory _name,
        string[] memory cid,
        uint256[] calldata characterId,
        uint256[] calldata amounts
    ) public payable {
        require(saleIsActive, "Sale must be active to mint");
        require(
            _mintedAmount[msg.sender] < walletLimit,
            "Exceeds personal wallet limits"
        );
        uint256 totalValue = 0;
        for (uint256 i = 0; i < characterId.length; i++) {
            totalValue =
                totalValue +
                character_price[characterId[i]] *
                amounts[i];
        }

        require(msg.value >= totalValue, "The price is not enough.");

        for (uint256 idx = 0; idx < characterId.length; idx++) {
            uint256 supply = totalSupply();
            require(
                character_price[characterId[idx]] > 0,
                "Character does not exist"
            );
            require(
                totalSupply() < MAX_SUPPLY,
                "Exceeds max supply of contract"
            );
            require(
                character_minted[characterId[idx]] <
                    character_supply[characterId[idx]],
                "The character amount for this archetype has reached its limit"
            );

            for (uint256 jdx = 1; jdx <= amounts[idx]; jdx++) {
                setRealTokenURI(supply + jdx, cid[idx]);
                _safeMint(msg.sender, supply + jdx);
                _setTokenURI(supply + 1, cid[idx]);

                _mintedAmount[msg.sender] = _mintedAmount[msg.sender].add(1);
                character_minted[characterId[idx]] =
                    character_minted[characterId[idx]] +
                    1;
                tokenPrice[supply + jdx] = msg.value;
                tokenOwner[supply + jdx] = msg.sender;
                string memory upperName;

                tokenNames[supply + jdx] = _name;
                names[upperName] = supply + jdx;
            }
        }
    }

    function presaleMint(
        string memory _name,
        string memory cid,
        uint256 characterId,
        uint256 amount
    ) public payable {
        uint256 supply = totalSupply();
        uint256 blockTimeStamp = block.timestamp;
        uint256 currentTimeStamp = blockTimeStamp.mul(1000);
        require(
            hasRole(PRESALE_ROLE, msg.sender),
            "Caller has not the role for presale"
        );
        require(character_price[characterId] > 0, "Character does not exist");
        require(saleIsActive, "Sale must be active to mint");
        require(
            _mintedAmount[msg.sender] < walletLimit,
            "Exceeds personal wallet limits"
        );
        require(totalSupply() < MAX_SUPPLY, "Exceeds max supply of contract");
        require(
            amount <
                character_supply[characterId] - character_minted[characterId],
            "The number of characters is insufficient."
        );
        require(
            msg.value >= character_price[characterId] * amount,
            "The price is not enough."
        );
        require(
            character_minted[characterId] < character_supply[characterId],
            "The character amount for this archetype has reached its limit"
        );
        require(
            currentTimeStamp > presaleStartDate,
            string(
                abi.encodePacked(
                    "Today is not for Presale(less than start date).",
                    currentTimeStamp
                )
            )
        );
        require(
            currentTimeStamp < presaleStopDate,
            string(
                abi.encodePacked(
                    "Today is not for Presale(more than stop date).",
                    currentTimeStamp
                )
            )
        );

        for (uint256 idx = 1; idx <= amount; idx++) {
            setRealTokenURI(supply + idx, cid);
            _safeMint(msg.sender, supply + 1);
            _setTokenURI(supply + 1, cid);

            _mintedAmount[msg.sender] = _mintedAmount[msg.sender].add(1);
            character_minted[characterId] = character_minted[characterId] + 1;
            tokenPrice[supply + idx] = msg.value;
            tokenOwner[supply + idx] = msg.sender;
            string memory upperName;

            tokenNames[supply + idx] = _name;
            names[upperName] = supply + idx;
        }
    }

    function presaleBatchMint(
        string memory _name,
        string[] memory cid,
        uint256[] calldata characterId,
        uint256[] calldata amounts
    ) public payable {
        require(saleIsActive, "Sale must be active to mint");
        require(
            hasRole(PRESALE_ROLE, msg.sender),
            "Caller has not the role for presale"
        );

        uint256 blockTimeStamp = block.timestamp;
        uint256 currentTimeStamp = blockTimeStamp.mul(1000);
        require(
            currentTimeStamp > presaleStartDate,
            string(
                abi.encodePacked(
                    "Today is not for Presale(less than start date).",
                    currentTimeStamp
                )
            )
        );
        require(
            currentTimeStamp < presaleStopDate,
            string(
                abi.encodePacked(
                    "Today is not for Presale(more than stop date).",
                    currentTimeStamp
                )
            )
        );

        uint256 totalValue = 0;
        for (uint256 i = 0; i < characterId.length; i++) {
            totalValue =
                totalValue +
                character_price[characterId[i]] *
                amounts[i];
        }

        require(msg.value >= totalValue, "The price is not enough.");

        for (uint256 idx = 0; idx < characterId.length; idx++) {
            uint256 supply = totalSupply();
            require(
                character_price[characterId[idx]] > 0,
                "Character does not exist"
            );
            require(
                totalSupply() < MAX_SUPPLY,
                "Exceeds max supply of contract"
            );
            require(
                character_minted[characterId[idx]] <
                    character_supply[characterId[idx]],
                "The character amount for this archetype has reached its limit"
            );

            for (uint256 jdx = 1; jdx <= amounts[idx]; jdx++) {
                setRealTokenURI(supply + idx, cid[idx]);
                _safeMint(msg.sender, supply + jdx);
                _setTokenURI(supply + 1, cid[idx]);

                _mintedAmount[msg.sender] = _mintedAmount[msg.sender].add(1);
                character_minted[characterId[idx]] =
                    character_minted[characterId[idx]] +
                    1;
                tokenPrice[supply + jdx] = msg.value;
                tokenOwner[supply + jdx] = msg.sender;
                string memory upperName;

                tokenNames[supply + jdx] = _name;
                names[upperName] = supply + jdx;
            }
        }
    }

    function redeem(uint256 _id) external {
        require(
            hasRole(REDEEM_ROLE, msg.sender),
            "Caller has not the role for presale"
        );

        require(_exists(_id), "No such token");
        tokenRedeemable[_id] = true;
        emit TokenRedeemed(_id);
    }

    function setCharacterPrice(uint256 id, uint256 characterPrice)
        public
        onlyOwner
    {
        character_price[id] = characterPrice;
    }

    function setCharacterSupply(uint256 id, uint256 supply) public onlyOwner {
        character_supply[id] = supply;
    }

    function transferOwnership(address newOwner)
        public
        virtual
        override
        onlyOwner
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);

        currentAdmin = newOwner;
        _setupRole(DEFAULT_ADMIN_ROLE, newOwner);
        _setupRole(REDEEM_ROLE, newOwner);
        _setupRole(BURI_ROLE, newOwner);
        _setupRole(PRESALE_ROLE, newOwner);
    }

    function setBaseURI(string memory baseURIL) public {
        require(hasRole(BURI_ROLE, msg.sender), "Caller is not a admin");
        baseuri = baseURIL;
    }

    function setRealTokenURI(uint256 tokenId, string memory cid) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller has not the role for super admin"
        );
        realTokenUri[tokenId] = string(abi.encodePacked(baseuri, "/", cid));
    }

    function setPresaleDate(uint64 timestamp_start, uint64 timestamp_stop)
        public
    {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller has not the role for super admin"
        );
        presaleStartDate = timestamp_start;
        presaleStopDate = timestamp_stop;
    }

    function _baseURI(uint256 tokenId)
        internal
        view
        virtual
        returns (string memory)
    {
        return realTokenUri[tokenId];
    }

    function currentTime() public view returns (uint256) {
        return block.timestamp;
    }

    bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721Enumerable, ERC721)
        returns (bool)
    {
        return
            interfaceId == _INTERFACE_ID_FEES ||
            AccessControl.supportsInterface(interfaceId) ||
            ERC721Enumerable.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function withdraw(address ownerWallet) external onlyOwner {
        uint256 balance = address(this).balance;

        payable(ownerWallet).transfer(balance);
    }
}
