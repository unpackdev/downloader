// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC2981.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./Address.sol";
import "./Strings.sol";
import "./ERC721AQueryable.sol";
import "./IERC721A.sol";
import "./console.sol";

interface IMedicine is IERC1155 {
    function burnGolden(address who, uint256 amount) external;

    function burnGreen(address who, uint256 amount) external;
}

interface IIQCoine {
    function playerClaim(address holder, uint256 amount) external;
}

contract CryptoIdiotsGraveDeed is ERC2981, ERC721AQueryable, Ownable {
    event Mint(address indexed _from, MintType _type, uint256 _amount);

    using Address for address payable;
    using Strings for uint256;

    enum MintType {
        LEGENDADRY,
        GENESIS,
        NORMAL
    }

    enum Stage {
        NOT_STARTED,
        PARALLEL_MINT,
        GENESIS_CLAIM,
        LEGENDARY_CLAIM,
        PUBLIC_MINT,
        GENESIS_MINT
    }

    address private constant BLACKHOLE =
        0x000000000000000000000000000000000000dEaD;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant PARALLEL_PUBLIC_SUPPLY = 6000;
    uint256 public constant PARALLEL_GENESIS_SUPPLY = 2000;
    uint256 public constant PARALLEL_LEGENDARY_SUPPLY = 1000;
    uint256 public constant TEAM_SUPPLY = 1000;

    uint256 public constant PUBLIC_WALLET_LIMIT = 20;
    uint256 public constant PUBLIC_SALE_PRICE = 0.025 ether;

    uint256 public constant GENESIS_PRICE = 0.05 ether;
    uint256 public constant GENESIS_BURN_GREEN_AMOUNT = 2;

    uint256 public constant CLAIM_COIN = 50_000 ether;
    uint256 public constant LEGENDARY_COIN_BONUS = 4;

    uint256 public teamMinted;
    uint256 public genesisMinted;
    uint256 public legendaryMinted;
    uint256 public rareMinted;

    Stage public stage = Stage.NOT_STARTED;

    string public baseURI;

    IERC721AQueryable private immutable idiotContract;
    IMedicine private immutable medicineContract;
    IIQCoine private immutable coinContract;

    mapping(address => uint256) private publicWalletMinted;

    constructor(
        address _baseAddress,
        address _medicineAddress,
        address _iqAddress,
        string memory _baseURI
    ) ERC721A("CryptoIdiotsGraveDeed", "CIGD") {
        idiotContract = IERC721AQueryable(_baseAddress);
        medicineContract = IMedicine(_medicineAddress);
        coinContract = IIQCoine(_iqAddress);
        baseURI = _baseURI;
        setFeeNumerator(800);
    }

    function mintGenesis(uint256[] memory tokenIds) external payable {
        require(
            tokenIds.length > 0 && tokenIds.length % 2 == 0,
            "Require Even Number Of Tokens"
        );
        uint256 amount = tokenIds.length / 2;
        require(
            stage == Stage.GENESIS_MINT || stage == Stage.PARALLEL_MINT,
            "Genesis Mint Not Started"
        );
        require(amount + publicMinted() <= publicSupply(), "Exceed Max Supply");
        if (stage == Stage.PARALLEL_MINT) {
            require(
                amount + genesisMinted <= PARALLEL_GENESIS_SUPPLY,
                "Exceed Max Supply"
            );
        }
        uint256 requiredFunds = GENESIS_PRICE * amount;
        require(msg.value >= requiredFunds, "Insufficient Fund");
        for (uint256 i = 0; i < tokenIds.length; ) {
            require(
                idiotContract.ownerOf(tokenIds[i]) == msg.sender,
                "No Auth"
            );
            idiotContract.transferFrom(msg.sender, BLACKHOLE, tokenIds[i]);
            unchecked {
                i++;
            }
        }
        coinContract.playerClaim(msg.sender, amount * CLAIM_COIN);
        emit Mint(msg.sender, MintType.GENESIS, amount);
        genesisMinted += amount;
        _safeMint(msg.sender, amount);
        if (msg.value > requiredFunds) {
            payable(msg.sender).sendValue(msg.value - requiredFunds);
        }
    }

    function claimGenesis(uint256[] memory tokenIds) external {
        require(
            tokenIds.length > 0 && tokenIds.length % 2 == 0,
            "Require Even Number Of Tokens"
        );
        uint256 amount = tokenIds.length / 2;
        require(
            stage == Stage.GENESIS_CLAIM || stage == Stage.PARALLEL_MINT,
            "Claim Not Started"
        );
        require(
            medicineContract.balanceOf(msg.sender, 1) >=
                tokenIds.length * GENESIS_BURN_GREEN_AMOUNT,
            "Insufficient Green Potions"
        );
        require(amount + publicMinted() <= publicSupply(), "Exceed Max Supply");
        if (stage == Stage.PARALLEL_MINT) {
            require(
                amount + genesisMinted <= PARALLEL_GENESIS_SUPPLY,
                "Exceed Max Supply"
            );
        }
        for (uint256 i = 0; i < tokenIds.length; ) {
            require(
                idiotContract.ownerOf(tokenIds[i]) == msg.sender,
                "No auth"
            );
            idiotContract.transferFrom(msg.sender, BLACKHOLE, tokenIds[i]);
            unchecked {
                i++;
            }
        }
        medicineContract.burnGreen(
            msg.sender,
            tokenIds.length * GENESIS_BURN_GREEN_AMOUNT
        );
        genesisMinted += amount;
        emit Mint(msg.sender, MintType.GENESIS, amount);
        coinContract.playerClaim(msg.sender, CLAIM_COIN * amount);
        _safeMint(msg.sender, amount);
    }

    function claimLegendary(uint256[] memory tokenIds) external {
        //console.log(baseContract.ownerOf(tokenIds[0]));
        uint256 amount = tokenIds.length;
        require(
            stage == Stage.PARALLEL_MINT || stage == Stage.LEGENDARY_CLAIM,
            "Claim Not Started"
        );
        require(
            medicineContract.balanceOf(msg.sender, 0) >= amount,
            "Insufficient potions"
        );
        require(amount + publicMinted() <= publicSupply(), "Exceed Max Supply");
        if (stage == Stage.PARALLEL_MINT) {
            require(
                amount + legendaryMinted <= PARALLEL_LEGENDARY_SUPPLY,
                "Exceed Max Supply"
            );
        }
        for (uint256 i = 0; i < tokenIds.length; ) {
            require(
                idiotContract.ownerOf(tokenIds[i]) == msg.sender,
                "No auth"
            );
            idiotContract.transferFrom(msg.sender, BLACKHOLE, tokenIds[i]);
            unchecked {
                i++;
            }
        }
        medicineContract.burnGolden(msg.sender, amount);
        legendaryMinted += amount;
        emit Mint(msg.sender, MintType.LEGENDADRY, amount);
        coinContract.playerClaim(
            msg.sender,
            amount * CLAIM_COIN * LEGENDARY_COIN_BONUS
        );
        _safeMint(msg.sender, amount);
    }

    function publicMint(uint256 amount) external payable {
        require(
            stage == Stage.PUBLIC_MINT || stage == Stage.PARALLEL_MINT,
            "mint not started"
        );
        uint256 walletMinted = publicWalletMinted[msg.sender];
        if (amount + walletMinted > PUBLIC_WALLET_LIMIT) {
            amount = PUBLIC_WALLET_LIMIT - walletMinted;
        }
        if (stage == Stage.PUBLIC_MINT) {
            uint256 _publicMinted = publicMinted();
            uint256 _publicSupply = publicSupply();
            if (_publicMinted + amount > _publicSupply) {
                amount = _publicSupply - _publicMinted;
            }
        } else if (stage == Stage.PARALLEL_MINT) {
            if (rareMinted + amount > PARALLEL_PUBLIC_SUPPLY) {
                amount = PARALLEL_PUBLIC_SUPPLY - rareMinted;
            }
            if (amount + publicMinted() > publicSupply()) {
                amount = publicSupply() - publicMinted();
            }
        }
        require(amount > 0, "Exceed wallet limit");
        uint256 requiredFunds = amount * PUBLIC_SALE_PRICE;
        require(msg.value >= requiredFunds, "Insufficient fund");
        emit Mint(msg.sender, MintType.NORMAL, amount);
        rareMinted += amount;
        publicWalletMinted[msg.sender] += amount;
        _safeMint(msg.sender, amount);
        if (msg.value > requiredFunds) {
            payable(msg.sender).sendValue(msg.value - requiredFunds);
        }
    }

    function publicMinted() public view returns (uint256) {
        return _totalMinted() - teamMinted;
    }

    function publicSupply() public pure returns (uint256) {
        return MAX_SUPPLY - TEAM_SUPPLY;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981, ERC721A)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // done
    function teamMint(
        address to,
        uint32 amount,
        MintType mintType
    ) external onlyOwner {
        teamMinted += amount;
        require(teamMinted <= TEAM_SUPPLY, "Exceed max supply");
        emit Mint(to, mintType, amount);
        _safeMint(to, amount);
    }

    function setFeeNumerator(uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(owner(), feeNumerator);
    }

    function setStage(Stage s) external onlyOwner {
        stage = s;
    }

    function setMetadataURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).sendValue(address(this).balance);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}
