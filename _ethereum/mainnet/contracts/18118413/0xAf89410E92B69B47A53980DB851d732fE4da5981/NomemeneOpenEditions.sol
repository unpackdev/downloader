// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Supply.sol";
import "./Ownable.sol";
import "./ERC2981.sol";
import "./IERC721.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract NomemeneOpenEditions is ERC1155Supply, Ownable, ERC2981, ReentrancyGuard {

    address public pieContractAddress = 0xfb5aceff3117ac013a387D383fD1643D573bd5b4;

    uint96 private royaltyBps = 1000;
    address public split;
    mapping(address => bool) private gifters;

    string public baseURI;
    bool public mintPaused = true;

    uint256[] public editionIds;
    uint256[] public amounts;

    uint256 public numEditions = 10;
    uint256 public pieDiscountPct = 10;

    uint256 public whitelistDiscountPct = 10;

    uint256 public setDiscountPct = 30;

    uint256 public basePrice = 0.0123 ether;

    uint256 public mintDuration = 5 days;
    uint256 public startTime;

    bytes32 public whitelistMerkleRoot;
    bool public whitelistOnly = true;

    modifier onlyGifter() {
        require(gifters[_msgSender()] || owner() == _msgSender(), "Not a gifter");
        _;
    }

    constructor() ERC1155("") {
        editionIds = new uint256[](numEditions);
        amounts = new uint256[](numEditions);

        for (uint256 i = 0; i < numEditions; i++) {
            editionIds[i] = i;
            amounts[i] = 1;
        }
    }

    function checkPieHolder(address user) public view returns (bool) {
        IERC721 pieContract = IERC721(pieContractAddress);
        bool hasPie = pieContract.balanceOf(user) > 0;
        return hasPie;
    }

    function updateSplitAddress(address _address) public onlyOwner {
        split = _address;
        _setDefaultRoyalty(split, royaltyBps);
    }

    function updateWhitelistOnly(bool _whitelistOnly) public onlyOwner {
        whitelistOnly = _whitelistOnly;
    }

    function updatePieContractAddress(address _address) public onlyOwner {
        pieContractAddress = _address;
    }

    function updatePieDiscountPct(uint256 _discountPct) public onlyOwner {
        pieDiscountPct = _discountPct;
    }

    function updateSetDiscountPct(uint256 _discountPct) public onlyOwner {
        setDiscountPct = _discountPct;
    }

    function updateWhitelistDiscountPct(uint256 _discountPct) public onlyOwner {
        whitelistDiscountPct = _discountPct;
    }

    function updateBasePrice(uint256 newPrice) public onlyOwner {
        basePrice = newPrice;
    }

    function updateMintPaused(bool paused) public onlyOwner {
        mintPaused = paused;

        if(!mintPaused) {
            startTime = block.timestamp;
        }
    }

    function updateMerkleRoot(bytes32 _whitelistMerkleRoot) public onlyOwner {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    function updateMintDuration(uint256 duration) public onlyOwner {
        mintDuration = duration;
    }

    function updateNumEditions(uint256 newNumEditions) public onlyOwner {
        numEditions = newNumEditions;
    }

    function updateBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function _verifyWhitelist(address account, bytes32[] memory merkleProof) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(account));
        return MerkleProof.verify(merkleProof, whitelistMerkleRoot, leaf);
    }

    function checkPrice(bool whitelisted, uint256 quantity, address user) public view returns (uint256) {
        bool hasPie = checkPieHolder(user);

        uint256 total = basePrice * quantity;

        uint256 discountPct = 0;

        if(hasPie) {
            discountPct += pieDiscountPct;
        }

        if(quantity == numEditions) {
            discountPct += setDiscountPct;
        }

        if(whitelisted) {
            discountPct += whitelistDiscountPct;
        }

        uint256 discountAmt = (total * discountPct) / 100;

        total -= discountAmt;

        return total;
    }

    function checkMintOpen() public view returns (bool) {
        return !mintPaused && (startTime + mintDuration) > block.timestamp;
    }

    function mintEditionWL(uint256 editionId, uint256 quantity, bytes32[] calldata merkleProof) public payable nonReentrant {
        bool mintOpen = checkMintOpen();
        
        require(mintOpen == true, "Mint is not open");
        require(editionId >= 0 && editionId < numEditions, "Invalid editionId");
        require(_verifyWhitelist(msg.sender, merkleProof), "invalid proof");

        uint256 totalPrice = checkPrice(true, quantity, msg.sender);
        require(msg.value == totalPrice, "Did not send correct amount");

        _mintEdition(editionId, quantity, msg.sender);
    }

    function mintSetWL(bytes32[] calldata merkleProof) public payable nonReentrant {
        bool mintOpen = checkMintOpen();

        require(mintOpen == true, "Mint is not open");

        require(_verifyWhitelist(msg.sender, merkleProof), "invalid proof");

        uint256 totalPrice = checkPrice(true, numEditions, msg.sender);
        require(msg.value == totalPrice, "Did not send correct amount");  

        _mintSet(msg.sender);
    }

    function mintEditionPublic(uint256 editionId, uint256 quantity) public payable nonReentrant {
        bool mintOpen = checkMintOpen();

        require(mintOpen == true, "Mint is not open");
        require(whitelistOnly == false, "Whitelist mint only");
        require(editionId >= 0 && editionId < numEditions, "Invalid editionId");

        uint256 totalPrice = checkPrice(false, quantity, msg.sender);
        require(msg.value == totalPrice, "Did not send correct amount");

        _mintEdition(editionId, quantity, msg.sender);
    }

    function mintSetPublic() public payable nonReentrant {
        bool mintOpen = checkMintOpen();

        require(mintOpen == true, "Mint is not open");
        require(whitelistOnly == false, "Whitelist mint only");

        uint256 totalPrice = checkPrice(false, numEditions, msg.sender);
        require(msg.value == totalPrice, "Did not send correct amount");

        _mintSet(msg.sender);
    }

    function _mintEdition(uint256 editionId, uint256 quantity, address to) internal {
        _mint(to, editionId, quantity, "");
    }

    function _mintSet(address to) internal {
        _mintBatch(to, editionIds, amounts, "");
    }

    function addGifter(address gifter) public onlyOwner nonReentrant {
        gifters[gifter] = true;
    }

    function giftEdition(uint256 editionID, address[] memory recipients) public onlyGifter {
        require(editionID >= 0 && editionID < numEditions, "Invalid editionId");

        for (uint256 i = 0; i < recipients.length; i++) {
            _mintEdition(editionID, 1, recipients[i]);
        }
    }

    function giftSet(address[] memory recipients) public onlyGifter {
        for (uint256 i = 0; i < recipients.length; i++) {
            _mintSet(recipients[i]);
        }
    }

    function uri(uint256 editionID) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(editionID)));
    }

    function withdraw() public onlyOwner {
        require(split != address(0), "split address not set");

        (bool success, ) = split.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}