// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.9.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./ERC721URIStorage.sol";
import "./MerkleProof.sol";

/// @custom:security-contact 1337foxnft@gmail.com
contract Fox1337 is ERC721URIStorage, Pausable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using SafeMath for uint64;
    using MerkleProof for bytes32[];

    /** WHITELIST INFO */
    bytes32 public merkleRoot =
        0xd046b5b4bd5feadf053d9446c19b5499854b4f6e90020ca5407e1dd01e7d1403;

    /** NFT DATA */
    uint64 public constant FOX1337_PRICE = 0.037 ether;
    uint16 public constant MAX_FOX1337 = 1337;
    uint8 public constant MAX_FOX1337_RESERVED = 37;
    uint8 public constant MAX_FOX1337_PURCHASE = 7;

    string private _fox1337BaseURI;
    bool private _isReservedClaimed = false;

    /* TOKEN ID STORAGE */
    Counters.Counter private _fox1337IdCounter;

    constructor() ERC721("1337Fox", "1337") {
        _pause();
    }

    /**
     * @dev function to get the baseURI of the metadata
     * @return the contract's baseURI
     */
    function _baseURI() internal view override returns (string memory) {
        return _fox1337BaseURI;
    }

    /**
     * @dev function to get the baseURI of the metadata
     * @return the contract's baseURI
     */
    function contractURI() public view returns (string memory) {
        return _fox1337BaseURI;
    }

    /**
     * @dev function to change the contract's baseURI of the metadata
     * @param baseURI the new baseURI
     */
    function setBaseURI(string memory baseURI) external onlyOwner {
        _fox1337BaseURI = baseURI;
    }

    /**
     * @dev See {ERC721URIStorage}
     */
    function setTokenURI(uint256 _tokenId, string memory _tokenURI) external {
        _setTokenURI(_tokenId, _tokenURI);
    }

    /**
     * @dev function to get current number of tokens minted
     * @return the number of tokens minted
     */
    function totalSupply() public view returns (uint256) {
        return _fox1337IdCounter.current();
    }

    /**
     * @dev function to check if there is available an specific number of tokens to mint.
     * @param _numberOfTokens the number of tokens to mint
     * @return true if the address has enough tokens to be minted
     */
    function hasSupply(uint8 _numberOfTokens) public view returns (bool) {
        return totalSupply().add(_numberOfTokens) <= MAX_FOX1337;
    }

    /**
     * @dev See {Pausable}
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev See {Pausable}
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev function to withdraw all the funds.
     */
    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "There is no funds to withdraw");

        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @dev function to check if there is enough msg.value to mint an specific number of tokens.
     * @param _numberOfTokens the number of tokens to mint
     * @return true if the there is enough msg.value
     */
    function _isEnoughValue(uint8 _numberOfTokens)
        internal
        view
        returns (bool)
    {
        return (msg.value >= FOX1337_PRICE.mul(_numberOfTokens));
    }

    /**
     * @dev function to check an address is whitelisted
     * @param _merkleProof the address to check
     * @return true if is whitelisted.
     */
    function _isWhiteListed(address _to, bytes32[] calldata _merkleProof)
        internal
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(_to));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    /**
     * @dev function to mint a list of reserved tokens.
     * @param _foxTokensReserved the list of tokens to mint
     * @param _numberOfTokensToMint the quantity of tokens to be mint
     */
    function reserve1337Fox(
        uint256[] memory _foxTokensReserved,
        uint8 _numberOfTokensToMint
    ) external payable onlyOwner whenNotPaused {
        require(
            hasSupply(_numberOfTokensToMint),
            "Purchase would exceed max supply"
        );
        require(_isReservedClaimed == false, "Can claim reserved only once");

        _mintTokensList(msg.sender, MAX_FOX1337_RESERVED, _foxTokensReserved);
        _isReservedClaimed = true;
    }

    /**
     * @dev function to mint a list of tokens.
     * @param _to the to store the tokens mint
     * @param _numberOfTokensToMint the quantity of tokens to be mint
     * @param _tokensIdToMint the list of tokens to mint
     */
    function _mintTokensList(
        address _to,
        uint8 _numberOfTokensToMint,
        uint256[] memory _tokensIdToMint
    ) internal {
        for (uint8 i = 0; i < _numberOfTokensToMint; i++) {
            _fox1337IdCounter.increment();
            _safeMint(_to, _tokensIdToMint[i]);
        }
    }

    /**
     * @dev MAIN FUNCTION. Used to mint the tokens
     * @param _to the to store the tokens mint
     * @param _foxTokens the list of tokens to mint
     * @param _numberOfTokensToMint the quantity of tokens to be mint
     * @param _merkleProof the merkleProof for whitelist
     */
    function mint1337Fox(
        address _to,
        uint256[] memory _foxTokens,
        uint8 _numberOfTokensToMint,
        bytes32[] calldata _merkleProof
    ) external payable whenNotPaused {
        require(_numberOfTokensToMint > 0, "No 1337Fox to mint");
        require(
            _numberOfTokensToMint <= MAX_FOX1337_PURCHASE,
            "Number of 1337Fox incorrect"
        );
        require(
            hasSupply(_numberOfTokensToMint),
            "Purchase would exceed max supply"
        );

        if (_isWhiteListed(_to, _merkleProof)) {
            if (this.balanceOf(_to) == 0) {
                require(
                    _isEnoughValue(_numberOfTokensToMint - 1),
                    "Ether amount incorrect"
                );
            } else {
                require(
                    _isEnoughValue(_numberOfTokensToMint),
                    "Ether amount incorrect"
                );
            }
            _mintTokensList(_to, _numberOfTokensToMint, _foxTokens);
        } else {
            require(
                _isEnoughValue(_numberOfTokensToMint),
                "Ether amount incorrect"
            );
            _mintTokensList(_to, _numberOfTokensToMint, _foxTokens);
        }
    }
}
