// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./MerkleProof.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./VRFConsumerBase.sol";
import "./AccessControl.sol";

contract Poppables is
    ERC721,
    ERC721Enumerable,
    Ownable,
    ReentrancyGuard,
    VRFConsumerBase,
    AccessControl
{
    using Address for address;
    using SafeMath for uint256;

    event ParticipantPresaleListMinted(bool state);
    event PresaleListMinted(bool state);
    event SaleListNFTMinted(bool state);
    event NFTRandomnessRequest(uint256 timestamp);
    event NFTRandomnessFullfill(uint256 timestamp);
    event NFTChainlinkError(uint256 timestamp, bytes32 requestId);
    event PermanentURI(string _value, uint256 indexed _id);

    bool public presaleParticipantIsActive = false;
    bool public presaleIsActive = false;
    bool public saleIsActive = false;

    bytes32 public presaleParticipantRoot;
    bytes32 public presaleRoot;

    uint256 public maxSupply;
    uint256 public maxMintableSupply;
    uint256 public maxAirdropSupply;
    uint256 public price;

    uint256 public saleNFT;
    uint256 public freeNFT;

    address private account1;
    address private account2;
    address private account3;
    address private account4;

    bool private _requestedVRF = false;
    uint256 private _seed = 0;
    bytes32 private _keyHash;
    uint256 private _fee;

    string private _contractURI;
    string private _tokenBaseURI;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    mapping(address => uint256) private presaleParticipantMinted;
    mapping(address => uint256) private presaleMinted;

    uint256 private totalAirDrop = 0;

    mapping(uint256 => string) private tokenURIs;

    constructor(
        address _account1,
        address _account2,
        address _account3,
        address _account4,
        address adminRoleAdress
    )
        ERC721("Poppables", "POP")
        VRFConsumerBase(
            0xf0d54349aDdcf704F77AE15b96510dEA15cb7952,
            0x514910771AF9Ca656af840dff83E8264EcF986CA
        )
    {
        price = 21000000000000000; //0.021 ETH
        maxAirdropSupply = 350;
        maxMintableSupply = 9671;
        maxSupply = 10021;

        account1 = _account1;
        account2 = _account2;
        account3 = _account3;
        account4 = _account4;

        _contractURI = "https://www.poppables.io/opensea.json";
        _tokenBaseURI = "https://poppables.mypinata.cloud/ipfs/bafybeiecgmnencv7lujl5idd52lyymu6ehkd3qxg34lp33xtprqedzbtie/";

        _keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
        _fee = 2 * 10**18; // 2 LINK

        //dev admin
        _setupRole(ADMIN_ROLE, adminRoleAdress);

        //contract owner
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        saleNFT = 20;
        freeNFT = 1;
    }

    modifier presaleMintable(uint256 quantity) {
        require(
            totalSupply().add(quantity) <= maxMintableSupply,
            "The qty exceeds maximum supply"
        );
        _;
    }

    function mintParticipantNFTs(
        address minter,
        uint256 quantity,
        bytes32[] calldata proof
    ) external payable nonReentrant presaleMintable(quantity) returns (bool) {
        require(presaleParticipantIsActive, "presales not active");
        require(quantity >= 1 && quantity < 4, "Wrong quantity");

        bool presaleParticipanList = minterInThePresaleList(proof, minter, 1);

        require(presaleParticipanList, "Not on the presales list");

        require(
            presaleParticipantMinted[msg.sender].add(quantity) <= 3,
            "Limit exceeded"
        );

        // 1 free + 2 additional
        uint256 payableQty = quantity;
        if (payableQty > 0) {
            payableQty = payableQty.sub(1);
        }

        require(msg.value >= price.mul(payableQty), "Not enough ETH");

        for (uint256 i = 0; i < quantity; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < maxMintableSupply) {
                presaleParticipantMinted[msg.sender] += 1;
                _safeMint(msg.sender, mintIndex);
            }
        }

        emit ParticipantPresaleListMinted(true);

        return true;
    }

    function mintPresaleNFTs(
        address minter,
        uint256 quantity,
        bytes32[] calldata proof
    ) external payable nonReentrant presaleMintable(quantity) returns (bool) {
        require(presaleIsActive, "presales not active");
        require(quantity >= 1 && quantity < 3, "Wrong quantity");

        bool presaleList = minterInThePresaleList(proof, minter, 2);

        require(presaleList, "Not on the presales list");

        require(presaleMinted[msg.sender].add(quantity) <= 3, "limit exceeded");

        // buy 2 additional and get one free
        uint256 mintQty = quantity;
        if (quantity > 1) {
            mintQty = mintQty.add(1);
        }

        require(msg.value >= price.mul(quantity), "Not enough ETH");

        for (uint256 i = 0; i < mintQty; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < maxMintableSupply) {
                presaleMinted[msg.sender] += 1;
                _safeMint(msg.sender, mintIndex);
            }
        }
        emit PresaleListMinted(true);

        return true;
    }

    function mintSaleNFTs(uint256 quantity)
        external
        payable
        nonReentrant
        returns (bool)
    {
        require(saleIsActive, "Sales is not active");
        require(quantity >= 1 && quantity < 21, "Wrong quantity");

        return mintNFTs(_msgSender(), quantity, false);
    }

    function mintNFTs(
        address minter,
        uint256 quantity,
        bool airDrop
    ) private returns (bool) {
        uint256 mintQty = quantity;
        if (quantity > saleNFT - 1) {
            mintQty = mintQty.add(freeNFT);
        }

        require(
            totalSupply().add(mintQty) <= maxMintableSupply,
            "maximum supply exceeded"
        );

        uint256 total = maxMintableSupply;

        if (airDrop) {
            require(hasRole(ADMIN_ROLE, msg.sender), "Not admin");
            total = maxAirdropSupply;
        } else {
            require(msg.value >= price.mul(quantity), "Not enough ETH");
        }

        for (uint256 i = 0; i < mintQty; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < total) {
                _safeMint(minter, mintIndex);
            }
        }

        emit SaleListNFTMinted(true);

        return true;
    }

    function minterInThePresaleList(
        bytes32[] memory proof,
        address minter,
        uint256 presaleList
    ) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(minter));

        if (presaleList == 1) {
            return MerkleProof.verify(proof, presaleParticipantRoot, leaf);
        }

        if (presaleList == 2) {
            return MerkleProof.verify(proof, presaleRoot, leaf);
        }

        return false;
    }

    function updateMerkleParticipantRoot(bytes32 _merklePresaleRoot) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Not admin");
        presaleRoot = _merklePresaleRoot;
    }

    function updatePresaleRoot(bytes32 _merkleParticipantRoot) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Not admin");
        presaleParticipantRoot = _merkleParticipantRoot;
    }

    function toggleParticipantPresale() external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Not admin");
        presaleParticipantIsActive = !presaleParticipantIsActive;
    }

    function togglePresale() external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Not admin");
        presaleIsActive = !presaleIsActive;
    }

    function toggleSale() external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Not admin");
        saleIsActive = !saleIsActive;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(tokenId <= totalSupply(), "Token does not exist");

        return
            string(
                abi.encodePacked(_tokenBaseURI, metadataOf(tokenId), ".json")
            );
    }

    function metadataOf(uint256 tokenId) public view returns (string memory) {
        require(tokenId <= totalSupply(), "Token id invalid");

        //poped token exists
        if (bytes(tokenURIs[tokenId]).length > 0) {
            return tokenURIs[tokenId];
        } else {
            uint256[] memory metaIds = new uint256[](maxSupply + 1);
            uint256 ss = _seed;

            for (uint256 i = 1; i <= maxSupply; i += 1) {
                metaIds[i] = i;
            }

            for (uint256 i = 1; i <= maxSupply; i += 1) {
                uint256 j = (uint256(keccak256(abi.encode(ss, i))) %
                    (maxSupply));
                (metaIds[i], metaIds[j]) = (metaIds[j], metaIds[i]);
            }
            return Strings.toString(metaIds[tokenId]);
        }
    }

    function updateTokenMetadata(uint256 tokenId, string memory tokenUpdatedURI)
        external
    {
        require(hasRole(ADMIN_ROLE, msg.sender), "Not admin");
        tokenURIs[tokenId] = tokenUpdatedURI;
    }

    function requestChainlinkVRF() public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Not admin");
        require(!_requestedVRF, "Already exec");
        require(LINK.balanceOf(address(this)) >= _fee);
        requestRandomness(_keyHash, _fee);
        _requestedVRF = true;
        emit NFTRandomnessRequest(block.timestamp);
    }

    function setSeed(uint256 randomNumber) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Not admin");
        _requestedVRF = true;
        _seed = randomNumber;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;

        payable(account1).transfer(balance.mul(15).div(100));
        payable(account2).transfer(balance.mul(15).div(100));
        payable(account3).transfer(balance.mul(20).div(100));
        payable(account4).transfer(balance.mul(50).div(100));
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomNumber)
        internal
        override
    {
        if (randomNumber > 0) {
            _seed = randomNumber;
            emit NFTRandomnessFullfill(block.timestamp);
        } else {
            emit NFTChainlinkError(block.timestamp, requestId);
        }
    }

    //emit event for OpenSea to freeze metadata
    function freezeMetadata() public onlyOwner {
        for (uint256 i = 1; i <= totalSupply(); i += 1) {
            emit PermanentURI(tokenURI(i), i);
        }
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory contract_uri) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Not admin");
        _contractURI = contract_uri;
    }

    function setBaseURI(string memory baseURI) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Not admin");
        _tokenBaseURI = baseURI;
    }

    function updateSalesQty(uint256 _saleNFT, uint256 _freeNFT) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Not admin");
        saleNFT = _saleNFT;
        freeNFT = _freeNFT;
    }

    function airdrop(address[] memory _to, uint256 amount) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Not admin");
        require(
            totalAirDrop + (_to.length * amount) <= maxAirdropSupply,
            "Airdop limit"
        );
        for (uint256 i = 0; i < _to.length; i += 1) {
            mintNFTs(_to[i], amount, true);
        }
    }

    // The following functions are overrides required by Solidity.

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
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
