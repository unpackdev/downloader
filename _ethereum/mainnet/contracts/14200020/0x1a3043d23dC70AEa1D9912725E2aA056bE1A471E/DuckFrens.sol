// DuckFrens (www.duckfrens.com)

// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0O0KXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMNK0OxxOOOO00KKNWMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMNKOO0KXXXXXXXK000K0KNMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMNKOOKXXXXXXXXXXXXXXNXK0KNMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMN0OOKXXXXXXXXXXXXXXXXXNNN0OXWMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMXkdOXXXXXXXXXXXXXXXXXXXXXNN0OXWMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMXkdOKXXXXXXXNNNNXXXXXXXXXXXXXkkNMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMWOdOKXXXXXKkddkOKNNXXXXXXXXX0dodkXMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMKxkKXXXXX0d;;oxld0XXXXXXXXXXkclxd0MMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMXxdkKXXXXXk:,;ooc:dKXXXXXXXXXOc;;cOWMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMXddOKXXXXXk:,,,,,;dKXX0OOkxxxdl:cdO0XWMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMXdoOKXXXXX0xlcccldOKkdoolllooooooodokNMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMNkdk0KXXXXXK0OO0KKOdooddoooodddddxxlxNMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMN0kkOKXXXXXXXXXXXxlllooddddddxkkkkkKWMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMWKxoxOKXXXXXXXXXKOxdllllllllloxkKWMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMN0OkxxdxxxkkO0KXKKKK0OkxdollloOXWMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMN0OOKK0OOkkxdddxxxddddddddddxkkkkKNMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMWKkk0KKXXKK00OOOOkkkkkkkkkkkOOOOOOOO0KWMMMMMMMMMMMMMMM
// MMMMMMMMMMN00K000xxOO0KXXXXXXKKK00000000000000000KKNXO0WMMMMMMMMMMMMMM
// MMMMMMMMMMKdoolcldkOKKKKKKXXXXXXKKKKXXXXXXXXXXXXXXKKXXO0WMMMMMMMMMMMMM
// MMMMMMMMMMXxxkoccdkO0KK00KXKKKKOk0KXXXXXXXXXXXXXXXXKO0kONMMMMMMMMMMMMM
// MMMMMMMMMMWOdkkolodxkOOO0Oxkkkxk0XXXXXXXXXXXXXXXXXXX0ddONMMMMMMMMMMMMM
// MMMMMMMMMMMNOxxxxdoooodxxxdxkO0KKKXXXXXXXXXXXXXXXXXKOkKNMMMMMMMMMMMMMM
// MMMMMMMMMMMMWXOxxkOxdxO0KKKXXXXOx0XXXXXXXXXXXXXXXXKO0NMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMWXOkxold0XXXXXXX0ddk0KKXXXXXXXXXXXK00KWMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMWX0xlxOKXXXX0dlooxxkOO0O000OOkO0XWMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMWKkdxOO0OO0K0OOOOOxlllllllxNMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMWWN0oclookXMMMMMMMMNOlclllo0NNNNWMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMNOxolooloxOOXWMMMMMN0dlcclclxkddkOKWMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMWkccccloc:odlxNMMMMWOlcccc;;cddlcoodKMMMMMMMMMMMMMMMM

// Development help from @lozzereth (www.allthingsweb3.com)

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";

contract DuckFrens is ERC721A, Ownable {
    uint256 public constant MAX_PER_TXN = 10;
    uint256 public constant MAX_SUPPLY = 5000;

    uint256 public mintPrice = 0.045 ether;
    uint256 public publicMintableSupply = 4000;

    constructor() ERC721A("Duck Frens", "DUCK") {}

    modifier hasCorrectAmount(uint256 _wei, uint256 _quantity) {
        require(_wei >= mintPrice * _quantity, "Insufficent funds");
        _;
    }

    modifier withinMaximumSupply(uint256 _quantity, uint256 _supply) {
        require(totalSupply() + _quantity <= _supply, "Surpasses supply");
        _;
    }

    modifier withinMaximumPerTxn(uint256 _quantity) {
        require(
            _quantity > 0 && _quantity <= MAX_PER_TXN,
            "Over maximum per txn"
        );
        _;
    }

    /**
     * Public sale and whitelist sale mechansim
     */
    bool public publicSale = false;

    modifier publicSaleActive() {
        require(publicSale, "Public sale not started");
        _;
    }

    function setPublicSale(bool toggle) external onlyOwner {
        publicSale = toggle;
    }

    /**
     * Public minting
     */
    function mintPublic(uint256 _quantity)
        public
        payable
        publicSaleActive
        hasCorrectAmount(msg.value, _quantity)
        withinMaximumSupply(_quantity, publicMintableSupply)
        withinMaximumPerTxn(_quantity)
    {
        _safeMint(msg.sender, _quantity);
    }

    /**
     * Claim a free mint if you are eligible
     */
    bytes32 public freeMintMerkleRoot;
    mapping(address => bool) public freeMintAddressClaimed;

    modifier hasValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address not eligible"
        );
        _;
    }

    modifier freeMintNotClaimed() {
        require(!freeMintAddressClaimed[msg.sender], "Free already claimed");
        _;
    }

    function setFreeMintMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        freeMintMerkleRoot = merkleRoot;
    }

    /**
     * Claim a free mint if eligible
     */
    function claimFreeMint(bytes32[] calldata merkleProof)
        public
        publicSaleActive
        hasValidMerkleProof(merkleProof, freeMintMerkleRoot)
        withinMaximumSupply(1, MAX_SUPPLY)
        freeMintNotClaimed
    {
        freeMintAddressClaimed[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }

    /**
     * Mint up to 10 per txn, but also include the free mint
     */
    function claimFreeMintWithQuantity(
        uint256 _quantity,
        bytes32[] calldata merkleProof
    )
        public
        payable
        publicSaleActive
        hasValidMerkleProof(merkleProof, freeMintMerkleRoot)
        hasCorrectAmount(msg.value, _quantity)
        withinMaximumSupply(_quantity + 1, publicMintableSupply)
        withinMaximumPerTxn(_quantity)
        freeMintNotClaimed
    {
        freeMintAddressClaimed[msg.sender] = true;
        _safeMint(msg.sender, _quantity + 1);
    }

    /**
     * Admin minting
     */
    function mintAdmin(address _recipient, uint256 _quantity)
        public
        onlyOwner
        withinMaximumSupply(_quantity, MAX_SUPPLY)
    {
        _safeMint(_recipient, _quantity);
    }

    /**
     * Allow adjustment of mintable supply
     */
    function setPublicMintableSupply(uint256 _total) public onlyOwner {
        require(_total <= MAX_SUPPLY, "Over max supply");
        require(_total >= totalSupply(), "Under total minted");
        publicMintableSupply = _total;
    }

    /**
     * Allow adjustment of minting price (in wei)
     */
    function setMintPrice(uint256 _price) public onlyOwner {
        mintPrice = _price;
    }

    /**
     * Base URI
     */
    string private baseURI;

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * Withdrawal
     */
    address private constant address1 =
        0xB614B836C336c9e7d8fC850bE935833f967cdd02;
    address private constant address2 =
        0x5B30516bcB5174E5F295031E0C53d02f1e6ab0a7;

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(address1), balance * 80 / 100);
        Address.sendValue(payable(address2), balance * 20 / 100);
    }
}
