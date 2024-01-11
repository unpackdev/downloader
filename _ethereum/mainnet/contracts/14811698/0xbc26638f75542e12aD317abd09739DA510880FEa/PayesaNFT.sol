// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC721.sol";
import "./MerkleProof.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";

/**
 * @title PayesaNFT
 */
contract PayesaNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    mapping(address => bool) private _minters;
    bool public whitelist_active = false;
    bool public sale_active = false;
    Counters.Counter private _tokenIdCounter;
    uint256 public minting_price = 0.05 ether;
    uint256 public HARD_CAP = 2000;
    uint256 public SOFT_CAP = 1800;
    uint256 public MAX_AMOUNT = 5;
    bytes32 public MERKLE_ROOT;
    bool public is_collection_locked = false;
    string public contract_base_uri = "https://0rexd186dj.execute-api.us-east-1.amazonaws.com/dev/generative/payesa/";
    address public vault_address;

    constructor(string memory _name, string memory _ticker)
        ERC721(_name, _ticker)
    {}

    function _baseURI() internal view override returns (string memory) {
        return contract_base_uri;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        string memory _tknId = Strings.toString(_tokenId);
        return string(abi.encodePacked(contract_base_uri, _tknId, ".json"));
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory ownerTokens)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalTkns = totalSupply();
            uint256 resultIndex = 0;
            uint256 tnkId;

            for (tnkId = 1; tnkId <= totalTkns; tnkId++) {
                if (ownerOf(tnkId) == _owner) {
                    result[resultIndex] = tnkId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    function fixBaseURI(string memory _newURI) public onlyOwner {
        require(!is_collection_locked, "Collection locked");
        contract_base_uri = _newURI;
    }

    /*
        This method will allow owner lock the collection
     */

    function lockCollection() public onlyOwner {
        is_collection_locked = true;
    }

    /*
        This method will allow owner to start and stop the sale
    */
    function fixSaleState(bool newState) external onlyOwner {
        require(!is_collection_locked, "Collection locked");
        sale_active = newState;
    }

    /*
        This method will allow owner to fix max amount of nfts per minting
    */
    function fixMaxAmount(uint256 newMax) external onlyOwner {
        require(!is_collection_locked, "Collection locked");
        MAX_AMOUNT = newMax;
    }

    /*
        This method will allow owner to fix the minting price
    */
    function fixPrice(uint256 price) external onlyOwner {
        require(!is_collection_locked, "Collection locked");
        minting_price = price;
    }

    /*
        This method will allow owner to fix the whitelist role
    */
    function fixWhitelist(bool state) external onlyOwner {
        require(!is_collection_locked, "Collection locked");
        whitelist_active = state;
    }

    /*
        This method will allow owner to change the gnosis safe wallet
    */
    function fixVault(address newAddress) public onlyOwner {
        require(newAddress != address(0), "Can't use black hole");
        vault_address = newAddress;
    }

    /*
        This method will allow owner to set the merkle root
    */
    function fixMerkleRoot(bytes32 root) external onlyOwner {
        require(!is_collection_locked, "Collection locked");
        MERKLE_ROOT = root;
    }

    /*
        This method will mint the token to provided user, can be called just by the proxy address.
    */
    function dropNFT(address _to, uint256 _amount) public onlyOwner {
        uint256 reached = _tokenIdCounter.current() + _amount;
        require(reached <= HARD_CAP, "Hard cap reached");
        for (uint256 j = 1; j <= _amount; j++) {
            _tokenIdCounter.increment();
            uint256 newTokenId = _tokenIdCounter.current();
            _mint(_to, newTokenId);
        }
    }

    /*
        This method will return the whitelisting state for a proof
    */
    function isWhitelisted(bytes32[] calldata _merkleProof, address _address)
        public
        view
        returns (bool)
    {
        require(whitelist_active, "Whitelist is not active");
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        bool whitelisted = MerkleProof.verify(_merkleProof, MERKLE_ROOT, leaf);
        return whitelisted;
    }

    /*
        This method will allow owner to withdraw all ethers
    */
    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(vault_address != address(0) && balance > 0, "Can't withdraw");
        bool success;
        (success, ) = vault_address.call{value: balance}("");
        require(success, "Withdraw to vault failed");
    }

    /*
        This method will allow users to buy the nft
    */
    function buyNFT(bytes32[] calldata _merkleProof) public payable {
        require(sale_active, "Can't buy because sale is not active");
        bool canMint = true;
        if (whitelist_active) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            canMint = MerkleProof.verify(_merkleProof, MERKLE_ROOT, leaf);
        }
        require(
            canMint && msg.value % minting_price == 0,
            "Sorry you can't mint right now"
        );
        uint256 amount = msg.value / minting_price;
        require(
            amount >= 1 && amount <= MAX_AMOUNT,
            "Amount should be at least 1 and must be less or equal to 5"
        );
        uint256 reached_hardcap = amount + totalSupply();
        require(reached_hardcap <= SOFT_CAP, "Soft cap reached");
        uint256 j = 0;
        for (j = 0; j < amount; j++) {
            _tokenIdCounter.increment();
            uint256 nextId = _tokenIdCounter.current();
            _mint(msg.sender, nextId);
        }
    }
}
