// SPDX-License-Identifier: MIT

/**
*   @title ERC-721 TL Core
*   @notice ERC-721 contract with owner and admin, merkle claim allowlist, public minting, airdrop, and owner minting
*   @author Transient Labs
*/

/*
   ___                            __  ___         ______                  _         __    __       __     
  / _ \___ _    _____ _______ ___/ / / _ )__ __  /_  _________ ____  ___ (____ ___ / /_  / / ___ _/ /  ___
 / ___/ _ | |/|/ / -_/ __/ -_/ _  / / _  / // /   / / / __/ _ `/ _ \(_-</ / -_/ _ / __/ / /_/ _ `/ _ \(_-<
/_/   \___|__,__/\__/_/  \__/\_,_/ /____/\_, /   /_/ /_/  \_,_/_//_/___/_/\__/_//_\__/ /____\_,_/_.__/___/
                                        /___/                                                             
*/

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./EIP2981AllToken.sol";

contract ERC721TLCore is ERC721, EIP2981AllToken, Ownable {

    bool public allowlistSaleOpen;
    bool public publicSaleOpen;
    bool public frozen;
    uint16 public mintAllowance;
    uint128 internal _tokenId;
    uint256 public mintPrice;
    uint256 public totalSupply;
    
    address payable public payoutAddress;
    address public adminAddress;

    bytes32 public immutable allowlistMerkleRoot;
    
    string internal baseTokenURI;

    mapping(address => uint16) internal numMinted;

    modifier isNotFrozen {
        require(!frozen, "ERC721TLCore: Metadata is frozen");
        _;
    }

    modifier adminOrOwner {
        require(msg.sender == adminAddress || msg.sender == owner(), "ERC721TLCore: Address not admin or owner");
        _;
    }

    /**
    *   @param name is the name of the contract
    *   @param symbol is the symbol
    *   @param royaltyRecipient is the royalty recipient
    *   @param royaltyPercentage is the royalty percentage to set
    *   @param price is the mint price
    *   @param supply is the total token supply
    *   @param merkleRoot is the allowlist merkle root
    *   @param admin is the admin address
    *   @param payout is the payout address
    */
    constructor (string memory name, string memory symbol,
        address royaltyRecipient, uint256 royaltyPercentage,
        uint256 price, uint256 supply, bytes32 merkleRoot,
        address admin, address payout)
        ERC721(name, symbol) EIP2981AllToken(royaltyRecipient, royaltyPercentage) Ownable() {
            mintPrice = price;
            totalSupply = supply;
            allowlistMerkleRoot = merkleRoot;
            adminAddress = admin;
            payoutAddress = payable(payout);
            _tokenId++;
    }

    /**
    *   @notice function to set the allowlist mint status
    *   @param status is the true/false flag for the allowlist mint status
    */
    function setAllowlistSaleStatus(bool status) external virtual adminOrOwner {
        allowlistSaleOpen = status;
    }

    /**
    *   @notice function to set the public mint status
    *   @param status is the true/false flag for the allowlist mint status
    */
    function setPublicSaleStatus(bool status) external virtual adminOrOwner {
        publicSaleOpen = status;
    }

    /**
    *   @notice freezes the metadata for the token
    *   @dev requires admin or owner
    */
    function freezeMetadata() external virtual adminOrOwner {
        frozen = true;
    }

    /**
    *   @notice sets the mint allowance for each address
    *   @dev requires admin or owner
    *   @param allowance is the new allowance
    */
    function setMintAllowance(uint16 allowance) external virtual adminOrOwner {
        mintAllowance = allowance;
    }

    /**
    *   @notice sets the base URI
    *   @dev requires admin or owner
    *   @param newURI is the base URI set for each token
    */
    function setBaseURI(string memory newURI) external virtual adminOrOwner isNotFrozen {
        baseTokenURI = newURI;
    }

    /**
    *   @notice function to change the royalty info
    *   @dev requires admin or owner
    *   @dev this is useful if the amount was set improperly at contract creation.
    *   @param newAddr is the new royalty payout addresss
    *   @param newPerc is the new royalty percentage, in basis points (out of 10,000)
    */
    function setRoyaltyInfo(address newAddr, uint256 newPerc) external virtual adminOrOwner {
        require(newAddr != address(0), "ERC721TLCore: Cannot set royalty receipient to the zero address");
        require(newPerc < 10000, "v: Cannot set royalty percentage above 10000");
        royaltyAddr = newAddr;
        royaltyPerc = newPerc;
    }

    /**
    *   @notice function for batch minting to many addresses
    *   @dev requires owner or admin
    *   @dev airdrop not subject to mint allowance constraintss
    *   @param addresses is an array of addresses to mint to
    */
    function airdrop(address[] calldata addresses) external virtual adminOrOwner {
        require(totalSupply + 1 - _tokenId >= addresses.length, "ERC721TLCore: No token supply left");

        uint256 start = _tokenId;

        for (uint256 i; i < addresses.length; i++) {
            _safeMint(addresses[i], start + i);
        }

        _tokenId += uint128(addresses.length);
    }

    /**
    *   @notice function for minting to the owner's address
    *   @dev requires owner or admin
    *   @dev not subject to mint allowance constraints
    *   @param numToMint is the number to mint
    */
    function ownerMint(uint128 numToMint) external virtual adminOrOwner {
        require(totalSupply + 1 - _tokenId >= numToMint, "ERC721TLCore: No token supply left");

        uint256 start = _tokenId;

        for (uint256 i; i < numToMint; i++) {
            _safeMint(owner(), start + i);
        }

        _tokenId += numToMint;
    }

    /**
    *   @notice function to withdraw ether from the contract
    *   @dev requires admin or owner
    */
    function withdrawEther() external virtual adminOrOwner {
        payoutAddress.transfer(address(this).balance);
    }

    /**
    *   @notice function for users to mint
    *   @dev requires payment
    *   @dev only mint one at a time. If looking to mint more than one at a time, utilize ERC721TLMultiMint
    *   @param merkleProof is the has for merkle proof verification
    */
    function mint(bytes32[] calldata merkleProof) external virtual payable {
        require(_tokenId <= totalSupply, "ERC721TLCore: No token supply left");
        require(msg.value >= mintPrice, "ERC721TLCore: Not enough ether attached to the transaction");
        require(numMinted[msg.sender] < mintAllowance, "ERC721TLCore: Mint allowance reached");
        if (allowlistSaleOpen) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(merkleProof, allowlistMerkleRoot, leaf), "ERC721TLCore: Not on allowlist");
        }
        else if (!publicSaleOpen) {
            revert("ERC721TLCore: Mint not open");
        }

        numMinted[msg.sender]++;

        _safeMint(msg.sender, uint256(_tokenId));
        
        _tokenId++;
    }

    /**
    *   @notice function to set the admin address on the contract
    *   @dev requires owner
    *   @param newAdmin is the new admin address
    */
    function setAdminAddress(address newAdmin) external virtual onlyOwner {
        require(newAdmin != address(0), "ERC721TLCore: New admin cannot be the zero address");
        adminAddress = newAdmin;
    }

    /**
    *   @notice function to set the payout address
    *   @dev requires owner
    *   @param payoutAddr is the new payout address
    */
    function setPayoutAddress(address payoutAddr) external virtual onlyOwner {
        require(payoutAddr != address(0), "ERC721TLCore: Payout address cannot be the zero address");
        payoutAddress = payable(payoutAddr);
    }

    /**
    *   @notice burn function for owners to use at their discretion
    *   @dev requires the msg sender to be the owner or an approved delegate
    *   @param tokenId is the token ID to burn
    */
    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Burn: Not Approved or Owner");
        _burn(tokenId);
    }

    /**
    *   @notice function to get number minted
    *   @param addr address to query
    *   @return uint16 for number minted
    */
    function getNumMinted(address addr) external view virtual returns (uint16) {
        return numMinted[addr];
    }

    /**
    *   @notice function to view remaining supply
    */
    function getRemainingSupply() external view virtual returns (uint256) {
        return totalSupply + 1 - _tokenId;
    }
   
    /**
    *   @notice overrides supportsInterface function
    *   @param interfaceId is supplied from anyone/contract calling this function, as defined in ERC 165
    *   @return a boolean saying if this contract supports the interface or not
    */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, EIP2981AllToken) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
    *   @notice override standard ERC721 base URI
    *   @dev doesn't require access control since it's internal
    *   @return string representing base URI
    */
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

}