// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";

interface IDegenGang {
    function getTokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory);
}

contract DegenGangBeastsNFT is Ownable, ERC721A {
    using SafeMath for uint256;
    using SafeMath for uint8;

    string private _baseTokenURI;

    uint256 public constant MAX_DGB = 5000;

    uint256 public constant MAX_BREED_ALLOWANCE = 2;
    uint256 public constant MAX_BREED_WL = 500;
    uint256 public constant MAX_BREED_WL_2 = 1000;

    uint256 public constant MAX_PRESALE = 1500;
    uint256 public MAX_PRESALE_ALLOWANCE = 2;

    uint256 public constant MAX_SALE_ALLOWANCE = 50;

    address team1Address;
    address team2Address;
    address team3Address;

    address degenGang;

    uint256 public price;
    uint256 public totalPresaleSupply;

    bytes32 public merkleRoot;

    bool public hasBreedMintStarted = false;
    bool public breedMintOver = false;
    bool public hasPreSaleStarted = false;
    bool public preSaleOver = false;
    bool public hasSaleStarted = false;

    mapping(uint256 => bool) public tokenIdToIsUsed;
    mapping(address => bool) public userToPresaleMinted;

    uint256 public breedWhitelistCount;

    constructor(string memory baseURI_, bytes32 _merkleRoot)
        ERC721A("DegenGangBeastsNFT", "DGB1", MAX_SALE_ALLOWANCE, MAX_DGB)
    {
        price = 0.05 ether;
        team1Address = 0x8d0A5BAff67AA982df20bb93d9aE38AC358BA807;
        team2Address = 0xd5a3383773a45dE394502092f17E9e4F50bf710A;
        team3Address = 0x5F058DCcffB7862566aBe44F85d409823F5ce921;

        degenGang = 0x45ebB5FE718F40052fB2DC2463C13717b7b72768;

        _baseTokenURI = baseURI_;

        merkleRoot = _merkleRoot;
    }

    function breedMint(uint8 _quantity) external payable {
        require(numberMinted(msg.sender) == 0, "DegenGangBeastsNFT::breedMint: You have already used Breed minting.");
        require(hasBreedMintStarted, "DegenGangBeastsNFT::breedMint: Breed minting hasn't started.");
        require(!breedMintOver, "DegenGangBeastsNFT::breedMint: Breed minting is over, no more allowances.");
        require(_quantity <= MAX_BREED_ALLOWANCE, "DegenGangBeastsNFT::breedMint: You are allowed buy 2 Beasts max.");

        if (_quantity > 0) {
            require(
                _quantity == 1 ? breedWhitelistCount <= MAX_BREED_WL_2 : true,
                "DegenGangBeastsNFT::breedMint: No more Whitelist spots."
            );
            require(
                _quantity == 2 ? breedWhitelistCount <= MAX_BREED_WL : true,
                "DegenGangBeastsNFT::breedMint: No more Whitelist spots."
            );
            require(
                msg.value >= price * _quantity,
                "DegenGangBeastsNFT::breedMint: Ether value sent is below the price."
            );
            breedWhitelistCount = breedWhitelistCount.add(1);
        }

        uint256[] memory tokensOfUser = IDegenGang(degenGang).getTokensOfOwner(msg.sender);

        uint256 breedQuantity;

        bool isPrevId = false;
        uint256 prevIdIndex;

        for (uint256 i = 0; i < tokensOfUser.length; i++) {
            bool isUsed = tokenIdToIsUsed[tokensOfUser[i]];

            if (isPrevId && !isUsed) {
                breedQuantity++;
                tokenIdToIsUsed[tokensOfUser[i]] = true;
                tokenIdToIsUsed[tokensOfUser[prevIdIndex]] = true;
                isPrevId = false;
            } else if (!isUsed) {
                isPrevId = true;
                prevIdIndex = i;
            }
        }

        require(breedQuantity > 0, "DegenGangBeastsNFT::breedMint:You can't breed or mint any beast.");

        _safeMint(msg.sender, breedQuantity + _quantity);
    }

    function preMint(uint _quantity, bytes32[] calldata merkleProof) external payable {
        require(hasPreSaleStarted, "DegenGangBeastsNFT::preMint: Presale hasn't started.");
        require(!preSaleOver, "DegenGangBeastsNFT::preMint: Presale is over, no more allowances.");
        require(!userToPresaleMinted[msg.sender], "DegenGangBeastsNFT::preMint: A user can do only one presale mint.");
        require(totalPresaleSupply < MAX_PRESALE, "DegenGangBeastsNFT::preMint: All presale tokens were minted already.");
        require(_quantity > 0, "DegenGangBeastsNFT::preMint: Quantity cannot be zero.");
        require(_quantity <= MAX_PRESALE_ALLOWANCE, "DegenGangBeastsNFT::preMint: Quantity has to be lower or equal to MAX_PRESALE_ALLOWANCE.");
        require(totalSupply() + _quantity <= MAX_DGB, "DegenGangBeastsNFT::preMint: Sold out.");
        require(msg.value * _quantity >= price, "DegenGangBeastsNFT::preMint: Ether value sent is below the price.");

        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), "DegenGangBeastsNFT::preMint: Invalid merkle proof.");

        _safeMint(msg.sender, _quantity);
        userToPresaleMinted[msg.sender] = true;
        totalPresaleSupply = totalPresaleSupply.add(_quantity);
    }

    function mint(uint256 _quantity) external payable {
        require(hasSaleStarted, "DegenGangBeastsNFT::mint: Sale hasn't started.");
        require(_quantity > 0, "DegenGangBeastsNFT::mint: Quantity cannot be zero.");
        require(_quantity <= MAX_SALE_ALLOWANCE, "DegenGangBeastsNFT::mint: Quantity cannot be bigger than MAX_BUYING.");
        require(totalSupply() + _quantity <= MAX_DGB, "DegenGangBeastsNFT::mint: Sold out.");
        require(msg.value >= price * _quantity, "DegenGangBeastsNFT::mint: Ether value sent is below the price.");

        _safeMint(msg.sender, _quantity);
    }

    function mintByOwner(address _to, uint256 _quantity) public onlyOwner {
        require(_quantity > 0, "DegenGangBeastsNFT::mintByOwner: Quantity cannot be zero.");
        require(_quantity <= MAX_SALE_ALLOWANCE, "DegenGangBeastsNFT::mintByOwner: Quantity cannot be bigger than MAX_SALE.");
        require(totalSupply() + _quantity <= MAX_DGB, "DegenGangBeastsNFT::mintByOwner: Sold out.");

        _safeMint(_to, _quantity);
    }

    function batchMintByOwner(
        address[] memory _mintAddressList,
        uint256[] memory _quantityList
    ) external onlyOwner {
        require(_mintAddressList.length == _quantityList.length, "DegenGangBeastsNFT::batchMintByOwner: The length should be same");

        for (uint256 i = 0; i < _mintAddressList.length; i += 1) {
            mintByOwner(_mintAddressList[i], _quantityList[i]);
        }
    }

    function changePreSaleAllowance(uint256 _preSaleAllowance) external onlyOwner {
        MAX_PRESALE_ALLOWANCE = _preSaleAllowance;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function startBreedMint() external onlyOwner {
        require(!hasBreedMintStarted, "DegenGangBeastsNFT::startSale: Breed minting is already active.");
        require(!breedMintOver, "DegenGangBeastsNFT::startSale: Breed minting is over, cannot start again.");

        hasBreedMintStarted = true;
    }

    function pauseBreedMint() external onlyOwner {
        require(hasBreedMintStarted, "DegenGangBeastsNFT::pauseSale: Breed minting is not active.");

        hasBreedMintStarted = false;
    }

    function startPreSale() external onlyOwner {
        require(!preSaleOver, "DegenGangBeastsNFT::startPreSale: Presale is over, cannot start again.");
        require(!hasPreSaleStarted, "DegenGangBeastsNFT::startPreSale: Presale is already active.");
        require(hasBreedMintStarted || breedMintOver, "DegenGangBeastsNFT::startPreSale: Breed minting should be active first.");

        hasPreSaleStarted = true;

        if (!breedMintOver) {
            hasBreedMintStarted = false;
            breedMintOver = true;
        }
    }

    function pausePreSale() external onlyOwner {
        require(hasPreSaleStarted, "DegenGangBeastsNFT::pausePreSale: Presale is not active.");

        hasPreSaleStarted = false;
    }

    function startSale() external onlyOwner {
        require(!hasSaleStarted, "DegenGangBeastsNFT::startSale: Sale is already active.");
        require(hasPreSaleStarted || preSaleOver, "DegenGangBeastsNFT::startSale: Presale should be active first.");

        hasSaleStarted = true;
        if (!preSaleOver) {
            hasPreSaleStarted = false;
            preSaleOver = true;
        }
    }

    function pauseSale() external onlyOwner {
        require(hasSaleStarted, "DegenGangBeastsNFT::pauseSale: Sale is not active.");

        hasSaleStarted = false;
    }

    function setTeam1Address(address _team1Address) external onlyOwner {
        team1Address = _team1Address;
    }

    function setTeam2Address(address _team2Address) external onlyOwner {
        team2Address = _team2Address;
    }

    function setTeam3Address(address _team3Address) external onlyOwner {
        team3Address = _team3Address;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    function withdrawETH() external onlyOwner {
        uint256 totalBalance = address(this).balance;
        uint256 team3Amount = totalBalance;

        uint256 team1Amount = (totalBalance * 9000) / 10000; // 90%
        uint256 team2Amount = (totalBalance * 500) / 10000; // 5%
        team3Amount = team3Amount - team1Amount - team2Amount; // 5%

        (bool withdrawTeam1, ) = team1Address.call{value: team1Amount}("");
        require(withdrawTeam1, "Withdraw Failed To Team 1 address.");

        (bool withdrawTeam2, ) = team2Address.call{value: team2Amount}("");
        require(withdrawTeam2, "Withdraw Failed To Team 2 address.");

        (bool withdrawTeam3, ) = team3Address.call{value: team3Amount}("");
        require(withdrawTeam3, "Withdraw Failed To Team 3 address.");
    }
}