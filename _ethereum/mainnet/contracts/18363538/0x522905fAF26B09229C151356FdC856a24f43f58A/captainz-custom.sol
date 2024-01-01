// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ECDSA.sol";
import "./Ownable.sol";
import "./ERC2981.sol";
import "./ReentrancyGuard.sol";
import "./ERC721AV4.sol";
import "./ERC721.sol";

contract ThePixelCaptainz is ERC721, ERC2981, Ownable, ReentrancyGuard {
    mapping(address => uint256[]) public _ownedTokens;

    string public baseURI;
    uint256 public maxSupply = 1069;
    uint256 public giveaway = 300;
    bool public isClaimingActive = true;

    address signer;
    ERC721A mintingContract;
    uint256 totalSupply;
    bool public _revealed = true;
    mapping(address => uint256) addressBlockBought;
    mapping(uint256 => bool) isTokenClaimed;

    constructor() ERC721("The Pixel Captainz", "PIXELCAPTAINZ")  {
        _setDefaultRoyalty(0xc858Db9Fd379d21B49B2216e8bFC6588bE3354D7, 1000);
        mintingContract = ERC721A(0x47448240A1596Ed76DB6426FA9CC26B09FA3b830); // PROD
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    modifier isSecured(uint8 mintType) {
        require(addressBlockBought[msg.sender] < block.timestamp, "CANNOT_MINT_ON_THE_SAME_BLOCK");
        require(tx.origin == msg.sender,"CONTRACTS_NOT_ALLOWED_TO_MINT");

        if(mintType == 1) {
            require(isClaimingActive, "PHASE_1_IS_NOT_YET_ACTIVE");
        }
        _;
    }

    function claim(uint256[] memory tokenId) external isSecured(1) {
        require(totalSupply + tokenId.length <= maxSupply, "EXCEEDS_MAX_SUPPLY");
        for (uint i = 0; i < tokenId.length; i++) {
            require(mintingContract.ownerOf(tokenId[i]) == msg.sender, "YOU_ARE_NOT_THE_OWNER_OF_THIS_TOKEN");
            addressBlockBought[msg.sender] = block.timestamp;
            totalSupply += 1;
            _safeMint( msg.sender, tokenId[i] );
        }
    }

    function updateRoyaltyPercentage(address newAddress, uint96 amount) external onlyOwner {
        _setDefaultRoyalty(newAddress, amount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function reveal(bool revealed, string calldata newbaseURI) external onlyOwner {
        _revealed = revealed;
        baseURI = newbaseURI;
    }

    function toggleClaimACtive() external onlyOwner {
        isClaimingActive = !isClaimingActive;
    }


    function setMinContract(address _mintingContract) external onlyOwner {
        mintingContract = ERC721A(_mintingContract);
    }


    function isAuthorized(bytes memory sig,bytes32 digest) private view returns (bool) {
        return ECDSA.recover(digest, sig) == signer;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }
    
    /**
     * Withdraw Ether
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");

        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Failed to withdraw payment");
    }
}