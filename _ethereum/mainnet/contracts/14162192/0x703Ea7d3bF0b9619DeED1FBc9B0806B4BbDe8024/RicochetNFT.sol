pragma solidity ^0.6.6;

import "./RicochetNFTBase.sol";
import "./MerkleProof.sol";

contract RicochetNFT is RicochetNFTBase {
    string public defaultURI;
    uint public startingIndex;

    bytes32 public merkleRoot = 0xf4e19bd6c9cde075ba1ef8063b82f67ef829cbb400d831af24791005908c119c;

    mapping (address => bool) public whitelistClaimed;

    constructor(
        uint256 _mintFeePerToken,
        uint256 _maxRicochet,
        string memory _defaultURI
    )
        public
        RicochetNFTBase(_mintFeePerToken, _maxRicochet)
    {
      defaultURI = _defaultURI;
    }

    function baseTokenURI() public view returns (string memory) {
        return defaultURI;
    }

    function setDefaultURI(string memory _defaultURI) public onlyOwner {
        defaultURI = _defaultURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(defaultURI).length > 0 ? string(abi.encodePacked(defaultURI, tokenId.toString())) : "";
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, totalSupply())));
    }

    function finalizeStartingIndex() public {
        require(startingIndex == 0, "Dice have already been rolled");
        startingIndex = random() % MAX_RICOCHET;
    }

    /**
     * @dev mint `numberToken` for msg.sender aka who call method.
     * @param numberToken number token collector want to mint
     */
    function _mintRicochet(uint256 numberToken, address userAddress, uint256 tokenIndex) internal returns (bool) {
        for (uint256 i = 0; i < numberToken; i++) {
            if (tokenIndex < MAX_RICOCHET) _safeMint(userAddress, tokenIndex);
        }
        return true;
    }

    function mintRicochet(uint256 numberToken)
        public
        payable
        online
        mintable(numberToken, totalSupply())
        returns (bool)
    {
        return _mintRicochet(numberToken, _msgSender(), totalSupply());
    }

    function mintRicochetToAddressWithId(uint256 numberToken, address userAddress, uint256 tokenIndex)
        public
        payable
        onlyOwner
        mintable(numberToken, totalSupply())
        returns (bool)
    {
        return _mintRicochet(numberToken, userAddress, tokenIndex);
    }

    function ownerMint(uint256 numberToken)         
        public
        payable
        mintable(numberToken, totalSupply())
        returns (bool)
    {
        require(msg.sender == 0x17Ae58ab79444AD5b8EE2e232CaF13C65c32aF75, "Only owner can mint");
        return _mintRicochet(numberToken, msg.sender, totalSupply());
    }
}