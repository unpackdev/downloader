pragma solidity ^0.8.4;
//import "./Initializable.sol";
import "./ERC721Upgradeable.sol";
import "./OwnableUpgradeable.sol";

import "./MerkleProofUpgradeable.sol";

//import "./ERC721EnumerableUpgradeable.sol";

import "./erc721enum.sol";

//import "./ERC721.sol";
//import "./Initializable.sol";
// import "./ERC721Full.sol";
// import "./ERC721Mintable.sol";

interface ContractInterface {
    function balanceOf(address owner) external view returns (uint256 number);
}

contract NFZ is OwnableUpgradeable, ERC721EnumerableUpgradeable {
    uint256 constant MAX_INIT_SUPPLY = 8001;
    uint256 constant MAXSUPPLY = 10001;
    uint256 constant MAX_PRE_MINT = 4;
    uint256 constant MINT_PRICE = .06 ether;
    uint256 constant WHITELIST_MINT_PRICE = .05 ether;
    uint256 constant HALF_MINT_PRICE = .03 ether;
    bool public isPresale;
    bool public isLaunched;
    bytes32 private Whitelist_Root;
    uint256 constant hasInitialValue = 42; // define as constant
    bytes32 private HalfMintRoot;
    bytes32 private uniCandyRoot;
    uint256 private value;

    string baseURI;
    mapping(address => bool) public preSaleMapping;

    //Where your zombie goes will be stored on the blockchain
    //coming in phase 2.0
    mapping(uint256 => Locations[]) public passport;
    struct Locations {
        string locationName;
        uint256 locationId;
    }

    //init function called on deploy

    function init(
        bytes32 wlroot,
        bytes32 hmroot,
        string memory _base
    ) public initializer {
        // MAX_INIT_SUPPLY = 8001;
        // MAXSUPPLY = 10001;
        // MAX_PRE_MINT = 4;
        // MINT_PRICE = .06 ether;
        // HALF_MINT_PRICE = .03 ether;
        isPresale = false;
        isLaunched = false;
        Whitelist_Root = wlroot;
        HalfMintRoot = hmroot;
        __ERC721_init("Nice Fun Zombies", "NFZ");
        __ERC721Enumerable_init();
        __Ownable_init();

        baseURI = _base;
    }

    function giveways(address[] memory freeNFZ) external onlyOwner {
        uint256 counter = totalSupply();
        for (uint256 i = 1; i <= freeNFZ.length; i++) {
            address winner = freeNFZ[i - 1];
            _safeMint(winner, counter + i);
        }
    }

    //owner can mint after deploy
    function teamMint(uint256 amount) external onlyOwner {
        uint256 counter = totalSupply();

        for (uint256 i = 1; i < amount + 1; i++) {
            _safeMint(msg.sender, counter + i);
        }
    }

    //to toggle general sale
    function launchToggle() public onlyOwner {
        isLaunched = !isLaunched;
    }

    //to toggle presale
    function presaleToggle() public onlyOwner {
        isPresale = !isPresale;
    }

    function NFTholderPresale(address account, uint256 _mintAmount)
        external
        payable
    {
        uint256 _mintPrice;
        if (
            ContractInterface(0x4F8730E0b32B04beaa5757e5aea3aeF970E5B613)
                .balanceOf(account) > 0
        ) {
            _mintPrice = .05 ether;
        } else if (
            ContractInterface(0xba30E5F9Bb24caa003E9f2f0497Ad287FDF95623)
                .balanceOf(account) > 0
        ) {
            _mintPrice = .06 ether;
        } else if (
            ContractInterface(0x60E4d786628Fea6478F785A6d7e704777c86a7c6)
                .balanceOf(account) > 0
        ) {
            _mintPrice = .06 ether;
        } else if (
            ContractInterface(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D)
                .balanceOf(account) > 0
        ) {
            _mintPrice = .06 ether;
        } else {
            revert("not part of pre-sale group");
        }

        // balance = ApeInterface(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D)
        //     .balanceOf(account);
        uint256 counter = totalSupply();
        require(
            _mintAmount < MAX_PRE_MINT,
            "Going for too many during presale!"
        );
        require(!preSaleMapping[account], "already minted");

        require(
            counter + _mintAmount < MAX_INIT_SUPPLY,
            "exceeds contract limit"
        );

        require(
            msg.value >= _mintPrice * _mintAmount,
            "Not enough eth sent: check price"
        );
        require(isPresale, "pre sale not active");
        for (uint256 i = 1; i < _mintAmount + 1; i++) {
            _safeMint(account, counter + i);
        }
        preSaleMapping[account] = true;
    }

    //general mint function - checks to make sure launch = true;
    function mint(address account, uint256 _mintAmount) external payable {
        uint256 counter = totalSupply();
        require(isLaunched, "general mint has not started");
        require(
            counter + _mintAmount < MAX_INIT_SUPPLY,
            "exceeds contract limit"
        );
        require(counter + _mintAmount < MAXSUPPLY, "overboard warning!");
        require(
            msg.value >= MINT_PRICE * _mintAmount,
            "Not enough eth sent: check price"
        );
        require(_mintAmount < 7, "Only mint 6. Leave some for the rest!");

        for (uint256 i = 1; i < _mintAmount + 1; i++) {
            _safeMint(account, counter + i);
        }
        preSaleMapping[account] = true;
    }

    //for those that quality for half mint price
    function presaleHalfMint(
        address account,
        bytes32[] calldata proof,
        uint256 _mintAmount
    ) external payable {
        uint256 counter = totalSupply();
        require(isPresale, "pre sale is not active");
        require(
            MerkleProofUpgradeable.verify(proof, HalfMintRoot, _leaf(account)),
            "account not part of whitelist"
        );
        require(!preSaleMapping[account], "already minted");
        require(
            counter + _mintAmount < MAX_INIT_SUPPLY,
            "exceeds contract limit"
        );
        require(_mintAmount < MAX_PRE_MINT, "trying to get too many zombies");
        require(
            msg.value >= HALF_MINT_PRICE * _mintAmount,
            "Not enough eth sent: check price"
        );

        for (uint256 i = 1; i < _mintAmount + 1; i++) {
            _safeMint(account, counter + i);
        }

        preSaleMapping[account] = true;
    }

    //general whitelist pre sale
    function preSaleWhitelist(
        address account,
        bytes32[] calldata proof,
        uint256 _mintAmount
    ) external payable {
        uint256 counter = totalSupply();
        require(isPresale, "pre sale is not active");
        require(
            MerkleProofUpgradeable.verify(
                proof,
                Whitelist_Root,
                _leaf(account)
            ),
            "account not part of whitelist"
        );
        // require(
        //     _verify(_leaf(account), proof, preSaleRoot),
        //     "not part of prelist"
        // );
        require(!preSaleMapping[account], "already minted");
        require(
            counter + _mintAmount < MAX_INIT_SUPPLY,
            "exceeds contract limit"
        );
        require(_mintAmount < MAX_PRE_MINT, "trying to get too many zombies");
        require(
            msg.value >= WHITELIST_MINT_PRICE * _mintAmount,
            "Not enough eth sent: check price"
        );
        for (uint256 i = 1; i < _mintAmount + 1; i++) {
            _safeMint(account, counter + i);
        }

        preSaleMapping[account] = true;
    }

    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function contractURI() public pure returns (string memory) {
        return "https://api.nicefunzombies.io/contract";
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function updatePresaleRoot(string memory presaleType, bytes32 root)
        external
        onlyOwner
    {
        if (
            keccak256(abi.encodePacked(presaleType)) ==
            keccak256(abi.encodePacked("presaleRoot"))
        ) {
            Whitelist_Root = root;
        } else if (
            keccak256(abi.encodePacked(presaleType)) ==
            keccak256(abi.encodePacked("presaleHalfMint"))
        ) {
            HalfMintRoot = root;
        } else if (
            keccak256(abi.encodePacked(presaleType)) ==
            keccak256(abi.encodePacked("uniCandyRoot"))
        ) {
            uniCandyRoot = root;
        } else {
            revert("Incorrect presaleType");
        }
    }
}
