// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//	                                                             ..
//	                                                             %#      .                          ,&&&
//	                                                        .**/(&&#(&&&,                        %&%...&%
//	                          &(                 *&&&#                      %&&%.           .&&&.......*&
//	                        .,/&&&&&&&%&&&&&&&(                                    (&&**&&&*............&*
//	#&*((###((//**,,,...................,&#                                              %&&&/..........&(
//	 (&.,.............................,&                                                      #&&.......&#
//	  .&////////*....................,&                                                            (&%,.&/
//	    &&////////////...............&/                                                                 (&&,         (&&
//	      &%//////////////,...........&                                                                              &/
//	       ,&(////////////.............%&                                                                         (&.
//	         ,&#/////////////*............&&                                                                  .&&
//	            &&//////////////*.............*%&&&(.          &&&(              *                       ,&&&&.
//	              *&%//////////////////&............(...,#&&&#.   &#...#&&&&(,     /&%&&&(,         ,#&&&/
//	                 *&&*//////////////&..........,,&............./&&&.........................&,..%&#&
//	                     %&%//////////#%........../*.................................**/*.......&.&%
//	                         #&&//////&.................&&&&@&@&&&&&&@............&&&&&&&&&&&...&&
//	                              *&&&,..............(&/....*&&&&&&&&&...........@.&&&&&&&&,,/..&,
//	                               &&...............*&....&&&&&&&&&@&&,.........,*&&&&&&&&&&&...&#
//	                              %&..................,&#../&&&&&#(*...............,,............&&
//	                             .&&(..................  ...................&@@@@.................&#
//	                             % &*............................................................/&&
//	                               &&*..........................................................(#&,
//	                                (&&............................&...............&...........&&..
//	                                   &&....................................................%&.
//	                                 &&&&&%./&/....,&&%,..............*...................#&&.
//	                                 &&/////%&&&%&&#.&&//&&&%.....&&%..&&#....*&&&*..*&&&/(&&&&&
//	                                  %&#///////&&///#&&&/////%&&&&&&/#&&(&&&(/(&&&#/////#%///&&/
//	                               .&&/////(///////(//////////////#(///#//////%&&&&%//////&&(%&.
//	                                (&&&#.....&&//////////////////////////////////&&//////(&...&&
//	                                .&,.........&&//////////////////////////////////&//////&#...,&*
//	                               /&.............#&#///////////////////////////////(&/////&&.....&(
//	                              *&.................&&//////////////////////////////&/////#&......&,
//	                              &,...................,&&(/%&/////////////////////////////#&......,&
//	                             &%.............&&.........&&&/&&(/////////////////////////%&.......%&
//	                            *&.............&&..............*&&&&&#/////////////////////&(........&.
//	                            &#............&&.......................&&&%(//////////////&&.........&&
//	                           ,&............,&/............................./&&&&&&%#(//&&........../&
//	                           &%............&&.........................................../&*.........&.
//	                           &,............&(............................................%&.........&/
//	                          (&............%&.............................................*&*........&%
//	                          &#............&&..............................................&&........%&
//	                         .&.............&/..............................................%&........*&
//	                         %&............(&,............................................../&.........&.
//	                         &#............&&...............................................,&,........&*

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./IERC2981.sol";

error MintNotActive();
error MintZeroQuantity();
error MintExceedMaxSupply();
error MintPriceNotMeet();
error URIQueryForNonexistentToken();

/**
 * @title WiredeadNFT Smart Contract
 * @author P4tt4n4
 */
contract WiredeadNFT is ERC721, IERC2981, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 constant MAX_SUPPLY = 5000;

    // Private Variables
    string _revealedBaseURI;
    uint256 private _currentId;

    // Public Variables
    string public ProvenanceHash;
    string public UnrevealedBaseURI;
    bool public IsActive = false;
    bool public IsRevealed = false;
    uint256 public SellPrice = 0.025 ether;

    address public Beneficiary;
    address public Royalties;
    uint256 public RoyalityPercentage = 5;

    // Constructor Method
    constructor(
        string memory unrevealedBaseURI,
        address beneficiary,
        address royalties
    ) ERC721("Wiredead", "WD") {
        UnrevealedBaseURI = unrevealedBaseURI;
        Beneficiary = beneficiary;
        Royalties = royalties;
    }

    // Setter Methods
    function setProvenanceHash(string calldata provenanceHash)
        public
        onlyOwner
    {
        ProvenanceHash = provenanceHash;
    }

    function setActive(bool isActive) public onlyOwner {
        IsActive = isActive;
    }

    function setRevealed(bool isRevealed) public onlyOwner {
        IsRevealed = isRevealed;
    }

    function setPrice(uint256 price) public onlyOwner {
        SellPrice = price;
    }

    function setBeneficiary(address beneficiary) public onlyOwner {
        Beneficiary = beneficiary;
    }

    function setRoyalties(address royalties) public onlyOwner {
        Royalties = royalties;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        _revealedBaseURI = uri;
    }

    function setUnrevealedBaseURI(string memory uri) public onlyOwner {
        UnrevealedBaseURI = uri;
    }

    // Getter Methods
    function totalSupply() public view returns (uint256) {
        return _currentId;
    }

    // Metadata
    function _baseURI() internal view virtual override returns (string memory) {
        return _revealedBaseURI;
    }

    /**
     * Return the token URI of the token with the specified `tokenId`. The token URI is
     * dynamically constructed from this contract's base uri if `IsRevealed` is true.
     * @param tokenId The ID of the token to retrive a metadata URI for.
     * @return The metadata URI of the token with the ID of `_id`.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) {
            revert URIQueryForNonexistentToken();
        }

        if (!IsRevealed) {
            return UnrevealedBaseURI;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }

    // Minting
    function mint(uint256 mintAmount) public payable {
        if (!IsActive) {
            revert MintNotActive();
        }
        if (mintAmount <= 0) {
            revert MintZeroQuantity();
        }
        if (_currentId + mintAmount > MAX_SUPPLY) {
            revert MintExceedMaxSupply();
        }

        if (msg.sender != owner()) {
            if (msg.value < SellPrice * mintAmount) {
                revert MintPriceNotMeet();
            }
        }

        for (uint256 i = 1; i <= mintAmount; i++) {
            _currentId++;
            _safeMint(msg.sender, _currentId);
        }
    }

    // Withdraw
    function withdraw() public onlyOwner {
        payable(Beneficiary).transfer(address(this).balance);
    }

    // ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // IERC2981
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address, uint256 royaltyAmount)
    {
        _tokenId; // silence solc warning
        royaltyAmount = (_salePrice / 100) * RoyalityPercentage;
        return (Royalties, royaltyAmount);
    }
}
