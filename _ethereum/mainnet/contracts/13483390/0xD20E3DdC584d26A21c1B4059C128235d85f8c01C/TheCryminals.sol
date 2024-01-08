// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ECDSA.sol";
import "./Ownable.sol";

contract TheCryminals is ERC721, Ownable {

    using ECDSA for bytes32;

    // base configuration
    uint constant public MAX_SUPPLY = 10000;
    uint constant public PRICE = 0.025 ether;

    string public baseURI;
    uint public reservedSupply;
    uint public maxMintsPerTransaction;
    uint public mintingStartTimestamp;

    // presale
    address public authorizedSigner;
    mapping(address => uint) public claimed;

    uint public totalSupply;

    constructor() ERC721("The Cryminals", "TCRM") {
        mintingStartTimestamp = 1635192000;
    }

    // Setters region
    function setBaseURI(string memory _baseURIArg) external onlyOwner {
        baseURI = _baseURIArg;
    }

    function setReservedSupply(uint _reservedSupply) external onlyOwner {
        reservedSupply = _reservedSupply;
    }

    function setMaxMintsPerTransaction(uint _maxMintsPerTransaction) external onlyOwner {
        maxMintsPerTransaction = _maxMintsPerTransaction;
    }

    function setMintingStartTimestamp(uint _mintingStartTimestamp) external onlyOwner {
        mintingStartTimestamp = _mintingStartTimestamp;
    }

    function setAuthorizedSigner(address _authorizedSigner) external onlyOwner {
        authorizedSigner = _authorizedSigner;
    }

    function configure(
        uint _reservedSupply,
        uint _maxMintsPerTransaction,
        uint _mintingStartTimestamp,
        address _authorizedSigner
    ) external onlyOwner {
        reservedSupply = _reservedSupply;
        maxMintsPerTransaction = _maxMintsPerTransaction;
        mintingStartTimestamp = _mintingStartTimestamp;
        authorizedSigner = _authorizedSigner;
    }
    // endregion

    // region
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    //endregion

    //
    function hashTransaction(address minter, uint maxClaimable) private pure returns (bytes32) {
        bytes32 argsHash = keccak256(abi.encodePacked(minter, maxClaimable));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", argsHash));
    }

    function recoverSignerAddress(address minter, uint maxClaimable, bytes memory signature) private pure returns (address) {
        bytes32 hash = hashTransaction(minter, maxClaimable);
        return hash.recover(signature);
    }

    // Mint and Claim functions
    modifier maxSupplyCheck(uint amount)  {
        require(totalSupply + reservedSupply + amount <= MAX_SUPPLY, "Tokens supply reached limit");
        _;
    }

    function claim(uint amount, uint maxClaimable, bytes memory signature) external payable {
        require(reservedSupply >= amount, "Reserve supply is out");
        require(block.timestamp >= mintingStartTimestamp, "Minting is not available");
        require(claimed[msg.sender] + amount <= maxClaimable, "You have claimed all tokens");
        require(recoverSignerAddress(msg.sender, maxClaimable, signature) == authorizedSigner, "You have not access to claiming");

        claimed[msg.sender] += amount;
        reservedSupply -= amount;
        mintNFTs(msg.sender, amount);
    }

    function mint(uint amount) external payable {
        require(block.timestamp >= mintingStartTimestamp, "Minting is not available");
        require(amount * PRICE == msg.value, "Wrong ethers value");
        require(amount <= maxMintsPerTransaction, "Max mints per transaction constraint violation");

        mintNFTs(msg.sender, amount);
    }

    function mintNFTs(address to, uint amount) internal maxSupplyCheck(amount) {
        uint fromToken = totalSupply + 1;
        totalSupply += amount;
        for (uint i = 0; i < amount; i++) {
            _mint(to, fromToken + i);
        }
    }
    //endregion

    function airdrop(address[] memory addresses, uint[] memory amounts) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            mintNFTs(addresses[i], amounts[i]);
        }
    }

    function airdropFromSupply(address[] memory addresses, uint[] memory amounts) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            require(reservedSupply >= amounts[i], "Reserve supply is out");
            reservedSupply -= amounts[i];
        }
        for (uint i = 0; i < addresses.length; i++) {
            mintNFTs(addresses[i], amounts[i]);
        }
    }

    function withdraw() public onlyOwner {
        uint _balance = address(this).balance;
        payable(0x1fD88f9fe115Bcf91F1a523D8bB41a9b8D93Ce9A).transfer(_balance * 30 / 100);
        payable(0xb0EE3Cf26cC794ad7d901e24bc653D33d1956e8c).transfer(_balance * 10 / 100);
        payable(0xBa4b7a79fB24eC220d7a593AEA1cd107f0e0dB87).transfer(_balance * 10 / 100);
        payable(0x1Bcae4AAd9103029F925Ad3c2346b566ECF848c3).transfer(_balance * 10 / 100);
        payable(0xCCe267417F8138063b938809B9d7b0f0eFCbC720).transfer(_balance * 10 / 100);
        payable(0xff43aD1865fCf2B2A6ffc5607c7a00a3cBDD78eB).transfer(_balance * 14 / 100);
        payable(0x5c3dCf9EC119E7E01c3eF6Efe9B1621A07376059).transfer(_balance * 16 / 100);
    }

}