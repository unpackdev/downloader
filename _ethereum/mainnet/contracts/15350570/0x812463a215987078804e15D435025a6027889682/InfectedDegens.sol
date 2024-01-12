//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./PaymentSplitter.sol";

contract InfectedDegens is ERC721A, Ownable {
    bool public isMintActive = false;

    uint256 public price         = 0 ether;
    uint256 public maxSupply     = 1000;
    uint256 public maxMintsPerTx = 5;
    uint256 public maxMintsTotal = 5;

    string internal _baseTokenURI;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    uint256 private _royaltyAmount = 1000; // 10%

    address public aMulti = 0x4e1456eed1729d977Cec20221DE684812a4347e9;

    struct Whitelist {
        bool isActive;
        uint256 price;
        uint256 maxMints;
        bytes32 merkleRoot;
    }

    Whitelist[] internal _whitelists;

    mapping(uint256 => mapping(address => uint256)) internal _whitelistsMints;

    constructor(string memory baseTokenURI) ERC721A("Infected Degens", "DEGENS") {
        _baseTokenURI = baseTokenURI;
    }


    //----------------------------------------
    // Mint / Ownership (public)
    //----------------------------------------

    function tokensOf(address _owner) public view returns (uint256[] memory) {
        uint256[] memory tokens = new uint256[](balanceOf(_owner));
        uint256 ctr = 0;
        for (uint256 i = 0; i < totalSupply(); i++) {
            if (ownerOf(i) == _owner) {
                tokens[ctr] = i;
                ctr++;
            }
        }
        return tokens;
    }

    function numberMintedOf(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }

    function mint(uint256 qty) external payable {
        require(isMintActive, "Mint isn't active");
        require(_numberMinted(msg.sender) + qty <= maxMintsTotal, "Exceeds mint limit");
        require(qty <= maxMintsPerTx && qty > 0, "Qty of mints not allowed");
        require(qty + totalSupply() <= maxSupply, "Exceeds total supply");
        require(msg.value == price * qty, "Invalid value");

        _safeMint(msg.sender, qty);
    }

    function mintWhitelist(uint256 whitelistIndex, uint256 qty, bytes32[] calldata merkleProof) external payable {
        Whitelist memory wl = _whitelists[whitelistIndex];

        require(wl.isActive, "Whitelist isn't active");
        require(_numberMinted(msg.sender) + qty <= maxMintsTotal, "Exceeds mint limit");
        require(qty <= maxMintsPerTx && qty > 0, "Qty of mints not allowed");
        require(qty + totalSupply() <= maxSupply, "Exceeds total supply");
        require(msg.value == wl.price * qty, "Invalid value");
        require(_whitelistsMints[whitelistIndex][msg.sender] + qty <= wl.maxMints, "Exceeds whitelist mint limit");

        require(MerkleProof.verify(
                merkleProof,
                wl.merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ), "Criteria not on the whitelist");

        _safeMint(msg.sender, qty);
        _whitelistsMints[whitelistIndex][msg.sender] += qty;
    }


    //----------------------------------------
    // Whitelist (public)
    //----------------------------------------

    function whitelists() public view returns (Whitelist[] memory) {
        return _whitelists;
    }

    function whitelistMintsOf(uint256 whitelistIndex, address minterAddress) public view returns (uint256) {
        return _whitelistsMints[whitelistIndex][minterAddress];
    }

    function whitelistValidateMerkleProof(uint256 whitelistIndex, address minterAddress, bytes32[] calldata merkleProof) public view returns (bool) {
        Whitelist memory wl = _whitelists[whitelistIndex];

        return MerkleProof.verify(
            merkleProof,
            wl.merkleRoot,
            keccak256(abi.encodePacked(minterAddress))
        );
    }


    //----------------------------------------
    // Royalty (public)
    //----------------------------------------

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        return (aMulti, ((_salePrice * _royaltyAmount) / 10000));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A) returns (bool) {
        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }


    //----------------------------------------
    // Misc (owner)
    //----------------------------------------

    function getBaseTokenURI() public view onlyOwner returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseTokenURI(string calldata uri) external onlyOwner {
        _baseTokenURI = uri;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setMaxSupply(uint256 newSupply) external onlyOwner {
        maxSupply = newSupply;
    }

    function toggleMintActive() external onlyOwner {
        isMintActive = !isMintActive;
    }

    function setMaxMintsPerTx(uint256 newMax) external onlyOwner {
        maxMintsPerTx = newMax;
    }

    function setMaxMintsTotal(uint256 newMax) external onlyOwner {
        maxMintsTotal = newMax;
    }

    // Mint
    function giveaway(address[] calldata adds, uint256 qty) external onlyOwner {
        uint256 minted = totalSupply();

        require((adds.length * qty) + minted <= maxSupply, "Value exceeds total supply");

        for (uint256 i = 0; i < adds.length; i++) {
            _safeMint(adds[i], qty);
        }
    }

    // Whitelist
    function whitelistCreate(bool isActive, uint256 whitelistPrice, uint256 whitelistMaxMints, bytes32 merkleRoot) external onlyOwner {
        Whitelist storage whitelist = _whitelists.push();

        whitelist.isActive = isActive;
        whitelist.price = whitelistPrice;
        whitelist.maxMints = whitelistMaxMints;
        whitelist.merkleRoot = merkleRoot;
    }

    function whitelistToggleActive(uint256 whitelistIndex) external onlyOwner {
        _whitelists[whitelistIndex].isActive = !_whitelists[whitelistIndex].isActive;
    }

    function whitelistSetPrice(uint256 whitelistIndex, uint256 newPrice) external onlyOwner {
        _whitelists[whitelistIndex].price = newPrice;
    }

    function whitelistSetMaxMints(uint256 whitelistIndex, uint256 maxMints) external onlyOwner {
        _whitelists[whitelistIndex].maxMints = maxMints;
    }

    function whitelistSetMerkleRoot(uint256 whitelistIndex, bytes32 merkleRoot) external onlyOwner {
        _whitelists[whitelistIndex].merkleRoot = merkleRoot;
    }

    // Withdraw
    function withdrawTeam() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);

        _widthdraw(aMulti, address(this).balance);
    }

    function emergencyWithdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);

        payable(aMulti).transfer(balance);
    }


    //----------------------------------------
    // Internal
    //----------------------------------------

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

}