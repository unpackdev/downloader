//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";

contract MeetBob is ERC721Enumerable, Ownable, Pausable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public mintPrice = 0.1 ether;
    uint256 public earlyAccessMintPrice = 0.08 ether;

    uint256 public maxSupply = 10101;
    uint256 public earlyAccessMaxSupply = 3101;

    uint8 public maxPerTransaction = 4;
    uint8 public maxPerWallet = 10;
    uint8 public maxPerWalletEarlyAccess = 4;

    uint256 public earlyAccessWindowOpens = 1645819200;
    uint256 public earlyAccessWindowCloses = 1645905600;
    uint256 public publicSaleWindowOpens = 1645992000;
    uint256 public publicSaleWindowCloses = 1646424000;

    bytes32 public merkleRoot;

    address private constant communityWallet = 0xB680b8c21f885390F2De0f7759C3681E633f1Faa;
    // Team addresses
    address private constant addr1 = 0xFaD54dF4CcDa532FddDf38117326F8a49A4d10c5;
    address private constant addr2 = 0x336c704BC377db46103d443309E9a652eD6AC0F0;
    address private constant addr3 = 0xE62Cc548C172F28C153397512E498Bb3a5B08c74;
    address private constant addr4 = 0xD99f8490b25C21081Ec22A51f5A82930eED4d8eB;
    address private constant addr5 = 0xDc6261f33FC8a28FcD45523fD6C9253726CC1dB0;

    string private baseTokenURI = "";

    mapping(address => bool) isTeam;

    modifier onlyTeam() {
        require(isTeam[msg.sender] == true, "Not part of MeetBob team");
        _;
    }

    constructor(string memory _baseTokenURI, bytes32 _merkleRoot) ERC721("MeetBOB", "BOB") {
        isTeam[addr1] = true;
        isTeam[addr2] = true;
        isTeam[addr3] = true;
        isTeam[addr4] = true;
        isTeam[addr5] = true;

        baseTokenURI = _baseTokenURI;
        merkleRoot = _merkleRoot;

        for (uint256 i; i < 101; i++) {
            _safeMint(communityWallet, i);
        }
    }

    /**
    * @notice edit the mint mintPrice
    *
    * @param _mintPrice the new mintPrice in wei
    */
    function setMintPrice(uint256 _mintPrice) external onlyTeam {
        mintPrice = _mintPrice;
    }

    /**
    * @notice edit the merkle root for early access sale
    *
    * @param _merkleRoot the new merkle root
    */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyTeam {
        merkleRoot = _merkleRoot;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
    * @notice set the base token uri
    *
    * @param _baseTokenURI the new base token uri
    */
    function setBaseURI(string memory _baseTokenURI) public onlyTeam {
        baseTokenURI = _baseTokenURI;
    }

    /**
    * @notice edit sale restrictions
    *
    * @param _maxPerTransaction the new max amount of tokens allowed to buy in one transaction
    * @param _maxPerWallet the max amount of tokens allowed to be minted by one address
    * @param _maxPerWalletEarlyAccess the max amount of tokens allowed to be minted by one address during early access sale
    */
    function editSaleRestrictions(uint8 _maxPerTransaction, uint8 _maxPerWallet, uint8 _maxPerWalletEarlyAccess) external onlyTeam {
        maxPerTransaction = _maxPerTransaction;
        maxPerWallet = _maxPerWallet;
        maxPerWalletEarlyAccess = _maxPerWalletEarlyAccess;
    }

    /**
    * @notice edit max supplies
    *
    * @param _maxSupply the new total max supply
    * @param _earlyAccessMaxSupply the new max supply for the early access sale
    */
    function editSupply(uint256 _maxSupply, uint256 _earlyAccessMaxSupply) external onlyTeam {
        require(_earlyAccessMaxSupply >= totalSupply(), "Early access supply can't be lower than the current total supply");
        require(_maxSupply >= _earlyAccessMaxSupply, "Max supply can't be lower than the early access max supply");

        maxSupply = _maxSupply;
        earlyAccessMaxSupply = _earlyAccessMaxSupply;
    }

    /**
    * @notice edit sale windows
    *
    * @param _earlyAccessWindowOpens UNIX timestamp for early access window opening time
    * @param _earlyAccessWindowCloses UNIX timestamp for early access window closing time
    * @param _publicSaleWindowOpens UNIX timestamp for public sale window opening time
    * @param _publicSaleWindowCloses UNIX timestamp for public sale window closing time
    */
    function editWindows(
        uint256 _earlyAccessWindowOpens,
        uint256 _earlyAccessWindowCloses,
        uint256 _publicSaleWindowOpens,
        uint256 _publicSaleWindowCloses
    ) external onlyTeam {
        require(
            _earlyAccessWindowCloses > _earlyAccessWindowOpens &&
            _publicSaleWindowOpens > _earlyAccessWindowCloses &&
            _publicSaleWindowCloses > _publicSaleWindowOpens,
            "window combination not allowed"
        );

        earlyAccessWindowOpens = _earlyAccessWindowOpens;
        earlyAccessWindowCloses = _earlyAccessWindowCloses;
        publicSaleWindowOpens = _publicSaleWindowOpens;
        publicSaleWindowCloses = _publicSaleWindowCloses;
    }

    /**
    * @notice global purchase function used in early access and public sale
    *
    * @param amount the amount of BOBs to purchase
    */
    function _purchase(uint256 amount) private {
        uint256 supply = totalSupply();
        require(supply + amount <= maxSupply, "Exceeds maximum supply of BOB");

        for (uint256 i; i < amount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    /**
    * @notice purchase during public sale
    *
    * @param amount the amount of BOBs to purchase
    */
    function publicSale(uint256 amount) public payable whenNotPaused {
        require(block.timestamp >= publicSaleWindowOpens && block.timestamp < publicSaleWindowCloses, "Public sale: window closed");
        require(msg.value >= mintPrice * amount, "Ether sent is less than mintPrice * amount");
        require(amount <= maxPerTransaction, "Exceeds maximum tokens per transaction");
        require(balanceOf(msg.sender) + amount <= maxPerWallet, "Exceeds maximum tokens per wallet");

        _purchase(amount);
    }

    /**
    * @notice purchase during early access sale
    *
    * @param amount the amount of BOBs to purchase
    * @param merkleProof the valid merkle proof of sender
    */
    function earlyAccessSale(
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external payable whenNotPaused {
        require(block.timestamp >= earlyAccessWindowOpens && block.timestamp <= earlyAccessWindowCloses, "Early access: window closed");
        require(msg.value >= earlyAccessMintPrice * amount, "Ether sent is less than earlyAccessMintPrice * amount");
        require(totalSupply() + amount <= earlyAccessMaxSupply, "Exceeds maximum early access supply");
        require(balanceOf(msg.sender) < maxPerWalletEarlyAccess, "Exceeds maximum tokens per wallet early access");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, leaf),
            "MerkleDistributor: Invalid proof. "
        );

        _purchase(amount);
    }

    function pause() external onlyTeam {
        _pause();
    }

    function unpause() external onlyTeam {
        _unpause();
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory baseURI = _baseURI();
        string memory json = ".json";
        return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString(), json))
        : '';
    }

    function withdrawAll() public onlyTeam {
        uint256 balance = address(this).balance;
        require(balance > 0, "Not enough balance");

        uint256 communityShare = balance.mul(5).div(100);
        uint256 teamMemberShare = balance.mul(19).div(100);

        _withdraw(communityWallet, communityShare);
        _withdraw(addr1, teamMemberShare);
        _withdraw(addr2, teamMemberShare);
        _withdraw(addr3, teamMemberShare);
        _withdraw(addr4, teamMemberShare);
        _withdraw(addr5, address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success,) = _address.call{value : _amount}("");
        require(success, "Failed to withdraw Ether");
    }
}