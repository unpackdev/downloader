// SPDX-License-Identifier: MIT

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

pragma solidity ^0.8.0;

contract Tunies is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 7500; // Max supply allowed to be minted

    uint256 public root_mint_amount = 5; // Mints allocated from allowlist mint for each allowlisted address
    uint256 public pub_mint_max_per_tx = 5; // Max mint per transaction for public mint
    uint256 public total_reserved = 60; // total reserved amount to be minted by team + community wallet
    uint256 public item_price_pub = 0.075 ether; // Mint price, public
    uint256 public item_price_wl = 0.06 ether; // Mint price, allowlist

    bytes32 public root; // Merkle root

    string private baseURI = "ipfs://QmZ4Kq6cSgtk1Pf5CBnsyWwR6QaohCiPhaY34YWxzXD8QF/"; // Base URI for tokenURI
    string private unrevealedURI = "ipfs://QmYJrqm3cNgusxasK1dV9QCx3gc4dbfkLVo5pzp7EQcfcE"; // Unrevealed URI for all tokens

    bool public is_allowlist_active; // Boolean for allowlist mint function
    bool public is_public_mint_active; // Boolean for public mint function
    bool public is_revealed; // Boolean for unrevealed vs revealed URI

    mapping (address => uint256) reservations; // Mapping tracks reservation mints

    constructor (bytes32 _root) ERC721A("Tunies NFT", "Tunies") {
        root = _root;

        reservations[0xB44e88a848cE623577D057a3825Da0d6834aF305] = 60;  // tunies
    }

    /*
      Mint for Allowlisted Addresses - Reentrancy Guarded
      _proof - bytes32 array to verify hash of msg.sender(leaf) is contained in merkle tree
      _amt - uint256 specifies amount to mint (must be no greater than root_mint_amount)
    */
    function allowlistMint(bytes32[] calldata _proof, uint256 _amt) external payable nonReentrant {
        require(totalSupply() + _amt <= MAX_SUPPLY - total_reserved, "Mint Amount Exceeds Total Allowed Mints");
        require(msg.sender == tx.origin, "Minting From Contract Not Allowed");
        require(item_price_wl * _amt == msg.value,  "Incorrect Payment");
        require(is_allowlist_active, "Allowlist Mint Not Active");

        uint64 newClaimTotal = _getAux(msg.sender) + uint64(_amt);
        require(newClaimTotal <= root_mint_amount, "Requested Claim Amount Invalid");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_proof, root, leaf), "Invalid Proof/Root/Leaf");

        _setAux(msg.sender, newClaimTotal);
        _safeMint(msg.sender, _amt);
    }

    /*
      Public Mint - Reentrancy Guarded
      _amt - uint256 amount to mint
    */
    function publicMint(uint256 _amt) external payable nonReentrant {
        require(totalSupply() + _amt <= MAX_SUPPLY - total_reserved, "Mint Amount Exceeds Total Allowed Mints");
        require(msg.sender == tx.origin, "Minting From Contract Not Allowed");
        require(item_price_pub * _amt == msg.value,  "Incorrect Payment Amount");
        require(is_public_mint_active, "Public Mint Not Active Yet");
        require(_amt <= pub_mint_max_per_tx, "Over Per Transaction Limit");

        _safeMint(msg.sender, _amt);
    }

    /*
      Reserved Team Mint, 250 Total - Reentrancy Guarded
      _amt - uint256 amount to mint
    */
    function reservationMint(uint256 _amt) external nonReentrant {
        uint256 amtReserved = reservations[msg.sender];

        require(totalSupply() + _amt <= MAX_SUPPLY, "Requested Amount Exceeds Total Supply");
        require(amtReserved >= _amt, "Invalid Reservation Amount");
        require(amtReserved <= total_reserved, "Amount Exceeds Total Reserved");

        reservations[msg.sender] -= _amt;
        total_reserved -= _amt;

        _safeMint(msg.sender, _amt);
    }

    /*
      SETTORS - onlyOwner access
    */

    /*
      Access modifier for allowlist mint function
      _val - TRUE for active / FALSE for inactive mint
    */
    function setAllowlistMintActive(bool _val) external onlyOwner {
        is_allowlist_active = _val;
    }

    /*
      Access modifier for public mint function
      _val - TRUE for active / FALSE for inactive mint
    */
    function setPublicMintActive(bool _val) external onlyOwner {
        is_public_mint_active = _val;
    }

    /*
      Access modifier for public mint function
      _val - TRUE for active / FALSE for inactive mint
    */
    function setIsRevealed(bool _val) external onlyOwner {
        is_revealed = _val;
    }

    /*
      Plant new merkle root to replace allowlist
      _root - bytes32 value of new merkle root
      _amt - uint256 amount each allowlisted address can mint
    */

    function plantNewRoot(bytes32 _root, uint256 _amt) external onlyOwner {
        root = _root;
        root_mint_amount = _amt;
    }

    /*
      Sets new base URI for NFT as _uri
      _uri - string value to be new base URI
    */
    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    /*
      Sets new unrevealed URI for NFT as _uri
      _uri - string value to be new unrevealed URI
    */
    function setUnrevealedURI(string memory _uri) external onlyOwner {
        unrevealedURI = _uri;
    }

    /*
      Sets new public mint price
      _price - uint256 value to be new price
    */
    function setItemPricePub(uint256 _price) external onlyOwner {
        item_price_pub = _price;
    }

    /*
      Sets new allowlist mint price
      _price - uint256 value to be new price
    */
    function setItemPriceWL(uint256 _price) external onlyOwner {
        item_price_wl = _price;
    }

    /*
      Sets new max mint amount per transaction
      _amount - uint256 value to be new max mint amount per transaction
    */
    function setMaxMintPerTx(uint256 _amt) external onlyOwner {
        pub_mint_max_per_tx = _amt;
    }

    /*
      GETTORS - view functions
    */

    /*
      Informational function returns whether or not a specified _user is included in current merkle root
      _proof - bytes32 array used to verify that _user is a allowlisted address
      _user - address to check remaining mints for
      amount - uint256 RETURN value that specifies number of remaining mints
    */
    function isOnAllowList(bytes32[] calldata _proof, address _user) public view returns (uint256) {
        bytes32 leaf = keccak256(abi.encodePacked(_user));
        return MerkleProof.verify(_proof, root, leaf) ? 1 : 0;
    }

    /*
      Returns current sale status
    */
    function getSaleStatus() public view returns (string memory) {
        if(is_public_mint_active) {
            return "public";
        }
        else if(is_allowlist_active) {
            return "allowlist";
        }
        else {
            return "closed";
        }
    }

    /*
      Returns tokenURI for specified _tokenID
    */
    function tokenURI(uint256 _tokenID) public view virtual override returns (string memory) {
        require(_exists(_tokenID), "ERC721Metadata: URI query for nonexistent token");

        if(is_revealed) {
            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenID.toString(), ".json")) : "";
        }
        else {
            return unrevealedURI;
        }
    }

    /*
      Utility Functions - onlyOwner access
    */

    /*
      Transfers ETH from this contract to predesignated addresses
    */
    function withdrawEth() public onlyOwner nonReentrant {
        uint256 total = address(this).balance;

        require(payable(0x452A89F1316798fDdC9D03f9af38b0586F8142e5).send((total * 5) / 100)); // palm tree
        require(payable(0x0c010EC68FE560a8Dacd025851E77801BaC0b8e0).send((total * 6) / 100)); // artist
        require(payable(0x6D736E36DEDBc9c8b6f93c44Cf8b4a2FC1BBBD0B).send((total * 89) / 100)); // tunies
    }

    /*
      Revert any accidental sending of ETH or any ERC-20 tokens to the contract
    */
    receive() payable external {
        revert("Contract does not allow receipt of ETH or ERC-20 tokens");
    }

    /*
      Revert handling for any bad data or function calls
    */
    fallback() payable external {
        revert("An incorrect function was called");
    }
}